#include "TINYDB_NETWORK.h"
#ifdef FULLPC
# include <assert.h>
#endif
#include <math.h>
#include <string.h>

/* Routing component for TinyDB.  Can receive and send
   data and query messages.  Data messages are tuples
   or aggregate values.  Queries represent portions
   of queries being injected into the network.

   In the TAG world, query messages flood down the routing tree,
   and data messages are sent up the network (to the node's) parent
   towards the root.  Obviously, there are other routing mechanisms
   that might make sense,  but the routing system needs to be careful
   to do duplicate elimination -- which may be hard since this API
   doesn't export the contents of the data messages.

   Note that the send routines in this component depend on the higher
   level tuple router in several ugly ways:

   1) They expect that the TOS_MsgPtr's deliver have space for
   the appropriate TINYDB_NETWORK header (type DbMsgHdr) at the
   top.

   The basic routing algorithm implemented by this component works as follows:
   
   1) Each mote maintains a small buffer of "neighbor" motes it can hear
   2) For each neighbor, the mote tracks the signal quality by observing sequence
   numbers on messages from that neighbor degrading quality when messages are missed
   3) Each mote picks a parent from its neighbors;  ideally, parents will be
   motes that have a high signal quality and are close to the root
   4) Once a parent has been selected, motes stick to that parent unless the quality of
   the parent degrades substantially (even if another parent that is closer to the
   root with similar quality appears) -- this "topology stability" property is
   important for insuring correct computation of aggregates.

   Authors:  Sam Madden -- basic structure, current maintainer
             Joe Hellerstein -- initial implementation of neighbor tracking and parent selection
*/


typedef struct{
  DbMsgHdr hdr;
  char data[1];
} NetworkMessage;

#define LEVEL_UNKNOWN -1
#define PARENT_UNKNOWN -1
#define BAD_IX -1
#define PARENT_RESELECT_INTERVAL 5 //5 epochs
#define PARENT_LOST_INTERVAL 10 //5 epochs
#define TIME_OF_FLIGHT 0
#define NUM_RELATIVES 5
#define MY_LEVEL ( (TOS_LOCAL_ADDRESS == 0) ? 0 : \
                    ((VAR(parentIx) == PARENT_UNKNOWN \
					  || VAR(relLevel)[VAR(parentIx)] == LEVEL_UNKNOWN) ? \
                         LEVEL_UNKNOWN : \
                         (VAR(relLevel)[VAR(parentIx)] + 1)) )
#define MAX_PROB_THRESH 127  //only switch parents if there's a node thats a lot more reliable

// We do a moving average at time t where
// avg_t = avg_{t-1}*(1-alpha) + alpha*newvalue
// Since we're using integers, we shift by ALPHABITS, rather than multiplying
// by a fraction.
// so ALPHABITS=2 is like alpha = 0.25 (i.e. divide by 4)
#define ALPHABITS 2

typedef enum {
  QUERY_TYPE = 0, 
  DATA_TYPE = 1
} MsgType;

#define TOS_FRAME_TYPE TINYDB_NETWORK_frame
TOS_FRAME_BEGIN(TINYDB_NETWORK_frame) {
  unsigned short sendCount; // increment each epoch
  // We track NUM_RELATIVES parents as potential parents.
  // For each, we will track the mean # of drops of msgs from that "relative".
  char relatives[NUM_RELATIVES]; // an array of senders we're tracking as potential parents
  char relOccupiedBits; // occupancy bitmap for slots in the relatives array
  short parentIx; // the current parent's index in the "relatives" array
                  // invariant: parentIx < NUM_RELATIVES
                  // invariant: relOccupiedBits is on for parentIx
  unsigned short lastIdxRelative[NUM_RELATIVES]; // last idx # from this rel
  unsigned char commProb[NUM_RELATIVES]; // an 8-bit weighted moving average of
                                         // delivery success (delivered = 255,
                                         // dropped = 0).
  char relLevel[NUM_RELATIVES];  // current level of rel

  TOS_MsgPtr msg;
  TOS_Msg dbg;
  char amId;
  short idx;
  bool forceTopology;
  bool uart;  //is uart in use?
  bool local; //was this message send local, or do our children need to see completion events
  bool wasCommand; //is there a command that needs to be executed in dbg?
  bool radio; //is radio in use? (pending flag for radio)

  char fanout;	// fanout of routing tree if forceTopology is true
  bool centralized; //all messages should be routed to the root (no aggregation?)
  short minparent; // min parent id number when we force topology
  short maxparent; // max parent id number when we force topology
  short parentCand1, parentCand2, parentCand3;
  short lastCheck, lastHeard;
}
TOS_FRAME_END(TINYDB_NETWORK_frame);

