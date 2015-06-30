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
 * "Dummy" UARTDebug module
 * Author: Tom Parker <T.E.V.Parker@ewi.tudelft.nl>
 *
 * Provides the UARTDebug interface, but does no actions. This is intended
 * for use with production environments
 */

module DummyDebugM
{
	provides interface UARTDebug;
	uses interface ByteComm as comm;
}

implementation
{
	inline command result_t UARTDebug.init(uint8_t flagset) {return SUCCESS;}
	inline command result_t UARTDebug.start(){return SUCCESS;}
	inline async command void UARTDebug.tx32status(uint8_t type, uint32_t value){}
	inline async command void UARTDebug.tx16status(uint8_t type, uint32_t value){}
	inline command void UARTDebug.txState(uint8_t byte){}	
	inline async command void UARTDebug.txStatus(uint8_t type, uint8_t data){}
	inline async command result_t UARTDebug.txByte(uint8_t byte) {return SUCCESS;}
	inline command result_t UARTDebug.enable() {return SUCCESS;}
	inline command result_t UARTDebug.disable() {return SUCCESS;}
	inline async event result_t comm.txDone() {return SUCCESS;}
	inline async event result_t comm.txByteReady(bool success) {return SUCCESS;}
	inline async event result_t comm.rxByteReady(uint8_t data, bool error, uint16_t strength) {return SUCCESS;}
	inline command result_t UARTDebug.setFlags(uint8_t flagset) {return SUCCESS;}
}

