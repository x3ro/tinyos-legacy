// $Id: HPLTimer2.nc,v 1.1.1.1 2007/11/05 19:10:12 jpolastre Exp $

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
 *
 */

// The Mica-specific parts of the hardware presentation layer.


/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

module HPLTimer2 {
    provides interface Clock as Timer2;
    provides interface StdControl;
}
implementation
{

#define  JIFFY_SCALE 0x4 //cpu clk/256 ~ 32uSec
#define  JIFFY_INTERVAL 2
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
      
      call Timer2.setRate(mi, ms);
      return SUCCESS;
    }

    command result_t StdControl.stop() {
      uint8_t mi;
      atomic {
	mi = minterval;
      }
      call Timer2.setRate(mi, 0);
      return SUCCESS;
    }


    async command void Timer2.setInterval(uint8_t value) {
        outp(value, OCR2);
    } 
    async command void Timer2.setNextInterval(uint8_t value) {
      atomic {
	minterval = value;
	set_flag = 1;
      }
    }

    async command uint8_t Timer2.getInterval() {
        return inp(OCR2);
    }

    async command uint8_t Timer2.getScale() {
      uint8_t ms;
		atomic {
		ms = mscale;
		}
      return ms;
    }

    async command void Timer2.setNextScale(uint8_t scale) {
      atomic {
	nextScale= scale;
        set_flag=1;
      }
    }
       

    async command result_t Timer2.setIntervalAndScale(uint8_t interval, uint8_t scale) {
        
        if (scale >7) return FAIL;
        scale|=0x8;
	atomic {
	  outp(0, TCCR2);	  //stop the timer
		cbi(TIMSK, OCIE2);
		cbi(TIMSK, TOIE2);  //clear interrupts
		mscale = scale;
		minterval = interval;
		outp(0,TCNT2);		  
		outp(interval, OCR2);
		sbi(TIFR,OCF2);	//clear Timer2 OCF flag by writing 1
		sbi(TIMSK, OCIE2);
		outp(scale, TCCR2);	 //start the timer
	}
    return SUCCESS;
    } //setIntervalandScale

  async command result_t Timer2.setRate(char interval, char scale) {
    scale &= 0x7;
    scale |= 0x8;
    atomic {
      cbi(TIMSK, TOIE2);
      cbi(TIMSK, OCIE2);     //Disable TC0 interrupt
	  outp(0, TCCR2);	  //stop the clock
      outp(0, TCNT2);
      outp(interval, OCR2);
      sbi(TIMSK, OCIE2);
      outp(scale, TCCR2);  //start the clock  
    }
    return SUCCESS;
  }

        
    async command uint8_t Timer2.readCounter() {
        return (inp(TCNT2));
    }

    async command void Timer2.setCounter(uint8_t n) {
        outp(n, TCNT2);
    }


    async command void Timer2.intEnable() {
	sbi(TIMSK, OCIE2); // enable timer1 interupt
}
    async command void Timer2.intDisable() {
	cbi(TIMSK, OCIE2); // disable timer1 interupt
}


  default async event result_t Timer2.fire() { return SUCCESS; }

  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE2) {
    atomic {
	if (set_flag) {
		nextScale|=0x8;
-		outp(nextScale, TCCR2);
		outp(minterval, OCR2);
		set_flag=0;
		}
    }  //set
    signal Timer2.fire();
  }

}//HPLTimer2
