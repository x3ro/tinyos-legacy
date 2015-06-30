//$Id: HPLTimer1M.nc,v 1.2 2004/09/29 18:54:56 jdprabhu Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/****************************************************************************
ATmega128 TIMER1 Services

****************************************************************************/

includes HPLTimer1;

module HPLTimer1M
{
  provides interface StdControl;
  provides interface Clock16 as Timer1;
//  provides interface TimerControl as ControlT1;
//  provides interface TimerCompare as CompareT1;
  provides interface TimerCapture as CaptureT1;

}
implementation
{

//Standard TOS Timer Interface implmentation
    uint8_t set_flag;
    uint8_t mscale, nextScale;
    uint16_t minterval ;

    command result_t StdControl.init() {
      atomic {
		mscale = TCLK_CPU_DIV256; 
		minterval = TIMER1_DEFAULT_INTERVAL;
      }
      return SUCCESS;
    }

    command result_t StdControl.start() {
      uint16_t mi;
      uint8_t  ms;
      atomic {
		mi = minterval;
		ms = mscale;
      }
      call Timer1.setRate(mi, ms);
      return SUCCESS;
    } //start

    command result_t StdControl.stop() {
      uint16_t mi;
      atomic {
		mi = minterval;
      }
      call Timer1.setRate(mi, 0);	   //default scale=0=OFF
      return SUCCESS;
    }


    async command void Timer1.setInterval(uint16_t value) {
        atomic outw(OCR1A,value);	 //defined in  local/avr/include/avr/sfr_defs.h
    } 
    async command void Timer1.setNextInterval(uint16_t value) {
      atomic {
	minterval = value;
	set_flag = 1;
      }
    }				  

    async command uint16_t Timer1.getInterval() {
		uint16_t i;
		atomic i = inw(OCR1AL);
        return i;
    }

    async command uint8_t Timer1.getScale() {
      uint8_t ms;
		atomic {
		ms = mscale;
		}
      return ms;
    }

    async command void Timer1.setNextScale(uint8_t scale) {
      atomic {
	nextScale= scale;
        set_flag=1;
      }
    }
       

    async command result_t Timer1.setIntervalAndScale(uint16_t interval, uint8_t scale) {
        
        if (scale >7) return FAIL;
        scale|=0x8;		//set Clear on Timer Compare
	atomic {
	  outp(0, TCCR1A);	  //stop the timer
		cbi(TIMSK, OCIE1A);	 //disable output compare
		cbi(TIMSK, TOIE1);  //disable Overflow interrupts
		cbi(TIMSK, TICIE1);	 //clear input capture
		mscale = scale;
		minterval = interval;
		outp(0,TCCR1A);	//normal operation
		outw(TCNT1L,0);		 //clear the 16bit count 
		outw(OCR1AL, interval);//set the compare value
		sbi(TIFR,OCF1A);	//clear Timer1A OCF flag by writing 1
		sbi(TIMSK, OCIE1A);	  //enable OCIE1A interrupt
		outp(scale, TCCR1B);	 //starts the timer with scale
	}
    return SUCCESS;
    } //setIntervalandScale

  async command result_t Timer1.setRate(uint16_t interval, char scale) {
   //same as .setIntervalAndScale but does not set mscale/minterval
   //Do NOT enable INTERRUPT
    scale &= 0x7;
    scale |= 0x8;
    atomic {
	  outp(0, TCCR1A);	  //stop the timer's clock
		cbi(TIMSK, OCIE1A);	 //disable output compare
		cbi(TIMSK, TOIE1);  //disable Overflow interrupts
		cbi(TIMSK, TICIE1);	 //clear input capture
		outw(TCNT1L,0);		 //clear the 16bit count 
		outw(OCR1AL, interval);//set the compare value
		sbi(TIFR,OCF1A);	//clear Timer1A OCF flag by writing 1
//		sbi(TIMSK, OCIE1A);	  //enable OCIE1A interrupt
		outp(scale, TCCR1B);	 //starts the timer with scale
    }//atomic
    return SUCCESS;
  }

        
    async command uint16_t Timer1.readCounter() {
		uint16_t i;
		atomic i = inw(TCNT1L);
        return (i );  //read time count
    }

    async command void Timer1.setCounter(uint16_t n) {
        outw(TCNT1L,n);
    }


    async command void Timer1.intEnable() {
	sbi(TIMSK, OCIE1A); // enable timer1 interupt
}
    async command void Timer1.intDisable() {
	cbi(TIMSK, OCIE1A); // disable timer1 interupt
}


  default async event result_t Timer1.fire() { return SUCCESS; }

  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE1A) {
    atomic {
	if (set_flag) {
		mscale = nextScale;
		nextScale|=0x8;
		outp(nextScale, TCCR1B);  //update the clock scale
		outw(OCR1AL, minterval); //update the compare value
		set_flag=0;
		}
    }  //set
    signal Timer1.fire();
  }

