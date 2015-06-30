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

module DataPlaneM {
    provides {
        interface DataPlane;
        interface StdControl;
    }

    uses {
        interface BitVecUtils;
        interface Random;
        interface DataManagement;
        interface ReceiveMsg as ReceiveDataMsg;
        interface SendMsg as SendDataMsg;
        interface Timer as TxTimer;
        interface Timer as RetxTimer;
        interface Timer as RxTimer;
#ifdef HW_DEBUG
        interface DebugLog;
        interface ChannelState;
#endif
    }
}

implementation {

#include "BitVecUtils.h"
    
    enum {
        S_IDLE,
        S_TX,
        S_RX
    };

    // Common variables
    uint8_t   _state;

    // Variables in TX state
    uint8_t * _pktsToSend = NULL;
    TOS_Msg   _msgBuf;

    // Variables in RX state
    uint8_t * _pktsToReceive = NULL;
    uint16_t  _srcAddr;

    static void setupDataMsg() {
        DataMsg * pDataMsg = (DataMsg *)(_msgBuf.data);
        call DataManagement.readPkt(pDataMsg->pageId, pDataMsg->pktId,
            pDataMsg->data);
    }

    task void sendDataMsg() {
        if (call SendDataMsg.send(TOS_BCAST_ADDR, sizeof(DataMsg), &_msgBuf)
            == FAIL) {
            call RetxTimer.start(TIMER_ONE_SHOT, 
                call Random.rand() % MAX_RETX_DELAY + 1);
        } else {
            dbg(DBG_USR1, "Sending DATA: Page %d, Packet %d\n",
                ((DataMsg *)(_msgBuf.data))->pageId,
                ((DataMsg *)(_msgBuf.data))->pktId);
        }
    }

    event void DataManagement.readPktDone(result_t success) {
        if (success == SUCCESS) {
            post sendDataMsg();
        } else {
            call TxTimer.start(TIMER_ONE_SHOT, 
                call Random.rand() % MAX_RETX_DELAY + 1);
        }
    }

    command result_t StdControl.init() {
        _state = S_IDLE;
        return SUCCESS;
    }
    command result_t StdControl.start() {
        return SUCCESS;
    }
    command result_t StdControl.stop() {
        return SUCCESS;
    }

    command result_t DataPlane.startTx(uint16_t objId, uint8_t pageId, uint8_t * pktsToSend) {
        DataMsg * pDataMsg = (DataMsg *)(_msgBuf.data);
        uint8_t  nextPktId;

        _pktsToSend = pktsToSend;
        _state = S_TX;

        pDataMsg->srcAddr = TOS_LOCAL_ADDRESS;
        pDataMsg->objId = objId;
        pDataMsg->pageId = pageId;
        for (nextPktId = 0; nextPktId < PKTS_PER_PAGE; nextPktId++) {
            if (BITVEC_GET(_pktsToSend, nextPktId)) break;
        }
        pDataMsg->pktId = nextPktId;
        setupDataMsg();
        return SUCCESS;
    }

    command result_t DataPlane.startRx(uint16_t srcAddr, uint8_t * pktsToReceive,
                                       uint16_t rxPeriod) {
        _srcAddr = srcAddr;
        _pktsToReceive = pktsToReceive;
        _state = S_RX;
        call RxTimer.start(TIMER_ONE_SHOT, rxPeriod);
        return SUCCESS;
    }

    event result_t SendDataMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        DataMsg * pDataMsg = (DataMsg *)(_msgBuf.data);
        uint8_t  nextPktId;

#ifdef HW_DEBUG
        call DebugLog.writeLog(DIR_TX,
                               AM_DATAMSG,
                               TOS_BCAST_ADDR,
                               call ChannelState.getChannel(),
                               pDataMsg->pageId,
                               pDataMsg->pktId);
#endif

        BITVEC_CLEAR(_pktsToSend, pDataMsg->pktId);

        for (nextPktId = pDataMsg->pktId + 1; nextPktId < PKTS_PER_PAGE; nextPktId++) {
            if (BITVEC_GET(_pktsToSend, nextPktId)) break;
        }
        if (nextPktId == PKTS_PER_PAGE) {
            // All data packets are sent out.
            _state = S_IDLE;
            signal DataPlane.txDone();
        } else {
            pDataMsg->pktId = nextPktId;
            // Add some delay between packet transmissions.
            call TxTimer.start(TIMER_ONE_SHOT, INTER_PKT_DELAY);
        }
        return SUCCESS;
    }

    event TOS_MsgPtr ReceiveDataMsg.receive(TOS_MsgPtr pMsg) {
        DataMsg * pDataMsg = (DataMsg *)(pMsg->data);
        uint16_t nextPktId;


#if (MC_CHANNELS>1)
#define LOYAL_RECEIVER
#endif

#ifdef LOYAL_RECEIVER
        // Receive from THE source only.
        if (_state == S_RX && pDataMsg->srcAddr == _srcAddr) {
#else
        if (_state == S_RX ||  (_state == S_IDLE && _pktsToReceive != NULL)) {
#endif
            if (pDataMsg->objId == call DataManagement.getObjId() &&
                pDataMsg->pageId == call DataManagement.getNextPageId() && 
                BITVEC_GET(_pktsToReceive, pDataMsg->pktId)) {
                // Got a new packet.
                dbg(DBG_USR1, "Received DATA: Page %d Packet %d from Node %d\n",
                    pDataMsg->pageId, pDataMsg->pktId, pDataMsg->srcAddr);

                // COPY THE DATA TO FLASH IN REAL CASE. 
                if (call DataManagement.writePkt(pDataMsg->pageId,
                    pDataMsg->pktId, pDataMsg->data) == SUCCESS) {
                    BITVEC_CLEAR(_pktsToReceive, pDataMsg->pktId);
                }

#ifdef HW_DEBUG
                call DebugLog.writeLog(DIR_RX,
                                       AM_DATAMSG,
                                       pDataMsg->srcAddr,
                                       call ChannelState.getChannel(),
                                       pDataMsg->pageId,
                                       pDataMsg->pktId);
#endif

                if (call BitVecUtils.indexOf(&nextPktId, 0, _pktsToReceive, PKTS_PER_PAGE)
                    == FAIL) {
                    // Received all packets of this page.
                    call RxTimer.stop();
                    _state = S_IDLE;
                    signal DataPlane.rxDone(TRUE);
                }
            }
        }
        return pMsg;
    }

    event result_t TxTimer.fired() {
        setupDataMsg();
        return SUCCESS;
    }

    event result_t RetxTimer.fired() {
        // No need to read data since it is a retransmission.
        post sendDataMsg();
        return SUCCESS;
    }

    event result_t RxTimer.fired() {
        _state = S_IDLE;
        signal DataPlane.rxDone(FALSE);
        return SUCCESS;
    }

    // Events not interested.
    event void DataManagement.initDone(result_t success) {}
    event void DataManagement.newObjComplete() {}

}
