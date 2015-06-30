/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2005, Technische Universitaet Berlin
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Test synchronisation
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

includes DTClock;
includes wsc;

module TestSyncM {
    provides {
        interface StdControl;
    }
    uses {
        interface TimerMilli as TimeoutTimer;
        interface Leds;
        interface BareSendMsg;
        interface ReceiveMsg;
        interface TDA5250Config;
        interface DTClock;
        interface DTDelta;
        interface RawDump;
    }
}
implementation {
#define TIME_BETWEEN_MSGS     1000
#define NUM_ENTRIES           200

    typedef struct {
        unsigned seqNo;
        int32_t targetDelta;
        int32_t actualDelta;
    } deltaEntry_t;
    
    deltaEntry_t deltas[NUM_ENTRIES];

    unsigned index;
    timeval_t baseTime;

    norace TOS_Msg sendMsg;
    
    void dumpWord(uint16_t seqNo, int16_t data) {
        uint8_t *s = (uint8_t *) &seqNo;
        uint8_t *d = (uint8_t *) &data;
        uint16_t check;
        check = 0x11;
        check = wscByte(check,s[1]);
        check = wscByte(check,s[0]);
        check = wscByte(check,d[1]);
        check = wscByte(check,d[0]);
        if(call RawDump.dumpWord(seqNo) == FAIL) return;
        if(call RawDump.dumpWord(data) == FAIL) return;
        if(call RawDump.dumpWord(check) == FAIL) return;
    }

    /**
     * Send a Message
     **/
    result_t SendMsg() {
        result_t res;
        int32_t delta;
        timeval_t tv;
        
        if(TOS_LOCAL_ADDRESS != 0) return SUCCESS;
        if(index >= NUM_ENTRIES) return SUCCESS;
        
        call DTClock.getTime(&tv);
        sendMsg.time_s = tv.tv_sec;
        sendMsg.time_us = tv.tv_usec;
        if((baseTime.tv_sec == 0) && (baseTime.tv_usec == 0)) {
            baseTime.tv_sec = tv.tv_sec;
            baseTime.tv_usec = tv.tv_usec;
        }

        call DTDelta.reserve();
        call DTDelta.getDelta(&baseTime, &tv,&delta);
        call DTDelta.release();

        sendMsg.length = 6;
        sendMsg.addr = 200;
        sendMsg.s_addr = TOS_LOCAL_ADDRESS;
        sendMsg.data[0] = ((uint8_t *) &index)[0];
        sendMsg.data[1] = ((uint8_t *) &index)[1];
        sendMsg.data[2] = ((uint8_t *) &delta)[0];
        sendMsg.data[3] = ((uint8_t *) &delta)[1];
        sendMsg.data[4] = ((uint8_t *) &delta)[2];
        sendMsg.data[5] = ((uint8_t *) &delta)[3];
        res = call BareSendMsg.send(&sendMsg);
        if(res == SUCCESS) call Leds.redOn();
        return res;
    }

    task void SendMsgTask()  {
        SendMsg();
    }

    event result_t TDA5250Config.ready() {
        return SUCCESS;
    }

    task void TimoutTimerTask() {
        if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
            post TimoutTimerTask();   
    }

    /**
     * Initializing the components. 
     **/
    command result_t StdControl.init() {
        atomic {
            baseTime.tv_sec = baseTime.tv_usec = 0;
            index = 0;
            for(index = 0; index < NUM_ENTRIES; index++) {
                deltas[index].seqNo = 0;
                deltas[index].targetDelta = 0;
                deltas[index].actualDelta = 0;
            }
            index = 0;
        }
        call Leds.init();
        return SUCCESS;
    }

    /**
     * Start the component. Send first message.
     * 
     * @return returns <code>SUCCESS</code> or <code>FAILED</code>
     **/
    command result_t StdControl.start() {
        call RawDump.init(0,TRUE);
        return post TimoutTimerTask();
    }
   
    /**
     * Stop the component. Do nothing.
     * 
     * @return returns <code>SUCCESS</code> or <code>FAILED</code>
     **/   
    command result_t StdControl.stop() {
        return SUCCESS;
    }
   

    /**
     * Message sent. Now set timer to send another random message sometime
     within the next 512 msec
    */
    event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success){
        if(success) {
            call Leds.redOff();
            atomic index++;
        }
        if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
            post TimoutTimerTask();
        return SUCCESS;
    }  
   
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
        unsigned i;
        int32_t d;
        timeval_t tv;
        int diff;
        
        call Leds.greenToggle();
        ((uint8_t *) &i)[0] = m->data[0];
        ((uint8_t *) &i)[1] = m->data[1];
        ((uint8_t *) &d)[0] = m->data[2];
        ((uint8_t *) &d)[1] = m->data[3];
        ((uint8_t *) &d)[2] = m->data[4];
        ((uint8_t *) &d)[3] = m->data[5];

        if((baseTime.tv_sec == 0) && (baseTime.tv_usec == 0)) {
            baseTime.tv_sec = m->time_s;
            baseTime.tv_usec = m->time_us;
            call DTDelta.reserve();
            call DTDelta.addDelta(&baseTime, d);
            call DTDelta.release();
        }
        deltas[i].seqNo = i;
        deltas[i].targetDelta = d;

        tv.tv_sec = m->time_s;
        tv.tv_usec = m->time_us;
        call DTDelta.reserve();
        call DTDelta.getDelta(&baseTime, &tv, &d);
        call DTDelta.release();
        deltas[i].actualDelta = d;
        diff = deltas[i].targetDelta - deltas[i].actualDelta;
        dumpWord(i, diff);
        return m;
    }
   
    /**
     * Timer fired, so send another random message
     */
    event result_t TimeoutTimer.fired() {
        if(SendMsg() == FAIL)
        {
            if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
                post TimoutTimerTask(); 
        }
        return SUCCESS;
    }
}
