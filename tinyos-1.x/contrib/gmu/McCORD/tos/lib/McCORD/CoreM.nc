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

module CoreM {
    provides interface Core;
    uses {
        interface NeighborProbe;
        interface Timer; 
        interface Timer as TimeoutTimer;
        interface SystemTime;
        interface Schedule;
        interface SendMsg as SendCoreCompeteMsg;
        interface ReceiveMsg as ReceiveCoreCompeteMsg;
        interface SendMsg as SendCoreSubscribeMsg;
        interface ReceiveMsg as ReceiveCoreSubscribeMsg;
        interface SendMsg as SendCoreClaimMsg;
        interface ReceiveMsg as ReceiveCoreClaimMsg;
        interface Random;
        interface NodeList;
        interface ChannelState;
        interface MsgBuf;
        interface Leds;
    } 
}

implementation {

    enum {
        MIN_SEND_DELAY = 16,
        MAX_SEND_RANGE = (SCHED_SLOT_LENGTH - 256), 
    };

    enum {
        S_READY,
        S_CORE_COMPETE_RX,
        S_CORE_SUBSCRIBE_TX,
        S_CORE_CLAIM_RX,
        S_CORE_COMPETE_TX,
        S_CORE_SUBSCRIBE_RX,
        S_CORE_CLAIM_TX,
        S_CORE_SETUP_DONE
    };

    typedef struct {
        uint16_t  node;
        bool      covered;
    } NodeCoverage;

    NodeCoverage _neighbors[CHANNELS_TO_PROBE][MAX_NEIGHBORS];

    bool     _isCoreNode;
    uint8_t  _depth;
    uint16_t _parent;
    uint8_t  _state;
    uint8_t  _parentDataChannelIndex; // for RX
    uint8_t  _dataChannelIndex;       // for TX

    uint16_t  _parentCandidate;
    uint8_t   _parentCandidateCoverage;
    uint8_t   _parentCandidateDepth;
    uint8_t   _parentCandidateDataChannelIndex;
    bool      _subscribed;

    bool      _timeout;
    uint16_t  _slotCount;

    static inline void initNeighborCoverage() {
        uint8_t i, j;
        uint16_t * pNeighborList;

        for (j = 0; j < CHANNELS_TO_PROBE; j++) {
            pNeighborList = call NeighborProbe.getNeighborList(j);
            for (i = 0; i < MAX_NEIGHBORS; i++) {
                _neighbors[j][i].node = pNeighborList[i];
                _neighbors[j][i].covered = FALSE;
            } 
        }
    }


    static inline NodeCoverage * getNeighbor(uint8_t channelIndex, 
        uint16_t node) {

        uint8_t i;
        for (i = 0; i < MAX_NEIGHBORS; i++) {
            if (_neighbors[channelIndex][i].node == node)
                return &_neighbors[channelIndex][i];
        }
        return NULL;
    }

    static inline void setNeighborCovered(uint16_t node) {
        uint8_t i;
        NodeCoverage * pNeighbor;

        for (i = 0; i < CHANNELS_TO_PROBE; i++) {
            pNeighbor = getNeighbor(i, node);
            if (pNeighbor != NULL) 
                pNeighbor->covered = TRUE;
        }
    }

    static inline uint8_t copyUncoveredNeighbors(uint8_t channelIndex, 
        uint16_t list[]) {

        uint8_t uncoveredCount = 0;
        uint8_t i;
        for (i = 0; i < MAX_NEIGHBORS; i++) {
            if (_neighbors[channelIndex][i].node != INVALID_NODE_ADDR 
                && _neighbors[channelIndex][i].covered == FALSE)
                list[uncoveredCount++] = _neighbors[channelIndex][i].node;
        }
        for (i = uncoveredCount; i < MAX_NEIGHBORS; i++)
            list[i] = INVALID_NODE_ADDR;
        return uncoveredCount;
    }


    static inline void startTimer() {
        call Timer.start(TIMER_ONE_SHOT,
            (call Random.rand() % MAX_SEND_RANGE) + MIN_SEND_DELAY);
    }


    task void sendCoreCompeteMsg() {
        TOS_MsgPtr msgBuf = call MsgBuf.getMsgBuf();
        CoreCompeteMsg * pCoreMsg;

        if (msgBuf == NULL) return; 

        pCoreMsg = (CoreCompeteMsg *)(msgBuf->data);

        _dataChannelIndex = _depth % CHANNELS_TO_PROBE; 

        pCoreMsg->sourceAddr = TOS_LOCAL_ADDRESS;
        pCoreMsg->sourceDepth = _depth;
        pCoreMsg->channelIndex = _dataChannelIndex;
        pCoreMsg->stateOffset = call Schedule.getSlotTime();
        if (copyUncoveredNeighbors(_dataChannelIndex,
            pCoreMsg->coveredNodes) == 0) {
            call MsgBuf.putMsgBuf(msgBuf);
            return;  // All neighbors are covered already.
        }

        if (call SendCoreCompeteMsg.send(TOS_BCAST_ADDR, 
            sizeof(CoreCompeteMsg), msgBuf) == SUCCESS) {
            dbg(DBG_USR1, "Sending CORE COMPETE message (depth %u, offset %u) at %u ms\n",
                pCoreMsg->sourceDepth,
                pCoreMsg->stateOffset,
                call SystemTime.getCurrentTimeMillis());

            dbg(DBG_USR1, "Covering: "); 
            call NodeList.printList(pCoreMsg->coveredNodes, MAX_NEIGHBORS);
        } else {
            call MsgBuf.putMsgBuf(msgBuf);
        }
    }

    task void sendCoreSubscribeMsg() {
        TOS_MsgPtr msgBuf = call MsgBuf.getMsgBuf();
        CoreSubscribeMsg * pCoreMsg;

        if (msgBuf == NULL) return;

        pCoreMsg = (CoreSubscribeMsg *)(msgBuf->data);

        pCoreMsg->sourceAddr = TOS_LOCAL_ADDRESS;
        pCoreMsg->destAddr = _parentCandidate;

        if (call SendCoreSubscribeMsg.send(TOS_BCAST_ADDR, 
            sizeof(CoreSubscribeMsg), msgBuf) == SUCCESS) {
            dbg(DBG_USR1, "Sending CORE SUBSCRIBE message to %u at %u ms\n",
                pCoreMsg->destAddr,
                call SystemTime.getCurrentTimeMillis());
        } else {
            call MsgBuf.putMsgBuf(msgBuf);
        }

        // Reset the parent candidate. 
        // Last time select from potential parents, next time from real ones.
        _parentCandidate = INVALID_NODE_ADDR;  
        _parentCandidateCoverage = 0;
        _parentCandidateDepth = INVALID_DEPTH;
    }

    task void sendCoreClaimMsg() {
        TOS_MsgPtr msgBuf = call MsgBuf.getMsgBuf();
        CoreClaimMsg * pCoreMsg;

        if (msgBuf == NULL) return;

        pCoreMsg = (CoreClaimMsg *)(msgBuf->data);

        pCoreMsg->sourceAddr = TOS_LOCAL_ADDRESS;
        pCoreMsg->sourceDepth = _depth;
        pCoreMsg->stateOffset = call Schedule.getSlotTime();
        pCoreMsg->channelIndex = _dataChannelIndex;

        if (!_subscribed || 
            copyUncoveredNeighbors(_dataChannelIndex, pCoreMsg->coveredNodes) == 0) {
            call MsgBuf.putMsgBuf(msgBuf); 
            return;
        }

        if (call SendCoreClaimMsg.send(TOS_BCAST_ADDR, sizeof(CoreClaimMsg), msgBuf) 
            == SUCCESS) {
            dbg(DBG_USR1, "Sending CORE CLAIM message (depth %u, offset %u) at %u ms\n",
                pCoreMsg->sourceDepth,
                pCoreMsg->stateOffset,
                call SystemTime.getCurrentTimeMillis());

            dbg(DBG_USR1, "Covering: "); 
            call NodeList.printList(pCoreMsg->coveredNodes, MAX_NEIGHBORS);
        } else {
            call MsgBuf.putMsgBuf(msgBuf);
        }

        _isCoreNode = TRUE;  // Becomes a core node.
    }

    command bool Core.isCoreNode() {
        return _isCoreNode;
    }

    command uint8_t Core.getDepth() {
        return _depth;
    }

    command uint16_t Core.getParent() {
        return _parent;
    }

    command void Core.setup() {

        call Schedule.stop();  
        call Schedule.start(0, SCHED_SLOT_LENGTH);

        _timeout = FALSE;
        _slotCount = 0;
        _parent = INVALID_NODE_ADDR;
        _parentDataChannelIndex = 0;
        _dataChannelIndex = 0;
        _parentCandidate = INVALID_NODE_ADDR;
        _parentCandidateCoverage = 0;
        _parentCandidateDepth = INVALID_DEPTH;
        _parentCandidateDataChannelIndex = 0;
       
        initNeighborCoverage();
        
        if (__isBase()){
            _isCoreNode = TRUE;
            _depth = 0;
            _subscribed = TRUE;  // To make the base always a core node.
            _state = S_CORE_COMPETE_TX;
            startTimer();
        } else {
            _isCoreNode = FALSE;
            _depth = INVALID_DEPTH;
            _subscribed = FALSE;
            _state = S_READY;
        }
        call ChannelState.turnOnRadio(__gChannelsToProbe[0]);

    }

    event void NeighborProbe.done() {}

    event result_t Timer.fired() {
        switch (_state) {
            case S_CORE_COMPETE_TX:
                post sendCoreCompeteMsg();
                break;
            case S_CORE_SUBSCRIBE_TX:
                post sendCoreSubscribeMsg();
                break;
            case S_CORE_CLAIM_TX:
                post sendCoreClaimMsg();
                break;
            default: 
                break;
        } 
        return SUCCESS;
    }

    static inline void tuneRadio() {
        uint8_t i;

        _slotCount = (_slotCount + 1) % (3 * CHANNELS_TO_PROBE);
        for (i = 0; i < CHANNELS_TO_PROBE; i++) {
            if (_slotCount == (3 * i))  {
                call ChannelState.turnOnRadio(__gChannelsToProbe[i]);
                break;
            }
        }
    }

    event result_t Schedule.slotChanged() {
        if (_state != S_CORE_SETUP_DONE) {
            if (_timeout == TRUE) {
                call Timer.stop();
                _state = S_CORE_SETUP_DONE;
                call ChannelState.turnOffRadio();
                signal Core.setupDone(FAIL);
            } else {
                tuneRadio();
            }
        }

        switch(_state) {
            case S_CORE_COMPETE_RX:
                if (_parentCandidate != INVALID_NODE_ADDR) {
                    _state = S_CORE_SUBSCRIBE_TX;
                    startTimer();
                }
                break;
            case S_CORE_SUBSCRIBE_TX:
                _state = S_CORE_CLAIM_RX;
                break;
            case S_CORE_CLAIM_RX:
                if (_parentCandidate != INVALID_NODE_ADDR) {
                    _parent = _parentCandidate;
                    _parentDataChannelIndex = _parentCandidateDataChannelIndex;
                    _depth = _parentCandidateDepth + 1;
                    _state = S_CORE_COMPETE_TX;
                    startTimer();
                } else {  // No parent available.
                    _state = S_CORE_COMPETE_RX; // Return to the first state. 
                }
                break;
            case S_CORE_COMPETE_TX:
                _state = S_CORE_SUBSCRIBE_RX;
                break;
            case S_CORE_SUBSCRIBE_RX:
                _state = S_CORE_CLAIM_TX;
                startTimer();
                break;
            case S_CORE_CLAIM_TX:
                _state = S_CORE_SETUP_DONE;
                call ChannelState.turnOffRadio();
                signal Core.setupDone(SUCCESS);
                break;
            default:
                break;
        }
        return SUCCESS;
    }
    
    static inline void startTimeoutTimer() {
        uint32_t delay;
        delay = SCHED_SLOT_LENGTH;
        delay = (delay << 4); // * 16, normally 6 slots.
        call TimeoutTimer.start(TIMER_ONE_SHOT, delay);
    }

    event TOS_MsgPtr ReceiveCoreCompeteMsg.receive(TOS_MsgPtr pMsg) {
        CoreCompeteMsg * pCoreMsg = (CoreCompeteMsg *)(pMsg->data);
        NodeCoverage * pNeighbor; 
        uint8_t tmpParentCoverage;
      
        if (_state == S_READY) {
            _state = S_CORE_COMPETE_RX;
            startTimeoutTimer();
        }

        /* Nodes who sent CoreCompeteMsg have already been covered. */
        setNeighborCovered(pCoreMsg->sourceAddr);

        if (_state == S_CORE_COMPETE_RX) {
            pNeighbor = getNeighbor(pCoreMsg->channelIndex, pCoreMsg->sourceAddr);
            if (pNeighbor == NULL) return pMsg;  // Ignore neighbors with poor links.

            tmpParentCoverage = call NodeList.countList(pCoreMsg->coveredNodes, MAX_NEIGHBORS);
            if (tmpParentCoverage > _parentCandidateCoverage) {
                _parentCandidate = pCoreMsg->sourceAddr;
                _parentCandidateCoverage = tmpParentCoverage;
                _parentCandidateDepth = pCoreMsg->sourceDepth;
            }
            dbg(DBG_USR1, "Received CORE COMPETE message from %u at %u ms\n",
                pCoreMsg->sourceAddr,
                call SystemTime.getCurrentTimeMillis());
        }

        return pMsg;
    }

    event TOS_MsgPtr ReceiveCoreSubscribeMsg.receive(TOS_MsgPtr pMsg) {
        CoreSubscribeMsg * pCoreMsg = (CoreSubscribeMsg *)(pMsg->data);
        NodeCoverage * pNeighbor;

        if (_state == S_CORE_SUBSCRIBE_RX 
            && pCoreMsg->destAddr == TOS_LOCAL_ADDRESS) {

            pNeighbor = getNeighbor(_dataChannelIndex, pCoreMsg->sourceAddr);
            if (pNeighbor == NULL) return pMsg;

            _subscribed = TRUE;

            dbg(DBG_USR1, "Received CORE SUBSCRIBE message from %u\n",
                pCoreMsg->sourceAddr);
        }   
        return pMsg;
    }

    event TOS_MsgPtr ReceiveCoreClaimMsg.receive(TOS_MsgPtr pMsg) {
        CoreClaimMsg * pCoreMsg = (CoreClaimMsg *)(pMsg->data);
        NodeCoverage * pNeighbor;
        uint8_t i;
        uint8_t tmpParentCoverage;
 
        if (_state == S_READY) {
            _state = S_CORE_COMPETE_RX;
            startTimeoutTimer();
        }

        /* Update coverage in local knowledge base. */
        for (i = 0; i < MAX_NEIGHBORS; i++) {
            if (pCoreMsg->coveredNodes[i] != INVALID_NODE_ADDR) {
                setNeighborCovered(pCoreMsg->coveredNodes[i]);
            }
        }
        /* Nodes who send core claim messages are already covered. */
        setNeighborCovered(pCoreMsg->sourceAddr);

        if (_state == S_CORE_COMPETE_RX || _state == S_CORE_CLAIM_RX) {
            pNeighbor = getNeighbor(pCoreMsg->channelIndex, pCoreMsg->sourceAddr);
            if (pNeighbor == NULL) return pMsg;

            /* Node in S_CORE_COMPETE_RX state jumps to S_CORE_CLAIM_RX
               state directly when received the claim message from a 
               valid parent. */
            
            if (_state != S_CORE_CLAIM_RX) {
                _parentCandidate = INVALID_NODE_ADDR;
                _parentCandidateCoverage = 0;
                _parentCandidateDepth = INVALID_DEPTH;
                _state = S_CORE_CLAIM_RX;
            }

            tmpParentCoverage = call NodeList.countList(pCoreMsg->coveredNodes, MAX_NEIGHBORS);
            if (tmpParentCoverage > _parentCandidateCoverage) {
                _parentCandidate = pCoreMsg->sourceAddr;
                _parentCandidateCoverage = tmpParentCoverage;
                _parentCandidateDepth = pCoreMsg->sourceDepth;
                _parentCandidateDataChannelIndex = pCoreMsg->channelIndex;
            } 
            dbg(DBG_USR1, "Received CORE CLAIM message from %u\n",
                pCoreMsg->sourceAddr);
        }
        return pMsg;
    }

    event result_t SendCoreCompeteMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        call MsgBuf.putMsgBuf(pMsg);
        return SUCCESS;
    }

    event result_t SendCoreSubscribeMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        call MsgBuf.putMsgBuf(pMsg);
        return SUCCESS;
    }

    event result_t SendCoreClaimMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        call MsgBuf.putMsgBuf(pMsg);
        return SUCCESS;
    }

    command uint8_t Core.getParentDataChannel() {
        return __gChannelsToProbe[_parentDataChannelIndex];
    }

    command uint8_t Core.getDataChannel() {
        return __gChannelsToProbe[_dataChannelIndex];
    }

    event result_t TimeoutTimer.fired() {
        _timeout = TRUE;
        return SUCCESS;
    }
}

