/**
 * Copyright (c) 2006 - George Mason University
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

#ifdef HW_DEBUG
includes DebugLog;
#endif

module ControlPlaneM {
    provides {
        interface StdControl;
    }
    uses {
        interface BitVecUtils;
        interface DataPlane;
        interface DataManagement;
        interface ChannelSelect;
        interface ChannelState;
        interface Random;
        interface ReceiveMsg as ReceiveAdvMsg;
        interface SendMsg as SendAdvMsg;
        interface ReceiveMsg as ReceiveReqMsg;
        interface SendMsg as SendReqMsg;
        interface ReceiveMsg as ReceiveChnMsg;
        interface SendMsg as SendChnMsg;
        interface SystemTime;
        interface Timer as AdvTimer;
        interface Timer as ReqCollectTimer;
        interface Timer as ReqTimer;
        interface Timer as ChnWaitTimer;
        interface Timer as RebootTimer;
#ifndef PLATFORM_PC
        interface NetProg;
#endif
        interface Leds;
#ifdef HW_DEBUG
        interface DebugLog;
#endif
    }
}

implementation {

    enum {
        S_DISABLED,
        S_IDLE,
        S_ADV,
        S_REQ,
        S_DATA_TX,
        S_DATA_RX
    };

    // Common variables.
    uint8_t  _state;
    uint8_t  _newDataAdvsRequired;
    uint8_t  _overheardAdvs;
    uint8_t  _advPeriodLog2;
    TOS_Msg  _senderMsgBuf;
    TOS_Msg  _receiverMsgBuf;
    uint8_t  _dataChannel;

    // Variables for senders.
    uint8_t _pageToSend;
    uint8_t  _pktsToSend[PAGE_BITVEC_SIZE];
    uint8_t  _chnMsgCount;
   
    // Variables for receivers.
    uint16_t _srcAddr;
    uint16_t _reqDelay;
    uint8_t  _pktsToReceive[PAGE_BITVEC_SIZE];


    void startAdvTimer(uint8_t periodLog2) {
        uint32_t delay;
        call AdvTimer.stop();
        delay = (uint32_t)0x1 << periodLog2;
        delay += call Random.rand() & (delay - 1);
        call AdvTimer.start(TIMER_ONE_SHOT, delay);

        dbg(DBG_USR3, "AdvTimer started at %ld ms, for a period of %d ms\n",
            call SystemTime.getCurrentTimeMillis(), delay);
    }

    void fillAdvMsg(AdvMsg * pAdvMsg) {
        pAdvMsg->srcAddr = TOS_LOCAL_ADDRESS;
        pAdvMsg->dataChannel = _dataChannel;
        pAdvMsg->objId = call DataManagement.getObjId();
        pAdvMsg->crcData = call DataManagement.getCrcData();
        pAdvMsg->numPages = call DataManagement.getNumPages();
        pAdvMsg->numPktsLastPage = call DataManagement.getNumPktsLastPage();
        pAdvMsg->numPagesComplete = call DataManagement.getNextPageId();
    }

    task void sendAdvToUARTTask() {
        AdvMsg * pAdvMsg = (AdvMsg *)(_senderMsgBuf.data);
        fillAdvMsg(pAdvMsg);
        call SendAdvMsg.send(TOS_UART_ADDR, sizeof(AdvMsg), &_senderMsgBuf);
    }

    void overheardOlderData() {
        /* Reduce adv rate to suppress the old data transfer. */
        _advPeriodLog2 = (MIN_ADV_PERIOD_LOG2 - 1);
        _newDataAdvsRequired = NUM_NEWDATA_ADVS_REQUIRED;
    }

    command result_t StdControl.init() {
        _state = S_DISABLED;
        return SUCCESS;
    }

    command result_t StdControl.start() {
        _overheardAdvs = 0;
        _newDataAdvsRequired = 0;
        _advPeriodLog2 = MIN_ADV_PERIOD_LOG2 - 1;
        call ChannelState.setChannel(0);
        call DataManagement.init();
        return SUCCESS;
    }

    event void DataManagement.initDone(result_t success) {
        if (success == SUCCESS) {
            call Leds.redOn();

            _state = S_IDLE;

            call DataManagement.setPageBitVec(_pktsToReceive);
            startAdvTimer(_advPeriodLog2);
        }
    }
 
    command result_t StdControl.stop() {
        _state = S_DISABLED;
        return SUCCESS;
    }

    event result_t AdvTimer.fired() {
        bool advSent = FALSE;
        bool channelBusy = FALSE;

        dbg(DBG_USR3, "AdvTimer fired at %ld ms\n", 
            call SystemTime.getCurrentTimeMillis());

        if (_newDataAdvsRequired > 0) _newDataAdvsRequired--;
        if (_newDataAdvsRequired == 0) {
            _advPeriodLog2++;
            if (_advPeriodLog2 > (MAX_ADV_PERIOD_LOG2 - 1))
                _advPeriodLog2 = MAX_ADV_PERIOD_LOG2 - 1;
        }

        if (_overheardAdvs < MAX_OVERHEARD_ADVS) {
            AdvMsg * pAdvMsg = (AdvMsg *)(_senderMsgBuf.data);
            _dataChannel = call ChannelSelect.getFreeChannel();
#if !defined(MC_UNIQUE)
            if (_dataChannel != MC_CHANNELS) {  // got a valid channel
#endif
                fillAdvMsg(pAdvMsg);
                if (call SendAdvMsg.send(TOS_BCAST_ADDR, sizeof(AdvMsg), &_senderMsgBuf)
                    == SUCCESS) {
                    advSent = TRUE;
                    _state = S_ADV;
                    dbg(DBG_USR1, "Sending ADV (objId=%d, numPages=%d, numPagesComplete=%d, dataChannel=%d) at %ld ms\n", 
                        pAdvMsg->objId,
                        pAdvMsg->numPages,
                        pAdvMsg->numPagesComplete,
                        pAdvMsg->dataChannel, 
                        call SystemTime.getCurrentTimeMillis());
                }
#if !defined(MC_UNIQUE)
            } else {
                channelBusy = TRUE;
            }
#endif
        }

        _overheardAdvs = 0;

        if (!advSent) {
            if (channelBusy) startAdvTimer(MIN_ADV_PERIOD_LOG2 - 1);
            else startAdvTimer(_advPeriodLog2);
        }

        return SUCCESS;
    }

    event result_t SendAdvMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