typedef struct {
	short nodeid;
	short msgcount;
} NodeMsgCount;

void initHeader(DbMsgHdr *header);
bool processHeader(DbMsgHdr header, MsgType type);
void setParentRange();


void TOS_COMMAND(TINYDB_NETWORK_INIT)() {
  VAR(sendCount) = 0;
  VAR(lastCheck) = 0;
  VAR(lastHeard) = 0;

  // mark statistics invalid
  VAR(relOccupiedBits) = 0;
  VAR(parentIx) = PARENT_UNKNOWN;

  //debugging ugliness -- if we're the root, make sure
  //set our parent properly.  
  if (TOS_LOCAL_ADDRESS == 0) {
    VAR(relOccupiedBits) = 1;
    VAR(relatives)[0] = 0;
    VAR(relLevel)[0] = LEVEL_UNKNOWN;
    VAR(parentIx) = 0;
  }
  VAR(idx) = 0;
  VAR(fanout) = 0xFF; //default -- no fanout
  VAR(centralized) = FALSE;
  VAR(fanout) = 0;
  VAR(radio) = FALSE;
  VAR(forceTopology) = FALSE;
  VAR(wasCommand) = FALSE;
  VAR(uart) = FALSE;

}

/* Send a 'data' message -- data messages contain information about
   data tuples that should be sent up the routing tree.
   
   REQUIRES:  msg is a message buffer of which the first entry is of
   type DbMsgHdr

   SIGNALS: TINYDB_NETWORK_SUB_MSG_SEND_DONE after message is sent,
   unless an error is returned.

   RETURNS: err_NoError if no error
            err_UnknownError if transmission fails.
*/
TinyDBError TOS_COMMAND(TINYDB_NETWORK_SEND_DATA_MESSAGE)(TOS_MsgPtr msg) {
  NetworkMessage *nw = (NetworkMessage *)msg->data;
  VAR(msg) = msg;
  VAR(amId) = AM_MSG(TINYDB_NETWORK_DATA_MESSAGE);

  initHeader(&nw->hdr);

  //HACK : Parent reselect interval in terms of data messages sent!
  VAR(sendCount)++; //increment epoch number (to forget about parents)
  //send message bcast, filter at app level
  if (VAR(sendCount) < 0)
      VAR(sendCount) = 0;
  // mote id 0 == a base station (connected directly to the root)
  if (TOS_LOCAL_ADDRESS == 0) {
    if (TOS_CALL_COMMAND(TINYDB_SUB_SEND_MESSAGE)(TOS_UART_ADDR,  VAR(amId), msg)) {
      VAR(radio) = TRUE;
      return err_NoError;
    } else
      return err_MessageSendFailed;
  } else {
      if (!VAR(radio) && TOS_CALL_COMMAND(TINYDB_SUB_SEND_MESSAGE)(TOS_BCAST_ADDR, VAR(amId), msg)) {
	  VAR(radio) = TRUE;
	  return err_NoError;
      }  else
	  return err_MessageSendFailed;
  }

}


/* Send a 'query' message -- query messages contain information about
   queries that should be sent to neighbors in the network.
   
   REQUIRES:  msg is a message buffer of which the first entry is of
   type DbMsgHdr

   SIGNALS: TINYDB_NETWORK_SUB_MSG_SEND_DONE after message is sent,
   unless an error is returned.

   RETURNS: err_NoError if no error
            err_UnknownError if transmission fails.
*/

