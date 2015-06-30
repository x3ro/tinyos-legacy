// $Id: MultiHopEngineGridM.nc,v 1.1 2004/02/25 06:54:57 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* 
 * A simple module that handles multihop packet movement.  It accepts 
 * messages from both applications and the network and does the necessary
 * interception and forwarding.
 * It interfaces to an algorithmic componenet via RouteSelect. It also acts
 * as a front end for RouteControl
 */

includes AM;
includes MultiHop;

#ifndef MHOP_QUEUE_SIZE
#define MHOP_QUEUE_SIZE	16
#endif

module MultiHopEngineGridM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Send[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface RouteControl;
    interface RouteQuery;
  }
  uses {
    interface ReceiveMsg[uint8_t id];
    interface SendMsg[uint8_t id];
    interface RouteControl as RouteSelectCntl;
    interface RouteQuery as RouteSelectQuery;
    interface RouteSelect;
    interface StdControl as SubControl;
    interface CommControl;
    interface StdControl as CommStdControl;
  }
}

implementation {

  enum {
    FWD_QUEUE_SIZE = MHOP_QUEUE_SIZE, // Forwarding Queue
    EMPTY = 0xff
  };


  /* Routing status of local node */


  /* Internal storage and scheduling state */
  struct TOS_Msg FwdBuffers[FWD_QUEUE_SIZE];
  struct TOS_Msg *FwdBufList[FWD_QUEUE_SIZE];

  uint8_t iFwdBufHead, iFwdBufTail;

  int timer_rate,timer_ticks;
  
  /***********************************************************************
   * Initialization 
   ***********************************************************************/


  static void initialize() {
    int n;

    for (n=0; n < FWD_QUEUE_SIZE; n++) {
      FwdBufList[n] = &FwdBuffers[n];
    } 

    iFwdBufHead = iFwdBufTail = 0;
  }

  command result_t StdControl.init() {
    initialize();
    call CommStdControl.init();
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    call CommStdControl.start();
    call SubControl.start();
    return call CommControl.setPromiscuous(TRUE);
  }

  command result_t StdControl.stop() {
    call SubControl.stop();
    // XXX message doesn't get received if we stop then start radio
    return call CommStdControl.stop();
  }


  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  command result_t Send.send[uint8_t id](TOS_MsgPtr pMsg, uint16_t PayloadLen) {

    uint16_t usMHLength = offsetof(TOS_MHopMsg,data) + PayloadLen;

    if (usMHLength > TOSH_DATA_LENGTH) {
      return FAIL;
    }

    dbg(DBG_ROUTE,"MHop: send\n");

    call RouteSelect.initializeFields(pMsg,id);

    if (call RouteSelect.selectRoute(pMsg,id) != SUCCESS) {
      return FAIL;
    }

    dbg(DBG_ROUTE,"MHop: out pkt 0x%x to 0x%x\n",((TOS_MHopMsg *)pMsg->data)->seqno, ((TOS_MHopMsg *)pMsg->data)->originaddr);
    
    if (call SendMsg.send[id](pMsg->addr, usMHLength, pMsg) != SUCCESS) {
      dbg(DBG_ROUTE,"MHop: send failed\n");
      return FAIL;
    }

    return SUCCESS;
    
  } 

  command void *Send.getBuffer[uint8_t id](TOS_MsgPtr pMsg, uint16_t* length) {
    
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;
    
    *length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);

    return (&pMHMsg->data[0]);

  }

  
  static TOS_MsgPtr mForward(TOS_MsgPtr pMsg, uint8_t id) {
    TOS_MsgPtr	pNewBuf = pMsg;
    
    if (((iFwdBufHead + 1) % FWD_QUEUE_SIZE) == iFwdBufTail) 
      return pNewBuf;
    
    if ((call RouteSelect.selectRoute(pMsg,id)) != SUCCESS) 
      return pNewBuf;
 
    // Failures at the send level do not cause the seq. number space to be 
    // rolled back properly.  This is somewhat broken.
    dbg(DBG_ROUTE, "Forwarding packet.\n");
    if (call SendMsg.send[id](pMsg->addr,pMsg->length,pMsg) == SUCCESS) {
      pNewBuf = FwdBufList[iFwdBufHead];
      FwdBufList[iFwdBufHead] = pMsg;
      iFwdBufHead++; iFwdBufHead %= FWD_QUEUE_SIZE;
    }
    
    return pNewBuf;
    
  }

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr pMsg) {
    TOS_MHopMsg		*pMHMsg = (TOS_MHopMsg *)pMsg->data;
    uint16_t		PayloadLen = pMsg->length - offsetof(TOS_MHopMsg,data);

    dbg(DBG_ROUTE, "MHop: Msg Rcvd, src 0x%02x, org 0x%02x, parent 0x%02x\n", 
        pMHMsg->sourceaddr, pMHMsg->originaddr, 0 /*pMHMsg->parentaddr*/);

    // Ordinary message requiring forwarding
    if (pMsg->addr == TOS_LOCAL_ADDRESS) { // Addressed to local node
      if ((signal Intercept.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen)) == SUCCESS) {
	if (pMHMsg->originaddr != TOS_LOCAL_ADDRESS) {
	  pMsg = mForward(pMsg,id);
	}
	else {
	  dbg(DBG_ROUTE, "MHop: Signalling receive\n");
	  return signal Receive.receive[id](pMsg, pMHMsg->data, TOSH_DATA_LENGTH - 7);
	}
      }
    }
    else {
      // Snoop the packet for permiscuous applications
      signal Snoop.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen);
    }

    return pMsg;
  }

 default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
   return msg;
 }
  

  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
    //dbg(DBG_ROUTE, "MHop: senddone 0x%x 0x%x\n", pMsg, success);  
    if (success == FAIL) {
      call RouteSelect.initializeFields(pMsg,id);
      
      if (call RouteSelect.selectRoute(pMsg,id) != SUCCESS) {
	signal Send.sendDone[id](pMsg, success);
      }
      
      dbg(DBG_ROUTE,"MHop: out pkt 0x%x to 0x%x\n",((TOS_MHopMsg *)pMsg->data)->seqno, ((TOS_MHopMsg *)pMsg->data)->originaddr);
      
      if (call SendMsg.send[id](pMsg->addr, pMsg->length, pMsg) != SUCCESS) {
	dbg(DBG_ROUTE,"MHop: send failed\n");
	signal Send.sendDone[id](pMsg, success);
      }
    } else if (pMsg == FwdBufList[iFwdBufTail]) { // Msg was from forwarding queue
      iFwdBufTail++; iFwdBufTail %= FWD_QUEUE_SIZE;
    }
    else {
      signal Send.sendDone[id](pMsg, success);
    } 
    return SUCCESS;
  }

  command uint16_t RouteControl.getParent() {
    return call RouteSelectCntl.getParent();
  }

  command uint8_t RouteControl.getQuality() {
    return call RouteSelectCntl.getQuality();
  }

  command uint8_t RouteControl.getDepth() {
    return call RouteSelectCntl.getDepth();
  }

  command uint8_t RouteControl.getOccupancy() {
    uint16_t uiOutstanding = (uint16_t)iFwdBufTail - (uint16_t)iFwdBufHead;
    uiOutstanding %= FWD_QUEUE_SIZE;
    return (uint8_t)uiOutstanding;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    TOS_MHopMsg	 *pMHMsg = (TOS_MHopMsg *)msg->data;
    return pMHMsg->sourceaddr;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) {
    return call RouteSelectCntl.setUpdateInterval(Interval);
  }

  command result_t RouteControl.manualUpdate() {
    return call RouteSelectCntl.manualUpdate();
  }

  command uint8_t RouteQuery.getParentCount() {
    return call RouteSelectQuery.getParentCount();
  }

  command uint16_t RouteQuery.getParentID(uint8_t which) {
    return call RouteSelectQuery.getParentID(which);
  }

  command uint8_t RouteQuery.getParentQuality(uint8_t which) {
    return call RouteSelectQuery.getParentQuality(which);
  }
  
  default event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }

  default event result_t Intercept.intercept[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
							 uint16_t payloadLen) {
    return SUCCESS;
  }

  default event result_t Snoop.intercept[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
                                                     uint16_t payloadLen) {
    return SUCCESS;
  }

}
