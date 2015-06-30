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
 * Component to measure the RSSI value using the battery level
 * 
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module RSSIVccM
{
    provides {
        interface RSSImV;
        interface StdControl;
    }
    uses {     
        interface BatteryLevel;
        interface HWMult;
        interface MSP430ADC12Single as RSSIQueryADC;
    }
}
implementation
{

   /**************** Variables  *******************/
    typedef enum {
        HWM_RELEASED,
        WANT_HWM,
        HAVE_HWM,
        HAVE_HWM_LOCK,
        HAVE_HWM_LOCK_REQUESTED
    } hwmState_t;

    hwmState_t hwmState;
    
    /**************** StdControl *******************/
    command result_t StdControl.init() {
        return call RSSIQueryADC.bind(MSP430ADC12_RSSI_SETTINGS_VCC);
    }
   
    command result_t StdControl.start() { 
        return SUCCESS;
    }
   
    command result_t StdControl.stop() {
        return SUCCESS;
    }

    /**************** RSSI ADC ****************/
    task void ReadRSSI() {
        if(call RSSIQueryADC.getData() == FAIL) {
            post ReadRSSI();
        }
    }

    uint16_t computeRSSI(uint32_t rawValue) {
        uint32_t voltage = call BatteryLevel.getLevel();
        uint32_t result;
        bool haveIt = TRUE;
        atomic {
            if(hwmState >= HAVE_HWM) {
                call HWMult.mult32i(rawValue, voltage, &result);
            } else {
                 haveIt = FALSE;
            }
        }
        if(haveIt == FALSE) result = rawValue*voltage;
        return (uint16_t)(result>>12);
    }

    async event result_t RSSIQueryADC.dataReady(uint16_t data) {
        uint16_t val = computeRSSI(data);
        atomic {
            if(hwmState == HAVE_HWM_LOCK) {
                hwmState = HAVE_HWM;
            }
            else if(hwmState == HAVE_HWM_LOCK_REQUESTED) {
                hwmState = HWM_RELEASED;
                call HWMult.release();
            } else {
                hwmState = HWM_RELEASED;
            } 
        }
        signal RSSImV.dataReady(val);
        return SUCCESS;
    }


    /**************** RSSImV ****************/
    async command result_t RSSImV.getData() {
        result_t res;
        atomic {
            if(hwmState == HAVE_HWM) {
                hwmState = HAVE_HWM_LOCK;
            } else {
                if(call HWMult.get()) {
                    hwmState = HAVE_HWM_LOCK;
                } else {
                    hwmState = WANT_HWM;
                }
            }
        }
        res = call RSSIQueryADC.getData();
        if(res == FAIL) post ReadRSSI();
        return res;
    }

    default async event result_t RSSImV.dataReady(uint16_t data) {
        return SUCCESS;
    }

    /**** HWMult ***********************************/
    event result_t HWMult.requested() {
        atomic {
            if(hwmState == HAVE_HWM_LOCK) {
                hwmState = HAVE_HWM_LOCK_REQUESTED;
            } else {
                call HWMult.release();
                hwmState = HWM_RELEASED;
            }
        }
        return SUCCESS;
    }
    
    event result_t HWMult.released() {
        atomic {
            if(hwmState == WANT_HWM) {
                if(call HWMult.get()) hwmState = HAVE_HWM_LOCK;
            }
        }
        return SUCCESS;
    }
}