TinyDBError TOS_COMMAND(TINYDB_NETWORK_SEND_QUERY_MESSAGE)(TOS_MsgPtr msg) {
  NetworkMessage *nw = (NetworkMessage *)msg->data;

  VAR(msg) = msg;
  VAR(amId) = AM_MSG(TINYDB_NETWORK_QUERY_MESSAGE);

  initHeader(&nw->hdr);
  
  if (!VAR(radio) && TOS_CALL_COMMAND(TINYDB_SUB_SEND_MESSAGE)(TOS_BCAST_ADDR, VAR(amId), msg)) {
      VAR(radio) = TRUE;
      return err_NoError;
  } else
    return err_MessageSendFailed;
}


/* Send a request for a query message to neighbors
   REQUIRES:  msg is a message buffer of which the first entry is of
   type DbMsgHdr

   SIGNALS: TINYDB_NETWORK_SUB_MSG_SEND_DONE after message is sent,
   unless an error is returned.

   RETURNS: err_NoError if no error
            err_UnknownError if transmission fails.
*/
TinyDBError TOS_COMMAND(TINYDB_NETWORK_SEND_QUERY_REQUEST)(TOS_MsgPtr msg, short from) {
  NetworkMessage *nw = (NetworkMessage *)msg->data;
  VAR(msg) = msg;
  VAR(amId) = AM_MSG(TINYDB_NETWORK_QUERY_REQUEST_MESSAGE);
  
  initHeader(&nw->hdr);

  if (TOS_CALL_COMMAND(TINYDB_SUB_SEND_MESSAGE)(from, VAR(amId), msg)) {
    VAR(radio) = TRUE;
    return err_NoError;
  }  else
    return err_MessageSendFailed;
}

//write a message out over the uart
TinyDBError TOS_COMMAND(TINYDB_NETWORK_SEND_UART_SYNC)(char *msg, char msgId) {

  if (!VAR(uart)) {
    memcpy(&VAR(dbg), msg, sizeof(TOS_Msg));
    if (TOS_CALL_COMMAND(TINYDB_SUB_SEND_MESSAGE)(TOS_UART_ADDR,msgId,&VAR(dbg)))  {
      VAR(uart) = TRUE;
    } else
      return err_MessageSendFailed;
  } else
    return err_MessageSendFailed;
  return err_NoError;
}

/* Called when the network component has finished delivering a message. */
char TOS_EVENT(TINYDB_NETWORK_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg) {
  printf ("SEND DONE \n");

  if (VAR(uart)) { //if we finished sending a message over t  CLR_RED_LED_PIN();he uart
    VAR(uart) = FALSE;
  }
  if (VAR(radio)) { //might not have been us that send the message!
    VAR(radio) = FALSE;
    if (!VAR(local) && !VAR(wasCommand)) { //message sent on behalf of some other component
      TOS_SIGNAL_EVENT(TINYDB_NETWORK_OUTPUT_DONE)(msg, VAR(amId));
    } else if (VAR(wasCommand)) { //command message that has been sent, now must be executed
      TOS_SIGNAL_EVENT(TINYDB_SCHEMA_COMMAND)(&VAR(dbg)); //fire the schema
      VAR(wasCommand) = FALSE;
    } else {
      VAR(local) = FALSE;
    }
  }
  return 0;
}

/* Event that's fired when a query message arrives */
TOS_MsgPtr TOS_EVENT(TINYDB_NETWORK_QUERY_MESSAGE)(TOS_MsgPtr msg) {
  NetworkMessage *nw = (NetworkMessage *)msg->data;  

 if (processHeader(nw->hdr,QUERY_TYPE)) {
    //only log messages we're actually processing
    if (!VAR(centralized)) {
      TOS_SIGNAL_EVENT(TINYDB_NETWORK_QUERY_SUB)(msg);
    } else {
      //forward without processing in centralized approach
      TOS_CALL_COMMAND(TINYDB_NETWORK_SEND_DATA_MESSAGE)(msg);
    }
  }

  return msg;
}

