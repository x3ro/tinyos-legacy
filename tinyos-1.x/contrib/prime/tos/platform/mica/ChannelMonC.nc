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
 */

module ChannelMonC {
  provides interface ChannelMon;
  uses {
    interface Random;
  }
}
implementation {
  enum {
    IDLE_STATE,
    START_SYMBOL_SEARCH,
    PACKET_START,
    DISABLED_STATE
  };

  enum {
    SAMPLE_RATE = 100/2*4
  };

  unsigned short CM_search[2];
  char CM_state;
  unsigned char CM_lastBit;
  unsigned char CM_startSymBits;
  short CM_waiting;

  async command result_t ChannelMon.init() {
    atomic {
      CM_waiting = -1;
    }
    return call ChannelMon.startSymbolSearch();
  }
  
  async command result_t ChannelMon.startSymbolSearch() {
    atomic {
      //Reset to idle state.
      CM_state = IDLE_STATE;
      //set the RFM pins.
      TOSH_SET_RFM_CTL0_PIN();
      TOSH_SET_RFM_CTL1_PIN();
      TOSH_CLR_RFM_TXD_PIN();
#ifdef CANBY
      // added these two lines to see if we can get arround the lack of wire
      // between the two pins-- Lakshman
      TOSH_MAKE_FLASH_SELECT_OUTPUT();
      TOSH_CLR_FLASH_SELECT_PIN();
#endif /* CANBY */
      cbi(TIMSK, OCIE2); //clear interrupts
      cbi(TIMSK, TOIE2);  //clear interrupts
      cbi(TIMSK, OCIE2); //clear interrupts
      outp(0x09, TCCR2); //scale the counter
      outp(SAMPLE_RATE, OCR2); // set upper byte of comp reg.
      sbi(TIMSK, OCIE2); // enable timer1 interupt
      outp(0x00, TCNT2); // clear current counter value
      sbi(DDRB, 6);
    }
    return SUCCESS;
  }



  TOSH_SIGNAL(SIG_OUTPUT_COMPARE2) {
    uint8_t bit = TOSH_READ_RFM_RXD_PIN();
    atomic { // Unnecessary, but nesC doesn't understand SIGNAL
      //fire the bit arrived event and send up the value.
      if (CM_state == IDLE_STATE) {
	CM_search[0] <<= 1;
	CM_search[0] = CM_search[0] | (bit & 0x1);
	if(CM_waiting != -1){
	  CM_waiting --;
	  if(CM_waiting == 1){
	    if ((CM_search[0] & 0xfff) == 0) {
	      CM_waiting = -1;
	      signal ChannelMon.idleDetect();
	    }else{
	      CM_waiting = (call Random.rand() & 0x1f) + 30;
	    } 
	  }
	}
	if ((CM_search[0] & 0x777) == 0x707){
	  CM_state = START_SYMBOL_SEARCH;
	  CM_search[0] = CM_search[1] = 0;
	  CM_startSymBits = 30;
	}
      }else if(CM_state == START_SYMBOL_SEARCH){
	unsigned int current = CM_search[CM_lastBit];
	CM_startSymBits--;
	if (CM_startSymBits == 0){
	  CM_state = IDLE_STATE;
	}
	if (CM_state != IDLE_STATE) {
	  current <<= 1;
	  current &=  0x1ff;  // start symbol is 9 bits
	  if(bit) current |=  0x1;  // start symbol is 9 bits
	  if (current == 0x135) {
	    cbi(TIMSK, OCIE2); 
	    CM_state = IDLE_STATE;
	    signal ChannelMon.startSymDetect();
	  }
	  if (CM_state != IDLE_STATE) {
	    CM_search[CM_lastBit] = current;
	    CM_lastBit ^= 1;
	  }
	}
      }
    }
    return;
  }

  async command result_t ChannelMon.stopMonitorChannel() {
    //disable timer
    atomic {
      cbi(TIMSK, OCIE2); 
      CM_state = DISABLED_STATE;
    }
    return SUCCESS;
  }

  async command result_t ChannelMon.macDelay() {
    atomic {
      CM_search[0] = 0xff;
      if(CM_waiting == -1) {
	CM_waiting = (call Random.rand() & 0x2f) + 80;
      }
    }

    return SUCCESS;
  }
}
