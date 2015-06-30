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
 * Author: Miklos Maroti, Branislav Kusy
 * Date last modified: 03/21/03
 */

interface AcousticMultiSampler
{
	/**
	 * Sets the microphone gain. Setting the gain to <code>0</code>
	 * will power off the microphone.
	 * @param gain The new microphone gain. 
	 */
	command void setGain(uint8_t gain);

	/**
	 * Sets the timing information of the continuous sampling.
	 * @param rate The granularity of the timing info in jiffies.
	 *	(1/32768 secs).
	 * @param timing A sequence of bytes describing the length
	 *	of sampling periods in the granularity specified by 
	 *	<code>rate</code>. The first byte is the length of
	 *	an initial waiting period, the next bytes are the
	 *	length of sampling periods. A final <code>0</code> 
	 *	terminates the sampling of the acoustic beacon.
	 */
	command void setTiming(uint8_t rate, uint8_t *timing);

	/**
	 * Indicates that an acoustic beacon radio message has arrived and
	 * we are ready to sample the microphone and the tone detector.
	 * During the sampling of the signal the radio is disabled.
	 * @param beacon The node ID of the beacon.
	 * @return <code>SUCCESS</code> to start the sampling, 
	 *         <code>FAIL</code> to ignore this beacon message.
	 */
	event result_t receive(uint16_t beacon);

	/**
	 * The sampled values are returned in this event at the requested rate.
	 * @param mic The 10-bit (ADC converted) microphone reading.
	 * @return <code>SUCCESS</code> to continue sampling, or 
	 *	<code>FAIL</code> to stop this sampling period.
	 */
	async event result_t dataReady(uint16_t mic);

	/**
	 * Called when the sampling is finished because we have reached the
	 * end of the timing information. When called, the radio is already 
	 * re-enabled.
	 */
	event void receiveDone();
}
