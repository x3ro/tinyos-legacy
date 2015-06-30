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
 * Date last modified: 03/18/03
 */

module ZeroCrossingsM
{
	provides 
	{
		interface StdControl;
		interface ZeroCrossings;
	}
	uses
	{
		interface ADC as MicADC;
		interface Mic;
		interface StdControl as MicControl;
		interface RadioSuspend;
	}
}

implementation
{
	command result_t StdControl.init()
	{
		call MicControl.init();
		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		call MicControl.stop();
		return SUCCESS;
	}

	command void ZeroCrossings.setGain(uint8_t gain)
	{
		if( gain != 0 )
		{
			call MicControl.start();
			call Mic.muxSel(1);	// get mic before the bandpass filter
			call Mic.gainAdjust(gain);
		}
		else
			call MicControl.stop();
	}

	uint16_t decayingAverage;	// the higher byte contains the average
	uint16_t decayingEnergy;	// the same decay, 255/256

	uint8_t crossingLength;
	uint8_t maxAmplitude;
	uint8_t startEnergy;
	uint8_t currentSign;

	command result_t ZeroCrossings.startSampling()
	{
		if( call RadioSuspend.suspend() != SUCCESS )
			return FAIL;

		decayingAverage = 128 << 8;
		decayingEnergy = 0;

		crossingLength = 1;
		maxAmplitude = 0;
		startEnergy = 0;
		currentSign = 1;

		call MicADC.getContinuousData();

		return SUCCESS;
	}

	task void stopSampling();

	event result_t MicADC.dataReady(uint16_t mic)
	{
		uint8_t sample, average, energy, sign;

		// drop the lower two bits
		sample = mic >> 2;

		// calculate the decayed average
		average = decayingAverage >> 8;	// very fast: 0 or 1 CPU cycle
		decayingAverage -= average;
		decayingAverage += sample;

		// the new sign
		sign = sample >= average;

		// compute the amplitude
		if( sign )
			sample -= average;
		else
			sample = average - sample;

		// calculate the decayed energy
		energy = decayingEnergy >> 8;	// very fast: 0 or 1 CPU cycle
		decayingEnergy -= energy;
		decayingEnergy += sample;

		if( sign == currentSign )
		{
			++crossingLength;
			if( sample > maxAmplitude )
				maxAmplitude = sample;
		}
		else
		{
			// the new sig
			currentSign = sign;

			if( signal ZeroCrossings.dataReady(crossingLength,
				maxAmplitude, startEnergy) == FAIL )
			{
				post stopSampling();
				return FAIL;
			}

			crossingLength = 1;
			maxAmplitude = sample;
			startEnergy = energy;
		}

		return SUCCESS;
	}

	task void stopSampling()
	{
		call RadioSuspend.resume();
		signal ZeroCrossings.samplingDone();
	}
}
