/*
 * Copyright (c) 2004, Vanderbilt University
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
 * Date last modified: 2/19/04
 */

/**
 * This is the hardware abstraction interface for microcontrollers with
 * one 16-bit timer/counter register and one 16-bit compare register.
 *
 *	W A R N I N G: All methods and events must be called while all 
 *	interrutps are disabled.
 */
interface HPLSysClock16
{
	/**
	 * This method returns the current time. The execution time
	 * of this method till the point it obtains the current time 
	 * must be constant. The HPLSYSALARM_SECOND is the number of
	 * ticks per seconds.
	 */
	async command uint16_t getTime();

	/**
	 * Fired when the 16-bit current time value overflows. 
	 */
	async event void overflow();

	/**
	 * Tests wheter there is a pending overflow. Returns TRUE
	 * if an overflow interrupt is pending, FAIL otherwise.
	 */
	async command bool getOverflowFlag();

	/**
	 * Sets the alarm time to the specified value. It is the 
	 * responsibility of the caller to ensure that the specified
	 * time is not too close to the current time.
	 */
	async command void setAlarm(uint16_t time);

	/**
	 * Fired when the alarm goes off. This event can be signalled
	 * a little later than the registered alarm time. It can be
	 * fired even after the overflow event if the alarm time
	 * was close to 0xFFFF. While handling this event higher
	 * level components must either call <code>setAlarm</code>
	 * or <code>cancelAlarm</code>.
	 */
	async event void fired();

	/**
	 * Cancels the alarm.
	 */
	async command void cancelAlarm();
}
