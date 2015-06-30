/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

module DataTransferM {
  provides {
    interface DataTransfer;
  }
  uses {
    interface ChannelState;
    interface Core;
    interface Schedule;
    interface SystemTime;
    interface DataManagement;
    interface Timer as RxTimer;
    interface Timer as TxTimer;
    interface MsgBuf;
    interface SendMsg as SendAdvMsg;
    interface ReceiveMsg as ReceiveAdvMsg;
    interface SendMsg as SendReqMsg;
    interface ReceiveMsg as ReceiveReqMsg;
    interface SendMsg as SendDataMsg;
    interface ReceiveMsg as ReceiveDataMsg;
    interface Random;
    interface BitVecUtils;
    interface Leds;
  }
}

implementation {

  #include "BitVecUtils.h"

  enum {
    S_DISABLED, 
    S_READY,
    S_RX_ACTIVE,
    S_RX_PASSIVE,
    S_TX_START,
    S_TX_SENDING,
    S_TX_IDLE,
    S_SLEEP,
  };

  enum {
    SLOT_C = 0,  // Child (RX)
    SLOT_P,      // Parent (TX)
    SLOT_Q,      // Quiescent (SLEEP)
  };

  enum {
      NOREQ_ROUNDS_B4_PHASE2 = 2,
      NUM_ROUNDS_B4_EXIT = 5,
  };

  uint8_t _state = S_DISABLED;

  // SLOT_C, SLOT_P or SLOT_Q.
  // For base station, this variable is used to count the slots
  // before starting data transfer (i.e., starting C-P-Q scheduling).
  uint8_t _slotCount;  

  /* State info for senders. */
  uint16_t _pageToSend;
  uint8_t  _pktsToSend[PKTS_BITVEC_SIZE];
  uint16_t _numPktsToSend;

  /* State info for receivers. */
  uint8_t _parentCompletePages;
  uint8_t _reqCount;

  /* State info for all. */
  
  TOS_MsgPtr _msgBufAdv;
  TOS_MsgPtr _msgBufReq;
  TOS_MsgPtr _msgBufData;

  /* Flags for core nodes. */
  uint8_t _hasCoreChildren = 0;

  uint8_t _noReqRoundCount = 0;  // used by core nodes.
  uint8_t _noDataRoundCount = 0; // used by non-core nodes.

  uint8_t _localPhase2Flag = 0;
  // core nodes: _localPhase2Flag is 1 when the local node receives all pages AND
  // it does not receive requests for NOREQ_ROUNDS_B4_PHASE2 rounds. 
  // noncore nodes: _localPhase2Flag is 1 when receiving ADV from parent 
  // with phase2Flag on.

  // Each node calls this function to quit data transfer.
  static inline void quitDataTransfer() {
      result_t result = ((call DataManagement.getNumPagesComplete() 
                         == call DataManagement.getNumPages()) ? SUCCESS: FAIL);
      call ChannelState.turnOffRadio();
      call TxTimer.stop();
      call RxTimer.stop();
      call Schedule.stop();
      call MsgBuf.putMsgBuf(_msgBufAdv);
      call MsgBuf.putMsgBuf(_msgBufReq);
      call MsgBuf.putMsgBuf(_msgBufData);
      _state = S_DISABLED;

      // Yellow toggling means ongoing data transfer.
      // Turned off when the data transfer is over.
      call Leds.yellowOff(); 

      signal DataTransfer.done(result);
      __finish();
  }

  task void sendData() {
    
      if (_state != S_TX_SENDING) return;
      
      if (call SendDataMsg.send(TOS_BCAST_ADDR, sizeof(DataMsg), _msgBufData) 
          == SUCCESS) {
          DataMsg * pDataMsg = (DataMsg *)(_msgBufData->data);
          dbg(DBG_USR1, "Sending DATA: Page %u, Packet %u, %u more, at %u ms\n",
              pDataMsg->page, 
              pDataMsg->packet, 
              pDataMsg->morePackets,
              call SystemTime.getCurrentTimeMillis());
      } else {
          call TxTimer.start(TIMER_ONE_SHOT, 
              call Random.rand() % RANDOM_DELAY + 1);
      }
  }

  task void sendAdv() {
      AdvMsg * pAdvMsg = (AdvMsg *)(_msgBufAdv->data);
      pAdvMsg->sourceAddr = TOS_LOCAL_ADDRESS;
      pAdvMsg->sourceDepth = call Core.getDepth();
      pAdvMsg->completePages = call DataManagement.getNumPagesComplete(); 
      pAdvMsg->phase2Flag = _localPhase2Flag;

      if (call SendAdvMsg.send(TOS_BCAST_ADDR, sizeof(AdvMsg), _msgBufAdv) 
          == SUCCESS) {
          dbg(DBG_USR1, "Sending ADV (%u pages, phase2Flag:%d) at %u ms\n",
              pAdvMsg->completePages,
              pAdvMsg->phase2Flag,
              call SystemTime.getCurrentTimeMillis());
      } else {
          post sendAdv();
      }    
  }
  
  static void setupDataMsg() {
  
      uint16_t idx;
    
      if (_state == S_TX_SENDING) { 
          if (call Schedule.getSlotTimeLeft() <= (PACKET_TRANSMISSION_TIME + MAX_JITTER)) {
              /* No time to send anything. */
              _state = S_SLEEP;
              call ChannelState.turnOffRadio();
              return;
          }

          if (call BitVecUtils.indexOf(&idx, 0, _pktsToSend, PKTS_PER_PAGE) == SUCCESS) {
              DataMsg * pDataMsg = (DataMsg *)(_msgBufData->data);
              pDataMsg->sourceAddr = TOS_LOCAL_ADDRESS;
              pDataMsg->sourceDepth = call Core.getDepth();
              pDataMsg->page = _pageToSend;
              pDataMsg->packet = idx;
              pDataMsg->morePackets = _numPktsToSend-1;
              pDataMsg->completePages = call DataManagement.getNumPagesComplete();
              pDataMsg->phase2Flag = _localPhase2Flag;
              // Fill the data.
              call DataManagement.readPkt(pDataMsg->page, pDataMsg->packet,
                  pDataMsg->data);
          } else {
              /* No packets pending to send. */
              _state = S_TX_IDLE;
              call TxTimer.start(TIMER_ONE_SHOT, MAX_REQ_DELAY); 
          }     
      }
  }

  event void DataManagement.readPktDone(result_t success) {
      if (success == SUCCESS) {
          post sendData();
      } else {
          call TxTimer.start(TIMER_ONE_SHOT, 
              call Random.rand() % RANDOM_DELAY + 1);
      }   
  }

  event void DataManagement.initDone(result_t success) {} 

  event void DataManagement.setObjMetadataDone() {}

  event void DataManagement.newObjComplete() {
      if (_state == S_DISABLED) return;

      __receiveAll(call Core.isCoreNode());

      if (!call Core.isCoreNode()) {
          // Non-core nodes quit as soon as they receive the new object.
          quitDataTransfer();
      }
  }
 
  command result_t DataTransfer.start() {
      memset(_pktsToSend, 0, sizeof(_pktsToSend));
      _numPktsToSend = 0;
      
      if (__isBase()) {
          // Assume base has always core children, 
          // otherwise it will enter phase 2 right at the beginning.
          _hasCoreChildren = 1;

          _slotCount = 0;
      } else {
          _hasCoreChildren = 0;
      }

      _noReqRoundCount = 0;
      _noDataRoundCount = 0;
      _localPhase2Flag = 0;

      // Prepare all of the three messages.
      // This requires the MsgBuf pool has at least three buffers.
      _msgBufAdv = call MsgBuf.getMsgBuf();
      _msgBufReq = call MsgBuf.getMsgBuf();
      _msgBufData = call MsgBuf.getMsgBuf();

      _state = S_READY;
      return SUCCESS;
  }

    
  static inline void doRx() {
      _reqCount = 0;

      if (!call Core.isCoreNode() && _noDataRoundCount++ >= NUM_ROUNDS_B4_EXIT) {
          // Non-core nodes tired of requesting and waiting for data.
          quitDataTransfer();
          return;
      }

      if (call DataManagement.getNumPages() == call DataManagement.getNumPagesComplete()) {
          /* Received all pages. Can sleep in all RX slots. */
          _state = S_SLEEP;
          call ChannelState.turnOffRadio();
      } else {
          call ChannelState.turnOnRadio(call Core.getParentDataChannel());
          if (call Core.isCoreNode() || _localPhase2Flag == 1) {
              _state = S_RX_ACTIVE;
          } else {
              _state = S_RX_PASSIVE;
          }
          if (_state == S_RX_ACTIVE &&
              _parentCompletePages > call DataManagement.getNumPagesComplete()) {
              call RxTimer.start(TIMER_ONE_SHOT, 
                  (call Random.rand() % MAX_REQ_DELAY) + MAX_JITTER);
          } 
      }
  }

  static inline void doTx() {
      if (call Core.isCoreNode() && call DataManagement.getNumPagesComplete() > 0) {
          // Core node and has data to send.
          if (_localPhase2Flag == 0) {
              // Phase 1.
              if (call DataManagement.getNumPagesComplete() == call DataManagement.getNumPages()) {       
                  // Object is complete.
                  // For single-page object, node may not know _hasCoreChildren or not.
                  if (call DataManagement.getNumPages() > 1 && _hasCoreChildren == 0) {
                      // Has no core children.
                      _localPhase2Flag = 1;
                  } else {
                      // Waits for a few rounds before switching to Phase 2.
                      if (_noReqRoundCount >= NOREQ_ROUNDS_B4_PHASE2)
                          _localPhase2Flag = 1;
                  }

                  if (_localPhase2Flag == 1) {
                      // Just enters Phase 2.
                      // Count starts from 0 for Phase 2.
                      _noReqRoundCount = 0;
                      __printEvent("Entering Phase 2");
                  } else {
                      // Still in Phase 1.
                      _noReqRoundCount++;
                  }
              }
          } else {
              // In Phase 2.
              if (_noReqRoundCount++ >= NUM_ROUNDS_B4_EXIT) {
                  // Nobody is making requests to me, quit.
                  quitDataTransfer();
                  return;
              }
          }
      
          call ChannelState.turnOnRadio(call Core.getDataChannel());
          _state = S_TX_START;
          // Schedule for advertisements.
          call TxTimer.start(TIMER_ONE_SHOT, 
              (call Random.rand() % MAX_REQ_DELAY) + MAX_JITTER);

      } else {
          // Either it is a non-core node, or it has no data to send yet.
          call ChannelState.turnOffRadio();
          _state = S_SLEEP;
      }
  }

  event result_t Schedule.slotChanged() {

    /* The schedule is repeating rounds of RX-TX-Sleep.
       The slot names (RX, TX and Sleep) do not exactly denote 
       what the nodes behave in the specified slot, for example,
       a noncore node could stay in passive listening in TX slots in
       the first phase, and go to sleep in TX slots in the
       second phase. */
       
    if (_state == S_DISABLED) return SUCCESS;

    if (_state == S_READY) {
      if (__isBase()) {
          if (_slotCount++ >= DATA_TRANSFER_START_SLOTS) { 
	      _state = S_SLEEP;  // Base station enters the main protocol.
              _slotCount = SLOT_C;
          }
      } else {
        /* Turn radio on for a short time to see if the upper nodes are sending. */
        call ChannelState.turnOnRadio(call Core.getParentDataChannel());
        call RxTimer.start(TIMER_ONE_SHOT, INIT_LISTEN_PERIOD);
      }

    } else {

      call RxTimer.stop();
      call TxTimer.stop();

#ifdef USE_SINGLE_CHANNEL
      if (_slotCount == SLOT_C) _slotCount = SLOT_P;
      else if (_slotCount == SLOT_P) _slotCount = SLOT_Q;
      else if (_slotCount == SLOT_Q) _slotCount = SLOT_C;
 
#else
      if (_localPhase2Flag == 0) {
          if (_slotCount == SLOT_C) _slotCount = SLOT_P;
          else _slotCount = SLOT_C;
      } else {
          if (call Core.isCoreNode() == TRUE) _slotCount = SLOT_P; // always sending
          else _slotCount = SLOT_C; // always receiving
      }
#endif

      if (_slotCount == SLOT_C) doRx();
      else if (_slotCount == SLOT_P) doTx();
      else if (_slotCount == SLOT_Q) {
          _state = S_SLEEP;
          call ChannelState.turnOffRadio();
      }
    }

    return SUCCESS;
  }
  
  event result_t TxTimer.fired() {
    if (_state == S_TX_START) {
        post sendAdv();
    } else if (_state == S_TX_IDLE) {
        // No more requests.
        _state = S_SLEEP;
        call ChannelState.turnOffRadio();
    } else if (_state == S_TX_SENDING) {
        setupDataMsg();
    }
    return SUCCESS;
  }

  event result_t RxTimer.fired() {
      uint32_t timeNow = call SystemTime.getCurrentTimeMillis();
      ReqMsg * pReqMsg = (ReqMsg *)(_msgBufReq->data);
     
      if (_state == S_READY) {
          /* Did not receive anything from upper nodes during the short time. */
          call ChannelState.turnOffRadio();
          return SUCCESS;
      }

      /* Not in ACTIVE state, do nothing. */
      if (_state == S_RX_PASSIVE) {
          return SUCCESS;
      }

      /* In ACTIVE state: */

      if (call Schedule.getSlotTimeLeft() <= ((PACKET_TRANSMISSION_TIME << 1) + MAX_JITTER)) {
          /* No time to request anything. */
          call ChannelState.turnOffRadio();
          _state = S_SLEEP;
          return SUCCESS;
      }

      if (_parentCompletePages <= call DataManagement.getNumPagesComplete()) {
          /* Parent can provide no more pages. */
          call ChannelState.turnOffRadio();
          _state = S_SLEEP;
          return SUCCESS;
      }

      if (++_reqCount > MAX_NOAVAIL_REQUESTS) {
          /* Too many requests without getting reply. */
          call ChannelState.turnOffRadio();
          _state = S_SLEEP;
          return SUCCESS;
      }

      /* Parent is not sending. Send request. */
      pReqMsg->destAddr = call Core.getParent();
      pReqMsg->sourceAddr = TOS_LOCAL_ADDRESS;
      pReqMsg->sourceDepth = call Core.getDepth();
      pReqMsg->page = call DataManagement.getNextIncompletePage();
      call DataManagement.getPageRecvBitVec(pReqMsg->page, pReqMsg->requestedPkts);
      pReqMsg->isCoreNode = (call Core.isCoreNode() ? 1:0);
      if (call SendReqMsg.send(TOS_BCAST_ADDR, sizeof(ReqMsg), _msgBufReq) == SUCCESS) {
#ifdef PLATFORM_PC
          char buf[PKTS_PER_PAGE+1];
          call BitVecUtils.printBitVec(buf, pReqMsg->requestedPkts, PKTS_PER_PAGE);
          dbg(DBG_USR1, "Sending REQ for Page %u (%s) to Parent %u at %u ms\n",
              pReqMsg->page,
              buf,
              pReqMsg->destAddr,
              timeNow);
#endif
      } 

      // Schedule next request in case the current request is lost.
      call RxTimer.start(TIMER_ONE_SHOT, 
          (IDLE_DETECT_PACKETS + 1) * PACKET_TRANSMISSION_TIME 
          + (call Random.rand() % (MAX_REQ_DELAY >> 1)));

      return SUCCESS;
  }

  event TOS_MsgPtr ReceiveReqMsg.receive(TOS_MsgPtr pMsg) {
      ReqMsg * pReqMsg = (ReqMsg *)(pMsg->data);
    
      /* Nodes should not receive anything in sleep state.
         But TOSSIM does not turn off radio even if CommControl.stop() is called. */
      if (!call ChannelState.isRadioOn()) return pMsg;
    
      if (_state == S_DISABLED) return pMsg;

      if (pReqMsg->destAddr == TOS_LOCAL_ADDRESS) {
      
          /* The request is sent to this node. */
          _noReqRoundCount = 0;

          if (pReqMsg->isCoreNode == 1){
              // From core node.
              if (_localPhase2Flag == 1) {
                  // Go back to phase1.
                  _localPhase2Flag = 0;
                  __printEvent("Returning to Phase 1"); 
              }
              _hasCoreChildren = 1;
          } else {
              // Not from core node.
              // Request denied in the first phase.
              if (_localPhase2Flag == 0)
                  return pMsg;
          }

          dbg(DBG_USR1, "Received REQ for Page %u from Node %u at %u ms\n",
              pReqMsg->page,
              pReqMsg->sourceAddr,
              call SystemTime.getCurrentTimeMillis());

          if (_state == S_TX_START) {
              call TxTimer.stop();  // cancel the adv scheduling
              _state = S_TX_IDLE;
          }

          if (_state == S_TX_IDLE 
              || (_state == S_TX_SENDING && pReqMsg->page < _pageToSend)) {
              // Set up the new page to send.
              _pageToSend = pReqMsg->page;
	      memcpy(_pktsToSend, pReqMsg->requestedPkts, sizeof(_pktsToSend));
              call BitVecUtils.countOnes(&_numPktsToSend, _pktsToSend, PKTS_PER_PAGE);
              _state = S_TX_SENDING;
              setupDataMsg();
          } else if (_state == S_TX_SENDING && _pageToSend == pReqMsg->page) {
              // Combine the packets to send.
              int i;
              for (i = 0; i < PKTS_BITVEC_SIZE; i++) {
                  _pktsToSend[i] |= pReqMsg->requestedPkts[i];
              }
              call BitVecUtils.countOnes(&_numPktsToSend, _pktsToSend, PKTS_PER_PAGE);
          }
      
      } else if (pReqMsg->destAddr == call Core.getParent()) {
          // Overheard a request addressed to my parent, 
          // which means the parent is sending.
          _noDataRoundCount = 0;

          if (_state == S_RX_ACTIVE) {

              if ((call Core.isCoreNode() && pReqMsg->isCoreNode == 1)
                  || (!call Core.isCoreNode() && pReqMsg->isCoreNode == 0)) {
                  if (pReqMsg->page <= call DataManagement.getNextIncompletePage()) {
                      /* Suppress own request and wait for a time period equal to 
                         the transmission time of the requested packets. */
                      uint16_t numPktsRequested;
                      call BitVecUtils.countOnes(&numPktsRequested, 
                          pReqMsg->requestedPkts, PKTS_PER_PAGE);
                      call RxTimer.stop();
                      call RxTimer.start(TIMER_ONE_SHOT,
                          numPktsRequested * PACKET_TRANSMISSION_TIME
                          + (call Random.rand() % (MAX_REQ_DELAY >> 1)));
                  }

              } else if (!call Core.isCoreNode() && pReqMsg->isCoreNode == 1) {
                  // Go back to phase 1.
                  _localPhase2Flag = 0;
                  _state = S_RX_PASSIVE;
                  call RxTimer.stop();
                  __printEvent("Returning to Phase 1"); 
              }
          } // if (_state)
      } // if (pReqMsg->destAddr)

      return pMsg;
  }

  static void checkAndStartApp(uint8_t parentPhase2Flag) {
      uint16_t slotTimeLeft = call Schedule.getSlotTimeLeft();

      if (parentPhase2Flag == 1 && _localPhase2Flag == 0) {
          dbg(DBG_USR1, "Received ADV from parent. Parent has entered phase 2.\n");
          if (!call Core.isCoreNode()) {
              // Noncore nodes enter phase 2 once their parent enters phase 2.
              _localPhase2Flag = 1;
              _state = S_RX_ACTIVE;
              __printEvent("Entering Phase 2");
          }
      }

      if (_state == S_READY) {

          if (slotTimeLeft > (SCHED_SLOT_LENGTH >> 2)) { // not at the end

              dbg(DBG_USR1, "Received first ADV/DATA from parent at %u ms\n",
                  call SystemTime.getCurrentTimeMillis());

              if (call Core.isCoreNode() || _localPhase2Flag == 1) {
                  _state = S_RX_ACTIVE;
              } else {
                  _state = S_RX_PASSIVE;
              }
              /* Start RX-TX rounds. */
              _slotCount = SLOT_C;
          }
      }
  }
 
  event TOS_MsgPtr ReceiveDataMsg.receive(TOS_MsgPtr pMsg) {
      DataMsg * pDataMsg = (DataMsg *)(pMsg->data);

      /* Nodes should not receive anything in sleep state.
         But TOSSIM does not turn off radio even if CommControl.stop() is called. */
      if (!call ChannelState.isRadioOn()) return pMsg;

      if (_state == S_DISABLED) return pMsg;

      if (pDataMsg->sourceAddr == call Core.getParent()) {
          checkAndStartApp(pDataMsg->phase2Flag);
          _parentCompletePages = pDataMsg->completePages;
          _reqCount = 0;  
          _noDataRoundCount = 0;

          if (pDataMsg->phase2Flag == 0 &&
              !call Core.isCoreNode() && _state == S_RX_ACTIVE) {
              // Go back to phase1.
              _localPhase2Flag = 0;
              _state = S_RX_PASSIVE;
              call RxTimer.stop();
              __printEvent("Returning to Phase 1"); 
          }
      }

      if (call DataManagement.writePkt(pDataMsg->page, pDataMsg->packet, pDataMsg->data)
          == SUCCESS) {
          call Leds.yellowToggle();
          dbg(DBG_USR1, "Received DATA: Page %u, Packet %u, %u more, at %u ms\n",
              pDataMsg->page, 
              pDataMsg->packet, 
              pDataMsg->morePackets,
              call SystemTime.getCurrentTimeMillis());
      }

      if (_state == S_RX_ACTIVE || _state == S_RX_PASSIVE) {
          if (_parentCompletePages <= call DataManagement.getNumPagesComplete()) {
              // Parents can provide no more pages.
              // This also includes the case that all pages are complete.
              call RxTimer.stop();
              call ChannelState.turnOffRadio();
              _state = S_SLEEP;
          } else {
              if (_state == S_RX_ACTIVE) {
                  if (pDataMsg->page <= call DataManagement.getNextIncompletePage()) {
                      // Parent is sending a lower numbered page than the one I need.
                      call RxTimer.stop(); 
                      call RxTimer.start(TIMER_ONE_SHOT, 
                          pDataMsg->morePackets * PACKET_TRANSMISSION_TIME
                          + (call Random.rand() % (MAX_REQ_DELAY >> 1)));
                  } 
              } 
          }
      }

      return pMsg;
  }

  event TOS_MsgPtr ReceiveAdvMsg.receive(TOS_MsgPtr pMsg) {
      AdvMsg * pAdvMsg = (AdvMsg *)(pMsg->data);

      /* Nodes should not receive anything in sleep state.
         But TOSSIM does not turn off radio even if CommControl.stop() is called. */
      if (!call ChannelState.isRadioOn()) return pMsg;

      if (_state == S_DISABLED) return pMsg;

      if (pAdvMsg->sourceAddr == call Core.getParent()) {
          checkAndStartApp(pAdvMsg->phase2Flag);
          _parentCompletePages = pAdvMsg->completePages;
          _noDataRoundCount = 0;

          if (pAdvMsg->phase2Flag == 0 &&
              !call Core.isCoreNode() && _state == S_RX_ACTIVE) {
              // Go back to phase1.
              _localPhase2Flag = 0;
              _state = S_RX_PASSIVE;
              call RxTimer.stop();
              __printEvent("Returning to Phase 1"); 
          }

          if (_parentCompletePages <= call DataManagement.getNumPagesComplete()) {
              // Parent cannot provide more data.
              call ChannelState.turnOffRadio();
              _state = S_SLEEP;
          } else {
              if (_state == S_RX_ACTIVE) {
                  call RxTimer.start(TIMER_ONE_SHOT, 
                      call Random.rand() % (MAX_REQ_DELAY >> 1));
              } 
          }
      }

      return pMsg;
  }

  event result_t SendReqMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
      return SUCCESS;
  }

  event result_t SendDataMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
      DataMsg * pDataMsg = (DataMsg *)(_msgBufData->data);
    
      call Leds.yellowToggle();

      BITVEC_CLEAR(_pktsToSend, pDataMsg->packet);
      _numPktsToSend--;
    
      /* Prepare to send next packet. */
      /* In TOSSIM, set up and send the next packet right away;
         using TxTimer to insert a random (small?) delay between packets
         would cause unexpected jitters in other timers. */
#ifdef PLATFORM_PC
      setupDataMsg();
#else
      call TxTimer.start(TIMER_ONE_SHOT, call Random.rand() % RANDOM_DELAY + 1);
#endif
    
      return SUCCESS;
  }

  event result_t SendAdvMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
      _state = S_TX_IDLE;
      call TxTimer.start(TIMER_ONE_SHOT, MAX_REQ_DELAY << 1);
      return SUCCESS;
  }


  // Events that are not related.

  event void Core.setupDone(result_t result) {}

}
