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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ----------------------------------------------------------
 * 
 * Measure Battery Level in mV
 *
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module BatteryLevelM {
    provides {
        interface StdControl;
        interface BatteryLevel;
    }
    uses {     
        interface  ADC;
        interface TimerMilli as WakeupTimer;
    }
}
implementation {
// #define BAT_DEBUG
    /**************** Definitions *****************/
    // #define SAMPLEINTERVAL 0x7fff // every 32 seconds
    #define SAMPLEINTERVAL 5000 // every five seconds
    #define LEVEL_INVALID 0xFFFF

    uint16_t level;  // current battery level in mV

    /******* Helper function ***********************/
    void signalFailure() {
#ifdef BAT_DEBUG
        atomic {
            for(;;) {
                ;
            }
        }
        return;
#endif
    }

    /**************** BatteryLevel *****************/

    async command uint16_t BatteryLevel.getLevel() { 
        uint16_t l;
        atomic l = level;
        return l; 
    };

    /**************** Tasks ************************/
    task void rescheduleTask();

    /**************** StdControl *******************/
    command result_t StdControl.init() {
        atomic level = LEVEL_INVALID;
        return SUCCESS;
    }
   
    command result_t StdControl.start() {
        result_t res = SUCCESS;
        res = call ADC.getData(); 
        if(res == FAIL) {
            post rescheduleTask();
        }
        return res;
    }
   
    command result_t StdControl.stop() {
        return call WakeupTimer.stop();
    }
     
    /************** Periodic measurement ************/
    event result_t WakeupTimer.fired() {
        result_t ok = SUCCESS;
        if(call ADC.getData() == FAIL) {
            ok = post rescheduleTask();
            if(ok == FAIL) {
                signalFailure();
            }
        }
        return ok;
    }

    task void rescheduleTask() {
        int32_t iV = SAMPLEINTERVAL;
        atomic if(level == LEVEL_INVALID) iV = 2;
        if(call WakeupTimer.setOneShot(iV) == FAIL) {
            if(post rescheduleTask() == FAIL) {
                signalFailure();
            }
        }
    }

    /************** Data processing ************/
    async event result_t ADC.dataReady(uint16_t data) {
        result_t res = SUCCESS;
        atomic level = data;
        res = post rescheduleTask();
        if(res == FAIL) {
            signalFailure();
        }
        return res;
    }
}