//TimerControl & TimerCapture Interface implementation 

  default async event void CaptureT1.captured(uint16_t time) { }
 // default async event void Timer1.overflow() { }


//CAPTURE Mode related functions

  /**
   * Set the edge that the capture should occur
   ****************************************************************/
  async command void CaptureT1.setEdge(uint8_t LowToHigh) {
  //set edge mode

  if( LowToHigh )
   sbi(TCCR1B,ICES1);	//rising edge
  else
   cbi(TCCR1B,ICES1);	//falling edge

//Set InputCapture pin PortD pin4 as INPUT
//  TOSH_MAKE_CC_SFD_INPUT();
  
  sbi(TIFR, ICF1);	//clear any pending interrupt
  return;
  }

/**
Not applicable
*****************************************************************************/
  async command void CaptureT1.setSynchronous(bool synch) {
  return;
  }

/**
   * Determine if a capture overflow is pending.
*****************************************************************************/
  async command bool CaptureT1.isOverflowPending() {
   return( inp(TIFR) & TOV1 );
    }
  

  /**
   * Reads the value of the last capture event in TxCCRx
   */
  async command uint16_t CaptureT1.getEvent() {
  uint16_t i;
  atomic i = inw(ICR1L);
   return (i);
   }

/**
   * Clear the capture overflow flag for when multiple captures occur
*****************************************************************************/
  async command void CaptureT1.clearOverflow() {
   sbi(TIFR,TOV1);
   return;
   }

/**
   * Clear the capture interrupt flag for when multiple captures occur
*****************************************************************************/
  async command void CaptureT1.clearPendingInterrupt() {
  sbi(TIFR, ICF1);	//clear any pending interrupt
   return;
   }

/**
Enable interrupt on capture
*****************************************************************************/
  async command void CaptureT1.enableEvents() {
  //put TIMER into Normal, capture mode
   cbi(TCCR1B,WGM13);
   cbi(TCCR1B,WGM12);
   sbi(TIMSK, TICIE1);
   }

/**
Disable interrupt on capture
*****************************************************************************/
  async command void CaptureT1.disableEvents() {
   cbi(TIMSK, TICIE1); //disable
   sbi(TIFR, ICF1);	//clear any pending interrupt
  }

/**
*****************************************************************************/
  async command bool CaptureT1.areEventsEnabled() { 
  return (inp(TIMSK) & TICIE1);
   }

/**
INPUT CAPTURE Interrupt Service Routine
   * Signal when an event is captured.
*****************************************************************************/

  TOSH_SIGNAL(SIG_INPUT_CAPTURE1)
  {	  
      signal CaptureT1.captured(call CaptureT1.getEvent());

  }
//******************************************************************

#ifdef COMPARE
//Count Compare Mode 

  async command uint16_t CompareT1.getEvent() {  }


  async command void CompareT1.setEvent( uint16_t x ) { }

  async command void CompareT1.setEventFromPrev( uint16_t x ) { }

  async command void CompareT1.setEventFromNow( uint16_t x ) {  }

  default async event void CompareT1.fired() { }

#endif


}//HPLTimer1M.nc

