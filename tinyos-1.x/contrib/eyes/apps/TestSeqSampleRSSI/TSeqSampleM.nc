/* -*- mode:c++; indent-tabs-mode: nil -*-
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Test Application for channel monitor based on sequential sampling
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module TSeqSampleM {
    provides {
        interface StdControl;
    }
    uses {
        interface LedsNumbered as Leds; 
        interface ChannelMonitor;
        interface ChannelMonitorControl;
        interface ChannelMonitorData;
        interface TDA5250Modes;
        interface TDA5250Config;
        interface TimerMilli as WakeupTimer;
    }
}
implementation {
    #define TIME_INTERVAL 20
    #define SAMPLESIZE 4500

    uint32_t idle;
    uint32_t busy;
    int16_t array[SAMPLESIZE];
    
    command result_t StdControl.init() {
        atomic {
            idle = 0;
            busy = 0;
        }
        return call Leds.init();  
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }

    command result_t StdControl.stop() {

    }
    
    void signalFailure() {
        atomic {
            call Leds.led0On();
            call Leds.led1On();
            call Leds.led2On();
            call Leds.led3On(); 
        }
    }

    task void rescheduleTask() {
        if(call WakeupTimer.setOneShot(TIME_INTERVAL) == FAIL) 
            if(post rescheduleTask() == FAIL) signalFailure();     
    }

    task void checkChannelTask() {
        if(call ChannelMonitor.start() == FAIL) signalFailure();
    }

    event result_t ChannelMonitor.channelBusy() {
        result_t ok1, ok2;
        atomic ++busy;
        ok1 = call Leds.led1Toggle();   
        ok2 = call ChannelMonitorData.getSnr();
        return rcombine(ok1,ok2);
    }

    async event result_t ChannelMonitorData.getSnrDone(int16_t snr) {
        atomic if(busy < SAMPLESIZE) array[busy-1] = snr;
        return post rescheduleTask();
    }

    event result_t ChannelMonitor.channelIdle() {
        result_t ok1, ok2;
        atomic ++idle;
        ok1 = call Leds.led0Toggle();   
        ok2 = post rescheduleTask();
        return rcombine(ok1,ok2);
    }   

   event result_t TDA5250Modes.RxModeDone() { return SUCCESS; };
   event result_t TDA5250Modes.CCAModeDone() {
       return call ChannelMonitorControl.updateNoiseFloor();
   };

   event result_t TDA5250Modes.SleepModeDone() { return SUCCESS; }

   async event void TDA5250Modes.interrupt() { };
   event result_t TDA5250Modes.ready() {
       // call TDA5250Modes.LowLNAGain();
       // call TDA5250Modes.SetRFPower(0); 
       call TDA5250Config.DataValidDetectionOff();
       return call TDA5250Modes.CCAMode();
   };
   
   event result_t TDA5250Config.ready() {
       return SUCCESS;
   }
   
   event result_t ChannelMonitorControl.updateNoiseFloorDone() {
       return call ChannelMonitor.start(); 
   }

    /************** Timer ***************************/
    event result_t WakeupTimer.fired() {
        call Leds.led3Toggle();         
        return post checkChannelTask();
    }
}


