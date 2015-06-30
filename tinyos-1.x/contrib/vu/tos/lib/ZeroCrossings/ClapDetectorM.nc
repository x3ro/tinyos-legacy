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
 * Date last modified: 06/23/03
 */

includes Timer;

module ClapDetectorM
{
	provides 
	{
		interface StdControl;
		interface ClapDetector;
	}
	uses
	{
		interface Timer;
		interface ADC as MicADC;
		interface Mic;
		interface StdControl as MicControl;
		interface Leds;
	}
}

implementation
{
	enum
	{
		MIC_GAIN = 128,
		ENERGY_THRESHOLD = 10,
		TIMER_RATE = 200,	// 164 HZ
		WARMUP_IGNORE = 300,	// 0.5 sec
		CLAP_IGNORE = 100,
	};

	norace uint16_t ignoreSamples;		// ignore this many samples
	norace uint16_t decayingAverage;	// the higher byte contains the average
	norace uint16_t decayingEnergy;		// the same decay, 255/256

	command result_t StdControl.init()
	{
		call MicControl.init();
		call Leds.init();

		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		call MicControl.start();
		call Mic.muxSel(1);	// get mic before the bandpass filter
		call Mic.gainAdjust(MIC_GAIN);

		ignoreSamples = WARMUP_IGNORE;
		call Timer.start2(TIMER_REPEAT, TIMER_RATE);

		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		call Timer.stop();
		call MicControl.stop();

		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		if( ignoreSamples == 0 )
			call MicADC.getData();
		else if( --ignoreSamples == 0 )
		{
			decayingAverage = 128 << 8;
			decayingEnergy = 0;
		}

		return SUCCESS;
	}

	default event void ClapDetector.fired(){
	}

	task void clapDetected()
	{
		signal ClapDetector.fired();
	}

	async event result_t MicADC.dataReady(uint16_t mic)
	{
		uint8_t sample, average, energy;

		// drop the lower two bits
		sample = mic >> 2;

		// calculate the decayed average
		average = decayingAverage >> 8;	// very fast: 0 or 1 CPU cycle
		decayingAverage -= average;
		decayingAverage += sample;

		// compute the amplitude
		if( sample >= average )
			sample -= average;
		else
			sample = average - sample;

		// calculate the decayed energy
		energy = decayingEnergy >> 5;	// very fast: 0 or 1 CPU cycle
		decayingEnergy -= energy;
		decayingEnergy += sample;

#ifdef CLAPDETCTOR_LEDS
		call Leds.set(0);
		if (energy >= (ENERGY_THRESHOLD>>2))
			call Leds.redOn();
		if (energy >= (ENERGY_THRESHOLD>>1))
			call Leds.greenOn();
		if (energy >= ENERGY_THRESHOLD)
			call Leds.yellowOn();
#endif

		if( energy >= ENERGY_THRESHOLD )
		{
			ignoreSamples = CLAP_IGNORE;
			post clapDetected();
		}

		return FAIL;
	}
}