#ifdef HW_DEBUG
        AdvMsg * pAdvMsg = (AdvMsg *)(pMsg->data);
        call DebugLog.writeLog(DIR_TX,
                               AM_ADVMSG,
                               TOS_BCAST_ADDR,
                               call ChannelState.getChannel(),
                               pAdvMsg->numPagesComplete,
                               0);
#endif

        // Initiate _pageToSend to an invalid value.
        // This will be updated when a request is received
        // since the lower pages have higher priority.
        _pageToSend = call DataManagement.getNumPages();
        memset(_pktsToSend, 0, PAGE_BITVEC_SIZE);
        _chnMsgCount = NUM_CHN_MSGS;
        call ReqCollectTimer.start(TIMER_ONE_SHOT, MAX_REQ_DELAY);
        return SUCCESS;
    }

    event TOS_MsgPtr ReceiveAdvMsg.receive(TOS_MsgPtr pMsg) {
        AdvMsg * pAdvMsg = (AdvMsg *)(pMsg->data);

        if (_state == S_DISABLED) return pMsg;

#ifdef HW_DEBUG
        call DebugLog.writeLog(DIR_RX,
                               AM_ADVMSG,
                               pAdvMsg->srcAddr,
                               call ChannelState.getChannel(),
                               pAdvMsg->numPagesComplete,
                               0);
#endif

        if (pAdvMsg->srcAddr == TOS_UART_ADDR
            && (pAdvMsg->objId < call DataManagement.getObjId() 
                || (pAdvMsg->objId == call DataManagement.getObjId()
                    && call DataManagement.getNextPageId() == call DataManagement.getNumPages()))) {
            post sendAdvToUARTTask();
            return pMsg;
        }

#if 1   // Comment out: Advertisers are not necessarily senders. 
        // Assume the sender will send the whole page.
        // The time will be updated if a corresponding request 
        // or channel message is received.
        call ChannelSelect.setChannelTaken(pAdvMsg->dataChannel, 
            MAX_REQ_DELAY + (PKTS_PER_PAGE + NUM_CHN_MSGS) * (PKT_TX_TIME + INTER_PKT_DELAY));
#endif

        _overheardAdvs++;

        if (pAdvMsg->objId < call DataManagement.getObjId()) {
            overheardOlderData();
            return pMsg;
        }

        if (pAdvMsg->objId > call DataManagement.getObjId()) {
            /* New object. Stop everything. */
            if (_state == S_IDLE) call AdvTimer.stop();
            else if (_state == S_ADV) call ReqCollectTimer.stop();
            else if (_state == S_REQ) { 
                call ChnWaitTimer.stop();
                call ReqTimer.stop();
            }

            call DataManagement.updateObj(pAdvMsg->objId, 
                pAdvMsg->numPages, pAdvMsg->numPktsLastPage,
                pAdvMsg->crcData);
            call DataManagement.setPageBitVec(_pktsToReceive);
            _advPeriodLog2 = (MIN_ADV_PERIOD_LOG2 - 1);
            _state = S_IDLE;
        }

        // Following lines consider the case where object is same.

        if (pAdvMsg->objId == 0)  // Invalid object.
            return pMsg;

        if (pAdvMsg->numPagesComplete < call DataManagement.getNextPageId()) {
            overheardOlderData();

        } else if (pAdvMsg->numPagesComplete > call DataManagement.getNextPageId()) {
            if (_state == S_IDLE ||
                (_state == S_ADV && _newDataAdvsRequired == 0)) {

                dbg(DBG_USR1, "Received ADV from %d (objId=%d) at %ld ms\n", 
                    pAdvMsg->srcAddr, 
                    pAdvMsg->objId,
                    call SystemTime.getCurrentTimeMillis());

                if (_state == S_IDLE) call AdvTimer.stop();
                else if (_state == S_ADV) call ReqCollectTimer.stop();

                _srcAddr = pAdvMsg->srcAddr;
                _reqDelay = call Random.rand() % (MAX_REQ_DELAY - PKT_TX_TIME) + 1;
                _dataChannel = pAdvMsg->dataChannel;
                call ReqTimer.start(TIMER_ONE_SHOT, _reqDelay);
                call ChnWaitTimer.start(TIMER_ONE_SHOT, MAX_REQ_DELAY + PKT_TX_TIME);

                _state = S_REQ;
            }            
        }
        
        return pMsg;       
    }

    event result_t ReqTimer.fired() {
        // Not suppressed by other requesters.

        ReqMsg * pReqMsg = (ReqMsg *)(_receiverMsgBuf.data);
        uint16_t msgDestAddr = TOS_BCAST_ADDR;
        if (_srcAddr == TOS_UART_ADDR)
            msgDestAddr = TOS_UART_ADDR;

        dbg(DBG_USR3, "ReqTimer fired at %ld ms\n", 
            call SystemTime.getCurrentTimeMillis());

        pReqMsg->srcAddr = TOS_LOCAL_ADDRESS;
        pReqMsg->destAddr = _srcAddr;
        pReqMsg->delay = _reqDelay;
        pReqMsg->dataChannel = _dataChannel;
        pReqMsg->objId = call DataManagement.getObjId();
        pReqMsg->pageId = call DataManagement.getNextPageId();
        memcpy(pReqMsg->requestedPkts, _pktsToReceive, PAGE_BITVEC_SIZE);
        if (call SendReqMsg.send(msgDestAddr, sizeof(ReqMsg), &_receiverMsgBuf)
            == SUCCESS) {
#ifdef PLATFORM_PC
            char buf[PKTS_PER_PAGE+1];
            call BitVecUtils.printBitVec(buf, pReqMsg->requestedPkts, PKTS_PER_PAGE);
            dbg(DBG_USR1, "Sending REQ for Page %d to %d (pktsToReceive: %s)\n",
                pReqMsg->pageId, pReqMsg->destAddr, buf);
#endif
        }

        return SUCCESS;
    }

    event result_t ChnWaitTimer.fired() {
        // Timeout in waiting for CHN message from _srcAddr.        
        dbg(DBG_USR3, "ChnWaitTimer fired at %ld ms\n",
            call SystemTime.getCurrentTimeMillis());

        _state = S_IDLE;
        startAdvTimer(_advPeriodLog2);

        return SUCCESS;
    }

    event result_t SendReqMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
