/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
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
 * Authors:		Sarah Bergbreiter
 * Date last modified:  9/4/02
 *
 */

module HPLUARTM {
  provides interface HPLUART as UART;
}
implementation
{
  async command result_t UART.init() {
    cli();
    outp(12, UBRRL);
    inp(UDR);
    outp(0xd8,UCSRB);
    outp(0x86,UCSRC);
    sbi(UCSRA, U2X);
    TOSH_SET_UART_RXD_PIN();
    sei();
    return SUCCESS;
  }

  async command result_t UART.stop() {
      outp(0x00, UCSRB);
      return SUCCESS;
  }

  default async event result_t UART.get(uint8_t data) { return SUCCESS; }
  TOSH_SIGNAL(SIG_UART_RECV) {
    if (inp(UCSRA) & 0x80) {
      signal UART.get(inp(UDR));
    }
  }

  default async event result_t UART.putDone() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_UART_TRANS) {
    signal UART.putDone();
  }

  async command result_t UART.put(uint8_t data) {
    // What is this doing -- why clear TX complete flag?????
    sbi(UCSRA, TXC);
    outp(data, UDR); 
    return SUCCESS;
  }
}

