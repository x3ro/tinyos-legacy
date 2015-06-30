/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Date last modified: 12/07/03
 */

/** 
 * This interface provides access to a free-running CPU timer that is 
 * started at startup. The current value of this timer is NOT supposed
 * to be changed. On the MICA2 platform the current implementation 
 * uses a 1/8 prescaler that results in a 921.6 KHz clock frequency.
 */
interface SysTime
{
	/**
	 * This method returns the lower 16 bits of the current time.
	 * The overhead of this method is absolutely negligible (this
	 * is a simple register read).
	 */
	async command uint16_t getTime16();

	/**
	 * This method returns the current time. This method has a very 
	 * little overhead and preferable to the getTime16() method if
	 * space is not of concern.
	 */
	async command uint32_t getTime32();

	/**
	 * Returns the closest 32-bit time (either in the future or in the 
	 * past, symmetrically) whose lower 16-bit is the supplied argument.
	 */
	async command uint32_t castTime16(uint16_t time16);
}
