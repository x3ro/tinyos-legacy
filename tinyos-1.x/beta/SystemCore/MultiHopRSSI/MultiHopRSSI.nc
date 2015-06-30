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

#ifdef MH_DEBUG
includes EventLoggerPerl;
#endif

includes MultiHopLayer;

module MultiHopRSSI {

  provides {
    interface StdControl;
    interface RouteSelect;
    interface RouteControl;
    
    command void forwardResult(result_t result);
    command uint16_t getTreeID();
  }

  uses {
    interface Timer;
    interface Timer as AgingTimer;

    interface SendMsg;
    interface ReceiveMsg;

    interface Random;

    interface RouteStats;

#ifdef TIMESYNC
    interface Time;
    interface TimeUtil;
    interface TimeSet;
#endif

#if defined(PLATFORM_MICA) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
    interface RadioCoordinator;
#endif

    interface SharedMsgBuf;

    interface MgmtAttr as MA_Parent;
    interface MgmtAttr as MA_CurrentTreeID;
    interface MgmtAttr as MA_CurrentParentCost;
    interface MgmtAttr as MA_CurrentParentLinkEst;
    interface MgmtAttr as MA_CurrentParentAckEst;
    interface MgmtAttr as MA_BeaconSeqno;
    interface MgmtAttr as MA_SuccessCounter;
    interface MgmtAttr as MA_FailCounter;
    interface MgmtAttr as MA_PacketTTLDrops;

    interface EventLogger;
  }
}

