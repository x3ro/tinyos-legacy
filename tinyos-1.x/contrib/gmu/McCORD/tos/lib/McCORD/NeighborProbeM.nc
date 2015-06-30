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

includes global;
includes McCORD;

module NeighborProbeM {
    provides interface NeighborProbe;
    uses {
        interface Timer as IntervalTimer;
        interface Timer as SendTimer;
        interface SendMsg as SendHelloMsg;
        interface ReceiveMsg as ReceiveHelloMsg;
        interface SendMsg as SendNeighborsMsg;
        interface ReceiveMsg as ReceiveNeighborsMsg;
        interface Random;
        interface NodeList;
        interface ChannelState;
        interface MsgBuf;
        interface Leds;
#ifdef HW_DEBUG_N
        interface DataManagement;
#endif
    }
}

implementation {

    enum {
        S_DISABLED,
        S_PROBING,
    };

    typedef struct {
        uint16_t sourceAddr;
        uint16_t pktTotal;
        uint16_t pktCount;
        uint16_t lqiSum; 
    } InLinkStatus;

    InLinkStatus _inLinkStatus[CHANNELS_TO_PROBE][MAX_IN_LINKS];
    uint8_t  _channelsProbed;
    uint16_t _helloMsgSeqno;
    uint8_t  _neighborsMsgSeqno;
    uint16_t _neighborList[CHANNELS_TO_PROBE][MAX_NEIGHBORS];
    uint8_t  _state = S_DISABLED;

#ifdef HW_DEBUG_N
    DebugLog _debugLog;
#endif

    static void updateLinkStatus(uint8_t channelIndex,
        uint16_t sourceAddr, uint16_t pktTotal,
        uint16_t seqno, uint8_t lqi) {

        int i;
        int emptySlot = MAX_IN_LINKS;

        for (i = 0; i < MAX_IN_LINKS; i++) {
            if (_inLinkStatus[channelIndex][i].sourceAddr == sourceAddr) break;
            if (emptySlot == MAX_IN_LINKS && 
                _inLinkStatus[channelIndex][i].sourceAddr == INVALID_NODE_ADDR) {
                emptySlot = i;
            }
        }
        if (i < MAX_IN_LINKS) {  // found.
            _inLinkStatus[channelIndex][i].pktTotal = pktTotal;
            _inLinkStatus[channelIndex][i].pktCount++;
            _inLinkStatus[channelIndex][i].lqiSum += (lqi & 0xff);
        } else if (emptySlot != MAX_IN_LINKS) {
            _inLinkStatus[channelIndex][emptySlot].sourceAddr = sourceAddr;
            _inLinkStatus[channelIndex][emptySlot].pktTotal = pktTotal;
            _inLinkStatus[channelIndex][emptySlot].pktCount = 1;
            _inLinkStatus[channelIndex][emptySlot].lqiSum = (lqi & 0xff);
        }
    }

    static bool isGoodLink(InLinkStatus * pLink) {
#if 0
        if (pLink->pktCount >=  HELLO_MSGS_THRESHOLD &&
            (pLink->lqiSum / pLink->pktCount) >= LQI_THRESHOLD) {
#endif
        if (pLink->pktCount >=  HELLO_MSGS_THRESHOLD) {
            return TRUE;
        } else {
            return FALSE; 
        }
    }

    static void pickNeighbors(uint8_t channelIndex, uint16_t neighbors[]) {
        int i;
        int count;
        for (i = 0, count = 0; 
             i < MAX_IN_LINKS && count < MAX_NEIGHBORS; 
             i++) {
            if (_inLinkStatus[channelIndex][i].sourceAddr != INVALID_NODE_ADDR) {
                if (isGoodLink(&(_inLinkStatus[channelIndex][i])))
                    neighbors[count++] 
                        = _inLinkStatus[channelIndex][i].sourceAddr;
            }
        }
        for (; count < MAX_NEIGHBORS; count++) {
            neighbors[count++] = INVALID_NODE_ADDR;
        }
    }

    static void updateNeighbors(uint8_t channelIndex,
        uint16_t sourceAddr, uint16_t neighbors[]) {

        int i;
        if (call NodeList.searchList(neighbors, MAX_NEIGHBORS, TOS_LOCAL_ADDRESS)
            == TRUE) {
            for (i = 0; i < MAX_IN_LINKS; i++) {
                if (_inLinkStatus[channelIndex][i].sourceAddr == sourceAddr &&
                    isGoodLink(&(_inLinkStatus[channelIndex][i]))) {
                    break; 
                }
            } 
            if (i < MAX_IN_LINKS) 
                call NodeList.addToList(_neighborList[channelIndex], MAX_NEIGHBORS, sourceAddr);
        }
    }

    command result_t NeighborProbe.start() {

        int i, j;

        for (j = 0; j < CHANNELS_TO_PROBE; j++) {
            for (i = 0; i < MAX_NEIGHBORS; i++) {
                _neighborList[j][i] = INVALID_NODE_ADDR;
            }
            for (i = 0; i < MAX_IN_LINKS; i++) {
                _inLinkStatus[j][i].sourceAddr = INVALID_NODE_ADDR;
            }
        }

        _channelsProbed = 0;
        _helloMsgSeqno = 0;
        _neighborsMsgSeqno = 0;

        _state = S_PROBING;
        call ChannelState.turnOnRadio(__gChannelsToProbe[0]);
        call IntervalTimer.start(TIMER_ONE_SHOT, HELLO_INTERVAL);

        return SUCCESS;
    }

    command uint16_t * NeighborProbe.getNeighborList(uint8_t channelIndex) {
        return _neighborList[channelIndex];
    }

    task void sendHelloMsg() {
        TOS_MsgPtr msgBuf = call MsgBuf.getMsgBuf();
        HelloMsg * pHelloMsg;
        uint16_t   currHelloMsgSeqno = _helloMsgSeqno; 

        // Increment it anyway. 
        _helloMsgSeqno++;

        if (msgBuf == NULL) return; 

        pHelloMsg = (HelloMsg *)(msgBuf->data);

        pHelloMsg->sourceAddr = TOS_LOCAL_ADDRESS;
        pHelloMsg->pktTotal = HELLO_MSGS;
        pHelloMsg->seqno = currHelloMsgSeqno;

        if (call SendHelloMsg.send(TOS_BCAST_ADDR, sizeof(HelloMsg), 
            msgBuf) == SUCCESS) {
            dbg(DBG_USR1, "Sending HELLO\n");
        } else {
            call MsgBuf.putMsgBuf(msgBuf);
        }
    }

    task void sendNeighborsMsg() {
        TOS_MsgPtr msgBuf = call MsgBuf.getMsgBuf();
        NeighborsMsg * pNeighborsMsg;
        uint8_t channelIndex = _channelsProbed;

        // Increment it anyway.
        _neighborsMsgSeqno++;

        if (msgBuf == NULL) return;

        pNeighborsMsg = (NeighborsMsg *)(msgBuf->data);

        pNeighborsMsg->sourceAddr = TOS_LOCAL_ADDRESS;
        pickNeighbors(channelIndex, pNeighborsMsg->neighbors);
        pNeighborsMsg->channelIndex = channelIndex;        

        if (call SendNeighborsMsg.send(TOS_BCAST_ADDR, 
            sizeof(NeighborsMsg), msgBuf) == SUCCESS) {
            dbg(DBG_USR1, "Sending NEIGHBORS\n");
            call NodeList.printList(pNeighborsMsg->neighbors, 
                MAX_NEIGHBORS);
        } else {
            call MsgBuf.putMsgBuf(msgBuf);
        }
    }

    event result_t SendTimer.fired() {
        if (_helloMsgSeqno >= HELLO_MSGS) {
            post sendNeighborsMsg();
        } else {
            post sendHelloMsg();
        }
        return SUCCESS;
    }

    event result_t IntervalTimer.fired() {
        if (_state == S_DISABLED) return SUCCESS;

        if (_state == S_PROBING) {
            if (_neighborsMsgSeqno >= NEIGHBORS_MSGS) {
                _channelsProbed++;
                if (_channelsProbed >= CHANNELS_TO_PROBE) {
                    _state = S_DISABLED;
                    call ChannelState.turnOffRadio();
                    signal NeighborProbe.done();
                } else {
                    _helloMsgSeqno = 0;
                    _neighborsMsgSeqno = 0;
                    call ChannelState.turnOnRadio(__gChannelsToProbe[_channelsProbed]);
                }
            } 
        }


        if (_state == S_PROBING) {
            call SendTimer.start(TIMER_ONE_SHOT,
                call Random.rand() % HELLO_DELAY + 1);
            call IntervalTimer.start(TIMER_ONE_SHOT, HELLO_INTERVAL);
        }

        return SUCCESS;
    } 

    event TOS_MsgPtr ReceiveHelloMsg.receive(TOS_MsgPtr pMsg) {
        HelloMsg * pHelloMsg = (HelloMsg *)(pMsg->data);

        if (_state != S_PROBING) return pMsg;

        dbg(DBG_USR1, "Received HELLO from %d\n", pHelloMsg->sourceAddr);

#ifdef HW_DEBUG_N
        memset(&_debugLog, 0, sizeof(_debugLog));
        _debugLog.who = DEBUG_NEIGHBOR_PROBE;
        _debugLog.dir = DEBUG_RX;
        _debugLog.type = AM_HELLOMSG;
        _debugLog.addr = pHelloMsg->sourceAddr;
        memcpy(_debugLog.data, pHelloMsg,
            sizeof(_debugLog.data));
        call DataManagement.writeDebug((uint8_t *)&_debugLog);
#endif

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_TMOTE)
        updateLinkStatus(_channelsProbed,
            pHelloMsg->sourceAddr, pHelloMsg->pktTotal,
            pHelloMsg->seqno, pMsg->lqi);
#else
        updateLinkStatus(_channelsProbed,
            pHelloMsg->sourceAddr, pHelloMsg->pktTotal,
            pHelloMsg->seqno, LQI_THRESHOLD + 1);
#endif
        return pMsg;
    }    

    event TOS_MsgPtr ReceiveNeighborsMsg.receive(TOS_MsgPtr pMsg) {
        NeighborsMsg * pNeighborsMsg = (NeighborsMsg *)(pMsg->data);

        if (_state != S_PROBING) return pMsg;

#ifdef HW_DEBUG_N
        memset(&_debugLog, 0, sizeof(_debugLog));
        _debugLog.who = DEBUG_NEIGHBOR_PROBE;
        _debugLog.dir = DEBUG_RX;
        _debugLog.type = AM_NEIGHBORSMSG;
        _debugLog.addr = pNeighborsMsg->sourceAddr;
        memcpy(_debugLog.data, pNeighborsMsg,
            sizeof(_debugLog.data));
        call DataManagement.writeDebug((uint8_t *)&_debugLog);
#endif

        updateNeighbors(pNeighborsMsg->channelIndex,
            pNeighborsMsg->sourceAddr, pNeighborsMsg->neighbors);

        return pMsg;
    }

    event result_t SendHelloMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
#ifdef HW_DEBUG_N
        memset(&_debugLog, 0, sizeof(_debugLog));
        _debugLog.who = DEBUG_NEIGHBOR_PROBE;
        _debugLog.dir = DEBUG_TX;
        _debugLog.type = AM_HELLOMSG;
        _debugLog.addr = TOS_BCAST_ADDR;
        memcpy(_debugLog.data, (HelloMsg *)(pMsg->data), 
            sizeof(_debugLog.data));
        call DataManagement.writeDebug((uint8_t *)&_debugLog);
#endif
        call MsgBuf.putMsgBuf(pMsg);
        return SUCCESS;
    }

    event result_t SendNeighborsMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
#ifdef HW_DEBUG_N
        memset(&_debugLog, 0, sizeof(_debugLog));
        _debugLog.who = DEBUG_NEIGHBOR_PROBE;
        _debugLog.dir = DEBUG_TX;
        _debugLog.type = AM_NEIGHBORSMSG;
        _debugLog.addr = TOS_BCAST_ADDR;
        memcpy(_debugLog.data, (NeighborsMsg *)(pMsg->data), 
            sizeof(_debugLog.data));
        call DataManagement.writeDebug((uint8_t *)&_debugLog);
#endif
        call MsgBuf.putMsgBuf(pMsg);
        return SUCCESS;
    }

#ifdef HW_DEBUG_N
    event void DataManagement.initDone(result_t success) {}
    event void DataManagement.setObjMetadataDone() {}
    event void DataManagement.readPktDone(result_t success) {}
    event void DataManagement.newObjComplete() {}
#endif

}
