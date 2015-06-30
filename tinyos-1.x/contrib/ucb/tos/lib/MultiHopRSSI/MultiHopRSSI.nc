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
 * Authors:          Gilman Tolle
 */


includes MultiHop;

module MultiHopRSSI {

  provides {
    interface StdControl;
    interface RouteSelect;
    interface RouteControl;
  }

  uses {
    interface Timer;

    interface SendMsg;
    interface ReceiveMsg;

    interface Random;

    interface RouteStats;

    interface Time;
    interface TimeUtil;
    interface TimeSet;
    interface RadioCoordinator;
  }
}

implementation {

  enum {
    BASE_STATION_ADDRESS = 0,
    BEACON_PERIOD        = 32,
  };

  enum {
    ROUTE_INVALID    = 0xff
  };


  TOS_Msg msgBuf;
  bool msgBufBusy;

  uint16_t gbCurrentParent;
  uint16_t gbCurrentParentCost;
  uint16_t gbCurrentLinkEst;
  uint8_t  gbCurrentHopCount;
  uint16_t gbCurrentCost;

  int16_t gCurrentSeqNo;

  uint16_t gUpdateInterval;

  task void SendRouteTask() {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *) &msgBuf.data[0];
    BeaconMsg *pRP = (BeaconMsg *)&pMHMsg->data[0];
    uint8_t length = offsetof(TOS_MHopMsg,data) + sizeof(BeaconMsg);

    dbg(DBG_ROUTE,"MultiHopRSSI Sending route update msg.\n");

    if (gbCurrentParent != TOS_BCAST_ADDR) {
      dbg(DBG_ROUTE,"MultiHopRSSI: Parent = %d\n", gbCurrentParent);
    }
    
    if (msgBufBusy) {
#ifndef PLATFORM_PC
      post SendRouteTask();
#endif
      return;
    }

    dbg(DBG_ROUTE,"MultiHopRSSI: Current cost: %d.\n", 
	gbCurrentParentCost + gbCurrentLinkEst);

    pRP->parent = gbCurrentParent;
    pRP->cost = gbCurrentParentCost + gbCurrentLinkEst;
    pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->hopcount = gbCurrentHopCount;
    pMHMsg->seqno = gCurrentSeqNo++;
    
    if (call SendMsg.send(TOS_BCAST_ADDR, length, &msgBuf) == SUCCESS) {
      atomic msgBufBusy = TRUE;
    }
  }

  task void TimerTask() {
    post SendRouteTask();
  }

  command result_t StdControl.init() {

    gbCurrentParent = TOS_BCAST_ADDR;
    gbCurrentParentCost = 0x7fff;
    gbCurrentLinkEst = 0x7fff;
    gbCurrentHopCount = ROUTE_INVALID;
    gbCurrentCost = 0xfffe;

    gCurrentSeqNo = 0;
    gUpdateInterval = BEACON_PERIOD;
    atomic msgBufBusy = FALSE;

    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDRESS) {
      gbCurrentParent = TOS_UART_ADDR;
      gbCurrentParentCost = 0;
      gbCurrentLinkEst = 0;
      gbCurrentHopCount = 0;
      gbCurrentCost = 0;
    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_ONE_SHOT, 
		     call Random.rand() % (1024 * gUpdateInterval));
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  command bool RouteSelect.isActive() {
    return TRUE;
  }

  command result_t RouteSelect.selectRoute(TOS_MsgPtr Msg, uint8_t id, 
					   uint8_t resend) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
    
    if (gbCurrentParent != TOS_UART_ADDR && resend == 0) {
      pMHMsg->seqno = gCurrentSeqNo++;
    }
    pMHMsg->hopcount = gbCurrentHopCount;
    Msg->addr = gbCurrentParent;

    return SUCCESS;
  }

  command result_t RouteSelect.initializeFields(TOS_MsgPtr Msg, uint8_t id) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

    pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->hopcount = ROUTE_INVALID;

    return SUCCESS;
  }

  command uint8_t* RouteSelect.getBuffer(TOS_MsgPtr Msg, uint16_t* Len) {

  }

  command uint16_t RouteControl.getParent() {
    return gbCurrentParent;
  }

  command uint8_t RouteControl.getQuality() {
    return gbCurrentLinkEst;
  }

  command uint8_t RouteControl.getDepth() {
    return gbCurrentHopCount;
  }

  command uint8_t RouteControl.getOccupancy() {
    return 0;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    TOS_MHopMsg		*pMHMsg = (TOS_MHopMsg *)msg->data;
    return pMHMsg->sourceaddr;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) {

    gUpdateInterval = Interval;
    return SUCCESS;
  }

  command result_t RouteControl.manualUpdate() {
    return SUCCESS;
  }


  event result_t Timer.fired() {
    post TimerTask();
    call Timer.start(TIMER_ONE_SHOT, 1024 * gUpdateInterval + 1);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {

    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
    BeaconMsg *pRP = (BeaconMsg *)&pMHMsg->data[0];

//    dbg(DBG_ROUTE, "Received Beacon(source=%d, cost=%d, strength=%d)\n",
//	pMHMsg->sourceaddr, pRP->cost, Msg->strength);

    /* if the message is from my parent
       store the new link estimation */

    if (pMHMsg->sourceaddr == gbCurrentParent) {

      gbCurrentParentCost = pRP->cost;
      gbCurrentLinkEst = Msg->strength;

      call TimeSet.set(call TimeUtil.create(0, pRP->timestamp));
      dbg(DBG_ROUTE,"TimeSync: Setting Time To: %d\n", pRP->timestamp);

    } else {

    /* if the message is not from my parent, 
       compare the message's cost + link estimate to my current cost,
       switch if necessary */

      if ((uint32_t) pRP->cost + (uint32_t) Msg->strength <
	  (uint32_t) gbCurrentParentCost + (uint32_t) gbCurrentLinkEst) {

	gbCurrentParent = pMHMsg->sourceaddr;
	gbCurrentParentCost = pRP->cost;
	gbCurrentLinkEst = Msg->strength;	
      }
    }

    return Msg;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    atomic msgBufBusy = FALSE;
    return SUCCESS;
  }

  async event void RadioCoordinator.startSymbol(uint8_t bitsPerBlock, 
						uint8_t offset, 
						TOS_MsgPtr msgBuff) {
    tos_time_t endTime;
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *) &msgBuff->data[0];
    BeaconMsg *pRP = (BeaconMsg *) &pMHMsg->data[0];

    atomic {
      if (msgBufBusy == TRUE) {
	endTime = call Time.get(); 
	pRP->timestamp = endTime.low32;
	dbg(DBG_ROUTE,"TimeSync: End Send RoutePacket Time %d\n", endTime.low32);
      }
    }
  }

  async event void RadioCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) {
      /* XXX: do nothing */
  }

  async event void RadioCoordinator.blockTimer() {
      /* XXX: do nothing */
  }
}

