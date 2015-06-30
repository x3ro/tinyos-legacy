// $Id: SpiByteFifoC.nc,v 1.1.1.1 2007/11/05 19:10:08 jpolastre Exp $

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
 */
module SpiByteFifoC
{
  provides interface SpiByteFifo;
  uses interface SlavePin;
}
implementation
{
  uint8_t nextByte;
  uint8_t state;

  enum {
    IDLE,
    FULL,
    OPEN,
    READING
  };

  enum {
    BIT_RATE = 20 * 4 / 2 * 5/4
  };


  TOSH_SIGNAL(SIG_SPI) {
    uint8_t temp = inp(SPDR);
    // Assume state == FULL (we've missed a deadline and are dead if it
    // isn't...)
    outp(nextByte, SPDR);
    state = OPEN;
#ifdef CANBY
    // added these two lines to see if we can get arround the lack of wire
    // between the two pins-- Lakshman
    TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_CLR_FLASH_SELECT_PIN();
#endif /* CANBY */
    signal SpiByteFifo.dataReady(temp);
  }

  async command result_t SpiByteFifo.send(uint8_t data) {
    result_t rval = FAIL;
    atomic {
      if(state == OPEN){
	nextByte = data;	
	state = FULL;
	rval = SUCCESS;
      }
      else if(state == IDLE){
	state = OPEN;
	signal SpiByteFifo.dataReady(0);
	call SlavePin.low();
	cbi(PORTB, 7);
	sbi(DDRB, 7);
	outp(0xc0, SPCR);
	outp(data, SPDR);
	//set the radio to TX.
	TOSH_CLR_RFM_CTL0_PIN();
	TOSH_SET_RFM_CTL1_PIN();
	//start the timer.
	cbi(TIMSK, TOIE2);
	cbi(TIMSK, OCIE2);
	outp(0, TCNT2);
	outp(BIT_RATE, OCR2);
	outp(0x19, TCCR2);
	rval = SUCCESS;
      }
    }
    return rval;
  }

  async command result_t SpiByteFifo.idle() {
    atomic {
      outp(0x00, SPCR);
      outp(0x00, SPDR);
      outp(0x00, TCCR2);
      nextByte = 0;
      call SlavePin.high(FALSE);
      TOSH_MAKE_RFM_TXD_OUTPUT();
      TOSH_CLR_RFM_TXD_PIN();
      TOSH_CLR_RFM_CTL0_PIN();
      TOSH_CLR_RFM_CTL1_PIN();
      state = IDLE;
      nextByte = 0;
    }
    return SUCCESS;
  }

  async command result_t SpiByteFifo.startReadBytes(uint16_t timing) {
    uint8_t oldState;
    // This state transition is sufficient because no other
    // function can execute when in the READING state. That is,
    // except txMode() and idle(), but they only modify the RFM control
    // pins, which this function doesn't deal with. - pal
    atomic { 
      oldState = state;
      if (state == IDLE) {
	state = READING;
      }
    }
    if(oldState == IDLE){
      //		MAKE_ONE_WIRE_OUTPUT();
      //		CLR_ONE_WIRE_PIN();
      call SlavePin.low();
      outp(0x00, SPCR);
      cbi(PORTB, 7);
      sbi(DDRB, 7);
      outp(0x0, TCCR2);
      outp(0x1, TCNT2);
      outp(BIT_RATE, OCR2);
      //don't change the radio state.
      timing += (400-19);
      if(timing > 0xfff0) timing = 0xfff0;
      //set the phase of the clock line
      outp(0x19, TCCR2);
      outp(BIT_RATE - 20, TCNT2);
      while(inp(PINB) & 0x80){;}
      while(__inw(TCNT1L) < timing){outp(0x0,TCNT2);}
      outp(0xc0, SPCR);
#ifdef CANBY
      // added these two lines to see if we can get arround the lack of wire
      // between the two pins-- Lakshman
      TOSH_MAKE_FLASH_SELECT_OUTPUT();
      TOSH_CLR_FLASH_SELECT_PIN();
#endif /* CANBY */
      outp(0x00, SPDR);
      sbi(PORTB, 6);
      cbi(PORTB, 6);
      return SUCCESS;
    }
    return FAIL;
  }

  async command result_t SpiByteFifo.txMode() {
    atomic {
      TOSH_CLR_RFM_CTL0_PIN();
      TOSH_SET_RFM_CTL1_PIN();
    }
    return SUCCESS;
  }

  async command result_t SpiByteFifo.rxMode() {
    atomic {
      TOSH_CLR_RFM_TXD_PIN();
      TOSH_MAKE_RFM_TXD_INPUT();
      TOSH_SET_RFM_CTL0_PIN();
      TOSH_SET_RFM_CTL1_PIN();
#ifdef CANBY
      // added these two lines to see if we can get arround the lack of wire
      // between the two pins-- Lakshman
      TOSH_MAKE_FLASH_SELECT_OUTPUT();
      TOSH_CLR_FLASH_SELECT_PIN();
#endif
    }
    return SUCCESS;
  }
  
  async command result_t SpiByteFifo.phaseShift() {
    unsigned char f;
    atomic {
      f = inp(TCNT2);
      if(f > 20) f -= 20;
      outp(f, TCNT2);
    }
    return SUCCESS;
  }

  event result_t SlavePin.notifyHigh() {
    return SUCCESS;
  }
}
