/*
 * Copyright (c) 2002 the University of Southern California.
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
 * Authors:	Wei Ye (original S-MAC code), Tom Parker (modifications for T-MAC)
 * 
 * UART debugging: this component is for sending debugging bytes thru UART
 *   Note: can't be used with any application that uses the UART, e.g. motenic
 *
 */

/**
 * @author Wei Ye
 * @author Tom Parker
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
		// Set 57.6 KBps
		outp(0,UBRR0H); 
		outp(15, UBRR0L);

		// Set UART double speed
		outp((1<<U2X),UCSR0A);

		// Set frame format: 8 data-bits, 1 stop-bit
		outp(((1 << UCSZ1) | (1 << UCSZ0)) , UCSR0C);

		// Enable reciever and transmitter and their interrupts
		outp(((1 << RXCIE) | (1 << TXCIE) | (1 << RXEN) | (1 << TXEN)) ,UCSR0B);
	   // suppose global interrupt is enabled
	   return SUCCESS;
	}

	async command result_t ByteComm.txByte(uint8_t byte)
	{
		char prev = inp(SREG) & 0x80;
		cli();
		if(prev) sei();
		// send byte to UART
		outp(byte, UDR0); 
		sbi(UCSR0A, TXC);
		return SUCCESS;
	}


	TOSH_INTERRUPT(SIG_UART0_TRANS) {
	   // UART is able to send next byte
	   // This interrupt handler is using the INTERRUPT macro, in which 
	   // the global interrupt is enabled, so the interrupt handler can
	   // be interrupted too.
	   signal ByteComm.txDone();
	}

	TOSH_SIGNAL(SIG_UART0_RECV) {
	    if (inp(UCSR0A) & (1 << RXC))
		{
			uint8_t data;
			data = inp(UDR0);
	   		signal ByteComm.rxByteReady(data,FALSE,0);
		}
	   return;
	}

#else
	command result_t StdControl.init() {return SUCCESS;}
	async command result_t ByteComm.txByte(uint8_t byte) {return SUCCESS;}
#endif  // UART_DEBUG_ENABLE
}
