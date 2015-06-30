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
 * Author: Miklos Maroti, Gyorgy Balogh
 * Date last modified: 03/18/03
 */

module YesNoRecognitionM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface ZeroCrossings;
		interface Leds;
	}
}

implementation
{
	enum
	{
		STATE_LISTEN,
		STATE_RECORD,
	};

	norace uint8_t state;

	command result_t StdControl.init()
	{
		call Leds.init();
		return SUCCESS;
	}

	task void startSampling();

	command result_t StdControl.start() 
	{
		call ZeroCrossings.setGain(128); // turn on mic
		post startSampling();
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	task void startSampling()
	{
		state = STATE_LISTEN;
		if( call ZeroCrossings.startSampling() != SUCCESS )
			post startSampling();
	}

	enum
	{
		ENERGY_THRESHOLD = 40,
		RECORD_DURATION = 9000, // around 0.7 sec
	};

	norace int16_t duration;	// the number of samples left

	uint32_t sum0;
	uint32_t sum1;
	uint32_t sum2;

	async event result_t ZeroCrossings.dataReady(uint8_t crossingLength, uint8_t maxAmplitude, uint8_t startEnergy)
	{
		switch( state )
		{
		case STATE_LISTEN:
			if( startEnergy > ENERGY_THRESHOLD )
			{
				atomic
				{
					state = STATE_RECORD;
					duration = RECORD_DURATION;
	
					sum0 = sum1 = sum2 = 0;
				}
				call Leds.yellowOn();
			}
			break;

		case STATE_RECORD:
			duration -= crossingLength;
			if( duration >= 0 )
			{
				atomic
				{
					if( maxAmplitude > 15 )
					{
						sum0 += maxAmplitude;
	
						if( 1 <= crossingLength && crossingLength <= 2 )
							sum1 += maxAmplitude;
						else if( 5 <= crossingLength && crossingLength <= 12 )
							sum2 += maxAmplitude;
					}
				}
			}
			else
			{
				state = STATE_RECORD;
				call Leds.yellowOff();

				return FAIL;
			}
			break;
		}

		return SUCCESS;
	}

	event void ZeroCrossings.samplingDone()
	{
		float a1,a2;
		
		atomic
		{
			a1 = ((float)sum1)/sum0;
			a2 = ((float)sum2)/sum0;
		}

		if( a1 >= 0.15 && a2 <= 0.4 )
		{
			call Leds.greenOn();
			call Leds.redOff();
		}
		else if( a1 <= 0.2 && a2 >= 0.4 )
		{
			call Leds.greenOff();
			call Leds.redOn();
		}
		else
		{
			call Leds.greenOff();
			call Leds.redOff();
		}

		post startSampling();
	}
}
