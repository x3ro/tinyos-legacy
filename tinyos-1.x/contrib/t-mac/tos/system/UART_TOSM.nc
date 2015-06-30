/*
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
 * Author:	Tom Parker
 * This module is designed for use by UARTDebug, connecting it directly
 * to the built-in TinyOS serial communications mechanisms
 */

module UART_TOSM
{
	provides interface ByteComm;
	provides interface StdControl;
	uses interface HPLUART as UART;
}

implementation
{
	command result_t StdControl.start() {return SUCCESS;}
	command result_t StdControl.stop() {return SUCCESS;}
	command result_t StdControl.init()
	{
		call UART.init();
		return SUCCESS;
	}

	async command result_t ByteComm.txByte(uint8_t byte)
	{
		call UART.put(byte);
		return SUCCESS;
	}


	async event result_t UART.putDone()
	{
	   signal ByteComm.txDone();
	   return SUCCESS;
	}
	
	async event result_t UART.get(uint8_t data)
	{
		signal ByteComm.rxByteReady(data,0,0);
		return SUCCESS;
	}
}
