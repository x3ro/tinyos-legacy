/* 
 * One Phase Pull implementation...
 * Authors: Moshe Golan, Mohan Mysore
 */


includes msg_types;
includes NeighborStore;
includes Ext_AM;
module OnePhasePullM {
  provides {
    interface StdControl;
#ifdef ENABLE_GRADIENT_OVERRIDE
    interface DiffusionControl;
#endif
    interface Subscribe;
    interface Publish;
    interface Filter[uint8_t myPriority];
  }

  uses {

    interface Timer;

    interface Leds;

    interface TxManControl;

    interface Enqueue as TxInterestMsg;
    interface Enqueue as TxDataMsg;

    interface ReceiveMsg as RxInterestMsg;
    interface ReceiveMsg as RxDataMsg;
  }
}
implementation {

#include <inttypes.h>
#include <string.h>

// We have no other choice but to include C files... tried to link with ".o"s
// separately after compilation of code, but that doesn't work out for
// certain NesC specific reasons: (1) problems with declaration of prototypes...
// if prototype happens to occur twice or in two different modules, the
// NesC compiler goes bonkers (2) NesC takes pride in single-file code
// optimizations since the whole application is finally one single file
// (app.c) which the compiler can heavily optimize.. this is not possible
// with last-minute linkage... 
#include "OPPLib/InterestCache.c"
#include "OPPLib/MatchingRules.c"
#include "OPPLib/DataCache.c"
#include "OPPLib/Debug.c"

// ================== Prototypes  ===================

result_t forwardToFilters(DiffMsgPtr msg, uint8_t startPriority);
void forwardDataMsg(Ext_TOS_MsgPtr packet, LOOPBACK_FLAG loopBackFlag);
void receiveInterestMessage(Ext_TOS_MsgPtr pExtTosMsg, 
			    LOOPBACK_FLAG loopBackFlag);
// Handles the event of arriving data message to a node


// ============ Local Variables =============

uint16_t seqNum;              // Monotonic increasing unique sequence number

InterestCache interestCache;   
DataCache dataCache;

Ext_TOS_Msg appDataPacket;
BOOL appDataPacketBusy;
Ext_TOS_Msg appInterestPacket;
BOOL appInterestPacketBusy;

Ext_TOS_Msg myDataPacket;         
Ext_TOS_MsgPtr recvdDataMsg;         
BOOL recvdDataMsgBusy;

Ext_TOS_Msg myInterestPacket;
Ext_TOS_MsgPtr recvdInterestMsg;         
BOOL recvdInterestMsgBusy;

// Exploratory Interests Interval Can later  base on connectivity
uint8_t interestSenderInterval;	      
uint8_t	oneSecondCounter;

SubscriptionHandle currSubHandle;
PublicationHandle maxPubHandle;

#ifdef ENABLE_GRADIENT_OVERRIDE
struct GradOverrideEntry
{
  Attribute attributes[MAX_ATT];
  uint8_t numAttrs;
  uint16_t gradients[MAX_GRADIENTS];
  uint8_t numGradients;
} gradOverrideTable[MAX_GRAD_OVERRIDES];
#endif

struct FilterEntry
{
  Attribute attributes[MAX_ATT];
  uint8_t numAttrs;
} filterTable[MAX_NUM_FILTERS];

// ======================== INIT =====================

command result_t StdControl.init()
{
  dbg(DBG_TEMP, "StdControl.init: sizeof(TOS_Msg) = %d "
      "sizeof(Ext_TOS_Msg) = %d\n", sizeof(TOS_Msg), sizeof(Ext_TOS_Msg));
  // Initialize Local State
  
  initInterestCache( &interestCache );
  initDataCache(&dataCache);
#ifdef ENABLE_GRADIENT_OVERRIDE
  memset((char *)gradOverrideTable, 0, 
	 sizeof(struct GradOverrideEntry) * MAX_GRAD_OVERRIDES);
#endif
  memset((char *)filterTable, 0, 
	 sizeof(struct FilterEntry) * MAX_NUM_FILTERS);

  // initialize data and interest pointers... 

  appDataPacketBusy = FALSE;
  appInterestPacketBusy = FALSE;
  
  recvdDataMsg = &myDataPacket;
  recvdDataMsgBusy = FALSE;
  recvdInterestMsg = &myInterestPacket;
  recvdInterestMsgBusy = FALSE;

  oneSecondCounter = TIMER_TICKS_PER_SEC; 
  seqNum = 0;
  currSubHandle = 0;
  maxPubHandle = 0;
  interestSenderInterval =  INTEREST_SENDER_PERIOD ;

  call Leds.init();
  
  dbg(DBG_USR1, "StdControl.init: initialized...\n");
  return SUCCESS;
}


// ======================= START ====================

command result_t StdControl.start()
{
  call Timer.start(TIMER_REPEAT, TIMER_PERIOD_MSEC); 

  return SUCCESS;
}

// =======================  STOP =====================

command result_t StdControl.stop()
{
  return SUCCESS;
}


#ifdef ENABLE_GRADIENT_OVERRIDE
// add a gradient override entry... 
// if there already exists an identical entry, simply replace it... if not,
// add a new one in place of the first available free entry 
// "attributes" consist of constraints -- the kind that would be specified
// in interests
command result_t DiffusionControl.addGradientOverride(Attribute *attributes, 
						      uint8_t numAttrs, 
						      uint16_t *gradients,
						      uint8_t numGradients)
{
  uint8_t i = 0;
  int8_t freeIndex = -1;
  int8_t matchIndex = -1;
  int8_t finalIndex = -1;

  if (attributes == NULL || numAttrs == 0 || numAttrs > MAX_ATT ||
      gradients == NULL || numGradients == 0 || numGradients > MAX_GRADIENTS)
  {
    dbg(DBG_ERROR, "addGradientOverride: sanity check failed!\n");
    return FAIL;
  }

  freeIndex = matchIndex = -1;
  for (i = 0; i < MAX_GRAD_OVERRIDES; i++)
  {
    if (gradOverrideTable[i].numAttrs == 0 || 
	gradOverrideTable[i].numGradients == 0)
    {
      // if we encounter free entries, remember the first such index...
      if (freeIndex == -1)
      {
	freeIndex = i;
      }
    }
    else if (areAttribArraysEquiv(attributes, numAttrs, 
				  gradOverrideTable[i].attributes,
				  gradOverrideTable[i].numAttrs))
    {
      // or if there's already a matching attribute array, remember its
      // position
      matchIndex = i;
      break;
    }
  }

  if (matchIndex != -1)
  {
    finalIndex = matchIndex;
  }
  else
  {
    finalIndex = freeIndex;
  }

  if (finalIndex >= 0)
  {
    memcpy((char *)gradOverrideTable[finalIndex].attributes, (char *)attributes,
	    sizeof(Attribute) * numAttrs);
    gradOverrideTable[finalIndex].numAttrs = numAttrs;

    memcpy((char *)gradOverrideTable[finalIndex].gradients, (char *)gradients,
	    sizeof(uint16_t) * numGradients);
    gradOverrideTable[finalIndex].numGradients = numGradients ;
  }
  // if neither a matching index nor a free index was found, then we will
  // do nothing and bail out...
  else
  {
    dbg(DBG_ERROR, "addGradientOverride: addition FAILED!\n");
    return FAIL;
  }
 
  dbg(DBG_USR1, "addGradientOverride: addition SUCCEEDED!\n");
  return SUCCESS;
}

// remove gradient override entry
command result_t DiffusionControl.removeGradientOverride(Attribute *attributes, 
							 uint8_t numAttrs)
{
  uint8_t i = 0;
  int8_t matchIndex = -1;

  if (attributes == NULL || numAttrs == 0 || numAttrs > MAX_ATT)
  {
    dbg(DBG_ERROR, "removeGradientOverride: sanity check failed!\n");
    return FAIL;
  }
  
  matchIndex = -1;
  for (i = 0; i < MAX_GRAD_OVERRIDES; i++)
  {
    if (gradOverrideTable[i].numAttrs != 0 &&
	areAttribArraysEquiv(attributes, numAttrs, 
			     gradOverrideTable[i].attributes,
			     gradOverrideTable[i].numAttrs))
    {
      // or if there's already a matching attribute array, remember its
      // position
      matchIndex = i;
      break;
    }
  }

  // if match is found, reset the matching entry and return SUCCESS...
  if (matchIndex != -1)
  {
    memset((char *)&gradOverrideTable[matchIndex], 0, 
	   sizeof(struct GradOverrideEntry));
    dbg(DBG_USR1, "removeGradientOverride: matched; matchIndex = %d!\n",
	matchIndex);
    prAttArray(DBG_USR1, TRUE, gradOverrideTable[matchIndex].attributes, 
		gradOverrideTable[matchIndex].numAttrs);
    return SUCCESS;
  }

  // no match found... return FAIL
  return FAIL;
}

#endif

// ==================  Subscribe API ===============

command SubscriptionHandle Subscribe.subscribe(AttributePtr attributes, 
					       uint8_t numAttrs) 
// subscribe for a certain data type... and have the Diffusion layer serve
// up data via the receiveMatchingData() event...
//
// attributes: array of attributes
// numAttrs: number of attributes contained therein
{
  InterestGradient thisGradient;
  InterestMessage *interestMsg = NULL;
  InterestEntry *entry = NULL;

  if (appInterestPacketBusy == TRUE)
  {
    dbg(DBG_ERROR, "Subscribe.subscribe: buffer busy!\n");
    return SUBSCRIBE_ERROR;
  }
  appInterestPacketBusy = TRUE;

  // numAttrs + 1 below is because we are adding a "CLASS IS INTEREST" in
  // addition to the attributes passed..
  if (attributes == NULL || numAttrs == 0 || numAttrs + 1> MAX_ATT)
  {
    appInterestPacketBusy = FALSE;
    return SUBSCRIBE_ERROR;
  }
  
  // Fill in standard Ext_TOS_Msg fields	
  memset((char *)&appInterestPacket, 0, sizeof(Ext_TOS_Msg));
  appInterestPacket.type = ESS_OPP_INTEREST;
  appInterestPacket.group = OPP_LOCAL_GROUP;
  // TODO: the below => wastage of packet size in case the attributes are
  // less in number than MAX_ATT... optimize!
  appInterestPacket.length = sizeof(InterestMessage);
  appInterestPacket.addr = TOS_BCAST_ADDR;
  // set the saddr field in the Ext_TOS_Msg
  appInterestPacket.saddr = TOS_LOCAL_ADDRESS;

  // Point to data part of Ext_TOS_Msg
  interestMsg = (InterestMessage *)(appInterestPacket.data);

  // NOTE: that we increment sequence number even if the message is not
  // sent out... this might break the sequence number stream, but the only
  // condition we have on the sequence number stream is "uniqueness"... and
  // is simply used to eliminate duplicates... even the "monotonically
  // increasing" requirement is not there because we use a "circular,
  // brute-force" data cache anyway
  interestMsg->seqNum = seqNum++;   
  interestMsg->sink  = TOS_LOCAL_ADDRESS ;  // Sink ID
  interestMsg->prevHop = TOS_LOCAL_ADDRESS; // Indicates original source
  interestMsg->expiration = DFLT_INTEREST_EXP_TIME;     // expiration time
  interestMsg->ttl = TTL;                     // time to live in terms of hops
  // intialize attribute list

  // The "+ 1" below is because we are adding a "CLASS IS INTEREST"
  // attribute
  interestMsg->numAttrs = numAttrs + 1;         // number of attributes

  interestMsg->attributes[0].key = CLASS;
  interestMsg->attributes[0].op = IS;
  interestMsg->attributes[0].value = INTEREST;

  memcpy((char *)&(interestMsg->attributes[1]), (char *)attributes, 
	 sizeof(Attribute) * numAttrs);

  currSubHandle = getNextSubHandle(&interestCache, currSubHandle);
  entry = addInterestCacheEntry(&interestCache, interestMsg, currSubHandle);
  // addInterestCacheEntry *has* to return a non-NULL entry...
  if (entry == NULL)
  {
    dbg(DBG_ERROR, "Subscribe.subscribe: couldn't add InterestEntry!!!\n");
    appInterestPacketBusy = FALSE;
    return SUBSCRIBE_ERROR;
  }

  thisGradient.prevHop = TOS_LOCAL_ADDRESS;
  thisGradient.expiration = interestMsg->expiration;
  updateInterestGradient(entry, &thisGradient);

  dbg(DBG_USR2, "Subscribe.subscribe: sending interest\n");
  prIntMes(DBG_USR2, TRUE, interestMsg);
  // check local address before send to enable testing with "nido"
  if (TOS_LOCAL_ADDRESS != NULL_NODE_ID)
  {
    result_t result = FAIL;

    dbg(DBG_USR2, "Subscribe.subscribe: sending packet to forwardFilters..\n");
    result = forwardToFilters(&appInterestPacket, 0);

    // Put on queue to be send
    // mmysore TODO: add task to take care of failure...
    if (result == FAIL)
    {
      dbg(DBG_USR2, "Subscribe.subscribe: no matching filter... enqueuing\n");
      call Leds.yellowOn(); 
      call TxInterestMsg.enqueue(&appInterestPacket);
    }
  }

  dbg(DBG_USR1, "Subscribe.subscribe: returning handle...\n");
  appInterestPacketBusy = FALSE;
  return entry->subHandle;
}


// unsubscribe a subscription specified by handle...
command result_t Subscribe.unsubscribe(SubscriptionHandle handle)
{

  return (unsubscribeByHandle(&interestCache, handle));
}


// default handler... in case application forgets to implement one, or does
// not want data as such (perhaps for testing)... use with care
default event result_t Subscribe.receiveMatchingData(SubscriptionHandle handle,
						     AttributePtr attributes, 
						     uint8_t numAttrs)
{
  return SUCCESS;
}


// ======================   Publish API ============== 

command PublicationHandle Publish.publish(AttributePtr attributes,
					  uint8_t numAttrs)
{
  // mmysore TODO: needs to be implemented in full...
  return maxPubHandle++;
}

//NOTE: the maximum number of attributes that can be sent down is 
//(MAX_ATT - 1) and not MAX_ATT because sendData internally adds the
//"CLASS IS DATA" attribute in addition to the data sent down...
//TODO: perhaps this semantics needs revisiting...
command result_t Publish.sendData(PublicationHandle handle,
				  AttributePtr attributes, uint8_t numAttrs)
{
  result_t result = FAIL;
  DataMessage *dataMsg = NULL;

  // mmysore: TODO: Need logic to fill in already set attributes first.... 
  
  // Fill in standard Ext_TOS_Msg fields	
  // NOTE: the numAttrs + 1 below is to compsensate for the "CLASS IS DATA"
  // attribute that we need to add...
  if (attributes == NULL || numAttrs == 0 || numAttrs + 1 > MAX_ATT)
  {
    dbg(DBG_ERROR, "Publish.sendData: sanity check failed! attributes = %p,"
	" numAttrs = %d!!\n", attributes, numAttrs);
    return FAIL;
  }

  if (TRUE == appDataPacketBusy)
  {
    dbg(DBG_ERROR, "Publish.sendData: appDataPacket is busy... sendData "
	"FAILed\n");
    return FAIL;
  }

  appDataPacketBusy = TRUE;

  memset((char *)&appDataPacket, 0, sizeof(Ext_TOS_Msg));
  // we don't fill in the "addr" field here... that is done by the
  // core Diffusion code
  appDataPacket.type = ESS_OPP_DATA;
  appDataPacket.group = OPP_LOCAL_GROUP;
  appDataPacket.length = sizeof(DataMessage);
  appDataPacket.saddr = TOS_LOCAL_ADDRESS;

  // Point to data part of Ext_TOS_Msg
  dataMsg = (DataMessage *)(appDataPacket.data);

  // NOTE: that we increment sequence number even if the message is not
  // sent out... this might cause discontinuities the sequence number
  // stream, but the only condition we have on the sequence number stream
  // is "uniqueness"... and is simply used to eliminate duplicates... even
  // the "monotonically increasing" requirement is not there because we use
  // a "circular, brute-force" data cache anyway
  dataMsg->seqNum =  seqNum++;            // Unique Monotonic increasing
  dataMsg->source  = TOS_LOCAL_ADDRESS; // Source ID
  dataMsg->prevHop = TOS_LOCAL_ADDRESS; // Indicates original source
  dataMsg->hopsToSrc = 0;            // time to live in terms of hops

  // intialize attribute list

  // the "+ 1" below is to because of the extra "CLASS IS DATA" attribute
  dataMsg->numAttrs = numAttrs + 1;           // number of attributes
  dataMsg->attributes[0].key = CLASS;
  dataMsg->attributes[0].op = IS;
  dataMsg->attributes[0].value = DATA;

  memcpy((char *)&(dataMsg->attributes[1]), (char *)attributes, 
	 sizeof(Attribute) *numAttrs);
  
  // Put in queue to be send
  call Leds.redOn();   // will be turned off by timer event...

  dbg(DBG_USR3, "Publish.sendData(): invoking forwardToFilters...\n");

  result = forwardToFilters(&appDataPacket, F_PRIORITY_MIN);

  if (result == FAIL)
  {
    dbg(DBG_USR3, "Publish.sendData(): invoking forwardDataMsg...\n");
    forwardDataMsg(&appDataPacket, LOOPBACK);
  }
 
  appDataPacketBusy = FALSE;
  return SUCCESS;
}

command result_t Publish.unPublish(PublicationHandle handle)
{
  // implement this...
  return SUCCESS;
}

// =================  Filter API ================== 
//
/* Design notes about the Filter API 

The priority would be deteremined by the actual parameterized instance
that a module implementing a filter is wired to.  The callback is
inherently provided for in the event "receiveMatchingData" of the Filter
interface.

Buffer management is kept simple by having both receiveMatchingData and
sendData requiring the called module to copy out the msg into their own
buffers -- passing of pointers would necessitate far more complicated
semantics, which is in a way unnecessary and for now impractical.

One other thing is that sendData *must* not be called from inside the event
handler for receiveMatchingData... it breaks both the convention of keeping
events light... and the semantics of filter operation.  sendData should be
invoked later from a task that is posted.

NOTE: lower priority numbers have higher priority 

*/


// Add a filter requesting data with the given attributes... the priority
//
// of the filter is dependent upon the wiring that is done at config.
// time... the only advantages of having parameterized interfaces is to
// give the illusion of "its own" interface to a module "using" this
// interface... and simplify maintenance of context by doing away with
// handles

command result_t Filter.addFilter[uint8_t myPriority](Attribute *attrArray, 
						      uint8_t numAttrs)
{
  struct FilterEntry *entry = NULL;


  if (attrArray == NULL || numAttrs == 0 || numAttrs > MAX_ATT)
  {
    dbg(DBG_ERROR, "addFilter: sanity check failed!!\n");
    return FAIL;
  }
  
  if (myPriority > F_PRIORITY_MAX)
  {
    dbg(DBG_ERROR, "addFilter: myPriority = %d; while F_PRIORITY_MAX = %d\n",
	myPriority, F_PRIORITY_MAX);
    return FAIL;
  }

  entry = &filterTable[myPriority];

  memcpy((char *)entry->attributes, attrArray, numAttrs * sizeof(Attribute));
  entry->numAttrs = numAttrs;

  return SUCCESS;
}

command result_t Filter.removeFilter[uint8_t myPriority]()
{
  if (myPriority > F_PRIORITY_MAX)
  {
    dbg(DBG_ERROR, "removeFilter: myPriority = %d; while MAX_NUM_FILTES = %d\n",
	myPriority, F_PRIORITY_MAX);
  }
  memset((char *)&(filterTable[myPriority]), 0, sizeof(struct FilterEntry));
}

command uint8_t Filter.getMyPriority[uint8_t myPriority]()
{
  return myPriority;
}
// default event handler in case a parameterized interface is not fully
// connected... this is usually needed for parameterized interfaces
default event result_t Filter.receiveMatchingMsg[uint8_t myPriority]
  (DiffMsgPtr msg)
{
  return SUCCESS;
}

// This function tries to forward data to all filters with priority >=
// startPriority.  This is distinct from the semantics of sendMessage where
// the priority is specified as a threshold... and all filters with
// priority > than that threshold are matched... 
// TODO: perhaps we should depart from the "threshold" approach -- to keep
// things simple and consistent
result_t forwardToFilters(DiffMsgPtr msg, uint8_t startPriority)
{
  uint8_t i = 0;
  InterestMessage *intMsg = NULL;
  DataMessage *dataMsg = NULL;
  Attribute *attributes = NULL;
  uint8_t numAttrs = 0;
  result_t retVal = FAIL;

  if (msg == NULL)
  {
    dbg(DBG_ERROR, "forwardToFilters: sanity check failed!!\n");
    return FAIL;
  }

  // NOTE: msg can be either an interest or a data message.  so, in order
  // to access attributes, we'll have to use their respective structs...
  // this would not have been a problem if both interest and data packets
  // used the same format (TODO!!)
  if (msg->type == ESS_OPP_INTEREST)
  {
    intMsg = (InterestMessage *)msg->data; 
    attributes = intMsg->attributes;
    numAttrs = intMsg->numAttrs;
  }
  else if (msg->type == ESS_OPP_DATA)
  {
    dataMsg = (DataMessage *)msg->data;
    attributes = dataMsg->attributes;
    numAttrs = dataMsg->numAttrs;
  }
  // it has to be either an INTEREST or DATA packet...
  else 
  {
    return FAIL;
  }

  // it is important to return return FAIL here because the application
  // might intentionally use MAX_NUM_FILTERS in order to force the message
  // to be forwarded out... and not seen by any filters
  if (startPriority > F_PRIORITY_MAX)
  {
    return FAIL;
  }

  for (i = startPriority; i <= F_PRIORITY_MAX; i++)
  {
    // check if filter exists first... and check if it matches
    if (filterTable[i].numAttrs > 0 &&
	oneWayMatch(filterTable[i].attributes, filterTable[i].numAttrs, 
		    attributes, numAttrs) == MATCH)
    {
      // NOTE: receiveMatchingMsg *must* copy out msg before doing its
      // stuff... and cannot hold onto msg
      dbg(DBG_USR1, "forwardToFilters: startPriority: %d: forwarding message "
	  "to filter %d\n",  startPriority, i);
      retVal = signal Filter.receiveMatchingMsg[i](msg);
      if (SUCCESS == retVal)
      {
	return SUCCESS;
      }
      // else, try to give it to the next filter...
    }
  }

  dbg(DBG_USR2, "forwardToFilters: startPriority: %d: no matching filter; "
      "packet is:\n", startPriority);
  if (msg->type == ESS_OPP_DATA)
  {
    prDataMes(DBG_USR2, TRUE, dataMsg);
  }
  else
  {
    prIntMes(DBG_USR2, TRUE, intMsg);
  }

  return FAIL;
}

// NOTE: the priorityThresh parameter below is a "threshold" -- meaning
// that filters with priority > priorityThreshold are considered for
// matching the data being sent out...
// TODO: should we change it to ">= priority" semantics instead of ">
// priorithThreshold"?
command result_t Filter.sendMessage[uint8_t myPriority](DiffMsgPtr msg, 
							uint8_t priorityThresh)
{
  result_t result = FAIL;
  uint8_t startPriority = 0;

  if (priorityThresh == F_PRIORITY_SEND_TO_NEXT)
  {
    startPriority = myPriority + 1;
  }
  else
  {
    startPriority = priorityThresh + 1;
  }

  // TODO: should have task and have appropriate buffer
  // management; for now we are fine because none of the code below
  // actually posts a task that'll hold "msg" even after this command
  // returns...

  // NOTE: we don't care if msg is an interest message or a data
  // message... forwardToFilters takes care of this difference...
  result = forwardToFilters(msg, startPriority);

  if (result == FAIL)
  {
    if (msg->type == ESS_OPP_DATA)
    {
      DataMessage *dataMsg = NULL;

      // Point to data part of Ext_TOS_Msg
      dataMsg = (DataMessage *)(msg->data);

      dbg(DBG_USR1, "Filter.sendMessage: calling forwardDataMsg on message\n");

      // this is the case where the the filter wants us to fill in the
      // fields of the packet... 
      if (msg->saddr == NULL_NODE_ID || dataMsg->source == NULL_NODE_ID)
      {

	dbg(DBG_USR1, "Filter.sendMessage: setting fields in data pkt from "
	    "filters\n");
	msg->group = OPP_LOCAL_GROUP;
	msg->length = sizeof(DataMessage);
	msg->saddr = TOS_LOCAL_ADDRESS;
	// we don't fill up the "addr" field because that job's left to
	// forwardData 

	// NOTE: that we increment sequence number even if the message is not
	// sent out... this might break the sequence number stream, but the only
	// condition we have on the sequence number stream is "uniqueness"... and
	// is simply used to eliminate duplicates... even the "monotonically
	// increasing" requirement is not there because we use a "circular,
	// brute-force" data cache anyway
	dataMsg->seqNum =  seqNum++;       
	dataMsg->source = TOS_LOCAL_ADDRESS;// Source ID
	dataMsg->prevHop = TOS_LOCAL_ADDRESS; // Indicates original source

	dataMsg->hopsToSrc = 0;            // time to live in terms of hops
      }

      forwardDataMsg(msg, LOOPBACK);
    }
    else
    {
      InterestMessage *interestMsg = NULL;

      // Point to data part of Ext_TOS_Msg
      interestMsg = (InterestMessage *)(msg->data);

      // handle it like just another interest message received from another
      // node...
      dbg(DBG_USR1, "Filter.sendMessage: calling receiveInterestMessage on "
	  "message\n");
      // this is the case where the the filter wants us to fill in the
      // fields of the packet... 
      if (msg->saddr == NULL_NODE_ID || interestMsg->sink == NULL_NODE_ID)
      {
	dbg(DBG_USR1, "Filter.sendMessage: setting fields in interest pkt from "
	    "filters\n");
	msg->type = ESS_OPP_INTEREST;
	msg->group = OPP_LOCAL_GROUP;
	// TODO: the below => wastage of packet size in case the attributes are
	// less in number than MAX_ATT... optimize!
	msg->length = sizeof(InterestMessage);
	msg->addr = TOS_BCAST_ADDR;
	// set the saddr field in the Ext_TOS_Msg
	msg->saddr = TOS_LOCAL_ADDRESS;

	// NOTE: that we increment sequence number even if the message is not
	// sent out... this might break the sequence number stream, but the only
	// condition we have on the sequence number stream is "uniqueness"... and
	// is simply used to eliminate duplicates... even the "monotonically
	// increasing" requirement is not there because we use a "circular,
	// brute-force" data cache anyway
	interestMsg->seqNum = seqNum++;
	interestMsg->sink  = TOS_LOCAL_ADDRESS ;  // Sink ID
	interestMsg->prevHop = TOS_LOCAL_ADDRESS; // Indicates original source
	interestMsg->expiration = DFLT_INTEREST_EXP_TIME;     // expiration time
	interestMsg->ttl = TTL;  // time to live in terms of hops
      }
      receiveInterestMessage(msg, LOOPBACK);
    }
  }

  return SUCCESS;
}

command uint16_t Filter.getNextSeqNum[uint8_t myPriority]()
{
  // NOTE: that we increment sequence number even if the message is not
  // sent out... this might break the sequence number stream, but the only
  // condition we have on the sequence number stream is "uniqueness"... and
  // is simply used to eliminate duplicates... even the "monotonically
  // increasing" requirement is not there because we use a "circular,
  // brute-force" data cache anyway
  return seqNum++;
}

// =================  Periodic Tasks ==================

task void interestSenderTask()
// resends local subscribed interest for new path selection
{
  InterestMessage *message = NULL;
  uint8_t i = 0;                // Loop Counter

  if (appInterestPacketBusy == TRUE)
  {
    dbg(DBG_ERROR, "interestSenderTask: appInterestPacket is busy!\n");
    return;
  }

  appInterestPacketBusy = TRUE;
  for (i = 0; i < MAX_INTERESTS; i++)
  {
    if (interestCache.entries[i].interest.sink == TOS_LOCAL_ADDRESS && 
	interestCache.entries[i].interest.expiration != 0 &&
	interestCache.entries[i].interest.expiration <= INTEREST_XMIT_MARGIN)
    {
      // NOTE: we increment sequence number even if the message is not
      // sent out... this might break the sequence number stream, but the only
      // condition we have on the sequence number stream is "uniqueness"... and
      // is simply used to eliminate duplicates... even the "monotonically
      // increasing" requirement is not there because we use a "circular,
      // brute-force" data cache anyway
      interestCache.entries[i].interest.seqNum = seqNum++;
      interestCache.entries[i].interest.expiration = DFLT_INTEREST_EXP_TIME;

      // Fill in standard Ext_TOS_Msg fields	
      memset((char *)&appInterestPacket, 0, sizeof(Ext_TOS_Msg));
      appInterestPacket.type = ESS_OPP_INTEREST;
      appInterestPacket.group = OPP_LOCAL_GROUP;
      // TODO: the below => wastage of packet size in case the attributes are
      // less in number than MAX_ATT... optimize!
      appInterestPacket.length = sizeof(InterestMessage);
      appInterestPacket.addr = TOS_BCAST_ADDR;
      appInterestPacket.saddr = TOS_LOCAL_ADDRESS;

      // Point to data part of Ext_TOS_Msg
      message = (InterestMessage *)(appInterestPacket.data);

      // copy interest message
      memcpy((char *)message, (char *)&(interestCache.entries[i].interest),
	     sizeof(InterestMessage));

      // now, there's a problem with the handle business... and it is that if
      // we simply send a new interest message for an about to expire interest
      // and that message went through filters, and then got added to interest
      // cache by receiveIntestMessage, the handle that is used for that
      // interest will have no relation to that of the original interest...
      // So what we do is to simply update the original interest cache entry
      // and have receiveInterestMessage recognize the interest as coming
      // from the local node (prevHop = TOS_LOCAL_ADDRESS) and then forward
      // it, as opposed to dropping it (because there's already an interest
      // cache entry)

      // check local address before send to enable testing with "nido"
      if (TOS_LOCAL_ADDRESS != NULL_NODE_ID)
      {
	result_t result = FAIL;

	result = forwardToFilters(&appInterestPacket, 0);

	// Put on queue to be sent
	// mmysore TODO: add task to take care of failure...
	if (result == FAIL)
	{
	  call Leds.yellowOn(); 
	  // fixed bug: should call receiveMatchingMsg instead...
	  //call TxInterestMsg.enqueue(&appInterestPacket);
	  receiveInterestMessage(&appInterestPacket, LOOPBACK);
	  dbg(DBG_USR1, "interestSenderTask: enqueuing interest: (guess) "
	      "src: %d seq: %d expiration: %d handle: %d\n",
	      message->sink, message->seqNum, message->expiration, 
	      interestCache.entries[i].subHandle); 
	}
	else
	{
	  dbg(DBG_USR1, "interestSenderTask: packet forwarded to some filter:\n");

	}
	prIntMes(DBG_USR1, TRUE, message);
      }
    } // end if
  } // end outer for
  appInterestPacketBusy = FALSE;
}


task void perSecondTask()
// Things to do every clock tick
{
  // Check Interest Cache Interval for Exploratory Interest
  ageInterests(&interestCache);

  // Check exploratory period 
  interestSenderInterval--;
  if (interestSenderInterval <= 0) 
  {
    // can simply call the function here instead of posting a task, but
    // generally, it is good to divide up the work into small chunks 
    // because otherwise, we might starve out more time critical processing...
    post interestSenderTask();
    interestSenderInterval = INTEREST_SENDER_PERIOD;
  } 
  
}


// making sure that if TxManControl is not connected, it still compiles 
// (as in the case where OnePhasePull) is being used in an application 
// that supplies its own TxManControl.tick(), you may not want to wire
// the TxManControl of OnePhasePull
default command void TxManControl.tick()
{
}

// ================== Every Clock tick Tasks ==========

// TODO: reevaluate using a task...
task void TxManTickTask()
// Supply tick to the TxMan module
{
  call TxManControl.tick();
 
}


// ===================== Timer ========================


event result_t Timer.fired()
// Timer callback - Things to do every clock call back
{
  call Leds.redOff();
  call Leds.greenOff();
  call Leds.yellowOff();

  // Run every tick tasks
  //post TxManTickTask();
  call TxManControl.tick();

  // Check task period 
  oneSecondCounter--;
  if (oneSecondCounter == 0) 
  {
    post perSecondTask();
    oneSecondCounter = TIMER_TICKS_PER_SEC;
  }
  
  return SUCCESS;
}



// ===================  Arriving Packets Handlers ==========

// ===================  receive Interest Message ===========

// handles an interest -- whether it comes from another node or it comes
// through a filter the sends down an interest packet...
void receiveInterestMessage(Ext_TOS_MsgPtr pExtTosMsg, LOOPBACK_FLAG loopBackFlag)
{
  UPDATE_STATUS interestStatus = 0;            // Flag for interestMsg statud
  InterestMessage *interestMsg;
  result_t result;

  interestMsg = (InterestMessage*) pExtTosMsg->data;

  dbg(DBG_USR1, "receiveInterestMessage: got INTEREST: sink: %d seq: %d"
      " prev: %d ttl: %d\n",
      interestMsg->sink, interestMsg->seqNum, interestMsg->prevHop,
      interestMsg->ttl);
  // If Time To Live is out - drop the packet
  // NOTE: ttl has to be an int8_t and not a uint8_t
  if (interestMsg->ttl < 0)
  {
    dbg(DBG_USR1, "receiveInterestMessage: TTL drop\n");
    return;
  }

  // Update interest cache
  // This takes care of (1) telling us if it is or is not a duplicate
  // (2) updating the cache appropriately (including interest gradients) if
  // this is a new interest...  And after that, if necessary we do the 
  // forwarding down below

  prIntMes(DBG_USR2, TRUE, interestMsg);
  
  interestStatus = updateInterestCache(&interestCache , interestMsg); 

  // If duplicate - drop
  if (interestStatus == UPDATE_DUPLICATE)  
  {
    // if it's an interest coming from here (an interest that was generated by
    // the "rotation" of an interest cache entry from a local subscription)...
    // we should send it... this is hacky but there are reasons... read the
    // documention in interestSenderTask() for more info.
    if (TOS_LOCAL_ADDRESS == interestMsg->sink && 
	TOS_LOCAL_ADDRESS == interestMsg->prevHop)
    {
      interestMsg->ttl--;
      // Check TTL before forwarding
      if (interestMsg->ttl >= 0 &&
	  // check local address before send to enable testing with "nido"
	  TOS_LOCAL_ADDRESS != NULL_NODE_ID)
      {
	// Put on queue to be sent
	call Leds.yellowOn(); 
	result = call TxInterestMsg.enqueue(pExtTosMsg);
	dbg(DBG_USR1, "receiveInterestMessage: rebroadcasting(1): %s\n",
	    result == SUCCESS ? "SUCCESS" : "FAIL");
      }
    }
    else
    {
      dbg(DBG_USR1, "receiveInterestMessage: sink = %d seq = %d; "
	  "DUPLICATE DROP\n", interestMsg->sink, interestMsg->seqNum);
    }
    prIntCache(DBG_USR2, TRUE, &interestCache);
    return;
  }
  else 
  {
    
    // Set broadcast destination
    pExtTosMsg->addr = TOS_BCAST_ADDR;
    pExtTosMsg->saddr = TOS_LOCAL_ADDRESS;
    // Set prevHop address
    interestMsg->prevHop = TOS_LOCAL_ADDRESS;

    interestMsg->ttl--;

    // Check TTL before forwarding
    if (interestMsg->ttl >= 0 &&
	// check local address before send to enable testing with "nido"
	TOS_LOCAL_ADDRESS != NULL_NODE_ID)
    {
      // Put on queue to be send
      call Leds.yellowOn(); 
      result = call TxInterestMsg.enqueue(pExtTosMsg);
      dbg(DBG_USR1, "receiveInterestMessage: rebroadcasting(2): %s\n",
	  result == SUCCESS ? "SUCCESS" : "FAIL");
    }
  }

} // end receive interest message


task void interestHandlerTask()
{
  result_t result = FAIL;

  dbg(DBG_USR2, "interestHandlerTask: got INTEREST message\n");
  result = forwardToFilters(recvdInterestMsg, 0);

  if (result == FAIL)
  // if the packet wasn't picked up by any filter, try to forward it... 
  {
    receiveInterestMessage(recvdInterestMsg, NON_LOOPBACK);
  }
  recvdInterestMsgBusy = FALSE; 
}

// ===================  Interest Handler ======================
event TOS_MsgPtr RxInterestMsg.receive(TOS_MsgPtr pTosMsg)
// Handles a received interest event
{
  Ext_TOS_MsgPtr tmp;

  if (pTosMsg == NULL)
  {
    dbg(DBG_ERROR, "RxInterestMsg.receive: TOS_Msg NULL!!!\n");
    return NULL;
  }

  // code for NIDO to ignore node 0 since it interferes with our logic...
  if (pTosMsg->addr == 0 || TOS_LOCAL_ADDRESS == 0)
  {
    if (pTosMsg->addr == 0)
    {
      dbg(DBG_ERROR, "RxInterestMsg.receive: pTosMsg->addr = 0!!!\n");
    }
    return pTosMsg;
  }

  // in using recvInterestMsgBusy, mutual exclusion is not an issue since
  // the receive event that comes up from the comm. stack cannot be
  // preempted
  if (recvdInterestMsgBusy)
  {
    // there's a task already posted to handle a received packet... drop
    // this packet... 
    // TODO: be able to handle multiple packets at a time
    dbg(DBG_USR1, "RxInterestMsg.receive: recvdInterestMsgBusy!!!\n");
    return pTosMsg;
  }
  
  recvdInterestMsgBusy = TRUE;


  // accept the current pointer and return the buffer that we've already
  // finished using...
  //
  // We assume here that TOS_Msg and Ext_TOS_Msg have exactly the same size...
  // by doing this, we look at the TOS_Msg as an Ext_TOS_Msg
  tmp = recvdInterestMsg;
  recvdInterestMsg = (Ext_TOS_MsgPtr)pTosMsg;
  pTosMsg = (TOS_MsgPtr)tmp;

  post interestHandlerTask();

  return pTosMsg;
}

// ================== receive Data Message ===================

void forwardDataMsg(Ext_TOS_MsgPtr pExtTosMsg, LOOPBACK_FLAG loopBackFlag)
// Handles the event of arriving data message to a node
{
  uint8_t i = 0, j = 0;            // Loop Index      
  BOOL alreadyInList = FALSE;
#ifdef ENABLE_GRADIENT_OVERRIDE
  BOOL gradientOverride = FALSE;
#endif
  uint8_t  currCount = 0;                     // current number of hops
  uint8_t  numNextHops = 0;                     // number of hops to forward data
  uint16_t nextHops[MAX_NUM_NEIGHBORS];   // nextHops to forward - aggregated 
  uint16_t currGradient[MAX_GRADIENTS]; // current interest nextHops 
  DataEntry entry;           // Temp data entry
  
  // Get The Data Message
  DataMessage * data = (DataMessage*) pExtTosMsg->data;

  memset((char *)nextHops, 0, MAX_NUM_NEIGHBORS * sizeof(uint16_t));
  memset((char *)currGradient, 0, MAX_GRADIENTS * sizeof(uint16_t));
  // If Time To Live is out - drop the packet
  if (data->hopsToSrc > TTL)
  {
    dbg(DBG_USR1, "forwardData: hopCount too large...\n");
    return;
  }

  // Get the data entry
  entry.seqNum = data->seqNum;
  entry.source = data->source;
 
  // Update data cache - drop if duplicate

  if (updateDataCache( &dataCache , &entry) == UPDATE_DUPLICATE )
  {
    dbg(DBG_USR1, "forwardData: dropping DUPLICATE DATA; src: %d, seq: %d "
	"prev: %d\n", data->source, data->seqNum, data->prevHop);
    return;
  }

  // Match data againt interest cache

  prIntCache(DBG_USR2, TRUE, &interestCache);

  numNextHops = 0;

#ifdef ENABLE_GRADIENT_OVERRIDE
  gradientOverride = FALSE;
  // Support for Gradient Override...
  for (i = 0; i < MAX_GRAD_OVERRIDES; i++)
  {
    InterestMessage intMsg;

    if (gradOverrideTable[i].numAttrs <= 0)
    {
      continue;
    }
    memcpy((char *)intMsg.attributes, (char *)gradOverrideTable[i].attributes, 
	   gradOverrideTable[i].numAttrs * sizeof(Attribute));
    intMsg.numAttrs = gradOverrideTable[i].numAttrs;

    if (dataMatch(&intMsg, data) == MATCH)
    {
      numNextHops = gradOverrideTable[i].numGradients;
      memcpy((char *)nextHops, (char *)gradOverrideTable[i].gradients,
	     sizeof(uint16_t) * numNextHops);
      // flag to indicate that Gradient Override has kicked in with this
      // data...
      dbg(DBG_USR1, "forwardDataMsg: data matched override entry; index = %d!\n",
	  i);
      prDataMes(DBG_USR2, TRUE, data);
      prAttArray(DBG_USR2, TRUE, gradOverrideTable[i].attributes,
                 gradOverrideTable[i].numAttrs);
      gradientOverride = TRUE;
      dbg(DBG_USR1, "forwardDataMsg: gradient override kicking in...\n");
    }
  }
  // Even though gradient override might have kicked in, we need to make a
  // pass through the interests matching the data in order to serve data to
  // local subscriptions... and as you'll notice below, if gradient
  // override has not kicked in, we also collect the interest gradients in
  // the nextHops array to forward data to... 
#endif

  for (i = 0; i < MAX_INTERESTS; i++)
  {
    // if entry is valid (not expired) and it matches, then...
    if ((interestCache.entries[i].interest.sink != NULL_NODE_ID) &&
	(interestCache.entries[i].interest.expiration > 0) &&
	(interestCache.entries[i].interest.numAttrs > 0) &&
	dataMatch(&(interestCache.entries[i].interest), data) == MATCH)
    {
      // collect unique matching interest gradients
      currCount = getInterestGradient(&interestCache.entries[i], currGradient,
				      MAX_NUM_NEIGHBORS);

      // NOTE: in OPP we are interested only in the first gradient
      dbg(DBG_USR2, "forwardData: found match... currCount = %d "
	  "currGradient[0] = %d\n", currCount, currGradient[0]);
      if (currCount != 0 && currGradient[0] != NULL_NODE_ID)
      {
	// If interest corresponds to a local subscription, serve the data
	// there...
	if (currGradient[0] == TOS_LOCAL_ADDRESS && 
	    interestCache.entries[i].subHandle != 0 &&
	    interestCache.entries[i].subHandle != SUBSCRIBE_ERROR)
	{
	  dbg(DBG_USR1, "forwardData: SENDING UP DATA %d to app from node %d to "
	      "application\n", data->seqNum, data->source);
	  call Leds.redOn();   // will be turned off by timer event...
	  signal Subscribe.receiveMatchingData
	    (interestCache.entries[i].subHandle, 
	    data->attributes, data->numAttrs);
	}
#ifdef ENABLE_GRADIENT_OVERRIDE
	else if (! gradientOverride)
	// else if gradient Override hasn't kicked in... 
	// add to the list of nodes to which to forward
#else
        else
#endif
	{
	  // NOTE: that nextHops array cannot include the current node... 
	  alreadyInList = FALSE;
	  for (j = 0; j < numNextHops; j++)
	  {
	    if (currGradient[0] == nextHops[j])
	    {
	      alreadyInList = TRUE;
	    }
	  }

	  if (!alreadyInList && numNextHops < MAX_NUM_NEIGHBORS)
	  {
	    nextHops[numNextHops++] = currGradient[0];
	  }
	}
      }
    } // end if
  } // end for

  // Forward the data packet to all matching unique gradients
  // Note in OPP data is never flooded / broadcast
  
  data->prevHop = TOS_LOCAL_ADDRESS;

  data->hopsToSrc++;

  // check for expiry before forwarding... 
  if (data->hopsToSrc > TTL)
  {
    return;
  }
   
  // send unicast to all matching gradients
  for (i = 0; i < numNextHops; i++)
  {
    // Set unicast destination
    pExtTosMsg->addr = nextHops[i];
    pExtTosMsg->saddr = TOS_LOCAL_ADDRESS;

    // check local address before send to enable testing with "nido"
    // TODO: think about the case when we have too many nodes to forward
    // to.. causing possible TxMan queue overflows...
    if (TOS_LOCAL_ADDRESS != NULL_NODE_ID)
    {
      // Put on queue to be send
      // mmysore: TODO: watch out for queue overflows... and post task if
      // necessary to enqueue if failed...
      dbg(DBG_USR1, "forwardData(): enqueuing DATA packet seq %d from node %d"
	  " to node %d\n", data->seqNum, data->source, pExtTosMsg->addr);
      call Leds.greenOn(); // reset by timer event
      call TxDataMsg.enqueue(pExtTosMsg);
    }
  }

  dbg(DBG_USR2, "forwardData: DATA sent to %d neighbors.\n", numNextHops);
  return;
}

task void nonLoopbackForwarder()
{
  result_t result = FAIL;

  // 0 below means that match with all filters in the order of priority
  result = forwardToFilters(recvdDataMsg, 0);

  if (result == FAIL)
  // if the packet wasn't picked up by any filter, try to forward it... 
  {
    forwardDataMsg(recvdDataMsg, NON_LOOPBACK);
  }

  recvdDataMsgBusy = FALSE;
}

event TOS_MsgPtr RxDataMsg.receive(TOS_MsgPtr pTosMsg)
{

  Ext_TOS_MsgPtr tmp = NULL;

  // code for NIDO to ignore node 0 since it interferes with our logic...
  if (pTosMsg->addr == 0 || TOS_LOCAL_ADDRESS == 0)
  {
    if (pTosMsg->addr == 0)
    {
      dbg(DBG_ERROR, "RxInterestMsg.receive: pTosMsg->addr = 0!!!\n");
    }
    return pTosMsg;
  }

  if (recvdDataMsgBusy)
  {
    // there's a task already posted to handle a received packet... drop
    // this packet... 
    // TODO: be able to handle multiple packets at a time
    dbg(DBG_USR1, "RxDataMsg.receive: recvdDataMsg is busy!\n");
    return pTosMsg;
  }

  recvdDataMsgBusy = TRUE;

  // accept the current pointer and return the buffer that we've already
  // finished using...
  //
  // We assume here that TOS_Msg and Ext_TOS_Msg have exactly the same size...
  // by doing this, we look at the TOS_Msg as an Ext_TOS_Msg
  tmp = recvdDataMsg;
  recvdDataMsg = (Ext_TOS_MsgPtr)pTosMsg;
  pTosMsg = (TOS_MsgPtr)tmp;

  post nonLoopbackForwarder();

  return pTosMsg;
}


} // End implementation