#ifdef HW_DEBUG
        ReqMsg * pReqMsg = (ReqMsg *)(pMsg->data); 
        call DebugLog.writeLog(DIR_TX,
                               AM_REQMSG,
                               pReqMsg->destAddr,
                               call ChannelState.getChannel(),
                               pReqMsg->pageId,
                               0);
#endif
        return SUCCESS;
    }

   
    task void sendChnMsg();
 

    event TOS_MsgPtr ReceiveReqMsg.receive(TOS_MsgPtr pMsg) {
        ReqMsg * pReqMsg = (ReqMsg *)(pMsg->data);

        if (_state == S_DISABLED) return pMsg;

#ifdef HW_DEBUG
        call DebugLog.writeLog(DIR_RX,
                               AM_REQMSG,
                               pReqMsg->srcAddr,
                               call ChannelState.getChannel(),
                               pReqMsg->pageId,
                               0);
#endif

        // Assume the sender will send the whole page.
        call ChannelSelect.setChannelTaken(pReqMsg->dataChannel, 
            MAX_REQ_DELAY - pReqMsg->delay + (PKTS_PER_PAGE + NUM_CHN_MSGS) * (PKT_TX_TIME + INTER_PKT_DELAY));

        if (pReqMsg->objId < call DataManagement.getObjId() 
            || (pReqMsg->objId == call DataManagement.getObjId()
                && pReqMsg->pageId < call DataManagement.getNextPageId())) {
            overheardOlderData();
        }

        if (_state == S_REQ && pReqMsg->destAddr == _srcAddr) {
            // Overheard request to the same src.
            if (call BitVecUtils.contains(pReqMsg->requestedPkts, _pktsToReceive,
                PAGE_BITVEC_SIZE)) {
                // Suppress my request if not sent yet.
                call ReqTimer.stop();
            }
        }

        if (_state == S_ADV && pReqMsg->destAddr == TOS_LOCAL_ADDRESS) {
            // Request destined to this node.
            dbg(DBG_USR1, "Received REQ from %d at %ld ms\n",
                pReqMsg->srcAddr, call SystemTime.getCurrentTimeMillis());

            if (pReqMsg->pageId < _pageToSend) {
                _pageToSend = pReqMsg->pageId;
                memcpy(_pktsToSend, pReqMsg->requestedPkts, PAGE_BITVEC_SIZE);
            } else if (pReqMsg->pageId == _pageToSend) {
                int i;
                // take union of packet bit vectors
                for ( i = 0; i < PAGE_BITVEC_SIZE; i++)
                    _pktsToSend[i] |= pReqMsg->requestedPkts[i];
            }
#ifdef FAST_RESPONSE
            _state = S_DATA_TX;
            call ReqCollectTimer.stop();
            post sendChnMsg();
#endif
        }

        return pMsg;
    }

    
    task void sendChnMsg() {
        ChnMsg * pChnMsg = (ChnMsg *)(_senderMsgBuf.data);

        pChnMsg->srcAddr = TOS_LOCAL_ADDRESS;
        pChnMsg->dataChannel = _dataChannel;
        pChnMsg->objId = call DataManagement.getObjId();
        pChnMsg->pageId = _pageToSend;
        memcpy(pChnMsg->pktsToSend, _pktsToSend, PAGE_BITVEC_SIZE);
        pChnMsg->moreChnMsg = _chnMsgCount - 1;
        if (call SendChnMsg.send(TOS_BCAST_ADDR, sizeof(ChnMsg), &_senderMsgBuf)
            == SUCCESS) {
#ifdef PLATFORM_PC
            char buf[PKTS_PER_PAGE+1];
            call BitVecUtils.printBitVec(buf, pChnMsg->pktsToSend, PKTS_PER_PAGE);
            dbg(DBG_USR1, "Sending CHN: Page %d, Channel %d (pktsToSend: %s)\n",
                pChnMsg->pageId, pChnMsg->dataChannel, buf);
#endif
        } else {
            // Schedules for retransmission.
            call ReqCollectTimer.start(TIMER_ONE_SHOT,
                call Random.rand() % MAX_RETX_DELAY + 1);
        }
    }

    event result_t ReqCollectTimer.fired() {
        
        dbg(DBG_USR3, "ReqCollectTimer fired at %ld ms\n",
            call SystemTime.getCurrentTimeMillis());

        if (_pageToSend < call DataManagement.getNumPages()) {
            // A valid _pageToSend means one or more requests are received.
            post sendChnMsg();
        } else {
            _state = S_IDLE;
            _overheardAdvs = 0;
            startAdvTimer(_advPeriodLog2); 
        }
        return SUCCESS;
    }

    event result_t SendChnMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