/* Event thats fired when a request for a query arrives from a neighbor */
TOS_MsgPtr TOS_EVENT(TINYDB_NETWORK_QUERY_REQUEST_MESSAGE)(TOS_MsgPtr msg) {
  NetworkMessage *nw = (NetworkMessage *)msg->data;
  processHeader(nw->hdr, QUERY_TYPE); //ignore return rest -- always handle these
  
  TOS_SIGNAL_EVENT(TINYDB_NETWORK_QUERY_REQUEST_SUB)(msg);

  return msg;
}

/* Event that's fired when a network data item arrives */
TOS_MsgPtr TOS_EVENT(TINYDB_NETWORK_DATA_MESSAGE)(TOS_MsgPtr msg) {
  NetworkMessage *nw = (NetworkMessage *)msg->data;
  //  TOS_MsgPtr data = (TOS_MsgPtr)(nw->data);

  if (TOS_LOCAL_ADDRESS == 0 && nw->hdr.senderid == 0) { //was this heartbeat from root?
    if (!VAR(radio) && !VAR(uart)) { //can't use uart since it shares dbg
      memcpy(&VAR(dbg), msg, sizeof(TOS_Msg));
      if (TOS_CALL_COMMAND(TINYDB_SUB_SEND_MESSAGE)(TOS_BCAST_ADDR, AM_MSG(TINYDB_NETWORK_DATA_MESSAGE), &VAR(dbg))) { //forward it 
	if (READ_RED_LED_PIN())
	  CLR_RED_LED_PIN();
	else
	  SET_RED_LED_PIN();
	VAR(radio) = TRUE;
	VAR(local) = TRUE;
      }
    }
  } 

  
  //root sends data messages as heartbeats -- ignore them
  if (processHeader(nw->hdr,DATA_TYPE) && nw->hdr.senderid != 0) {
    TOS_SIGNAL_EVENT(TINYDB_NETWORK_DATA_SUB)(msg);
  } else //give mote a chance to look at it event though it wasn't addressed locally
    TOS_SIGNAL_EVENT(TINYDB_NETWORK_SNOOPED_SUB)(msg, AM_MSG(TINYDB_NETWORK_DATA_MESSAGE),
						 VAR(parentIx) != PARENT_UNKNOWN &&
						 nw->hdr.senderid == VAR(relatives)[VAR(parentIx)]);
  return msg;
}


/* Intercept schema command messages so that they can be forwarded from the root out
   to the rest of the nodes
*/
TOS_MsgPtr TOS_EVENT(TINYDB_COMMAND_MESSAGE)(TOS_MsgPtr msg) {

  //forward the message
  if (TOS_LOCAL_ADDRESS == 0 && !VAR(radio)) {
    if (TOS_CALL_COMMAND(TINYDB_SUB_SEND_MESSAGE)(TOS_BCAST_ADDR, AM_MSG(TINYDB_COMMAND_MESSAGE), msg)) {
      memcpy(&VAR(dbg), msg, sizeof(TOS_Msg)); //save off command for later execution.
      VAR(wasCommand) = TRUE; //note that we'll need to executed the command later
      VAR(radio) = TRUE;
    }
  } else {
    TOS_SIGNAL_EVENT(TINYDB_SCHEMA_COMMAND)(msg); //fire the schema
  }

  return msg;
}

/* Maintain the local header information */
void initHeader(DbMsgHdr *header) {
  header->senderid = TOS_LOCAL_ADDRESS;
  header->parentid = VAR(relatives)[VAR(parentIx)];
  header->level = MY_LEVEL;
#ifdef FULLPC
  assert(VAR(parentIx) != PARENT_UNKNOWN);
  assert(header->level != LEVEL_UNKNOWN);
  assert(header->level == VAR(relLevel)[VAR(parentIx)] + 1);
#endif
  header->idx = VAR(idx)++;
  if (header->idx < 0) // overflow!
	header->idx = VAR(idx) = 0;
  //  TOS_CALL_COMMAND(GET_TIME)(&header->sendtime);
  
}

