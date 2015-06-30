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
 * Date last modified: 04/11/03
 */

interface AcousticRangingSensor
{
	/**
	 * Signaled when the AcousticRanging process starts, usually by
	 * receiving some kind of signal.
	 *
	 * @param actuator The node ID of the AcousticRanging actuator
	 *	who initiated the AcousticRanging.
	 * @return <code>FAIL</code> to ignore this AcousticRanging signal,
	 *	<code>SUCCESS</code> to process this AcousticRanging signal.
	 */
	event result_t receive(uint16_t actuator);
	
	/**
	 * Signaled when the AcousticRanging is complete.
	 *
	 * @param actuator The node ID of the AcousticRanging actuator.
	 * @param distance The distance between this node and the actuator 
	 *	in centimeters.
	 */
	event void receiveDone(uint16_t actuator, int16_t distance);
}
