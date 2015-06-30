// $Id: HPLClock.nc,v 1.1.1.1 2007/11/05 19:10:06 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 * modified 2/17/04 kamin whitheouse: changed from timer0 to timer2 so that we could use output compare register.  Also set clock source back to internal oscillator instead of 32Khz, which doesn't exist on atmega8
 */

// The Mica-specific parts of the hardware presentation layer.


/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

module HPLClock {
    provides interface Clock;
    provides interface StdControl;

}
implementation
{
    uint8_t set_flag;
    uint8_t mscale, nextScale, minterval ;

  //this is to make the clock emulate a 32Khz oscillator
  const float INTERVAL_MULTIPLIER=0.9765;  //this is 1Mhz/1.024Mhz
  enum{ SCALE_OFFSET=4};  

    command result_t StdControl.init() {
      atomic {
	mscale = DEFAULT_SCALE+SCALE_OFFSET; 
	minterval = DEFAULT_INTERVAL*INTERVAL_MULTIPLIER;
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
        outp(value*INTERVAL_MULTIPLIER, OCR2);
    } 
    async command void Clock.setNextInterval(uint8_t value) {
      atomic {
	minterval = value*INTERVAL_MULTIPLIER;
	set_flag = 1;
      }
    }

    async command uint8_t Clock.getInterval() {
        return inp(OCR2);
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
	scale &= 7;
	nextScale = scale==0? 0 : 7 <= scale+SCALE_OFFSET ? 7 : scale+SCALE_OFFSET; //change scaler for 1Mhz clock instead of 32Khz clock
        set_flag=1;
      }
    }
       

    async command result_t Clock.setIntervalAndScale(uint8_t interval, uint8_t scale) {
        
        if (scale >7) return FAIL;
	scale = scale==0? 0 : 7 <= scale+SCALE_OFFSET ? 7 : scale+SCALE_OFFSET; //change scaler for 1Mhz clock instead of 32Khz clock
        scale|=0x8;
	interval=interval*INTERVAL_MULTIPLIER;
	atomic {
	  cbi(TIMSK, OCIE2);
	  outp(scale, TCCR2);
	  mscale = scale;
	  outp(0,TCNT2);
	  outp(interval, OCR2);
	  minterval = interval;
	  sbi(TIMSK, OCIE2);
	}
        return SUCCESS;
    }
        
    async command uint8_t Clock.readCounter() {
        return (inp(TCNT2));
    }

    async command void Clock.setCounter(uint8_t n) {
        outp(n, TCNT2);
    }

    async command void Clock.intDisable() {
        cbi(TIMSK, OCIE2);
    }
    async command void Clock.intEnable() {
        sbi(TIMSK, OCIE2);
    }

  async command result_t Clock.setRate(char interval, char scale) {
    if (scale >7) return FAIL;
    atomic{
      scale = scale==0? 0 : 7 <= scale+SCALE_OFFSET ? 7 : scale+SCALE_OFFSET; //change scaler for 1Mhz clock instead of 32Khz clock
      scale |= 0x8;
      cbi(TIMSK, TOIE2);
      cbi(TIMSK, OCIE2);     //Disable TC0 interrupt
      //      sbi(ASSR, AS0);        //set Timer/Counter0 to be asynchronous
      //from the CPU clock with a second external
      //clock(32,768kHz)driving it.
      outp(scale, TCCR2);    //prescale the timer to be clock/128 to make it
      outp(0, TCNT2);
      outp(interval*INTERVAL_MULTIPLIER, OCR2);
      sbi(TIMSK, OCIE2);
    }
    return SUCCESS;
  }

  default async event result_t Clock.fire() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE2) {
    atomic {
      if (set_flag) {
	mscale = nextScale;
	nextScale|=0x8;
	outp(nextScale, TCCR2);
	
	outp(minterval, OCR2);
	set_flag=0;
      }
    }
    signal Clock.fire();
  }

}
