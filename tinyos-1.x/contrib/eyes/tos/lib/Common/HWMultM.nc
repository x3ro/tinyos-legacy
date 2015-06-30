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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * expose the hardware mulitplier as a component
 * - Author -------------------------------------------------------------
 * Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */

module HWMultM {
    provides {
        interface HWMult[uint8_t id];
        interface StdControl;
    }
}
implementation {
    /***** semaphore implementation *******/
    bool busy;
    uint8_t clientId;
    bool taskPending;
    
    void release(uint8_t i) {
        bool b;
        atomic b = busy;
        if(!b) signal HWMult.released[i]();
    }

    task void ReleasedTask() {
        uint8_t i;
        uint8_t cId;
        atomic cId = clientId;
        for (i = 0; i < cId; i++) {
            release(i);
        }
        for (i = cId+1; i < uniqueCount("HWMult"); i++) {
            release(i);
        }
        release(cId);
        atomic taskPending = FALSE;
    }
  
    task void RequestedTask() {
        uint8_t cId;
        bool b;
        atomic {
            cId = clientId;
            b = busy;
        }
        // inform owner that bus was requested
        if (b) signal HWMult.requested[cId]();
    }
 
    command result_t StdControl.init() {
        atomic {
            busy = FALSE;
            taskPending = FALSE;
        }
        return SUCCESS;
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        return SUCCESS;
    }

    async command bool HWMult.get[uint8_t id]() {
        bool old;
        atomic {
            old = busy;
            busy = TRUE;
            if(!old) {
                clientId = id;
            } else {
                post RequestedTask();
            }
        }
        return !old;
    }
 
    async command result_t HWMult.release[uint8_t id]() {
        atomic {
            if((busy == TRUE) && (clientId == id)) {
                busy = FALSE;
                if((taskPending == FALSE) && (post ReleasedTask() == TRUE)) {
                    taskPending = TRUE;
                }
            }
        }
        return SUCCESS;
    }

    default event result_t HWMult.released[uint8_t id]() {
        return SUCCESS;
    }
  
    default event result_t HWMult.requested[uint8_t id]() {
        return SUCCESS;
    }

    /********** lets go to work **********/
    typedef union 
    {
        int32_t op;
        struct {
            uint16_t lo;
            int16_t hi;
        };
    } i32parts_t;


    async command result_t HWMult.mult32i[uint8_t id](int32_t a, int32_t b, int32_t *r) {
        int16_t sum3, sum2, sum1, sum0;
        uint16_t op1hi, op1lo, op2hi, op2lo;
        i32parts_t parts;
        result_t res = SUCCESS;
        sum3 = sum2 = 0;
        parts.op = a;
        op1hi = parts.hi;
        op1lo = parts.lo;
        parts.op = b;
        op2hi = parts.hi;
        op2lo = parts.lo;

        // LSB*LSB
        MPY = op1lo;
        OP2 = op2lo;
        sum0 = RESLO;
        sum1 = RESHI;
        // LSBs x MSBs
        MPY = op1lo;
        OP2 = op2hi;
        MAC = op2lo;
        OP2 = op1hi;
        sum1 += RESLO;
        if(READ_SR & SR_C) ++sum2;  // asm("addc &0x13c, %0" : "=m" (sum2));
        sum2 += RESHI;
        // MSBs x MSBs
        MPY = op1hi;
        OP2 = op2hi;
        sum2 += RESLO;
        if(READ_SR & SR_C) ++sum3;
        sum3 += RESHI;
        // asm("addc &0x13c, %0" : "=m" (sum3));
        if((sum2 != 0) || (sum3 != 0)) res = FAIL;
        parts.lo = sum0;
        parts.hi = sum1;
        *r = parts.op;
        return res;
    }
}