// handle case where parent is unknown.
// parent becomes the sender of this msg
void tinydbParentInit(DbMsgHdr header, short clock) 
{
  //  short curtime;

#ifdef FULLPC
	assert(VAR(relOccupiedBits) == 0); // PARENT_UNKNOWN means no relatives!
#endif
	VAR(parentIx) = 0; // put parent in 1st slot in relatives array
	VAR(relOccupiedBits) = 0x1; // 1 slot occupied: slot 0
    VAR(relatives)[0] = header.senderid; // sender is parent
	VAR(lastIdxRelative)[0] = header.idx; 
	VAR(commProb)[0] = 0xff; // ignore 1st message in stats
    VAR(relLevel)[0] = header.level;
    //synchronize time with new parent (unless parent is root!)
    //	if (MY_LEVEL != 1 
    //		&& VAR(relatives)[VAR(parentIx)] == header.senderid) {
    //	  curtime = header.sendtime + TIME_OF_FLIGHT;
    // XXXX not sure that time sync works right!
    //  TOS_CALL_COMMAND(SET_TIME)(curtime);
    //}
	printf("%d: parent is %d\n", TOS_LOCAL_ADDRESS, header.senderid);
}

// loop through list of relatives looking for match to sender of msg. 
// If match found, update stats and return index of match.  Else return BAD_IX.
short tinydbUpdateSenderStats(DbMsgHdr header, short clock)
{
  int i, j, numDrops;
  unsigned short oldProb;

  for (i = 0; i < NUM_RELATIVES; i++) {
	oldProb = VAR(commProb)[i];
	if ((VAR(relOccupiedBits) & (0x1 << VAR(parentIx))) //we have a parent?
		&& VAR(relatives)[i] == header.senderid) {
	  // valid match found: update stats for this relative

	  if (header.idx > VAR(lastIdxRelative)[i]) {
		if (VAR(lastIdxRelative)[i] == 0)
		  numDrops = 0;
		else
		  // the -1 is because the sender's incrementing by 1 is natural
		  numDrops = (header.idx - VAR(lastIdxRelative)[i] - 1);
	  }
	  else if (VAR(lastIdxRelative)[i] >= 0x3f &&
			header.idx < VAR(lastIdxRelative)[i] - 0x3f)
		  // hackety hack: assume wraparound if last Idx was above 128 and
		  // new idx is more than 128 lower than last
		  numDrops = (0x7f - VAR(lastIdxRelative)[i]) + header.idx;
	  else
	    // assume received out of order
	    numDrops = -1;

	  if (numDrops >= 0) {
	    // at each epoch i, our weighted moving avg a_i will be calculated
	    // (.75 * a_{i-1}) + (.25 * received)
	    // where received is 1 if we heard in that epoch, else 0
	    // We do this in integer logic in the range [0-255],
	    // so .25 ~= 63
	    for (j = 0; j < numDrops; j++)
	      // subtract out 1/4 of the probability per drop
	      VAR(commProb)[i] = VAR(commProb)[i] - (VAR(commProb)[i] >> ALPHABITS);

	    // we heard this epoch.
	    // decrement history by a factor of 1/2^ALPHABITS.
	    VAR(commProb)[i] -= (VAR(commProb)[i] >> ALPHABITS);
	    // add in 2^8 * 1/(2^ALPHABITS) -1 = 2^(8-ALPHABITS) - 1
	    VAR(commProb)[i] += (1 << (8-ALPHABITS)) - 1;
	  }
	  else {
	    // we inaccurately claimed not to receive a packet a while ago.
	    // add it back in.  It's hard to weight it appropriately, but
	    // as a HACK lets decay it 1 epoch, i.e. add in 1/16 ~= 15
	    VAR(commProb)[i] = (VAR(commProb)[i] - (VAR(commProb)[i] >> ALPHABITS));
	    VAR(commProb)[i] += (1 << (8-2*ALPHABITS)) - 1;
	  }

	  VAR(lastIdxRelative)[i] = header.idx;
	  VAR(relLevel)[i] = header.level;
	  
	  return(i);
	} 
  }
  return(BAD_IX);
}

