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
 * @author Jan Flora <janflora@diku.dk>
 */

module HPLUART1M {
	provides interface HPLUART as UART;
}

#define UART_BUFFER_SIZE 50

implementation
{
	// The buffer used to buffer UART data into.
	char buffer[UART_BUFFER_SIZE];
	uint16_t bufferHead = 0;
	uint16_t bufferCount = 0;
	const uint16_t bufferSize = UART_BUFFER_SIZE;

	bool bufferFull = FALSE;
	bool is_sending = FALSE;
	bool syncRequest = FALSE;
	bool classicPut = FALSE;

	// Forward declarations
	result_t moveToBuffer(char data);
	result_t moveToUART();
	task void signal_done_tsk();

	/** 
	 * Uart initialization routine.
	 * 
	 * <p>Section numbers in () refers to MC9S08GB60 Data Sheet.</p>
	 *
	 * @return SUCCESS always
	 */
	async command result_t UART.init(uint32_t baudrate)
	{
		// Set baud rate (Section 11.10.1):
		// SCI1BD = BUSCLK/(16*baudrate) 

		SCI1BD = busClock/(16*baudrate);

		// Set the SCI1 control register (Section 11.10.3)
		// b7 : Disable interrupt on transmit TDRE (will be enabled by put)
		// b6 : Hardware interrupts from TC disabled
		// b5 : Receiver interrupt enable RDFR
		// b4 : IDLE disable
		// b3 : TE - Transmitter enable
		// b2 : RE - Receiver enable
		// b1 : Wakeup disable
		// b0 : SBK disable
		SCI1C2 = 0x2C; // 00101100;
      
		// TODO: Do we need to set pin directions?

		return SUCCESS;
	}

	/* Stop the UART - must init again to start it... */
	async command result_t UART.stop()
	{
		SCI1BD = 0x0000;
		SCI1C2  = 0x00;
		return SUCCESS;
	}

	async command result_t UART.setRate(int rate)
	{
		// Should be implemented some day :-)
		return SUCCESS;
	}

	/** Default get event. */
	default async event result_t UART.get(uint8_t data) { return SUCCESS; }
  
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
	TOSH_SIGNAL(SCI1RX)
	{
		// Test for RDRF.
		if (SCI1S1_RDRF) {
			// Set, there is data, otherwise it was probably an error.
			signal UART.get(SCI1D);
		}
	}


	/** Default putDone event.
	 * 
	 * <p>I do not think default events work at all.</p>
	 */
	default async event result_t UART.putDone() { return SUCCESS; }


	command async uint8_t UART.putString(uint8_t *data, uint8_t len)
	{
		uint8_t i=0;
		// Copy data to buffer.
		while (i<len) {
			if (!moveToBuffer(data[i])) {
				return i;
			}
			i++;
		}
		// Move data to the UART.
		moveToUART();
		return len;		
	}

	command async result_t UART.put(uint8_t data)
	{
		classicPut = TRUE;
		SCI1C2_TIE = 1;
		SCI1D = data;
	}
	
	command async result_t UART.putSync(uint8_t data)
	{
		atomic syncRequest = TRUE;
		// Wait for Transmit Data Register to be empty.
		while(!SCI1S1_TDRE);
		SCI1D = data;
		// Wait for Transmission Complete.
		while(!SCI1S1_TC);
		atomic syncRequest = FALSE;
		// Make sure to start buffered operation again.
		moveToUART();
		return SUCCESS;
	}

	command async result_t UART.putBuffered(uint8_t data)
	{
		// Copy data to buffer.
		if (!moveToBuffer(data)) {
			return FAIL;
		}
		// Move data to the UART.
		moveToUART();
		return SUCCESS;
	}
	
	TOSH_SIGNAL(SCI1TX)
	{
		if (SCI1S1_TDRE) {
			if (classicPut) {
				// Handle classic put/putDone.
				SCI1C2_TIE = 0;
				post signal_done_tsk();
			} else {
				atomic is_sending = FALSE;
				// Move data to UART.
				if (!moveToUART()) {
					SCI1C2_TIE = 0;
				}
			}
		}
	}

	// Task posted to leave interrupt context in classic mode
	task void signal_done_tsk() {
		classicPut = FALSE;
		signal UART.putDone();
	}
  
  
	// Helper functions
	inline result_t moveToBuffer(char data)
	{
		result_t res = FAIL;
		atomic {
			if (!bufferFull) {
				buffer[((bufferHead+bufferCount)%bufferSize)] = data;
				bufferCount++;
				bufferFull = (bufferCount == bufferSize);
				res = SUCCESS;
			}
		}
		return res;
	}
	
	inline result_t moveToUART()
	{
		// Data in buffer to UART.
		result_t res = FAIL;
		atomic {
			if (!is_sending && !syncRequest && bufferCount) {
				// Move data from buffer to UART if no one is currently sending,
				// no syncronous transfer is requested and data is in the buffer.
				SCI1C2_TIE = 1;
				SCI1D = buffer[bufferHead];
				bufferHead++;
				bufferHead = bufferHead%bufferSize;
				bufferCount--;
				bufferFull = FALSE;
				is_sending = TRUE;
				res = SUCCESS;
			} 
		}
		return res;
	}
  
}
