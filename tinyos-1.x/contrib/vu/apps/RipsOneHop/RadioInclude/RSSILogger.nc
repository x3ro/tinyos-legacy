/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 02/02/04
 */

interface RSSILogger
{
	/**
	 * Resets all buffers and error information.
	 */
	async command void reset();

	/**
	 * Checks that the suplied result is SUCCESS. If not,
	 * then turns the radio back on and reports the error.
	 * Returns SUCCESS if no check has failed so far.
	 */
	async command bool check(result_t result, uint16_t line);

	/**
	 * Returns TRUE if one of the previous checks failed.
	 */
	async command bool isBuggy();

	/**
	 * Records an 8-bit value for later reporting.
	 */
	async command void record8(uint8_t value);

	/**
	 * Records an 16-bit value for later reporting.
	 */
	async command void record16(uint16_t value);

	/**
	 * Records an 16-bit value for later reporting.
	 */
	async command void record32(uint32_t value);

	/**
	 * Allocates the specified size buffer and retuns
	 * its address.
	 */
	async command void *recordBuffer(uint16_t length);

	/**
	 * Sends the recorded values back to the base station.
	 */
	async command void report();

	/**
	 * Signaled when reporting is done from this mote.
	 */
	event void reportDone();

	/**
	 * Returns the length of the recorded data
	 */
	async command uint16_t getLength();
	
	/**
	 * Returns pointer  to the first byte of the recorded data
	 */
	async command uint8_t *getBufferStart();
}
