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
 *
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  9/19/02
 *
 */


module SysTimeC {
    provides interface SysTime;
}
implementation
{
    uint16_t  high16;

    command result_t SysTime.init() {        
        outp(0x41, TCCR1B);// set clock source 
        // disable output comparation interrupt
        cbi(TIMSK, OCIE1A);
        cbi(TIMSK, OCIE1B);
        // enable timer1 overflow interrupt
        sbi(TIMSK, TOIE1);
        high16=0;
        sei(); // enable interrupt  
        return SUCCESS;
    }

    command result_t SysTime.get(uint32_t * time){
        // read  hardware timer1's TCNT1L and TCNT1H register 
        uint16_t tt =  __inw_atomic(TCNT1L);
        char temp = TOSH_interrupt_disable();
        *time = ((uint32_t)high16<<16);
        if (temp) TOSH_interrupt_enable();
        *time += tt; 
        return SUCCESS; 
    }

    command result_t SysTime.set(uint32_t  time){
        char temp;
        uint16_t t = time & 0xFFFF;
        // write into  hardware timer1's TCNT1 register
        temp = TOSH_interrupt_disable();
        __outw(t, TCNT1L);
        high16 = time >>16 ;
        if (temp) TOSH_interrupt_enable();
        return SUCCESS;
    }

    TOSH_INTERRUPT(SIG_OVERFLOW1) __attribute((spontaneous)){
        high16 ++;
    }

}
