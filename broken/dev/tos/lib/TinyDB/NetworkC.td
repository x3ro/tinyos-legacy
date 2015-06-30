/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * Authors:	Sam Madden
 *              Design by Sam Madden, Wei Hong, and Joe Hellerstein
 * Date last modified:  6/26/02
 *
 *
 */


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



module NetworkC {

  provides {
    interface Network;
    interface StdControl;

  }

  uses {
    interface SendMsg as SendDataMsg;
    interface SendMsg as SendQueryMsg;
    interface SendMsg as SendQueryRequest;
    interface SendMsg as DebugMsg;
    interface SendMsg as SchemaMsg;

    interface ReceiveMsg as RcvDataMsg;
    interface ReceiveMsg as RcvQueryMsg;
    interface ReceiveMsg as RcvRequestMsg;
    interface ReceiveMsg as RcvSchemaMsg;

    interface CommandUse;
    interface Leds;
    interface Random;
    interface AttrRegister as ParentAttr;

    interface QueryProcessor;
  }
      
}

implementation {
  enum {
    LEVEL_UNKNOWN = -1,
    PARENT_UNKNOWN = -1,
    BAD_IX = -1,
    UNKNOWN_ROOT = -1,
    PARENT_RESELECT_INTERVAL = 5, //5 epochs
    PARENT_LOST_INTERVAL = 10, //5 epochs
    TIME_OF_FLIGHT = 0,
    NUM_RELATIVES = 5,
    MAX_PROB_THRESH = 127,  //only switch parents if there's a node thats a lot more reliable
    ALPHABITS = 2, // We do a moving average at time t where
                  // avg_t = avg_{t-1}*(1-alpha) + alpha*newvalue
                  // Since we're using integers, we shift by ALPHABITS, rather than multiplying
                  // by a fraction.
                  // so ALPHABITS=2 is like alpha = 0.25 (i.e. divide by 4)
    QUERY_RETRIES = 5,
    NUM_ROOTS = 4,
    DATA_RETRIES = 0 //don't retry data messages for now, since we have no way of eliminating duplicates
  };


  uint16_t mSendCount; // increment each epoch
  // We track NUM_RELATIVES parents potential parents.
  // For each, we will track the mean # of drops of msgs from that "relative".
  char mRelatives[NUM_RELATIVES]; // an array of senders we're tracking potential parents
  char mRelOccupiedBits; // occupancy bitmap for slots in the relatives array
  short mParentIx[NUM_ROOTS]; // the current parent's index in the "relatives" array
                  // invariant: parentIx < NUM_RELATIVES
                  // invariant: relOccupiedBits is on for parentIx
  unsigned short mLastIdxRelative[NUM_RELATIVES]; // last idx # from this rel
  unsigned char mCommProb[NUM_RELATIVES]; // an 8-bit weighted moving average of
                                         // delivery success (delivered = 255,
                                         // dropped = 0).
  short mRoots[NUM_ROOTS];
  char mRelLevel[NUM_ROOTS][NUM_RELATIVES];  // current level of rel

  TOS_MsgPtr mMsg;
  TOS_Msg mDbg;
  char mAmId;
  short mIdx;
  bool mIsRoot;
  bool mForceTopology;
  bool mUart;  //is uart in use?
  bool mLocal; //was this message send local, or do our children need to see completion events
  bool mWasCommand; //is there a command that needs to be executed in dbg?
  bool mRadio; //is radio in use? (pending flag for radio)

  char mFanout;	// fanout of routing tree if forceTopology is true
  bool mCentralized; //all messages should be routed to the root (no aggregation?)
  short mMinparent; // min parent id number when we force topology
  short mMaxparent; // max parent id number when we force topology
  short mParentCand1, mParentCand2, mParentCand3;
  short mLastCheck, mLastHeard;


  enum {
    NUM_RECENT_MSGS = 8
  };

  long mRecentMsgs[NUM_RECENT_MSGS];
  uint8_t mNextMsg;

  short mRetryCnt;

  SchemaErrorNo errorNo;

  typedef enum {
    QUERY_TYPE = 0, 
    DATA_TYPE = 1
  } MsgType;

  typedef struct {
    short nodeid;
    short msgcount;
  } NodeMsgCount;

  typedef struct{
    DbMsgHdr hdr;
    char data[1];
  } NetworkMessage;


  void initHeader(DbMsgHdr *header,uint8_t rootId);
  bool processHeader(DbMsgHdr header, MsgType type,uint8_t rootId);
  void setParentRange();
  void setRoot(uint8_t rootId);
  bool checkRoot(TOS_MsgPtr msg, uint8_t *rootId);


  uint8_t myLevel(uint8_t rootId) {
    if (mParentIx[rootId] == 0) return 0;
    if (mParentIx[rootId] == PARENT_UNKNOWN || mRelLevel[rootId][mParentIx[rootId]] == LEVEL_UNKNOWN)
      return LEVEL_UNKNOWN;
    return mRelLevel[rootId][mParentIx[rootId]] + 1;
  }

    command result_t StdControl.init() {
      int i;

      mSendCount = 0;
      mLastCheck = 0;
      mLastHeard = 0;

      mNextMsg = 0;
      for (i = 0; i < NUM_RECENT_MSGS; i++)
	mRecentMsgs[i] = 0xFFFFFFFF;

      // mark statistics invalid
      mRelOccupiedBits = 0;
      for (i = 0; i < NUM_ROOTS; i++) {
	mParentIx[i] = PARENT_UNKNOWN;
	mRoots[i] = UNKNOWN_ROOT;
      }

      mIdx = 0;
      mFanout = 0xFF; //default -- no fanout
      mCentralized = FALSE;
      mFanout = 0;
      mRadio = FALSE;
      mForceTopology = FALSE;
      mWasCommand = FALSE;
      mUart = FALSE;

      mRetryCnt = 0;

	  return call ParentAttr.registerAttr("parent", UINT16, 2);
    }

    //set up data structures as though we're the root of this network
    void setRoot(uint8_t rootId) {
      //mRelOccupiedBits = 1;
      //mRelatives[0] = 0;
      //mRelLevel[rootId][0] = LEVEL_UNKNOWN;
      //mParentIx[rootId] = 0;
    }

    uint8_t getRootId(short rootNode) {
      int i;
      int firstUnknown = -1;

      for (i = 0; i < NUM_ROOTS; i++) {
	if (mRoots[i] != UNKNOWN_ROOT) {
	  if (mRoots[i] == rootNode) {
	    return i;
	  }
	} else if (firstUnknown == -1) {
	    firstUnknown = i;
	}
      }
      if (firstUnknown != -1) {
	mRoots[firstUnknown] = rootNode;
	return firstUnknown;
      }
	
      //HACK -- no more routing trees are available!
      return 0; //something, anyway...
    }

    //check the message to see if it sez we're supposed to be root
    //if so, set up the root and return TRUE, otherwise return FALSE
    bool checkRoot(TOS_MsgPtr msg, uint8_t *rootIdPtr) {
      short root = call QueryProcessor.msgToQueryRoot(msg);
      uint8_t rootId = getRootId(root);
      *rootIdPtr = rootId;
      if (root == TOS_LOCAL_ADDRESS) setRoot(rootId);
      return root == TOS_LOCAL_ADDRESS;
    }
    
     command result_t StdControl.start() {
       return SUCCESS;
     }
     
     command result_t StdControl.stop() {
       return SUCCESS;
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
     command TinyDBError Network.sendDataMessage(TOS_MsgPtr msg) {
      NetworkMessage *nw = (NetworkMessage *)msg->data;
      bool amRoot;
      uint8_t rootId = 0;

      mMsg = msg;
      mAmId = kDATA_MESSAGE_ID;
      

      amRoot = checkRoot(msg, &rootId);
      

      initHeader(&nw->hdr, rootId);

      //HACK : Parent reselect interval in terms of data messages sent!
      mSendCount++; //increment epoch number (to forget about parents)
      //send message bcast, filter at app level

      //send count is unsigned -- shouldn't wrap around
      //if (mSendCount < 0)
      //mSendCount = 0;

      // mote id 0 == a base station (connected directly to the root)
      if (!mRadio) {
	mRadio = TRUE;
	if (amRoot) {
	  if (call SendDataMsg.send(TOS_UART_ADDR, kMSG_LEN, msg) == SUCCESS) {
	    return err_NoError;
	  } else {
	    mRadio = FALSE;
	    return err_MessageSendFailed;
	  }
	} else {
	  mRetryCnt = DATA_RETRIES;
	  if (call SendDataMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg) == SUCCESS) {
	    return err_NoError;
	  }  else {
	    mRadio = FALSE;
	    return err_MessageSendFailed;
	  }
	}
      } return err_MessageSendFailed;

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

     command TinyDBError Network.sendQueryMessage(TOS_MsgPtr msg) {
      NetworkMessage *nw = (NetworkMessage *)msg->data;
      uint8_t rootId = 0;
      
      checkRoot(msg, &rootId);

      mMsg = msg;
      mAmId = kQUERY_MESSAGE_ID;

      initHeader(&nw->hdr, rootId);
  
      if (!mRadio) {
	mRadio = TRUE;
	mRetryCnt = QUERY_RETRIES;
	if (call SendQueryMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg) == SUCCESS) {
	  call Leds.redToggle();
	  return err_NoError;
	} else {
	  mRadio = FALSE;
	  return err_MessageSendFailed;
	}
      } 
      return err_MessageSendFailed;
      
     }


    /* Send a request for a query message to neighbors
       REQUIRES:  msg is a message buffer of which the first entry is of
       type DbMsgHdr
       
       SIGNALS: TINYDB_NETWORK_SUB_MSG_SEND_DONE after message is sent,
       unless an error is returned.
       
       RETURNS: err_NoError if no error
       err_MessageSendFailed if transmission fails.
    */
     command TinyDBError Network.sendQueryRequest(TOS_MsgPtr msg, uint16_t from) {
       NetworkMessage *nw = (NetworkMessage *)msg->data;
       uint8_t rootId = 0;
       
       checkRoot(msg, &rootId);


       mMsg = msg;
       mAmId = kQUERY_REQUEST_MESSAGE_ID;
       
       initHeader(&nw->hdr, rootId);
       
       if (!mRadio) {
	 mRadio = TRUE;
	 if (call SendQueryRequest.send(from, kMSG_LEN, msg) == SUCCESS) {
	   return err_NoError;
	 }  else {
	   mRadio = FALSE;
	   return err_MessageSendFailed;
	 }
       }
       return err_MessageSendFailed;
     }
     
    //write a message out over the uart
     command result_t Network.sendUart(char *msg, uint8_t amid) {
       if (!mUart /*&& !mRadio*/) {
	 mUart = TRUE;
	 memcpy(&mDbg.data, msg, kMSG_LEN);
	 if (call DebugMsg.send(TOS_UART_ADDR,kMSG_LEN,&mDbg))  {
	   return err_NoError;
	 } else {
	   mUart = FALSE;
	   return err_MessageSendFailed;
	 }
       } else
	 return err_MessageSendFailed;
     }


    /* Called when the network component has finished delivering a message. */
     result_t sendDone(TOS_MsgPtr msg) {
       dbg(DBG_USR1,"SEND DONE \n");

       if (mUart && msg == &mDbg) { //if we finished sending a message over the uart
	 mUart = FALSE;
       } else if (mRadio) { //might not have been us that send the message!
	 mRadio = FALSE;
	if (!mLocal && !mWasCommand) { //message sent on behalf of some other component
	  signal Network.outputDone(msg, mAmId);
	} else if (mWasCommand) { //command message that has been sent, now must be executed
	  // XXX, ignore command return value for now
	  call CommandUse.invokeMsg(&mDbg, NULL, &errorNo);
	  mWasCommand = FALSE;
	} else {
	  mLocal = FALSE;
	} 
       } 
       return SUCCESS;
     }

     event result_t SendQueryMsg.sendDone(TOS_MsgPtr msg, result_t success) {
       if ((!success || !msg->ack) && mRetryCnt-- > 0)
	 return call SendQueryMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg);
       else {
	 mRetryCnt = 0;
	 return sendDone(msg);
       }
     }

     event result_t SendDataMsg.sendDone(TOS_MsgPtr msg, result_t success) {
       if ((!success || !msg->ack) && mRetryCnt-- > 0)
	 return call SendDataMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg);
       else {
	 mRetryCnt = 0;
	 return sendDone(msg);
       }
     }

     event result_t SendQueryRequest.sendDone(TOS_MsgPtr msg, result_t success) {
	 return sendDone(msg);
     }

     event result_t DebugMsg.sendDone(TOS_MsgPtr msg, result_t success) {

	 return sendDone(msg);
     }

     event result_t SchemaMsg.sendDone(TOS_MsgPtr msg, result_t success) {

	 return sendDone(msg);
     }


     /* Check a message for CRC and to see if we've already ack'd it... 
      Return true if the messsage should be rejected.
     */
     bool filterMessage(TOS_MsgPtr msg, bool checkRecent ) {
       if (msg->crc == 0) return TRUE;

       if (checkRecent) {
	 NetworkMessage *nw = (NetworkMessage *)msg->data;  
	 long id = (((long)nw->hdr.senderid) << 16) + nw->hdr.idx;
	 short i;

	 if (id == 0) return FALSE; //ignore id 0

	 for (i = 0; i < NUM_RECENT_MSGS; i++) {
	   if (mRecentMsgs[i] == id) return TRUE;
	 }

	 mRecentMsgs[mNextMsg++] = id;
	 
	 if (mNextMsg == NUM_RECENT_MSGS) mNextMsg = 0; //circular buffer
       }
       
       return FALSE;
     }

    /* Event that's fired when a query message arrives */
     event TOS_MsgPtr RcvQueryMsg.receive(TOS_MsgPtr msg) {
      NetworkMessage *nw = (NetworkMessage *)msg->data;  
      uint8_t rootId = 0;

      checkRoot(msg, &rootId);

      if (filterMessage(msg,TRUE)) return msg;

      if (processHeader(nw->hdr,QUERY_TYPE,rootId)) {
	//only log messages we're actually processing
	if (!mCentralized) {
	  signal Network.querySub(msg);
	} else {
	  //forward without processing in centralized approach
	  call Network.sendDataMessage(msg);
	}
      }

      return msg;
    }

    /* Event thats fired when a request for a query arrives from a neighbor */
     event TOS_MsgPtr RcvRequestMsg.receive(TOS_MsgPtr msg) {
      NetworkMessage *nw = (NetworkMessage *)msg->data;
      uint8_t rootId = 0;

      checkRoot(msg, &rootId);
      if (filterMessage(msg,FALSE)) return msg;

      processHeader(nw->hdr, QUERY_TYPE,rootId); //ignore return rest -- always handle these
  
      signal Network.queryRequestSub(msg);

      return msg;
    }

    /* Event that's fired when a network data item arrives */
     event TOS_MsgPtr RcvDataMsg.receive(TOS_MsgPtr msg) {
      NetworkMessage *nw = (NetworkMessage *)msg->data;
      uint8_t rootId;
      bool amRoot = checkRoot(msg, &rootId);

      if (filterMessage(msg,TRUE)) return msg;

      if (amRoot && nw->hdr.senderid == 0) { //was this heartbeat from root?
	if (!mRadio /*&& !mUart*/) { //can't use uart since it shares dbg
	  mRadio = TRUE;
	  mLocal = TRUE;
	  //memcpy(&mDbg, msg, sizeof(TOS_Msg));
	  if (call SendDataMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg) == FAIL) {
	    mRadio = FALSE;
	    mLocal = FALSE;
	  }
	}
      } 

  
      //root sends data messages heartbeats -- ignore them
      if (processHeader(nw->hdr,DATA_TYPE,rootId) && nw->hdr.senderid != 0) {
	signal Network.dataSub(msg);
      } else //give mote a chance to look at it event though it wasn't addressed locally
	signal Network.snoopedSub(msg, kDATA_MESSAGE_ID, mParentIx[rootId] != PARENT_UNKNOWN &&
						     nw->hdr.senderid == mRelatives[mParentIx[rootId]]);
      return msg;
     }


    /* Intercept schema command messages so that they can be forwarded from the root out
       to the rest of the nodes
    */     
    event TOS_MsgPtr RcvSchemaMsg.receive(TOS_MsgPtr msg) {
      uint8_t rootId;
      bool amRoot = checkRoot(msg, &rootId);

      bool shouldResend = ((struct CommandMsg *)(msg->data))->fromBase;

      ((struct CommandMsg *)(msg->data))->fromBase = FALSE;
      if (filterMessage(msg,FALSE)) return msg;



      //forward the message
      if ((amRoot || shouldResend)  && !mRadio) {

	mWasCommand = TRUE; //note that we'll need to executed the command later
	mRadio = TRUE;	
	if (call SchemaMsg.send(TOS_BCAST_ADDR, kMSG_LEN,  msg) == SUCCESS) {
	  memcpy(&mDbg, msg, sizeof(TOS_Msg)); //save off command for later execution.
	} else { //failure
	  mWasCommand = FALSE;
	  mRadio = FALSE;	
	}
      } else {
	// XXX ignore command return values for now
	  call Leds.greenToggle();
	call CommandUse.invokeMsg(msg, NULL, &errorNo);
      }

      return msg;
    }

    /* Maintain the local header information */
    void initHeader(DbMsgHdr *header, uint8_t rootId) {
      header->senderid = TOS_LOCAL_ADDRESS;
      header->parentid = mRelatives[mParentIx[rootId]];
      header->level = myLevel(rootId);
      header->idx = mIdx++;
      //if (header->idx < 0) // overflow!
      //header->idx = mIdx = 0;
      //  TOS_CALL_COMMAND(GET_TIME)(&header->sendtime);
  
    }

    // handle case where parent is unknown.
    // parent becomes the sender of this msg
    void tinydbParentInit(DbMsgHdr header, short clock, uint8_t rootId) 
      {
	//  short curtime;

	mParentIx[rootId] = 0; // put parent in 1st slot in relatives array
	mRelOccupiedBits = 0x1; // 1 slot occupied: slot 0
	mRelatives[0] = header.senderid; // sender is parent
	mLastIdxRelative[0] = header.idx; 
	mCommProb[0] = 0xff; // ignore 1st message in stats
	mRelLevel[rootId][0] = header.level;
	//synchronize time with new parent (unless parent is root!)
	//	if (MY_LEVEL != 1 
	//		&& mRelatives[mParentIx] == header.senderid) {
	//	  curtime = header.sendtime + TIME_OF_FLIGHT;
	// XXXX not sure that time sync works right!
	//  TOS_CALL_COMMAND(SET_TIME)(curtime);
	//}
	dbg(DBG_USR1,"%d: parent is %d\n", TOS_LOCAL_ADDRESS, header.senderid);
      }

    // loop through list of relatives looking for match to sender of msg. 
    // If match found, update stats and return index of match.  Else return BAD_IX.
    short tinydbUpdateSenderStats(DbMsgHdr header, short clock, uint8_t rootId)
      {
	int i, j, numDrops;
	unsigned short oldProb;

	for (i = 0; i < NUM_RELATIVES; i++) {
	  oldProb = mCommProb[i];
	  if ((mRelOccupiedBits & (0x1 << mParentIx[rootId])) //we have a parent?
	      && mRelatives[i] == header.senderid) {
	    // valid match found: update stats for this relative

	    if (header.idx > mLastIdxRelative[i]) {
	      if (mLastIdxRelative[i] == 0)
		numDrops = 0;
	      else
		// the -1 is because the sender's incrementing by 1 is natural
		numDrops = (header.idx - mLastIdxRelative[i] - 1);
	    }
	    else if (mLastIdxRelative[i] >= 0x3f &&
		     header.idx < mLastIdxRelative[i] - 0x3f)
	      // hackety hack: assume wraparound if last Idx was above 128 and
	      // new idx is more than 128 lower than last
	      numDrops = (0x7f - mLastIdxRelative[i]) + header.idx;
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
		mCommProb[i] = mCommProb[i] - (mCommProb[i] >> ALPHABITS);

	      // we heard this epoch.
	      // decrement history by a factor of 1/2^ALPHABITS.
	      mCommProb[i] -= (mCommProb[i] >> ALPHABITS);
	      // add in 2^8 * 1/(2^ALPHABITS) -1 = 2^(8-ALPHABITS) - 1
	      mCommProb[i] += (1 << (8-ALPHABITS)) - 1;
	    }
	    else {
	      // we inaccurately claimed not to receive a packet a while ago.
	      // add it back in.  It's hard to weight it appropriately, but
	      // a HACK lets decay it 1 epoch, i.e. add in 1/16 ~= 15
	      mCommProb[i] = (mCommProb[i] - (mCommProb[i] >> ALPHABITS));
	      mCommProb[i] += (1 << (8-2*ALPHABITS)) - 1;
	    }

	    mLastIdxRelative[i] = header.idx;
	    mRelLevel[rootId][i] = header.level;
	  
	    return(i);
	  } 
	}
	return(BAD_IX);
      }

    void tinydbRelativeReplace(DbMsgHdr header, short clock, uint8_t rootId)
      {
	int i;
	short worst;
	unsigned char lowestProb = 255;

	// either put sender in an empty relative slot,
	// or evict worst (which requires a definition of worst)
	// 
	for (i = 0, worst = -1; i < NUM_RELATIVES; i++) {
	  if (!( mRelOccupiedBits & (0x1 << i) )) { // slot is empty, use it
	    worst = i;
	    break;
	  }
	  else { // XXX HACK: for now, always evict based on lowest commProv
	    if ((worst == -1
		 || ((mCommProb[i] < lowestProb)))
		&& (i != mParentIx[rootId])) {
	      worst = i;
	      lowestProb = mCommProb[i];
	    }
	  }
	}
	mRelOccupiedBits |= (0x1 << worst);
	mRelatives[worst] = header.senderid;
	mLastIdxRelative[worst] = header.idx;
	mCommProb[worst] = 0xff; // ignore 1st message in stats
	mRelLevel[rootId][worst] = header.level;
      }

    void tinydbChooseParent(DbMsgHdr header, short clock, uint8_t rootId)
      {
	short i, best;
	unsigned char prob, tmpprob;
	short oldparent;
	short oldlevel;

	for (i = 0, best = -1, prob=0; i < NUM_RELATIVES; i++) {
	  // HACK II: to avoid loops, don't choose a parent at a higher level than 
	  // ourselves. At our own level, can choose parents numbered higher than us

	  if (mRelLevel[rootId][i] < myLevel(rootId) 
	      || (mRelLevel[rootId][i] == myLevel(rootId) && mRelatives[i] > TOS_LOCAL_ADDRESS))
	    if (mRelOccupiedBits & (0x1 << i)) {
	      tmpprob = mCommProb[i];
	      if (tmpprob > prob) {
		prob = tmpprob;
		best = i;
	      }
	    }
	}

	// HACK: choose parent based on least mean message arrival
	// set up new parent, and reset for new measurements
	//keep momentum for current parent at same level unless we see someone MUCH better
	// or new parent is at lower level
	if (mCommProb[best] - mCommProb[mParentIx[rootId]] > MAX_PROB_THRESH
	    || mRelLevel[rootId][best] < myLevel(rootId) ) {
	  oldlevel = myLevel(rootId);
	  oldparent = mParentIx[rootId];
	  mParentIx[rootId] = best;
	  dbg(DBG_USR1,"%d: new parent is %d.  I was at level %d, now at level %d.  She's at level %d\n", TOS_LOCAL_ADDRESS, mRelatives[best], oldlevel,myLevel(rootId), mRelLevel[rootId][best]);
	}

	//synchronize time with new parent (unless parent is root!)
	//  if (MY_LEVEL != 1 
	//	  && mRelatives[mParentIx] == header.senderid) 
	//	TOS_CALL_COMMAND(SET_TIME)(header.sendtime + TIME_OF_FLIGHT);
      }

    /* Do something with the header information in a message
   received from a neighbor / parent (e.g. update 
   routing tables, parent information, etc. )

   Return true if the message should be processed by the
   tuple router, or false if it should be rejected
*/
    bool processHeader(DbMsgHdr header,MsgType type, uint8_t rootId) 
      {
	bool wasParent = FALSE;

	if ((!mForceTopology || 
	     header.senderid == mParentCand1 ||
	     header.senderid == mParentCand2 || 
	     header.senderid == mParentCand3 ) &&
	     mParentIx[rootId] != 0 )
	  {
	    short clock = 0;
	    short match;

	    // ignore our own messages
	    if (header.senderid == TOS_LOCAL_ADDRESS && header.senderid != 0)
	      return FALSE;


	    //does our parent think we're it's parent?
	    //if (type == DATA_TYPE &&
	    //		    mParentIx != PARENT_UNKNOWN && 
	    //		    header.parentid == mRelatives[mParentIx]) {
	    //		  mParentIx = PARENT_UNKNOWN; //look for a new parent
	    //		  return FALSE; //and ignore this message!
	    //		}

	    if (mSendCount - mLastHeard < 0)
	      mLastHeard = mSendCount; //handle wraparound


	    if (mRelatives[mParentIx[rootId]] == header.senderid) {
	      //parent's level went up! -- reselect parent
	      if (header.level > mRelLevel[rootId][mParentIx[rootId]]) {
		mSendCount += PARENT_LOST_INTERVAL + 1;
	      }  else //parents level wen't down?  that's ok!
		mLastHeard = mSendCount;
	    }

	    //our parent thinks we're his parent -- bad news -- do something
	    if (header.parentid == TOS_LOCAL_ADDRESS && header.senderid == mRelatives[mParentIx[rootId]]) {
	      mSendCount += PARENT_LOST_INTERVAL + 1;
	    }

	    //HACK ! if we haven't heard from our parent for awhile, forget
	    //everything we know about our parent
		
	    if (mSendCount - mLastHeard> PARENT_LOST_INTERVAL) {
	      short parent = mParentIx[rootId];
	      mCommProb[mParentIx[rootId]] = 0; //make parent look awful
	      tinydbChooseParent(header, clock,rootId);
	      if (parent != mParentIx[rootId]) mLastHeard = mSendCount;
	      else {
		//reset routing!
		mParentIx[rootId] = PARENT_UNKNOWN;
		mRelOccupiedBits = 0;
	      }
	    }
			  
		  

	    //TOS_CALL_COMMAND(GET_TIME)(&clock);
	    clock = 0; //hack: clock unused!

	    // Base case: PARENT_UNKNOWN.  Initialize.
	    if (mParentIx[rootId] == PARENT_UNKNOWN) {
	      tinydbParentInit(header, clock, rootId);
	      wasParent = TRUE; // having no parent means this node is our parent
	      mLastHeard = mSendCount;
	    }
	    else { // common case
	      //  Update stats for this sender, if known.
	      match = tinydbUpdateSenderStats(header, clock,rootId);
	      if (match != BAD_IX && match == mParentIx[rootId])
		wasParent = TRUE;
	      else if (match == BAD_IX) {
		// Sender was not known.
		// Decide whether to keep track of this sender (i.e. make
		// it a "relative".)
		tinydbRelativeReplace(header, clock, rootId);
	      }
		    
	      // Decide whether to change parents.
	      if (mSendCount - mLastCheck > PARENT_RESELECT_INTERVAL) {
		tinydbChooseParent(header, clock, rootId);
		mLastCheck = mSendCount;
	      }
	    }
	  }

	if (type == DATA_TYPE && header.parentid == TOS_LOCAL_ADDRESS)
	  return TRUE; //handle data messages to us
	else if (type == QUERY_TYPE) { //&& (wasParent || header.senderid == 0)) { /*}*/
	  dbg(DBG_USR1,"%d: GOT QUERY MESSAGE \n", TOS_LOCAL_ADDRESS);
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
	if (mFanout == 1)
	  {
	    mMinparent = TOS_LOCAL_ADDRESS - 1;
	    mMaxparent = TOS_LOCAL_ADDRESS - 1;
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
		nodes_per_level *= mFanout;
		maxparent = minparent + nodes_per_level - 1;
	      }
	    mMinparent = prevminparent;
	    mMaxparent = prevmaxparent;
	  }
	// randomly pick three parent candidates between minparent and maxparent
	nodes_per_level = mMaxparent - mMinparent + 1;
	if (nodes_per_level <= 2)
	  {
	    mParentCand1 = mMinparent;
	    mParentCand2 = mParentCand3 = mMaxparent;
	  }
	else
	  {
	    mParentCand1 = mMinparent + call Random.rand() % nodes_per_level;
	    mParentCand2 = mMinparent + call Random.rand()  % nodes_per_level;
	    mParentCand3 = mMinparent + call Random.rand() % nodes_per_level;
	  }
      }

    //neighbor radius constraint
    /* Limit the possible parents each mote can select */
    command result_t Network.forceTopology(uint8_t fanout) {
      int i;

      call Leds.redToggle();

      for (i = 0; i < NUM_ROOTS; i++)
	mParentIx[i] = PARENT_UNKNOWN;

      if ((unsigned char)fanout != 0xFF) {
	call Leds.greenOn();
	mFanout = fanout;
	setParentRange();
      } else {
	call Leds.greenOff();
	mFanout = fanout;
	mForceTopology = FALSE;    
      }

      return SUCCESS;
    }


    //centralized vs. in-net aggregation
    /* Route all the data to the root (perform no in-network aggregation */
    command result_t Network.setCentralized(bool on) {
      if (!on) {
	mCentralized = FALSE;
	call Leds.greenToggle();
      } else {
	mCentralized = TRUE;
	call Leds.redToggle();
      }
      return SUCCESS;
    }

	event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo err)
	{
		// XXX ignore command return values for now
		return SUCCESS;
	}

	event result_t ParentAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
	{
		*err = SCHEMA_RESULT_READY;
		*(uint16_t*)resultBuf = mRelatives[mParentIx[0]];
		return SUCCESS;
	}
	event result_t ParentAttr.setAttr(char *name, char *resultBuf)
	{
		// don't allow manually setting parent
		return FAIL;
	}

	event result_t QueryProcessor.queryComplete(ParsedQueryPtr q) {
	  return SUCCESS;
	}
}

