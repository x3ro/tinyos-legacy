/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 * Modified by Mads Bondo Dydensborg, sep. 2002. August 2003.
 * Modified by Martin leopold, mar. 2003
 */

// The btnode2_2-specific parts of the hardware presentation layer.

module HPLClock {
  provides interface Clock;
  provides interface StdControl;
}
implementation
{

     uint8_t set_flag;
     uint8_t mscale, nextScale, minterval ;

    command result_t StdControl.init() {
      atomic {
        mscale = DEFAULT_SCALE; 
        minterval = DEFAULT_INTERVAL;
      }
      return SUCCESS;
    }

    command result_t StdControl.start() {
      uint8_t mi, ms;
      atomic {
	mi = minterval;
	ms = mscale;
      }
      
      call Clock.setRate(mi, ms);
      return SUCCESS;
    }

    command result_t StdControl.stop() {
      uint8_t mi;
      atomic {
	mi = minterval;
      }

      call Clock.setRate(mi, 0);
      return SUCCESS;
    }

    async command void Clock.setInterval(uint8_t value) {
        outp(value, OCR0);
    } 
    async command void Clock.setNextInterval(uint8_t value) {
      atomic {
	minterval = value;
	set_flag = 1;
      }
    }

    async command uint8_t Clock.getInterval() {
        return inp(OCR0);
    }

    async command uint8_t Clock.getScale() {
      uint8_t ms;
      atomic {
	ms = mscale;
      }
      
      return ms;
    }

    async command void Clock.setNextScale(uint8_t scale) {
      atomic {
	nextScale= scale;
        set_flag=1;
      }
    }
       
    async command result_t Clock.setIntervalAndScale(uint8_t interval, uint8_t scale) {
        if (scale >7) return FAIL;
        scale|=0x8;
	atomic {
	  cbi(TIMSK, OCIE0);
	  outp(scale, TCCR0);
	  mscale = scale;
	  outp(0,TCNT0);
	  outp(interval, OCR0);
	  minterval = interval;
	  sbi(TIMSK, OCIE0);
	}
        return SUCCESS;
    }
        
    async command uint8_t Clock.readCounter() {
        return (inp(TCNT0));
    }

    async command void Clock.setCounter(uint8_t n) {
        outp(n, TCNT0);
    }

    async command void Clock.intDisable() {
        cbi(TIMSK, OCIE0);
    }
    async command void Clock.intEnable() {
        sbi(TIMSK, OCIE0);
    }

  async command result_t Clock.setRate(char interval, char scale) {
    scale &= 0x7;
    scale |= 0x8;
    atomic {
      cbi(TIMSK, TOIE0); // disable interrupts on timer 0
      cbi(TIMSK, OCIE0); // disable interrupts on timer 0 overflow
      sbi(ASSR, AS0);        //set Timer/Counter0 to be asynchronous
      //from the CPU clock with a second external
      //clock(32,768kHz)driving it.
      outp(scale, TCCR0);    //prescale the timer to be clock/128 to make it
    
      // I believe this is needed for the 128...
      while( ! ( inp(ASSR)  & (1 << TCR0UB)) ); // wait until TCCR is set

      outp(0, TCNT0);
      outp(interval, OCR0);
      sbi(TIMSK, OCIE0); 
    }
    return SUCCESS;
  }

  default async event result_t Clock.fire() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE0) {
    atomic {
      if (set_flag) {
	mscale = nextScale;
	nextScale|=0x8;
	outp(nextScale, TCCR0);
	
	outp(minterval, OCR0);
	set_flag=0;
      }
    }
    signal Clock.fire();
    }
}
