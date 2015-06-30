/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 */

module UARTLL
{
	provides interface ByteComm;
	provides interface StdControl;
}

implementation
{
	command result_t StdControl.start() {return SUCCESS;}
	command result_t StdControl.stop() {return SUCCESS;}
#ifdef ENABLE_UART_DEBUG
	command result_t StdControl.init()
	{
	   // initialize UART
	   outp(12, UBRR);
	   inp(UDR); 
	   outp(0xd8,UCR);
	   TOSH_SET_UART_RXD0_PIN();
	   // suppose global interrupt is enabled
	   return SUCCESS;
	}


	async command result_t ByteComm.txByte(uint8_t byte)
	{
		char prev = inp(SREG) & 0x80;
		cli();
		if(prev) sei();
		// send byte to UART
		sbi(USR, TXC);
		outp(byte, UDR); 
		return SUCCESS;
	}


	TOSH_INTERRUPT(SIG_UART_TRANS) {
	   // UART is able to send next byte
	   // This interrupt handler is using the INTERRUPT macro, in which 
	   // the global interrupt is enabled, so the interrupt handler can
	   // be interrupted too.
	   signal ByteComm.txDone();
	}

#else
	command result_t StdControl.init() {return SUCCESS;}
	async command result_t ByteComm.txByte(uint8_t byte) {return SUCCESS;}
#endif  // UART_DEBUG_ENABLE
}

