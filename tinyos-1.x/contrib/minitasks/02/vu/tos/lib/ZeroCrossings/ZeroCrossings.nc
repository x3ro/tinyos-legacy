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
 * Date last modified: 03/19/03
 */

interface ZeroCrossings
{
	/**
	 * Sets the microphone gain. Setting the gain to <code>0</code>
	 * will power off the microphone. By default, the microphone is
	 * turned off.
	 * @param gain The new microphone gain. 
	 */
	command void setGain(uint8_t gain);

	/**
	 * Starts sampling the microphone.
	 * @return <code>SUCCESS</code> if the radio was succesfully suspended
	 *	and the sampling is started, <code>FAIL</code> otherwise.
	 */
	command result_t startSampling();

	/**
	 * Fired for each zero crossing record.
	 * @param crossinglength The number of samples in the zero crossing interval.
	 * @param maxAmplitude The maximum amplitude in the interval 
	 *	(with respect to a moving average)
	 * @param startEnergy The energy (a moving average of the amplitudes)
	 *	at the start of the interval.
	 * @return <code>SUCCESS</code> to continue sampling, <code>FAIL</code>
	 *	to stop sampling.
	 */
	event result_t dataReady(uint8_t crossingLength, uint8_t maxAmplitude, uint8_t startEnergy);

	/**
	 * Fired after the sampling is stopped as a result of returning 
	 * <code>FAIL</code> in <code>dataReady</code> and the radio is succesfully
	 * resumed.
	 */
	event void samplingDone();
}
