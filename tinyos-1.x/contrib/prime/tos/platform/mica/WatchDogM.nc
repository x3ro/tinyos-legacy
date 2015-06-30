/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * Authors:		Su Ping  <sping@intel-research.net>
 *
 */



/**
 * The Watch dog interface. 
 * When enabled, the watch dog will reset a mote at a specified time
 **/
includes TosTime;
module WatchDogM {
    provides interface WatchDog;
    uses {
        interface AbsoluteTimer as AbsoluteTimer2;
        interface Random;
        interface TimeUtil;
    }
}

implementation {

    command result_t WatchDog.set(tos_time_t t ) {
        uint16_t delta = call Random.rand();
        delta = (delta>>8)|(delta & 0xFF); 
        // add a random delay ranging from 0 to 512 seconds
        t = call TimeUtil.addUint32(t, delta<<10);
        return call AbsoluteTimer2.set(t);
        
    }

    command result_t WatchDog.cancel() {
        
        return  call AbsoluteTimer2.cancel();
    }
    
    /** AbsoluteTimer event. Enable watch dog timer and 
     *  set its timeout period 34 ms
     **/  
    event result_t AbsoluteTimer2.fired() {
        TOSH_CLR_YELLOW_LED_PIN();
        wdt_enable(1);
        return SUCCESS ;
    }
}

