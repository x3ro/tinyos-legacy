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
 */

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component
module HPLRFMC {
  provides interface HPLRFM as RFM;
}
implementation
{
  default event result_t RFM.bitEvent() { return SUCCESS; }
  TOSH_SIGNAL(SIG_OUTPUT_COMPARE1A) {
    signal RFM.bitEvent();
  }

  command uint8_t RFM.rxBit() {
    return TOSH_READ_RFM_RXD_PIN();
  }

  command result_t RFM.txBit(uint8_t data) {
    //set the output pin accordingly.
    if (data & 0x01)
      TOSH_SET_RFM_TXD_PIN();
    else
      TOSH_CLR_RFM_TXD_PIN();
    return SUCCESS;
  }

  command result_t RFM.powerOff() {
    TOSH_CLR_RFM_CTL0_PIN();
    TOSH_CLR_RFM_CTL1_PIN();
    return SUCCESS;
  }

  command result_t RFM.disableTimer() {
    // disable timer1 interupt
    outp(0x00, TCCR1B); // scale the counter
    cbi(TIMSK, OCIE1A); 
    return SUCCESS;
  }

  command result_t RFM.enableTimer() {
    outp(0x09, TCCR1B); // scale the counter
    sbi(TIMSK, OCIE1A); 
    return SUCCESS;
  }

  command result_t RFM.txMode() {
    TOSH_SET_RFM_CTL0_PIN();
    TOSH_CLR_RFM_CTL1_PIN();
    return SUCCESS;
  }

  command result_t RFM.rxMode() {
    TOSH_SET_RFM_CTL0_PIN();
    TOSH_SET_RFM_CTL1_PIN();
    TOSH_CLR_RFM_TXD_PIN();
    return SUCCESS;
  }

  command result_t RFM.setBitRate(uint8_t level) {
    switch (level)
      {
      case 0:
	outp(0x00, OCR1AH); // set upper byte of comp reg.
	outp(0xc8, OCR1AL); // set the lower byte compare
	outp(0x00, TCNT1H); // clear current counter value
	outp(0x00, TCNT1L); // clear current couter high byte value
	break;

      case 1:
	outp(0x01, OCR1AH); // set upper byte of comp reg.
	outp(0x2c, OCR1AL); // set the lower byte compare
	break;

      case 2:
	outp(0x01, OCR1AH); // set upper byte of comp reg.
	outp(0x90, OCR1AL); // set the lower byte compare
	break;
      }
    return SUCCESS;
  }


  command result_t RFM.init() {
    //set the RFM pins.
    call RFM.rxMode();

    cbi(TIMSK, OCIE1A); //clear interrupts
    cbi(TIMSK, TICIE1); //clear interrupts
    cbi(TIMSK, TOIE1);  //clear interrupts
    cbi(TIMSK, OCIE1B); //clear interrupts
    outp(0x09, TCCR1B); // scale the counter
    outp(0x00, TCCR1A);
    outp(0x00, OCR1AH); // set upper byte of comp reg.
    outp(0xc8, OCR1AL); // set the lower byte compare
    sbi(TIMSK, OCIE1A); // enable timer1 interupt
    outp(0x00, TCNT1H); // clear current counter value
    outp(0x00, TCNT1L); // clear current couter high byte value
    sei(); //enable system interrupts.
    return SUCCESS;
  }
}
