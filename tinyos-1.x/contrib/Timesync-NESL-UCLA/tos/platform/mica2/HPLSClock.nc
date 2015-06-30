/* -*-C-*- */
/**********************************************************************
Copyright ©2003 The Regents of the University of California (Regents).
All Rights Reserved.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose, without fee, and without written 
agreement is hereby granted, provided that the above copyright notice 
and the following three paragraphs appear in all copies and derivatives 
of this software.

IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE 
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF 
CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, 
ENHANCEMENTS, OR MODIFICATIONS.

This software was created by Ram Kumar {ram@ee.ucla.edu}, 
Saurabh Ganeriwal {saurabh@ee.ucla.edu} at the 
Networked & Embedded Systems Laboratory (http://nesl.ee.ucla.edu), 
University of California, Los Angeles. Any publications based on the 
use of this software or its derivatives must clearly acknowledge such 
use in the text of the publication.
**********************************************************************/
/****************************************************************
 Description: The hardware abstraction layer for the AVR Timer3. This
 component also maintains the global time data-strucutre and is used
 by the TPSN middleware component for time-synchronization.
 *****************************************************************/

module HPLSClock {
  provides interface SClock;
  provides interface StdControl;
}

implementation
{
  uint16_t MTicks;
  GTime Update;
  uint8_t sign;
  uint8_t needupdate;

  /********* Interface StdControl *************/
  command result_t StdControl.init(){
    return SUCCESS;
  }

  command result_t StdControl.stop(){
    call SClock.SetRate(MAX_VAL, CLK_STOP);
    return SUCCESS;
  }

  command result_t StdControl.start(){
    call SClock.SetRate(MAX_VAL, CLK_STOP);
  }

  
  /******** Interface SClock **************/
  async command result_t SClock.SetRate(uint16_t interval, char scale){
    scale &= 0x7; /* Clears all the bits except the last three scale bits */
    scale |= 0x8; /* Sets the WGM32 bit in Timer3 register B */
    atomic{
      cbi(ETIMSK, OCIE3A); /* Disable the output compare match interrupt */
      TCCR3B = scale; /* Assign the scale and the WGM32 bit in Timer3 register B */
      TCNT3 = 0x0000;/* Clear the Timer3 counter register */
      OCR3A = interval; /* Setting the value of the output compare register A for Timer 3 */
      TCCR3A = 0x00;
      TCCR3A |= (1 << COM3A0); /* Toggle on Output Compare Match A */
      DDRE |= (1 << DDE3);  /* Set the OC3A pin to output */
      TCCR3C = 0x00;
      sbi(ETIMSK, OCIE3A);
    }
    needupdate = 0;
    return SUCCESS;
  }

  async command uint16_t SClock.readCounter(){
    return TCNT3;
  }

  async command result_t SClock.setCounter(uint16_t n){
    atomic{
      TCNT3 = n;
    }
    return SUCCESS;
  }

  async command void SClock.getTime(GTime* t){
    atomic{
      t->sticks = TCNT3;
      if (bit_is_set(ETIFR, OCF3A)){ /* Check if there is any pending interrupt */
	MTicks++;
	ETIFR |= (1 << OCF3A); /*  Writing a logic one to the flag will clear the pending interrupt  */
	signal SClock.fire(MTicks);
      }
      t->mticks = MTicks;
    }
  }

  async command void SClock.setTime(uint8_t PosOrNeg, GTime* t){
    sign = PosOrNeg;
    Update.mticks = t->mticks;
    Update.sticks = t->sticks;
    needupdate = 1;
  }

  async command void SClock.intEnable(){
    cbi(ETIMSK, OCIE3A);
  }
  
  async command void SClock.intDisable(){
    sbi(ETIMSK, OCIE3A);
  }
  
  default async event result_t SClock.syncDone(){return SUCCESS;}
  default async event result_t SClock.fire(uint16_t mTicks){return SUCCESS;}
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE3A){
    if (needupdate){
      if (sign == NEGATIVE){
	TCNT3 = MAX_VAL - Update.sticks;
	MTicks = MTicks - Update.mticks; /* We do not need to subtract 1 as 1 is being added already and we have omitted it */
      }
      else if (sign == POSITIVE){
	TCNT3 = Update.sticks;
	MTicks = MTicks + Update.mticks + 1;
	signal SClock.fire(MTicks);
      }
      needupdate = 0;
      signal SClock.syncDone();
    }
    else{
      MTicks++;
      signal SClock.fire(MTicks);
    }
  }
}
