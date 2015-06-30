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
 * UARTDebug
 * Author: Tom Parker <T.E.V.Parker@ewi.tudelft.nl>
 *
 * Interface for debugging via the UART. Message codes are in system/TMACEvents.h
 */

interface UARTDebug
{
	#define FLAG_RADIO 0x1
	#define FLAG_STATUS 0x2
	#define FLAG_LONGSTATUS 0x4
	
	command result_t init(uint8_t flagset);
	command result_t start();
	async command void tx32status(uint8_t type, uint32_t value);
	async command void tx16status(uint8_t type, uint32_t value);
	async command result_t txByte(uint8_t byte);
	async command void txStatus(uint8_t type, uint8_t data);
	command void  txState(uint8_t byte);
	command result_t disable();
	command result_t enable();
	command result_t setFlags(uint8_t flagset);
}

