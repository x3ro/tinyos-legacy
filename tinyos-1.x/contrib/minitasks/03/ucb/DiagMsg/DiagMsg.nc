/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 2/14/03
 */

/**
 * The DiagMsg interface allows messages to be sent back to the base station
 * containing several values and their type information, like in 
 * <code>printf(...)</code>. The base station must be connected to a PC using 
 * a serial cable. On the PC a Java application (PrintDiagMsgs) decodes the 
 * message and displays its content using the correct type information. 
 * See the implementation for the format of the message.
 */
interface DiagMsg
{
	/**
	 * Initiates the recording of a new DiagMsg. It returns FAIL if
	 * the component is busy recording or sending another message.
	 */
	command result_t record();

	/**
	 * Adds a new value to the end of the message. If the message 
	 * cannot hold more information, then the new value is simply dropped.
	 */
	command void int8(int8_t value);
	command void uint8(uint8_t value);
	command void hex8(uint8_t value);
	command void int16(int16_t value);
	command void uint16(uint16_t value);
	command void hex16(uint16_t value);
	command void int32(int32_t value);
	command void int64(int64_t value);
	command void uint64(uint64_t value);
	command void uint32(uint32_t value);
	command void hex32(uint32_t value);
	command void real(float value);
	command void chr(char value);
	command void token(uint8_t index);

	/**
	 * Adds an array of values to the end of the message. 
	 * The maximum length of the array is <code>15</code>.
	 * If the message cannot hold all elements of the array,
	 * then no value is stored.
	 */
	command void int8s(int8_t *value, uint8_t len);
	command void uint8s(uint8_t *value, uint8_t len);
	command void hex8s(uint8_t *value, uint8_t len);
	command void int16s(int16_t *value, uint8_t len);
	command void uint16s(uint16_t *value, uint8_t len);
	command void hex16s(uint16_t *value, uint8_t len);
	command void int32s(int32_t *value, uint8_t len);
	command void uint32s(uint32_t *value, uint8_t len);
	command void hex32s(uint32_t *value, uint8_t len);
	command void int64s(int64_t *value, uint8_t len);
	command void uint64s(uint64_t *value, uint8_t len);
	command void reals(float *value, uint8_t len);
	command void chrs(char *value, uint8_t len);
	command void tokens(uint8_t *value, uint8_t len);

	/**
	 * These are useful shorthand methods for <code>chrs</code>
	 * <code>token</code>.
	 */
	command void boolean(bool value);
	command void str(char* value);

	/**
	 * Initiates the sending of the recorded message. 
	 */
	command void send();

	/**
	 * Changes the default nodeid of the BASE_STATION
	 */
	command void setBaseStation(uint16_t nodeID);
}
