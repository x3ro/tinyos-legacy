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
 *
 * Changed by Mads Bondo Dydensborg, <madsdyd@diku.dk>
 *
 * This file implements support for the UART1 running at 19200 8N1. 
 * This may change :-)
 *
 * Ported to 8051 by Sidsel Jensen & Anders Egeskov Petersen, 
 *                   Dept of Computer Science, University of Copenhagen
 * Date last modified: Dec 2005
 *
 */

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component.


module HPLUARTM {
  provides interface HPLUART as UART;
  uses interface Interrupt;
}

implementation {

  uint8_t *sendStart, *sendEnd;
  uint8_t mychar[2];

  task void signal_done_tsk();
  
// Uart initialization routine.
  async command result_t UART.init() {
    atomic{
  // Pins
      P0_ALT |= 0x06;
      P0_DIR |= 0x02;
  // Timer1 options  19.2 Kb/s
      TMOD &= 0x0F;	// GATE=0; CT=0; M=2
      TMOD |= 0x20;
      CKCON |= 0x10;	// T1M=1 (/4 timer clock)
      TH1 = 0xF3;	// Reload
      TL1 = TH1;
      TR1 = 1;
  // Serial		// 8 bit; No Parity; 1 stop bit
      PCON |= 0x80;	// Baud Rate = Timer1 overflow / 16
      SCON = 0x52;	// Serial mode1, enable receiver
      ES = 1;		// Enable serial interrupt
    
  // Initialize variables
      sendStart = NULL;
    }

    return SUCCESS;
  }

  async command result_t UART.stop() {
    atomic ES = 0;
    return SUCCESS;
  }

  /* Set the rate */
  async command result_t UART.setRate(int rate) {
    return SUCCESS;
  }

  default async event result_t UART.get(uint8_t data) { 
    return SUCCESS; 
  }
 
  async command result_t UART.put2(uint8_t * start, uint8_t * end) {
    bool was_sending;
     atomic { 
       if(sendStart == NULL) {
         sendStart = start;
         sendEnd = end;
         was_sending = FALSE;
       } else
         was_sending = TRUE;
     }
       if (was_sending) {
				// There's something in the send buffer
				// and we're not done sending what was in there..
         return FAIL;
       } else {
				// Enable data register empty interrupt
				// Once we get one we'll start sending
         atomic TI = 1;
         return SUCCESS;
       }
  }

  async command result_t UART.put(uint8_t data) {
    atomic mychar[0] = data;
    return call UART.put2(mychar, &mychar[1]);
  }
  
  TOSH_INTERRUPT(SIG_SERIAL) {
    char buffer;
    if(RI) {			// Receive
      atomic buffer = SBUF;
      signal UART.get(buffer);
      atomic RI = 0;
    }
    else if(TI) {		// Transmit done
      atomic {
        if (sendStart && (sendStart < sendEnd)) {
          SBUF = *(sendStart);	// Transmit the data
          sendStart++;
        } else {
          // Leave interrupt context
          post signal_done_tsk();
        }
        TI = 0;
      }
    }
  }

  /* Task posted to leave interrupt context */
  task void signal_done_tsk() {
    atomic {
      sendStart = NULL;
    }
      signal UART.putDone();
  }

}
