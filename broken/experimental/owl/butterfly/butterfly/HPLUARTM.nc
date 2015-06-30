// $Id: HPLUARTM.nc,v 1.1 2003/10/14 19:09:24 idgay Exp $

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
 * Date last modified:  $Id: HPLUARTM.nc,v 1.1 2003/10/14 19:09:24 idgay Exp $
 *
 */

// The hardware presentation layer. 

// The model is that HPL is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component


/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */
module HPLUARTM {
  provides interface HPLUART as UART;

}
implementation
{
  async command result_t UART.init() {
    // 4800 baud (1MHz clock)
    outp(0, UBRR0H);
    outp(12, UBRR0L);
    inp(UDR0); 
    // async, 8 bits, no parity, 1 stop bit
    outp(0, UCSR0A);
    outp(1 << RXCIE0 | 1 << TXCIE0 | 1 << RXEN0 | 1 << TXEN0, UCSR0B);
    outp(3 << UCSZ01, UCSR0C);
    TOSH_SET_UART_RXD0_PIN();

    return SUCCESS;
  }

  async command result_t UART.stop() {
      outp(0x00, UCSR0B);
      return SUCCESS;
  }

  default async event result_t UART.get(uint8_t data) { return SUCCESS; }
  TOSH_SIGNAL(SIG_UART_RECV) {
    if (inp(UCSR0A) & (1 << RXC0))
      signal UART.get(inp(UDR0));
  }

  default event async result_t UART.putDone() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_UART_TRANS) {
    signal UART.putDone();
  }

  command async result_t UART.put(uint8_t data) {
    sbi(UCSR0A, TXC0);
    outp(data, UDR0); 
    return SUCCESS;
  }
}
