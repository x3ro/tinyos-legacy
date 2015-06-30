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


module SysTimeM {
    provides interface SysTime;
}
implementation
{
    uint16_t timeH16;
    
    command result_t Syste,.init() {
        timeH16 = 0;
        // enable timer1 overflow interrupt
        sbi(TIMSK, TOIE1);
        return SUCCESS;
    }

    command result_t SysTime.get(uint16_t * high16, uint16_t * low16){
        uint8_t sreg; 
        *high16 = timeH16;
        
        // read  hardware timer1's TCNT1L and TCNT1H register 
        sreg = inp(SREG); // save global interrupt flag
	cli(); // disable interrupt
        *low16 = inp(TCNT1); // read 16 bits TCNT1 
        outp(sreg, SREG); // restore glabal interrupt flag
        return SUCCESS; 
    }
    command result_t SysTime.set(uint16_t  high16, uint16_t  low16){
        uint8_t sreg;
        timeH16 = high16;

        // write into  hardware timer1's TCNT1 register
        sreg = inp(SREG); // save global interrupt flag
        cli(); // disable interrupt
        outp(low16, TCNT1); // write into TCNT1
        outp(sreg, SREG); // restore glabal interrupt flag
        return SUCCESS;
    }

    TOSH_INTERRUPT(SIG_OVERFLOW1) {
        timeH16++;
  }

}