#ifdef HW_DEBUG
        ChnMsg * pChnMsg = (ChnMsg *)(pMsg->data);
        call DebugLog.writeLog(DIR_TX,
                               AM_CHNMSG,
                               TOS_BCAST_ADDR,
                               call ChannelState.getChannel(),
                               pChnMsg->pageId,
                               0);
#endif
        _chnMsgCount--;
        if (_chnMsgCount > 0) {
            post sendChnMsg();
        } else {
            _state = S_DATA_TX;
            call ChannelState.setChannel(_dataChannel);
            call DataPlane.startTx(call DataManagement.getObjId(), _pageToSend, _pktsToSend);
            call Leds.yellowOn();
        }
        return SUCCESS;
    }

    event TOS_MsgPtr ReceiveChnMsg.receive(TOS_MsgPtr pMsg) {
        ChnMsg * pChnMsg = (ChnMsg *)(pMsg->data);
        uint16_t numPktsToSend;

        if (_state == S_DISABLED) return pMsg;

#ifdef HW_DEBUG
        call DebugLog.writeLog(DIR_RX,
                               AM_CHNMSG,
                               pChnMsg->srcAddr,
                               call ChannelState.getChannel(),
                               pChnMsg->pageId,
                               0);
#endif
     
        call BitVecUtils.countOnes(&numPktsToSend, pChnMsg->pktsToSend, PKTS_PER_PAGE);
        call ChannelSelect.setChannelTaken(pChnMsg->dataChannel, 
            (numPktsToSend + pChnMsg->moreChnMsg) * (PKT_TX_TIME + INTER_PKT_DELAY));
        
        if (pChnMsg->objId == call DataManagement.getObjId() 
            && pChnMsg->pageId == call DataManagement.getNextPageId()
            && call BitVecUtils.overlaps(pChnMsg->pktsToSend, _pktsToReceive,
                PAGE_BITVEC_SIZE) == TRUE) {
            if (_state == S_IDLE 
                || (_state == S_ADV && _newDataAdvsRequired == 0)
                || (_state == S_REQ && _srcAddr == pChnMsg->srcAddr)) {

                if (_state == S_IDLE) call AdvTimer.stop();
                if (_state == S_ADV) call ReqCollectTimer.stop();
                if (_state == S_REQ) {
                    call ReqTimer.stop();
                    call ChnWaitTimer.stop();
                }

                _state = S_DATA_RX;
                call ChannelState.setChannel(pChnMsg->dataChannel);
                call DataPlane.startRx(pChnMsg->srcAddr, _pktsToReceive,
                    (numPktsToSend + pChnMsg->moreChnMsg) * (PKT_TX_TIME + INTER_PKT_DELAY)
                     + RX_GRACE_PERIOD);

                call Leds.greenOn();
            }
        }

        return pMsg;
    } 

    event result_t DataPlane.txDone() {
        call Leds.yellowOff();
        call ChannelState.setChannel(0);
        _state = S_IDLE;
        _overheardAdvs = 0;
        startAdvTimer(_advPeriodLog2);
        return SUCCESS;
    }

    event result_t DataPlane.rxDone(bool receivedNewPage) {
        uint8_t advPeriodLog2;

        call Leds.greenOff();

        if (receivedNewPage) {
            call DataManagement.flushPage();
            call DataManagement.setPageBitVec(_pktsToReceive);
            _newDataAdvsRequired = NUM_NEWDATA_ADVS_REQUIRED;
            _advPeriodLog2 = MIN_ADV_PERIOD_LOG2 - 1;
            advPeriodLog2 = MIN_ADV_PERIOD_LOG2 - 2;
        } else {
            advPeriodLog2 = _advPeriodLog2;
            // Don't be over aggressive in advertising
            // since the sender will send adv soon.
            if (advPeriodLog2 < MIN_ADV_PERIOD_LOG2 + 1)
                advPeriodLog2 = MIN_ADV_PERIOD_LOG2 + 1;
        }
        call ChannelState.setChannel(0);
        _state = S_IDLE;
        _overheardAdvs = 0;
        startAdvTimer(advPeriodLog2);
        return SUCCESS;
    }

    event void DataManagement.newObjComplete() {
        if (_srcAddr == TOS_UART_ADDR) {
            // Inform the PC program to stop.
            post sendAdvToUARTTask();
        }

#if !(defined(NO_REBOOT) || defined(PLATFORM_PC))
        call RebootTimer.start(TIMER_ONE_SHOT, 1024);
#endif
    }

    event result_t RebootTimer.fired() {
#ifndef PLATFORM_PC
        call NetProg.reboot();
#endif
        return SUCCESS;
    }

    // Events not interested.
    event void DataManagement.readPktDone(result_t success) {}

}
