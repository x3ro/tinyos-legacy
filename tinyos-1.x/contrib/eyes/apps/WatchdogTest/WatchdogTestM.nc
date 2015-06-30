/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * test watchdog component
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module WatchdogTestM {
    provides {
        interface StdControl;
    }
    uses {
        interface Watchdog;
        interface TimerMilli as Timer;
        interface Leds;
    }
}
implementation {

#define WD_ENABLE 1000
#define WD_PATPAT 500

    typedef enum {
        INIT,
        ENABLE,
        PATPAT,
        FIRE
    } testState_t;

    testState_t testState;
    
    command result_t StdControl.init() {
        testState = INIT;
        return call Leds.init();
    }
    
    command result_t StdControl.start() {
        call Leds.redOn();
        testState = ENABLE;
        return call Timer.setOneShot(WD_ENABLE);
    }
    
    command result_t StdControl.stop() {
        return SUCCESS;
    }

    event result_t Timer.fired() {
        result_t res = SUCCESS;
        if(testState == ENABLE) {
            call Watchdog.enable();
            call Leds.redOff();
            call Leds.greenOn();
            testState = PATPAT;
            res = call Timer.setOneShot(WD_PATPAT);
        }
        else if(testState == PATPAT) {
            call Leds.greenOff();
            call Leds.yellowOn();
            call Watchdog.patpat();
            testState = FIRE;
            res = call Timer.setOneShot(WD_PATPAT);
        }
        return res;
    }
}


