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
 * - Description ---------------------------------------------------------
 * a clock module that keeps the time in ms and us
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

includes DTClock;

module DTClockM {
    provides {
        interface DTClock;
        interface DTDelta;
        interface TicClock;
        interface TicDelta;
        interface StdControl;
    }
    uses {
        interface MSP430Timer as Timer;
        interface HWMult;
    }
}
implementation {
    /********* Definitions ********/
#define ONE_MILLION 1000000
#define MIN_DELTA_SECONDS -2146
#define MAX_DELTA_SECONDS +2146

    typedef enum {
        HWM_RELEASED,
        WANT_HWM,
        HAVE_HWM,
        HWM_REQUESTED
    } hwmState_t;

    /********* Variables **********/
    uint32_t counter2sec;
    hwmState_t hwmState;
    uint16_t reserveCount;
    
    /********** resource ************/

    result_t getHWMult() {
        result_t res = FAIL;
        hwmState_t h;
        atomic h = hwmState;
        if(h >= HAVE_HWM) {
            res = SUCCESS;
        } else {
            res = call HWMult.get();
            if(res == SUCCESS) {
                atomic hwmState = HAVE_HWM;
            } else {
                atomic hwmState = WANT_HWM;
            }
        }
        return res;
    };

    result_t releaseHWMult() {
        atomic {
            if(reserveCount == 0) {
                switch(hwmState) {
                    case HAVE_HWM:
                    case HWM_REQUESTED:
                        call HWMult.release();
                    case WANT_HWM:
                        hwmState = HWM_RELEASED;
                        break;
                    default: break;
                }
            }
        }
        return SUCCESS;
    };

    async command result_t DTDelta.reserve() {
        atomic reserveCount++;
        return getHWMult();
    }
    
    async command result_t DTDelta.release() {
        atomic reserveCount--;
        return releaseHWMult();
    }

    event result_t HWMult.requested() {
        atomic {
            if(hwmState == HAVE_HWM) hwmState = HWM_REQUESTED;
        }
        return SUCCESS;
    }
    
    event result_t HWMult.released() {
        hwmState_t h;
        result_t res = SUCCESS;
        atomic h = hwmState;
        if(h == WANT_HWM) res = getHWMult();
        return res;
    }

    /********** time ****************/
    async event void Timer.overflow() {
        ++counter2sec;
    }

    async command void DTClock.getTime(timeval *tv) {
        atomic {
            tv->tv_usec = call Timer.read();
            tv->tv_sec = counter2sec<<1;
        }
        if(0x8000 & tv->tv_usec) 
        {
            tv->tv_sec++;
            tv->tv_usec &= 0x7fff;
        }
        // compute a microsecond from tics as close as we can make it
        // tv->tv_usec = (tv->tv_usec*30517)/1000;
        // less precise but faster: t.low32*61/2;
        tv->tv_usec = (tv->tv_usec*64 - tv->tv_usec*2 - tv->tv_usec)/2; 
    }

    
    async command result_t DTDelta.getDelta(const timeval *now, const timeval *then, int32_t *delta) {
        bool computed = FALSE;
        int32_t ds = now->tv_sec - then->tv_sec; 
        int32_t dus = now->tv_usec - then->tv_usec;
        // check for overflow
        if(ds < MIN_DELTA_SECONDS) {
            (*delta) = MIN_DELTA_SECONDS - 1;
            return FAIL;
        }
        if(ds > MAX_DELTA_SECONDS) {
            (*delta) = MAX_DELTA_SECONDS + 1;
            return FAIL;
        }
        atomic {
            if(hwmState >= HAVE_HWM) {
                call HWMult.mult32i(ds, ONE_MILLION, delta);
                computed = TRUE;
            }
        }
        if(computed == FALSE) (*delta) = ds*ONE_MILLION;
        (*delta) += dus;
        return SUCCESS;
    }

    /**
     * Adds a delta to the current time.  
     */
    command result_t DTDelta.addDelta(timeval *tv, int32_t delta) {
        int32_t ds;
        int32_t dus = 0;
        int32_t tmp;
        bool computed = FALSE;
        ds = delta/ONE_MILLION;
        atomic {
            if(hwmState >= HAVE_HWM) {
                call HWMult.mult32i(ds, ONE_MILLION, &tmp);
                dus = delta - tmp;
                computed = TRUE;
            }
        }
        if(computed == FALSE) {
            dus = delta - ds*ONE_MILLION;
        }
        tv->tv_sec += ds;
        tv->tv_usec += dus;
        
        if(tv->tv_usec >= ONE_MILLION) {
            tv->tv_sec++;
            tv->tv_usec -= ONE_MILLION;
        }
        else if(tv->tv_usec < 0) {
            tv->tv_sec--;
            tv->tv_usec += ONE_MILLION;
        }
        return SUCCESS;
    }

    /********* TicCLock ************************/
    async command void TicClock.getTime(ticval_t *tv) {
        atomic {
            tv->tv_tics = call Timer.read();
            tv->tv_sec = counter2sec<<1;
        }
        if(0x8000 & tv->tv_tics) 
        {
            tv->tv_sec++;
            tv->tv_tics &= 0x7fff;
        }
    }

    /********* TicDelta ************************/
    async command result_t TicDelta.getDelta(const ticval_t *now,
                                        const ticval_t *then, int16_t *delta) {
        int32_t ds = now->tv_sec - then->tv_sec;
        int16_t dus = now->tv_tics - then->tv_tics;
        if((ds < -1) || (ds > 1)) return FAIL;
        (*delta) = ds*0x8000 + dus;
        return SUCCESS;
    }

    /********** StdControl ****************/
    command result_t StdControl.init(){
        atomic { counter2sec = 2148; }
        return SUCCESS;
    }
  
    command result_t StdControl.start(){
        return SUCCESS;
    }

    command result_t StdControl.stop(){
        return SUCCESS; 
    }
}


 
