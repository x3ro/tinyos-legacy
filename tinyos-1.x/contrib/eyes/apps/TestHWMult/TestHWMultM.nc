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
 * test hardware mulitplier as a component
 * - Author -------------------------------------------------------------
 * Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */

module TestHWMultM {
    provides {
        interface StdControl;
    }
    uses {
        interface HWMult;
        interface Leds;
        interface Random;
    }
}
implementation {

    typedef union 
    {
        int32_t op;
        struct {
            uint16_t lo;
            uint16_t hi;
        };
    } i32parts_t;

    norace int32_t a;
    norace int32_t b;
    norace int32_t rhw;
    norace int32_t rsw;

    void signalFailure() {
        call Leds.greenOn();
        call Leds.yellowOn();
        atomic {
            for(;;) {
                ;
            }
        }
    }
    
    task void GetTask() {
        result_t res;
        i32parts_t p;
        p.hi = call Random.rand();
        p.lo = call Random.rand();
        a = p.op;
        // p.hi = call Random.rand();
        p.hi = 0;
        p.lo = call Random.rand();
        b = p.op;
        if(call HWMult.get()) {
            call Leds.redToggle();
            call HWMult.mult32i(a, b, &rhw);
            call HWMult.release();
            rsw = a*b;
            if(rhw != rsw) signalFailure();
        }
        post GetTask();
    }
    
    command result_t StdControl.init() {
        result_t r1, r2;
        r1 = call Random.init();
        r2 = call Leds.init();
        return rcombine(r1,r2);
    }

    command result_t StdControl.start() {
        return post GetTask();
    }
    command result_t StdControl.stop() {
        return SUCCESS;
    }
    event result_t HWMult.requested() {
        return SUCCESS;
    }
    event result_t HWMult.released() {
        return SUCCESS;
    }
}


