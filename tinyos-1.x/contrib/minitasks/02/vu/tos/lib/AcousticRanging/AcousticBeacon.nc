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
 * Date last modified: 03/03/03
 */

interface AcousticBeacon
{
	/**
	 * Sets the timing specification of the buzzer.
	 * @param rate The granularity of the buzzer timing in 
	 *	jiffies. (1/32768 secs).
	 * @param timing A sequence of bytes describing the length
	 *	of silence and buzzing periods in the granularity 
	 *	specified by <code>rate</code>. A final <code>0</code> 
	 *	will terminate the sending of the acoustic beacon.
	 */
	command void setTiming(uint8_t rate, uint8_t *timing);

	/**
	 * Initiates the sending of a radio and acoustic signal.
	 * After the radio message is sent, the radio is disabled,
	 * and the buzzer is turned off and on according to
	 * the timing specification.
	 *
	 * @return <code>FAIL</code> if for some reason the radio and 
	 *	acoustic signal	cannot be sent this time, 
	 *	<code>SUCCESS</code> otherwise.
	 */
	command result_t send();

	/**
	 * Signaled when the sending of the radio and acoustic signal 
	 * is finished and the radio is reenabled.
	 */
	event void sendDone();
}
