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

/* Authors:		Fred Jiang
 * Revision:		$Id: HPLUARTM.nc,v 1.1.1.1 2007/11/05 19:10:06 jpolastre Exp $
 *
 */

module HPLUARTM {
  provides interface HPLUART as UART;

}
implementation
{
  async command result_t UART.init() {

    atomic { 
      outp(0, UBRRH);
      outp(12, UBRRL); //set the baud rate generator register (4800 baud) or 9600 baud
      //if U2X 
      inp(UDR); //read the uart data received register to invalidate frame error and parity error flags
      
      // Set UART single  speed if 0 and double speed if 1
      outp((1<<U2X),UCSRA);
      
      // Set frame format: 8 data-bits, 1 stop-bit
      outp(((3 << UCSZ0) | (1 << URSEL)) , UCSRC);
      
      // Enable reciever and transmitter and their interrupts
      outp(((1 << RXCIE) | (1 << TXCIE) | (1 << RXEN) | (1 << TXEN)) ,UCSRB);
      
    }
    
    TOSH_SET_UART_RXD_PIN();//use pull-up resister on transmit line to make it hight when idle
    return SUCCESS;
  }
  
  async command result_t UART.stop() {
    outp(0x00, UCSRA);
    outp(0x00, UCSRB);
    outp(0x00, UCSRC);
  }
  
  default async event result_t UART.get(uint8_t data) { return SUCCESS; }
  TOSH_SIGNAL(SIG_UART_RECV) {
    if (inp(UCSRA) & 0x80)
      signal UART.get(inp(UDR));
  }
  
  default async event result_t UART.putDone() { return SUCCESS; }
  TOSH_INTERRUPT(SIG_UART_TRANS) {
    signal UART.putDone();
  }
  
  async command result_t UART.put(uint8_t data) {
    outp(data, UDR); 
    sbi(UCSRA, TXC);
    return SUCCESS;
  }
}


