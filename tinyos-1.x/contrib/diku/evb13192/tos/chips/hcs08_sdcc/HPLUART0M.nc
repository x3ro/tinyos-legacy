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
 * Based on HPLBTUARTM.nc by:
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Changed by Mads Bondo Dydensborg, <madsdyd@diku.dk>, 2002-2004
 *
 * Ported from btnode to evb13192 */



/** 
 *
 * Implementation of serial support for the evb 13192 board.
 *
 * <p>Note, the evb13192 have the RS232 port on SCI1, and the USB port
 * (through the FTDI chip) on SCI2.</p>
 * 
 * <p>This module assumes an 8 MHz BUSCLK (16MHz CPUCLK/ICGOUT).</p>
 */

// To use SCI1: s/SCI2/SCI1/;

module HPLUART0M {
	provides interface HPLUART as UART;
	// uses interface Interrupt;
}
implementation
{
	volatile norace uint8_t *sendStart, *sendEnd;
	uint16_t sendNext, sendCount;
	uint8_t mychar[2];
	volatile norace bool isSending = FALSE;

	task void signal_done_tsk();
  
	/** 
	 * Uart initialization routine.
	 *
	 * <p>Sets up the parameters of the UART. Note, that a 8 MHz BUSCLK
	 * is assumed.</p>
	 * 
	 * <p>Section numbers in () refers to MC9S08GB60 Data Sheet.</p>
	 *
	 * @return SUCCESS always
	 */
	async command result_t UART.init()
	{
		atomic
		{
			// Set baud rate (Section 11.10.1):
			// SCI2BD = BUSCLK/(16*baudrate) 
			// baudrate =
//#ifdef ENVIRONMENT_USESMAC
			SCI2BDH = 0x00;
			SCI2BDL = 0x0D; // d = 38400 @ 8MHz BUSCLK (0C)
//			#warning INFO: Uses SimpleMac clock
//#else
//			#warning No precise clock. Uart will only support 300 baud
//			SCI2BDH = 0x06; // 300 @ 8MHz BUSCLK
//			SCI2BDL = 0x82;
//#endif

			// SCI2BDH = 0x00; // 19200 @ 8MHz ?? 
			// SCI2BDL = 0x1A;

			// Set the SCI2 control register (Section 11.10.3)
			// b7 : Disable interrupt on transmit TDRE (will be enabled by put)
			// b6 : Hardware interrupts from TC disabled
			// b5 : Receiver interrupt enable RDRF
			// b4 : IDLE disable
			// b3 : TE - Transmitter enable
			// b2 : RE - Receiver enable
			// b1 : Wakeup disable
			// b0 : SBK disable
      
			SCI2C2 = 0x2C; // 00101100;
      
			// TODO: Do we need to set pin directions?
			// TOSH_SET_UART_RXD0_PIN();
      
			// Initialize variables
			sendStart = NULL;
		}
		return SUCCESS;
	}

	// Stop the UART - must init again to start it...
	async command result_t UART.stop()
	{
		SCI2BDH = 0x00;
		SCI2BDL = 0x00;
		SCI2C2  = 0x00;
		return SUCCESS;
	}

#ifdef SUPPORT_RATE_CHANGE_NONONO
	async command result_t BTUART.setRate(int rate)
	{
		// Since putPacket now signals that the char in the buffer
		// has moved into the shift register it means that we have to wait
		// a while untill the final byte in the register has been sent..

		// Wait for the last char in the buffer to be sent
		while ( ! ( UCSR0A & (1<<UDRE)));

		switch (rate) {
			case 0: {
				outp(0, UBRR0L); // 460.8 on target platform
				outp(0, UBRR0H);
				break;
			}
			case 1: {
				outp(1, UBRR0L); // 230.4 on target platform
				outp(0, UBRR0H);
				break;
			}
			case 2: {
				outp(3, UBRR0L); // 115.2 on target platform
				outp(0, UBRR0H);
				break;
			}
			default: {
				outp(7, UBRR0L); // 56.7 on target platform
				outp(0, UBRR0H);
			}
		}
		return SUCCESS;
	}
#endif
  
	/** Default get event.
	 * 
	 * <p>I do not think default events work at all.</p>
	 */
	default async event result_t UART.get(uint8_t uartData) { return SUCCESS; }
  
	/**
	 * Interrupt handler for receiving a byte.
	 * 
	 * <p>Note, the documentation is a bit unclear about the causes for
	 * this interrupt. I am pretty sure it will only trigger for RDRF,
	 * so the check in SCI2S1 may seem unneccessary. However, we have to
	 * read it anyway in order to clear the flag, so its only about a
	 * couple of instructions more.</p>
	 * 
	 * <p>The SMAC example code actually loops while testing this
	 * bit...</p>
	 */
	TOSH_SIGNAL(SCI2RX)
	{
		// Test for RDRF
		if (SCI2S1_RDRF) {
		//if (0x20 & SCI2S1) {
			// Set, there is data, otherwise it was probably an error.
			signal UART.get(SCI2D);
		}
	}
	
	/** Default putDone event.
	 * 
	 * <p>I do not think default events work at all.</p>
	 */
	default async event result_t UART.putDone() { return SUCCESS; }

	/* Put command, call put2 */
	command async result_t UART.put(uint8_t uartData)
	{
		atomic mychar[0] = uartData;
		return call UART.put2(mychar, &mychar[1]);
	}

	/* Put2 command */
	command async result_t UART.put2(uint8_t * start, uint8_t * end)
	{
		bool wasSending;
		atomic
		{
			wasSending = isSending;
			isSending = TRUE;
		}
		if (wasSending) {
			// There's something in the send buffer
			// and we're not done sending what was in there..
			return FAIL;
		} else {
			// Channel is clear to send.
			atomic {
				sendStart = start;
				sendEnd = end;
				// Enable data register empty interrupt
				// Once we get one we'll start sending
				// TODO: The order of interrupts... or tons of interrupts, or?
				SCI2C2_TIE = 1;
			}
			return SUCCESS;
		}
	}

	/* We get an interrupt, if there is room for data. */
	TOSH_SIGNAL(SCI2TX)
	{			
		// TODO: May be safer just to assume that it is a TDRE?
		if (SCI2S1_TDRE) { // Check that this was a TDRE interrupt
			// Disable interrupt.
			SCI2C2_TIE = 0;	
			if (isSending && sendStart < sendEnd) {
				SCI2D = *(sendStart);
				sendStart++;
				SCI2C2_TIE = 1;
			} else {
				// Free channel.
				isSending = FALSE;
				// Leave interrupt context
				post signal_done_tsk();
			}
		}
		
	}

	/* Task posted to leave interrupt context */
	task void signal_done_tsk()
	{
		signal UART.putDone();
	}
}
