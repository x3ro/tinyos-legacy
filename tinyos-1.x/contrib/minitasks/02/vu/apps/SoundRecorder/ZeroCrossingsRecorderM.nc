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

module ZeroCrossingsRecorderM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface ZeroCrossings;
		interface Leds;
		interface SendBigMsg;
	}
}

implementation
{
	enum
	{
		BUFFER_LENGTH = 1000,
		SILENCE_LENGTH = 200,
		ENERGY_THRESHOLD = 40,
		BASE_STATION = 1973,
	};

	struct zcRecord_s
	{
		uint8_t crossingLength;
		uint8_t maxAmplitude;
		uint8_t startEnergy;
	};

	struct zcRecord_s buffer[BUFFER_LENGTH];
	uint16_t bufferIndex;		// the position of the next sample
	uint16_t recordCounter;		// the number of samples remaining

	enum
	{
		STATE_LISTEN,
		STATE_RECORD,
		STATE_SEND,
	};

	uint8_t state;

	command result_t StdControl.init()
	{
		call Leds.init();

		return SUCCESS;
	}

	task void startSampling();

	command result_t StdControl.start() 
	{
		call ZeroCrossings.setGain(128);
		post startSampling();

		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	task void startSampling()
	{
		if( call ZeroCrossings.startSampling() == SUCCESS )
		{
			state = STATE_LISTEN;
			bufferIndex = 0;

			call Leds.redOn();
		}
		else
			post startSampling();
	}

	event result_t ZeroCrossings.dataReady(uint8_t crossingLength, uint8_t maxAmplitude, uint8_t startEnergy)
	{
		buffer[bufferIndex].crossingLength = crossingLength;
		buffer[bufferIndex].maxAmplitude = maxAmplitude;
		buffer[bufferIndex].startEnergy = startEnergy;

		if( ++bufferIndex >= BUFFER_LENGTH )
		{
			bufferIndex = 0;
			call Leds.greenToggle();
		}

		switch( state )
		{
		case STATE_LISTEN:
			if( startEnergy > ENERGY_THRESHOLD )
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
				return FAIL;
			}
			break;
		}

		return SUCCESS;
	}

	event void ZeroCrossings.samplingDone()
	{
		call Leds.redOff();
		call Leds.yellowOff();

		if( call SendBigMsg.send2(BASE_STATION,
			buffer + bufferIndex, buffer + BUFFER_LENGTH,
			buffer, buffer + bufferIndex) != SUCCESS )
		{
			signal SendBigMsg.sendDone(FAIL);
		}
	}

	event void SendBigMsg.sendDone(result_t success)
	{
		state = STATE_LISTEN;
		post startSampling();
	}
}