void tinydbRelativeReplace(DbMsgHdr header, short clock)
{
  int i;
  short worst;
  unsigned char lowestProb = 255;

  // either put sender in an empty relative slot,
  // or evict worst (which requires a definition of worst)
  // 
  for (i = 0, worst = -1; i < NUM_RELATIVES; i++) {
	if (!( VAR(relOccupiedBits) & (0x1 << i) )) { // slot is empty, use it
	  worst = i;
	  break;
	}
	else { // XXX HACK: for now, always evict based on lowest commProv
	  if ((worst == -1
		   || ((VAR(commProb)[i] < lowestProb)))
		  && (i != VAR(parentIx))) {
		worst = i;
		lowestProb = VAR(commProb)[i];
	  }
	}
  }
#ifdef FULLPC
  assert(worst >= 0);
  assert(worst != VAR(parentIx));
#endif
  VAR(relOccupiedBits) |= (0x1 << worst);
  VAR(relatives)[worst] = header.senderid;
  VAR(lastIdxRelative)[worst] = header.idx;
  VAR(commProb)[worst] = 0xff; // ignore 1st message in stats
  VAR(relLevel)[worst] = header.level;
}

void tinydbChooseParent(DbMsgHdr header, short clock)
{
  short i, best;
#if 0
  double epsilon;
  double lowerconf[NUM_RELATIVES];
#endif
  unsigned char prob, tmpprob;
  short oldparent;
  short oldlevel;

  // reselect parent
#if 0
  for (i = 0, best = -1; i < NUM_RELATIVES; i++) {
	// compute lower confidence bound
	epsilon = (PARENT_RESELECT_INTERVAL*TICKS_PER_SECOND)
	  * sqrt( ( 1/(2*VAR(numMsgs)[i])) * log(2/(1-.95)));
	lowerconf[i] = (VAR(sumArrival)[i]/VAR(numMsgs)[i]) - epsilon;
	if (best < 0 || (lowerconf[i] < lowerconf[best]))
	  best = i;
  }
#endif

  for (i = 0, best = -1, prob=0; i < NUM_RELATIVES; i++) {
    // HACK II: to avoid loops, don't choose a parent at a higher level than 
    // ourselves. At our own level, can choose parents numbered higher than us

    if (VAR(relLevel)[i] < MY_LEVEL 
	|| (VAR(relLevel)[i] == MY_LEVEL && VAR(relatives)[i] > TOS_LOCAL_ADDRESS))
      if (VAR(relOccupiedBits) & (0x1 << i)) {
	tmpprob = VAR(commProb)[i];
	if (tmpprob > prob) {
	  prob = tmpprob;
	  best = i;
	}
      }
  }
#ifdef FULLPC
  assert(best >= 0);
#endif

  // HACK: choose parent based on least mean message arrival
  // set up new parent, and reset for new measurements
  //keep momentum for current parent at same level unless we see someone MUCH better
  // or new parent is at lower level
  if (VAR(commProb)[best] - VAR(commProb)[VAR(parentIx)] > MAX_PROB_THRESH
      || VAR(relLevel)[best] < MY_LEVEL ) {
	oldlevel = MY_LEVEL;
	oldparent = VAR(parentIx);
	VAR(parentIx) = best;
	printf("%d: new parent is %d.  I was at level %d, now at level %d.  She's at level %d\n", TOS_LOCAL_ADDRESS, VAR(relatives)[best], oldlevel, MY_LEVEL, VAR(relLevel)[best]);
  }

  //synchronize time with new parent (unless parent is root!)
  //  if (MY_LEVEL != 1 
  //	  && VAR(relatives)[VAR(parentIx)] == header.senderid) 
  //	TOS_CALL_COMMAND(SET_TIME)(header.sendtime + TIME_OF_FLIGHT);
}

