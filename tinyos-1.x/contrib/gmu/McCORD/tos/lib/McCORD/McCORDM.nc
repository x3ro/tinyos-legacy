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

module McCORDM {
     provides {
         interface StdControl;
         interface McCORD;
     }
     uses {
         interface StdControl as TimerControl;
         interface StdControl as CommControl;
         interface StdControl as ChannelStateControl;
         interface StdControl as FlashWPControl;
         interface Leds;
         interface Random;
         interface ChannelState; 
         interface DataManagement;
         interface NeighborProbe;
         interface Core;
         interface DataTransfer;
         interface DataTransfer as BaseDataTransfer;  // through UART.
         interface SystemTime;
         interface Timer;
         interface SendMsg as SendSchedMsg;
         interface ReceiveMsg as ReceiveSchedMsg;
         interface MsgBuf;
     }
}

implementation {
    
    enum {
        S_INIT,
        S_READY,
        S_SCHED_MSG_PENDING,
        S_SCHED_MSG_SENT,
        S_NEIGHBOR_PROBING,
        S_CORE_SETUP,
        S_DATA_TRANSFER,
    };

    uint32_t _startTimeMillis;
    uint8_t  _state = S_INIT;
    
    command result_t StdControl.init() {
        result_t result = SUCCESS;
        result = rcombine(call TimerControl.init(), result);
        result = rcombine(call CommControl.init(), result);
        result = rcombine(call ChannelStateControl.init(), result);
        result = rcombine(call FlashWPControl.init(), result);
        result = rcombine(call Leds.init(), result);
        result = rcombine(call Random.init(), result);
        
        return result;
    }

    command result_t StdControl.start() {
        result_t result = SUCCESS;
        result = rcombine(call TimerControl.start(), result);
        result = rcombine(call CommControl.start(), result);
        result = rcombine(call ChannelStateControl.start(), result);
        result = rcombine(call FlashWPControl.start(), result);

        result = rcombine(call DataManagement.init(), result);

        return result;
    }

    command result_t StdControl.stop() {
        return SUCCESS;
    }

    event void DataManagement.initDone(result_t success) {
        _state = S_READY;

        if (__isBase()) {
            // Start listening to UART.
            call BaseDataTransfer.start();
        }
    }

    task void sendSchedMsgTask() {
        TOS_MsgPtr msgBuf = call MsgBuf.getMsgBuf();
        SchedMsg * pSchedMsg;

        if (msgBuf == NULL) {
            call Timer.start(TIMER_ONE_SHOT, 
                call Random.rand() % 16 + 1);
        }
  
        pSchedMsg = (SchedMsg *)(msgBuf->data);

        pSchedMsg->startTimeMillis = _startTimeMillis;
        call DataManagement.getObjMetadata(&(pSchedMsg->metadata));

        if (call SendSchedMsg.send(TOS_BCAST_ADDR,
            sizeof(SchedMsg), msgBuf) == SUCCESS) {
            dbg(DBG_USR1, "Sending SCHED message for schedule at %u ms.\n",
                _startTimeMillis); 
        } else {
            call MsgBuf.putMsgBuf(msgBuf);
            call Timer.start(TIMER_ONE_SHOT, 
                call Random.rand() % 16 + 1);
        }
    }

    event void BaseDataTransfer.done(result_t result) {
        if (result == SUCCESS) {
            // Base received new object. Broadcast schedule message.
            _startTimeMillis = call SystemTime.getCurrentTimeMillis() 
                + NEIGHBOR_PROBE_START_TIME; 
            _state = S_SCHED_MSG_PENDING; 
            call Timer.start(TIMER_ONE_SHOT, BASE_BOOT_TIME);
            call Leds.redOff();  // will be on when data transfer is done.
            signal McCORD.started();

            dbg(DBG_USR1, "Base station received a new object. "
                          "McCORD started at %u ms.\n",
                 call SystemTime.getCurrentTimeMillis());
        } else {
            // Wait for new object.
            call BaseDataTransfer.start();
        }
    }

    event result_t Timer.fired() {
        switch(_state) {
            case S_SCHED_MSG_PENDING:
                post sendSchedMsgTask();
                break;
            case S_SCHED_MSG_SENT:
                _state = S_NEIGHBOR_PROBING; 
                call NeighborProbe.start();
                break;
            default:
                break;
        }
        return SUCCESS;
    }

    event result_t SendSchedMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        _state = S_SCHED_MSG_SENT;
        call MsgBuf.putMsgBuf(pMsg);
        call Timer.start(TIMER_ONE_SHOT,
            _startTimeMillis - call SystemTime.getCurrentTimeMillis());
        call ChannelState.turnOffRadio();
        return SUCCESS;
    }
   
    event TOS_MsgPtr ReceiveSchedMsg.receive(TOS_MsgPtr pMsg) {
        SchedMsg * pSchedMsg = (SchedMsg *)(pMsg->data);

        if (_state == S_READY) {
            call DataManagement.setObjMetadata(&(pSchedMsg->metadata));
            _startTimeMillis = pSchedMsg->startTimeMillis;
            _state = S_SCHED_MSG_PENDING;
            call Timer.start(TIMER_ONE_SHOT, call Random.rand() % 16 + 1);
            call Leds.redOff(); // will be on when data transfer is done.
            signal McCORD.started();

            dbg(DBG_USR1, "McCORD started at %u ms.\n",
                 call SystemTime.getCurrentTimeMillis());
        }
        return pMsg;
    }
    
    event void NeighborProbe.done() {
        _state = S_CORE_SETUP;
        call Core.setup();
    }

    event void Core.setupDone(result_t result) {
#ifdef PLATFORM_PC
        uint32_t timeNow = call SystemTime.getCurrentTimeMillis();
        dbg(DBG_USR1, "isCoreNode %u, depth %u, parent %u, dataChannel %d at %u ms\n",
            call Core.isCoreNode(),
            call Core.getDepth(),
            call Core.getParent(),
            call Core.getDataChannel(),
            timeNow);
        __reportCore(call Core.isCoreNode()); 
#endif
        _state = S_DATA_TRANSFER;
        call DataTransfer.start();
    }

    event void DataTransfer.done(result_t result) {

        call Leds.redOn(); 

        _state = S_READY;
      
        if (__isBase()) {
            // Listen to the UART again.
            call BaseDataTransfer.start();
        }

        dbg(DBG_USR1, "McCORD done at %u ms.\n",
            call SystemTime.getCurrentTimeMillis());
     
        // Assume the radio was on before McCORD started.
        // Now return to its original channel.
        call ChannelState.turnOnRadio(INIT_CHANNEL);

        signal McCORD.done(SUCCESS);
    }

    event void DataManagement.setObjMetadataDone() {}

    event void DataManagement.readPktDone(result_t success) {}

    event void DataManagement.newObjComplete() {}
}

