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


 * Changed by Mads Bondo Dydensborg, <madsdyd@diku.dk>
 * Lots of cleanup needed.

 * This file implements support for the UART1 running at 19200 8N1. 
 * This may change :-)

 *
 */

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component

/* Note: The btnode2_2 uses uart 0 to connect to the Bluetooth module, and
   uart 1 to connect externally. 
   uart 0 is mapped to PE0 = RXD0, PE1 = TXD0,
   uart 1 is mapped to PD2 = RXD1, PD3 = TXD1.
 
   The code below currently only maps uart 1, as this is the one we need for
   external communication */


module HPLUARTM {
  provides interface HPLUART as UART;
  uses interface Interrupt;
}
implementation
{

  /** 
      Uart initialization routine.
  */
  async command result_t UART.init() {
    /* UART 0 (currently not enabled)
       is connected to the bluetooth hardware.

       Setting the baud rate (bps, really).
       This is documented in the datasheet for the atmega128l on 
       page 172.

       The registers used are
       UBBR0L and UBBR0H.

       Table 83 on page 190 (82 on 191/192) of the datasheet:

       (Note, currently our stk 500's run at 3.6864, but the 
       btnodes run at 7.3728!)

       bps      UBBRL (3.6864)   UBBRL (7.3728)
       19.2k      11
       28.8k       7
       38.4k                       11
       57.6k       3                 7

       The default value in SmartIts for UART0 is  7@7.3728 == 57.6k  
       The default value in TinyOS UART1 is       11@3.6864 == 19.2k
       (well, it is 12, but I think that is for a slightly higher clock, 
       4MHz == 19.2 (+0.2%).. hmmm).

    */

    /*
      uart 1 is mapped to PD2 = RXD1, PD3 = TXD1.

      it is set to 7 - see table above.
      
    */
    // outp(3, UBRR1L); // 56.7 on stk500

    //outp(7, UBRR1L); // 56.7 on target platform
    //outp(0, UBRR1H);
    
    // For some reason this works better for me!?
    call UART.setRate(3);

    // From the SmartIts code... ... hmm
    /* Temp outcommented at it does not seem to work....
    // enable RX complete interrupt
    outp(inp(UCSR1B)|(1<<RXCIE), UCSR1B);
    // enable receiver
    outp(inp(UCSR1B)|(1<<RXEN), UCSR1B);
    // enable transmitter
    outp(inp(UCSR1B)|(1<<TXEN), UCSR1B);
    */
    // TinyOS:
   inp(UDR1); 
   //outp(0xd8,UCSR1B); // Receive and transmit enabled, enable interrupts
   outp(1<<RXCIE | 1<<TXCIE | 1<<RXEN | 1<<TXEN,UCSR1B);   

   TOSH_SET_UART_RXD1_PIN();
   //   call Interrupt.enable();
   return SUCCESS;
  }

  async command result_t UART.stop() {
    return SUCCESS;
  }

  /* Set the rate */
  async command result_t UART.setRate(int rate) {
    // TODO: This really depends on the clockrate! Wont work on the
    // stk platform currently...
    switch (rate) {
    case 0: {
      outp(0, UBRR1L); // 460.8 on target platform
      outp(0, UBRR1H);
      break;
    }
    case 1: {
      outp(1, UBRR1L); // 230.4 on target platform
      outp(0, UBRR1H);
      break;
    }
    case 2: {
      outp(3, UBRR1L); // 115.2 on target platform
      outp(0, UBRR1H);
      break;
    }
    default: {
      outp(7, UBRR1L); // 56.7 on target platform
      outp(0, UBRR1H);
    }
    }
    
    return SUCCESS;
  }


  TOSH_SIGNAL(SIG_UART1_DATA) {
       //cbi(UCSR0A, UDRE); // Clear UDRE flag - no data ready
       cbi(UCSR0B, UDRIE);
  }

  /* Get a byte, signal */
  default async event result_t UART.get(uint8_t data) { return SUCCESS; }
  TOSH_SIGNAL(SIG_UART1_RECV) {
    if (inp(UCSR1A) & 0x80)
      signal UART.get(inp(UDR1));
  }

  default async event result_t UART.putDone() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_UART1_TRANS) {
    signal UART.putDone();
  }

  async command result_t UART.put(uint8_t data) {
    sbi(UCSR1A, TXC);
    outp(data, UDR1); 
    return SUCCESS;
  }
}