/* Do something with the header information in a message
   received from a neighbor / parent (e.g. update 
   routing tables, parent information, etc. )

   Return true if the message should be processed by the
   tuple router, or false if it should be rejected
*/
bool processHeader(DbMsgHdr header,MsgType type) 
{
	bool wasParent = FALSE;

	if ((!VAR(forceTopology) || 
	    header.senderid == VAR(parentCand1) ||
	    header.senderid == VAR(parentCand2) || 
	    header.senderid == VAR(parentCand3) ) &&
	    TOS_LOCAL_ADDRESS != 0 )
	    {
		short clock;
		short match;

		// ignore our own messages
		if (header.senderid == TOS_LOCAL_ADDRESS)
		  return FALSE;


		//does our parent think we're it's parent?
		//if (type == DATA_TYPE &&
		//		    VAR(parentIx) != PARENT_UNKNOWN && 
		//		    header.parentid == VAR(relatives)[VAR(parentIx)]) {
		//		  VAR(parentIx) = PARENT_UNKNOWN; //look for a new parent
		//		  return FALSE; //and ignore this message!
		//		}

		if (VAR(sendCount) - VAR(lastHeard) < 0)
		    VAR(lastHeard) = VAR(sendCount); //handle wraparound


		if (VAR(relatives)[VAR(parentIx)] == header.senderid) {
		    //parent's level went up! -- reselect parent
		    if (header.level > VAR(relLevel)[VAR(parentIx)]) {
			VAR(sendCount) += PARENT_LOST_INTERVAL + 1;
		    }  else //parents level wen't down?  that's ok!
			VAR(lastHeard) = VAR(sendCount);
		}

		//our parent thinks we're his parent -- bad news -- do something
		if (header.parentid == TOS_LOCAL_ADDRESS && header.senderid == VAR(relatives)[VAR(parentIx)]) {
		  VAR(sendCount) += PARENT_LOST_INTERVAL + 1;
		}

		//HACK ! if we haven't heard from our parent for awhile, forget
		//everything we know about our parent
		
		if (VAR(sendCount) - VAR(lastHeard)> PARENT_LOST_INTERVAL) {
		    short parent = VAR(parentIx);
		    VAR(commProb)[VAR(parentIx)] = 0; //make parent look awful
		    tinydbChooseParent(header, clock);
		    if (parent != VAR(parentIx)) VAR(lastHeard) = VAR(sendCount);
		    else {
			//reset routing!
			VAR(parentIx) = PARENT_UNKNOWN;
			VAR(relOccupiedBits) = 0;
		    }
		}
			  
		  

		TOS_CALL_COMMAND(GET_TIME)(&clock);

		// Base case: PARENT_UNKNOWN.  Initialize.
		if (VAR(parentIx) == PARENT_UNKNOWN) {
		    tinydbParentInit(header, clock);
		    wasParent = TRUE; // having no parent means this node is our parent
		    VAR(lastHeard) = VAR(sendCount);
		}
		else { // common case
		    //  Update stats for this sender, if known.
		    match = tinydbUpdateSenderStats(header, clock);
		    if (match != BAD_IX && match == VAR(parentIx))
			wasParent = TRUE;
		    else if (match == BAD_IX) {
			// Sender was not known.
			// Decide whether to keep track of this sender (i.e. make
			// it a "relative".)
			tinydbRelativeReplace(header, clock);
		    }
		    
		    // Decide whether to change parents.
		    if (VAR(sendCount) - VAR(lastCheck) > PARENT_RESELECT_INTERVAL) {
			tinydbChooseParent(header, clock);
			VAR(lastCheck) = VAR(sendCount);
		    }
		}
	    }

  if (type == DATA_TYPE && header.parentid == TOS_LOCAL_ADDRESS)
    return TRUE; //handle data messages to us
  else if (type == QUERY_TYPE) { //&& (wasParent || header.senderid == 0)) {
    printf ("%d: GOT QUERY MESSAGE \n", TOS_LOCAL_ADDRESS);
    return TRUE; 
  } 
  else
    return FALSE;  //and nothing else
}

