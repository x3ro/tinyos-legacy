// $Id: PIC18F452HPLClock.nc,v 1.1 2005/04/13 16:38:06 hjkoerber Exp $

/*			
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
 * @author: Jason Hill
 * @author: David Gay
 * @author: Philip Levis
 * @author: Hans-Joerg Koerber 
 *          <hj.koerber@hsu-hh.de>
 *	    (+49)40-6541-2638/2627
 * 
 * $Date: 2005/04/13 16:38:06 $
 * $Revision: 1.1 $
 */

/*							   
 * Timer0 is a 16-bit timer with the internal oscillator as clock input.    					   
 */ 


module PIC18F452HPLClock {
    provides interface StdControl;
    provides interface Clock;

    uses interface PIC18F452Interrupt as TIMER0_Overflow;

}

implementation
{
    uint8_t set_flag;
    uint8_t mscale, nextScale;
    uint16_t minterval ;

    enum {
      maxTimerInterval = 0xffff         // 16-bit overflow timer
    };

    command result_t StdControl.init() {
      atomic {
	set_flag = 0;
	mscale = DEFAULT_SCALE; 
	minterval = DEFAULT_INTERVAL;
      }
      
      T0CONbits_T08BIT = 0x0;           // 16-bit timer mode
      T0CONbits_T0CS = 0x0;             // Timer0 clock source = internal clock 
      T0CONbits_PSA = 0x0;              // prescaler enabled
      T0CONbits_T0PS2 = 0x1;            // prescaler  = 256
      T0CONbits_T0PS1 = 0x1;
      T0CONbits_T0PS0 = 0x1;
      WriteTimer0(0);
      return SUCCESS;
    }

    command result_t StdControl.start() {
      uint8_t mi;
      uint16_t ms;

      atomic {
	mi = minterval;
	ms = mscale;
      }
      
      call Clock.setRate(mi, ms);
      return SUCCESS;
    }

    command result_t StdControl.stop() {
      uint16_t mi;
      atomic {
	mi = minterval;
      }

      call Clock.setRate(mi, 0);
      return SUCCESS;
    }


    async command void Clock.setInterval(uint16_t value) {
      uint32_t temp;
      minterval =  maxTimerInterval - value +1; // "+1" is needed to write the correct interval, e.g. if value = 4 then minterval has to be 0xfffc 

      lostTicks = ReadTimer0();
      temp = (uint32_t)minterval + (uint32_t)lostTicks ;
      if(temp>0xffff){
	WriteTimer0(0xffff);
	overflow_flag = 1;
      }
      else {
	WriteTimer0((uint16_t)temp);
	overflow_flag = 0;
      }
      INTCONbits_TMR0IE = 0x1;
    }

    async command void Clock.setNextInterval(uint16_t value) {
      atomic {
	minterval =  maxTimerInterval - value;
        set_flag = 1;
      }
    }

    async command uint16_t Clock.getInterval() {
        return minterval;
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
       

    async command result_t Clock.setIntervalAndScale(uint16_t interval, uint8_t scale) {
      
      scale &= 0x7;
      atomic {
	INTCONbits_TMR0IE = 0x0;
	mscale = scale;	  
	minterval =  maxTimerInterval - interval;
	T0CONbits_T0PS2 = scale>>2;         //prescale the timer1
	T0CONbits_T0PS1 = scale>>1;
	T0CONbits_T0PS0 = scale;     
	WriteTimer0(maxTimerInterval - interval);
	INTCONbits_TMR0IE = 0x1;
      }
      return SUCCESS;
    }
        
    async command uint16_t Clock.readCounter() {
      return (ReadTimer0());
    }

    async command void Clock.setCounter(uint16_t n) {
      WriteTimer0(n);
    }

    async command void Clock.intDisable() {
      INTCONbits_TMR0IE = 0x0;
    }
    async command void Clock.intEnable() {
      INTCONbits_TMR0IE = 0x1;
    }
    

  async command result_t  Clock.setRate(uint16_t interval, uint8_t scale) {

    scale &= 0x7;
    atomic {
      INTCONbits_TMR0IE = 0x0;                     //disable TMR0 overflow Interrupt  
      mscale = scale;	  
      minterval =  maxTimerInterval - interval;
      T0CONbits_T0PS2 = scale>>2;                  //prescale the timer0
      T0CONbits_T0PS1 = scale>>1;
      T0CONbits_T0PS0 = scale;   
      WriteTimer0(maxTimerInterval - interval);    //write the interval into TMR0 register         
      INTCONbits_TMR0IE = 0x1;                     //enable TMR0 overflow Interrupt
      T0CONbits_TMR0ON =0x1;                       //start  Timer0
    }
 
       return SUCCESS;
  }



  async event result_t TIMER0_Overflow.fired(){
    atomic {
      if (set_flag) {
	mscale = nextScale;
      T0CONbits_T0PS2 = mscale>>2;         //prescale the timer1
      T0CONbits_T0PS1 = mscale>>1;
      T0CONbits_T0PS0 = mscale;   
      WriteTimer0(minterval);
      set_flag=0;
      }
     }
    INTCONbits_TMR0IE = 0x0;
  signal Clock.fire();
  return SUCCESS;
  }


  default async event result_t Clock.fire() { return SUCCESS; }

}
