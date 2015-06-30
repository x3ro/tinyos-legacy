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

module SoundRecorderM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface ADC as MicADC;
		interface Mic;
		interface StdControl as MicControl;
		interface Leds;
		interface StdControl as RadioSuspend;
		interface SendBigMsg;
	}
}

implementation
{
	enum
	{
		BUFFER_LENGTH = 3000,
		SILENCE_LENGTH = 500,
		ENERGY_THRESHOLD = 40,
		MIC_GAIN = 128,
		BASE_STATION = 1973,
	};

	uint8_t buffer[BUFFER_LENGTH];
	norace uint16_t bufferIndex;		// the position of the next sample
	norace uint16_t recordCounter;		// the number of samples remaining

	uint16_t decayingAverage;	// the higher byte contains the average
	uint16_t decayingEnergy;	// the same decay, 255/256

	enum
	{
		STATE_LISTEN,
		STATE_RECORD,
		STATE_SEND,
	};

	norace uint8_t state;

	command result_t StdControl.init()
	{
		call Leds.init();
		call MicControl.init();

		return SUCCESS;
	}

	task void startSampling();

// HACK: for some stupid reason we cannot start immediatelly.
//	this behaviors is dependent on the new MICA2 radio stack

	uint16_t counter;
	task void waiter()
	{
		call Leds.yellowToggle();

		if( --counter == 0 )
			post startSampling();
		else
			post waiter();
	}

	command result_t StdControl.start() 
	{
		call MicControl.start();
		call Mic.muxSel(1);		// get mic before the bandpass filter
		call Mic.gainAdjust(MIC_GAIN);

//		post startSampling();
		counter = 3; post waiter();

		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		call MicControl.stop();
		return SUCCESS;
	}

	task void startSampling()
	{
		if( call RadioSuspend.stop() == SUCCESS )
		{
			// initialize
			atomic
			{
				decayingAverage = 128 << 8;
				decayingEnergy = 0;
			}

			// clear the buffer
			atomic
			{
				bufferIndex = BUFFER_LENGTH;
				do {
					buffer[--bufferIndex] = 0;
				} while( bufferIndex != 0 );
			}	
			state = STATE_LISTEN;

			call Leds.redOn();

			// start sampling
			call MicADC.getContinuousData();
		}
		else
			post startSampling();
	}

	task void stopSampling();

	async event result_t MicADC.dataReady(uint16_t mic)
	{
		uint8_t sample, average, energy;

		// drop the lower two bits
		sample = mic >> 2;

		// record the sample
		atomic
		{
			buffer[bufferIndex] = sample;
			if( ++bufferIndex >= BUFFER_LENGTH )
			{
				bufferIndex = 0;
				call Leds.greenToggle();
			}
		}	

		switch( state )
		{
		case STATE_LISTEN:
			atomic
			{			
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
				energy = decayingEnergy >> 8;	// very fast: 0 or 1 CPU cycle
				decayingEnergy -= energy;
				decayingEnergy += sample;
			}

			if( energy > ENERGY_THRESHOLD )
			{
				state = STATE_RECORD;
				call Leds.yellowOn();

				recordCounter = BUFFER_LENGTH - SILENCE_LENGTH;
			}

			break;

		case STATE_RECORD:
			if( --recordCounter == 0 )
			{
				state = STATE_SEND;
				post stopSampling();

				return FAIL;
			}
			break;
		}

		return SUCCESS;
	}

	task void stopSampling()
	{
		call Leds.redOff();
		call Leds.yellowOff();
		call RadioSuspend.start();

		if( call SendBigMsg.send2(BASE_STATION,
			buffer + bufferIndex, buffer + BUFFER_LENGTH,
			buffer, buffer + bufferIndex) != SUCCESS )
		{
			signal SendBigMsg.sendDone(FAIL);
		}

	}

	void event SendBigMsg.sendDone(result_t success)
	{
		state = STATE_LISTEN;
		post startSampling();
	}
}