//alternate parent selection code to constrain the possible
//set of parents we will select at any one time -- this
//is to provide a method for fixing the network topology
void setParentRange()
{
	short nodes_per_level = 1;
	if (VAR(fanout) == 1)
	{
		VAR(minparent) = TOS_LOCAL_ADDRESS - 1;
		VAR(maxparent) = TOS_LOCAL_ADDRESS - 1;
	}
	else
	{
		short minparent = 0;
		short maxparent = 0;
		short prevminparent = minparent;
		short prevmaxparent = maxparent;
		//WARNING : may hang in an infinite loop if fanout < 0 !
		while (TOS_LOCAL_ADDRESS > maxparent)
		{
			prevminparent = minparent;
			prevmaxparent = maxparent;
			minparent = maxparent + 1;
			nodes_per_level *= VAR(fanout);
			maxparent = minparent + nodes_per_level - 1;
		}
		VAR(minparent) = prevminparent;
		VAR(maxparent) = prevmaxparent;
	}
	// randomly pick three parent candidates between minparent and maxparent
	nodes_per_level = VAR(maxparent) - VAR(minparent) + 1;
	if (nodes_per_level <= 2)
	{
		VAR(parentCand1) = VAR(minparent);
		VAR(parentCand2) = VAR(parentCand3) = VAR(maxparent);
	}
	else
	{
		VAR(parentCand1) = VAR(minparent) + TOS_CALL_COMMAND(NEXT_RAND)() % nodes_per_level;
		VAR(parentCand2) = VAR(minparent) + TOS_CALL_COMMAND(NEXT_RAND)() % nodes_per_level;
		VAR(parentCand3) = VAR(minparent) + TOS_CALL_COMMAND(NEXT_RAND)() % nodes_per_level;
	}
#if 0
	// XXX hack special-case fanout 2
	if (VAR(fanout) == 2 && TOS_LOCAL_ADDRESS > 2)
	{
		VAR(minparent) = ((TOS_LOCAL_ADDRESS + 1) >> 1) - 1;
		if (VAR(minparent) + 1 < VAR(maxparent))
			VAR(maxparent) = VAR(minparent) + 1;
	}
#endif
}


short TOS_COMMAND(TINYDB_NETWORK_GET_PARENT)(void)
{
	return VAR(relatives)[VAR(parentIx)];
}

//pot setting


void TOS_COMMAND(TDB_POT)(char pot) {
  if (READ_RED_LED_PIN())
    CLR_RED_LED_PIN();
  else
    SET_RED_LED_PIN();

  TOS_CALL_COMMAND(TDB_POT_SET)(pot);
}

//neighbor radius constraint

void TOS_COMMAND(TDB_FORCE_TOPOLOGY)(char fanout) {
  if (READ_RED_LED_PIN())
    CLR_RED_LED_PIN();
  else
    SET_RED_LED_PIN();

  if ((unsigned char)fanout != 0xFF) {
    CLR_GREEN_LED_PIN();
    VAR(fanout) = fanout;
    setParentRange();
    VAR(parentIx) = PARENT_UNKNOWN;
  } else {
    SET_GREEN_LED_PIN();
    VAR(fanout) = fanout;
    VAR(forceTopology) = FALSE;    
    VAR(parentIx) = PARENT_UNKNOWN;
  }


}


//centralized vs. in-net aggregation

void TOS_COMMAND(TDB_SET_CENTRALIZED)(bool on) {
  if (!on) {
    VAR(centralized) = FALSE;
    if (READ_GREEN_LED_PIN())
      CLR_GREEN_LED_PIN();
    else
      SET_GREEN_LED_PIN();
  } else {
    VAR(centralized) = TRUE;
    if (READ_RED_LED_PIN())
      CLR_RED_LED_PIN();
    else
      SET_RED_LED_PIN();
  }
}
