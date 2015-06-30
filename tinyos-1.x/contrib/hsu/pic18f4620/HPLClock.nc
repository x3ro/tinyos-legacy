// $Id: HPLClock.nc,v 1.1 2005/05/25 10:04:02 hjkoerber Exp $

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
 * $Date: 2005/05/25 10:04:02 $
 * $Revision: 1.1 $
 *
 */


/*-------------------------------------------------------------------------
 *								   
 * Timer1 is a 16-bit timer with an 32.768 KHz external oscillator 
 * as clock input, which is connected between pins RC0 and RC1.   
 * When sleep mode is enabled, which is done by default in         
 * pic18f4620hardware.h, timer1 can run with a resolution of binary 
 * 3 ms (3*1/1024 s), because the wake-up lasts about 2.2 ms.                                              
 * In the case of disabled sleeping timer1 can be invoked with an  
 * minimum interval of one binary 1 ms (1/1024 s).                 
 * However in both cases the precision  of timer1 is  +/- 0.5 clock cycle,    
 * which equals 1/65.536 s. This precision is caused by the uncertainty                                       
 * about the exact incrementation moment of timer 1  when overwriting the 
 * timer1-register with the new interval value. 								   
 *
 *-------------------------------------------------------------------------*/ 


module HPLClock {
    provides interface StdControl;
    provides interface Clock;

    uses interface PIC18F4620Interrupt as TIMER1_Overflow;

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
      
      T1CONbits_RD16 = 0x0;             // enable register read/ write of Timer 1 in two 8-bit operations
      T1CONbits_T1OSCEN =0x1;           // enable Timer1 oscillator
      T1CONbits_TMR1CS =0x1;            // Timer1 clock source = external clock from pin RC0/ RC1
      T1CONbits_T1SYNC = 0x1;           // make Timer1 asynchron
      WriteTimer1(0);
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
      minterval =  maxTimerInterval - value +2; // one "+1" is needed to write the correct interval, e.g. if value = 1 then minterval has to be 0xffff 
                                                // second "+1" because of overhead of the interrupt service routine
                                                // the "+1" is necessary because the timer1-module is close to an additional
                                                // incrementation at the end of the interrupt handler
      lostTicks = ReadTimer1();
      temp = (uint32_t)minterval + (uint32_t)lostTicks ;
      if(temp>0xffff){
	WriteTimer1(0xffff);
	overflow_flag = 1;
      }
      else {
	WriteTimer1((uint16_t)temp);
	overflow_flag = 0;
      }
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
      
      scale &= 0x3;
      atomic {
	PIE1bits_TMR1IE = 0x0;
	mscale = scale;	  
	minterval =  maxTimerInterval - interval;
	T1CONbits_T1CKPS1 = scale>>1;         //prescale the timer1
	T1CONbits_T1CKPS0 = scale;
	WriteTimer1(maxTimerInterval - interval);
	PIE1bits_TMR2IE = 0x1;
      }
      return SUCCESS;
    }
        
    async command uint16_t Clock.readCounter() {
      return (ReadTimer1());
    }

    async command void Clock.setCounter(uint16_t n) {
      WriteTimer1(n);
    }

    async command void Clock.intDisable() {
      PIE1bits_TMR1IE = 0x0;
    }
    async command void Clock.intEnable() {
      PIE1bits_TMR1IE = 0x1;
    }
    

  async command result_t  Clock.setRate(uint16_t interval, uint8_t scale) {

    scale &= 0x3;
    atomic {
      PIE1bits_TMR1IE = 0x0;                     //disable TMR1 overflow Interrupt  
      mscale = scale;	  
      minterval =  maxTimerInterval - interval;
      T1CONbits_T1CKPS1 = scale>>1;              //prescale the timer1
      T1CONbits_T1CKPS0 = scale;
      WriteTimer1(maxTimerInterval - interval);  //write the interval into TMR1 register         
      PIE1bits_TMR1IE = 0x1;                     //enable TMR1 overflow Interrupt
      T1CONbits_TMR1ON = 0x1;                     //start  Timer1
    }
 
       return SUCCESS;
  }



  async event result_t TIMER1_Overflow.fired(){
    atomic {
      if (set_flag) {
	mscale = nextScale;
	T1CONbits_T1CKPS1 = mscale>>1;         //prescale the timer1
	T1CONbits_T1CKPS0 = mscale;
        WriteTimer1(minterval);
	set_flag=0;
      }
     }
  signal Clock.fire();
  return SUCCESS;
  }


  default async event result_t Clock.fire() { return SUCCESS; }

}
