/*  -*- mode:c++; indent-tabs-mode: nil -*- 
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Discription --------------------------------------------------------
 * distribute a time stamp to all nodes in the network
 *
 * - Author -------------------------------------------------------------
 * @author Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */

includes DistributeTS;

module DistributeTSM {
    provides {
        interface StdControl;
        interface DistributeTSConfig;
        interface DistributeTS;
    }
    uses {
        interface Send as SendTS;
        interface Receive as ReceiveTS;
        interface DTClock;
        interface Leds;
        interface TimerMilli as Timer;
    }
}
implementation {
    
    // use only lower twelve bits for epoch
#define MASK 0x0FFF
    
    // for 100ms clock drift update every 16min (assuming max 100ppm drift of crystal)
// #define DEFAULT_INTERVALL  1000000 
#define DEFAULT_INTERVALL 1000
#define INITIAL_INTERVALL 3000
    
    int32_t stampIntervall;
    uint16_t epoch;
    uint16_t originId;

    TOS_Msg dataMsg;
    bool dataMsgLock;

    command result_t StdControl.init() { 
        dataMsgLock = FALSE;
        originId = 1;
        epoch = 0;
        stampIntervall = DEFAULT_INTERVALL;
        return SUCCESS;  
    }

    command result_t StdControl.stop()  {
        call Timer.stop();
        return SUCCESS; 
    }

    command result_t StdControl.start() {
        if(originId == TOS_LOCAL_ADDRESS) {
            call Timer.setOneShot(INITIAL_INTERVALL);
        }
        return SUCCESS;
    }

    bool getDataMsgLock() {
        bool old;
        atomic {
            old = dataMsgLock;
            dataMsgLock = TRUE;
        }
        return !old;
    }

    void releaseDataMsgLock() {
        dataMsgLock = FALSE;
    }
  
    /***********************************************************************
     * Subscriptions
     ***********************************************************************/

    void task SendTask() {
        call Leds.redToggle();
        if(call SendTS.send(&dataMsg, sizeof(TimeStampMsg)) == FAIL) {
            if(post SendTask() == FAIL) releaseDataMsgLock();
        }
    }

    event result_t SendTS.sendDone(TOS_MsgPtr msg, result_t success) {
        releaseDataMsgLock();
        return SUCCESS;
    }
  
    event TOS_MsgPtr ReceiveTS.receive(TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
        TimeStampMsg *ts = payload;
        timeval tv;
        tv.tv_sec = msg->time_s;
        tv.tv_usec = msg->time_us;
        call Leds.yellowToggle();
        signal DistributeTS.newTimeStamp(ts->originId, ts->epoch, &tv);
        return msg;
    }

    /**
     * Timer fired, so send another time stamp msg
     */
    event result_t Timer.fired() {
        TimeStampMsg *msg;
        timeval tv;
        uint16_t length;
        if(originId == TOS_LOCAL_ADDRESS) {
            ++epoch;
            call Leds.greenToggle();
            call Timer.setOneShot(stampIntervall);
            if(getDataMsgLock())
            {
                msg = call SendTS.getBuffer(&dataMsg, &length);
                if(length >= sizeof(TimeStampMsg)) {
                    msg->originId = TOS_LOCAL_ADDRESS;
                    msg->epoch = (epoch & MASK);
                    call DTClock.getTime(&tv);
                    dataMsg.time_s = tv.tv_sec;
                    dataMsg.time_us = tv.tv_usec;
                    if(post SendTask() == FAIL) {
                        releaseDataMsgLock(); 
                    } else {
                        signal DistributeTS.newTimeStamp(TOS_LOCAL_ADDRESS, epoch, &tv);    
                    }
                } else {
                    releaseDataMsgLock(); 
                }
            }
        }
        return SUCCESS;
    }

    /**
     * DistributeTSConfig
     */
    command result_t DistributeTSConfig.setOriginAndIntervall(uint16_t id, int32_t ms) {
        call Timer.stop();
        originId = id;
        stampIntervall = ms;
        if(originId == TOS_LOCAL_ADDRESS) call Timer.setOneShot(INITIAL_INTERVALL);
    }
}