implementation {

  
  enum {
    BEACON_PERIOD        = 31,
    MAX_MISSED_BEACONS   = 5,
  };

  enum {
    ROUTE_INVALID    = 0xff,
    UNKNOWN_ACK_EST  = 127,
  };

/*
  TOS_Msg msgBuf;
*/
  bool msgBufBusy = FALSE;

  int8_t   beaconSeqno = 1;
  uint8_t  missedBeacons = 0;
  uint16_t beaconPeriod;

  uint16_t currentTreeID = 0;
  uint16_t currentParentAddr;
  uint16_t currentParentCost;
  uint16_t currentParentLinkEst;
  uint16_t currentParentLQI;
  uint16_t currentParentAckEst;

  uint16_t packetTTLDrops = 0;
  uint16_t successCounter = 0;
  uint16_t failCounter = 0;

#define MAX(a_,b_) (a_ > b_ ? a_ : b_)
#define MIN(a_,b_) (a_ < b_ ? a_ : b_)

  uint16_t adjustLQI(uint8_t val) {
    uint16_t result = (80 - (val - 50));
    result = (((result * result) >> 3) * result) >> 3;
    return result;
  }

  task void SendRouteTask() {
    TOS_MsgPtr pMsgBuf = call SharedMsgBuf.getMsgBuf();
    MultihopBeaconMsg *pRP = (MultihopBeaconMsg *)&pMsgBuf->data[0];
    uint8_t length = sizeof(MultihopBeaconMsg);

    dbg(DBG_ROUTE,"MultiHopRSSI Sending route update msg.\n");

    if (currentParentAddr != TOS_BCAST_ADDR) {
      dbg(DBG_ROUTE,"MultiHopRSSI: Parent = %d\n", currentParentAddr);
    }

    if (!call SharedMsgBuf.lock()) {
#ifndef PLATFORM_PC
      post SendRouteTask();
#endif
      return;
    }

    atomic msgBufBusy = TRUE;

    dbg(DBG_ROUTE,"MultiHopRSSI: Current cost: %d.\n", 
	currentParentCost + currentParentLinkEst);

    pRP->parent = currentParentAddr;
    pRP->sourceAddr = TOS_LOCAL_ADDRESS;
    pRP->cost = currentParentCost + currentParentLinkEst;
#ifndef NO_ACK_EST
    pRP->cost += currentParentAckEst;
#endif
    pRP->treeID = currentTreeID;
    pRP->beaconSeqno = beaconSeqno;
    pRP->beaconPeriod = beaconPeriod;

#ifdef TIMESYNC
    atomic {
      tos_time_t endTime;
      if (msgBufBusy == TRUE) {
	endTime = call Time.get(); 
	pRP->timestamp = endTime.low32;
	dbg(DBG_ROUTE,"TimeSync: End Send RoutePacket Time %d\n", endTime.low32);
      }
    }
#endif

    if (!call SendMsg.send(TOS_BCAST_ADDR, length, pMsgBuf)) {
      atomic msgBufBusy = FALSE;
      call SharedMsgBuf.unlock();
    }
  }

  command result_t StdControl.init() {

    currentParentAddr = TOS_BCAST_ADDR;
    currentParentCost = 0xffff;
    currentParentLinkEst = 0xffff;
    currentParentAckEst = UNKNOWN_ACK_EST;
    currentParentLQI = 0x0;

    call MA_Parent.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_CurrentTreeID.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_CurrentParentCost.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_CurrentParentLinkEst.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_CurrentParentAckEst.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_BeaconSeqno.init(sizeof(uint8_t), MA_TYPE_UINT);
    call MA_SuccessCounter.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_FailCounter.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_PacketTTLDrops.init(sizeof(uint16_t), MA_TYPE_UINT);
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call AgingTimer.stop();
    call Timer.stop();
    return SUCCESS;
  }

  command bool RouteSelect.isActive() {
    return TRUE;
  }

  command result_t RouteSelect.selectRoute(TOS_MsgPtr Msg, uint8_t id) {
    MultihopLayerMsg *pMHMsg = (MultihopLayerMsg *)&Msg->data[0];

    Msg->addr = currentParentAddr;
    pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->ttl--;

    if (pMHMsg->ttl == 0) {
      if (packetTTLDrops < 0xffff)
	packetTTLDrops++;
      return FAIL;
    } else {
      return SUCCESS;
    }
  }

  command void forwardResult(result_t result) {
    if (result == SUCCESS) {
      successCounter++; 
    } else {
      failCounter++;
    }
  }

  command result_t RouteSelect.initializeFields(TOS_MsgPtr Msg, uint8_t id) {
    MultihopLayerMsg *pMHMsg = (MultihopLayerMsg *)&Msg->data[0];

    pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->ttl = 16;
    pMHMsg->type = id;

    return SUCCESS;
  }

  command uint8_t* RouteSelect.getBuffer(TOS_MsgPtr Msg, uint16_t* Len) {

  }

  command uint16_t RouteControl.getParent() {
    return currentParentAddr;
  }

  command uint8_t RouteControl.getQuality() {
    return currentParentLinkEst;
  }

  command uint8_t RouteControl.getDepth() {
    return 0;
  }

  command uint8_t RouteControl.getOccupancy() {
    return 0;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    MultihopLayerMsg		*pMHMsg = (MultihopLayerMsg *)msg->data;
    return pMHMsg->sourceaddr;
  }

  command uint16_t getTreeID() {
    return currentTreeID;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t interval) {
    return FAIL;
  }

  command result_t RouteControl.manualUpdate() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    post SendRouteTask();
    return SUCCESS;
  }

  event result_t AgingTimer.fired() {
#ifndef NO_ACK_EST
    if (successCounter + failCounter > 0) {
      currentParentAckEst = (255 - (255 * successCounter) / (successCounter + failCounter));
      successCounter = failCounter = 0;
    }
#endif

    if (missedBeacons > MAX_MISSED_BEACONS) {
      if (currentParentLinkEst << 1 < 0xffff) {
	currentParentLinkEst <<= 1;
      } else {
	currentParentLinkEst = 0xffff;
      }
    }
    if (missedBeacons != 0xff) {
      missedBeacons++;
    }

    call AgingTimer.start(TIMER_ONE_SHOT, (1024 * beaconPeriod));
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {

    MultihopBeaconMsg *pRP = (MultihopBeaconMsg *)&Msg->data[0];

//    dbg(DBG_ROUTE, "Received Beacon(source=%d, cost=%d, strength=%d)\n",
//	pMHMsg->sourceaddr, pRP->cost, Msg->strength);

    
    /* 
       If we already belong to the newest tree we know of, consider the beacon seqno.
       If it is newer, send out our own beacon.
    */

    if (pRP->beaconSeqno > beaconSeqno || pRP->beaconSeqno == 0) {
      if (pRP->beaconSeqno == 0) {
	beaconSeqno++;
	if (beaconSeqno == 0)
	  beaconSeqno++;
      }	else {
	beaconSeqno = pRP->beaconSeqno;
      }

      if (pRP->beaconPeriod != beaconPeriod) {
	beaconPeriod = pRP->beaconPeriod;
	call AgingTimer.stop();
	call AgingTimer.start(TIMER_ONE_SHOT,
			      1024 * beaconPeriod);
      }
      call Timer.start(TIMER_ONE_SHOT, 
		       (call Random.rand() % (1024 * beaconPeriod)) + 1);
    }
    
    /* Now evaluate whether we should reparent to the beacon. */
      
    if (pRP->sourceAddr == currentParentAddr) {

      uint16_t newLinkEst;

      
      currentTreeID = pRP->treeID;
      currentParentCost = pRP->cost;

#ifdef PLATFORM_TELOS
      newLinkEst = adjustLQI(Msg->lqi);
      currentParentLQI = Msg->lqi;
#else
      newLinkEst = Msg->strength;
#endif

      currentParentLinkEst = newLinkEst;

      missedBeacons = 0;

#ifdef TIMESYNC
      call TimeSet.set(call TimeUtil.create(0, pRP->timestamp));
      dbg(DBG_ROUTE,"TimeSync: Setting Time To: %d\n", pRP->timestamp);
#endif

    } else {

    /* if the message is not from my parent, 
       compare the message's cost + link estimate to my current cost,
       switch if necessary */

      uint32_t currentQuality = 
	(uint32_t) currentParentCost + (uint32_t) currentParentLinkEst; 
      uint16_t newLinkEst;
      uint32_t newQuality = pRP->cost;
      
#ifdef PLATFORM_TELOS
      newLinkEst = adjustLQI(Msg->lqi);
      newQuality += (uint32_t) adjustLQI(Msg->lqi);
#else
      newLinkEst = Msg->strength;
      newQuality += (uint32_t) Msg->strength;
#endif
      
#ifdef NO_ACK_EST
      // do nothing
#else
      currentQuality += (uint32_t) currentParentAckEst;
      newQuality += (uint32_t) UNKNOWN_ACK_EST;
#endif

      if (newQuality < currentQuality && pRP->parent != TOS_LOCAL_ADDRESS) {
	
	currentTreeID = pRP->treeID;
	currentParentAddr = pRP->sourceAddr;
	currentParentCost = pRP->cost;
	currentParentLinkEst = newLinkEst;
	currentParentAckEst = UNKNOWN_ACK_EST;
#ifdef PLATFORM_TELOS
	currentParentLQI = Msg->lqi;
#endif
	successCounter = 0;
	failCounter = 0;
      }
    }

#ifdef MH_DEBUG
    <snms>
       logEvent("Got Multihop Beacon(source=%2d,cost=%2d,tree=%2d)", 
		pRP->sourceAddr, pRP->cost, pRP->treeID);
    </snms>
#endif
	
    return Msg;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    if (pMsg == call SharedMsgBuf.getMsgBuf()) {
      atomic msgBufBusy = FALSE;
      call SharedMsgBuf.unlock();
    }
    return SUCCESS;
  }

#if defined(PLATFORM_MICA) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)

  async event void RadioCoordinator.startSymbol(uint8_t bitsPerBlock, 
						uint8_t offset, 
						TOS_MsgPtr msgBuff) {

#ifdef TIMESYNC
    MultihopLayerMsg *pMHMsg = (MultihopLayerMsg *) &msgBuff->data[0];
    MultihopBeaconMsg *pRP = (MultihopBeaconMsg *) &pMHMsg->data[0];

    tos_time_t endTime;
    atomic {
      if (msgBufBusy == TRUE) {
	endTime = call Time.get(); 
	pRP->timestamp = endTime.low32;
	dbg(DBG_ROUTE,"TimeSync: End Send RoutePacket Time %d\n", endTime.low32);
      }
    }
#endif

  }

  async event void RadioCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) {
      /* XXX: do nothing */
  }

  async event void RadioCoordinator.blockTimer() {
      /* XXX: do nothing */
  }

#endif

  event result_t MA_Parent.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &currentParentAddr, sizeof(currentParentAddr));
    return SUCCESS;
  }
  event result_t MA_CurrentTreeID.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &currentTreeID, sizeof(currentTreeID));
    return SUCCESS;
  }
  event result_t MA_BeaconSeqno.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &beaconSeqno, sizeof(beaconSeqno));
    return SUCCESS;
  }
  event result_t MA_CurrentParentCost.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &currentParentCost, sizeof(currentParentCost));
    return SUCCESS;
  }
  event result_t MA_CurrentParentLinkEst.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &currentParentLinkEst, sizeof(currentParentLinkEst));
    return SUCCESS;
  }
  event result_t MA_CurrentParentAckEst.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &currentParentAckEst, sizeof(currentParentAckEst));
    return SUCCESS;
  }
  event result_t MA_SuccessCounter.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &successCounter, sizeof(successCounter));
    return SUCCESS;
  }
  event result_t MA_FailCounter.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &failCounter, sizeof(failCounter));
    return SUCCESS;
  }
  event result_t MA_PacketTTLDrops.getAttr(uint8_t *attrBuf) {
    memcpy(attrBuf, &packetTTLDrops, sizeof(packetTTLDrops));
    return SUCCESS;
  }
}

