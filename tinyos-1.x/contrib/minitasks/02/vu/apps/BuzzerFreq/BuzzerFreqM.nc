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
 * Date last modified: 04/01/03
 */

includes Timer;

module BuzzerFreqM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface LocalTime;
		interface ZeroCrossings;
		interface DiagMsg;
		interface StdControl as SounderControl;
		interface Timer;
		interface Leds;
	}
}

implementation
{
	enum
	{
		STATE_WARMUP,
		STATE_SILENCE_INIT,
		STATE_SILENCE,
		STATE_BUZZERON,
		STATE_LISTEN_START,
		STATE_LISTEN,
		STATE_LISTEN_END,
		STATE_LISTEN_DONE,
	};

	uint8_t state;

	enum
	{
		TIMEOUT_WARMUP = 14,	// in 0.1 seconds
		TIMEOUT_SILENCE = 5,
		TIMEOUT_BUZZERON = 1,
		TIMEOUT_LISTEN = 20,
	};

	uint8_t timeout;

	command result_t StdControl.init()
	{
		call Leds.init();
		call SounderControl.init();
		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		timeout = TIMEOUT_WARMUP;
		state = STATE_WARMUP;

		call ZeroCrossings.setGain(128);	// turn on mic
		call Timer.start2(TIMER_REPEAT, 3277);	 // 0.1 sec

		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	uint8_t silenceMaxEnergy;
	uint8_t buzzMaxAmplitude;
	uint16_t buzzLength;	// in number of samples
	uint32_t buzzTime;	// in jiffies
	uint16_t buzzCrossings;

	task void startSampling()
	{
		silenceMaxEnergy = 0;
		buzzMaxAmplitude = 0;
		buzzLength = 0;
		buzzTime = 0;
		buzzCrossings = 0;

		if( call ZeroCrossings.startSampling() == SUCCESS )
		{
			timeout = TIMEOUT_SILENCE;
			state = STATE_SILENCE;
		}
		else
			post startSampling();
	}

	event result_t Timer.fired()
	{
		call Leds.yellowToggle();

		if( --timeout != 0 )
			return SUCCESS;

		switch( state )
		{
		case STATE_WARMUP:
			call Leds.redOn();
			state = STATE_SILENCE_INIT;
			post startSampling();
			break;

		case STATE_SILENCE:
			call SounderControl.start();
			timeout = TIMEOUT_BUZZERON;
			state = STATE_BUZZERON;
			break;
		
		case STATE_BUZZERON:
			timeout = TIMEOUT_LISTEN;
			state = STATE_LISTEN_START;
			break;

		case STATE_LISTEN:
			state = STATE_LISTEN_END;
			break;
		}

		return SUCCESS;
	}

	event result_t ZeroCrossings.dataReady(uint8_t crossingLength, 
		uint8_t maxAmplitude, uint8_t startEnergy)
	{
		switch( state )
		{
		case STATE_SILENCE:
			if( startEnergy > silenceMaxEnergy )
				silenceMaxEnergy = startEnergy;
			break;

		case STATE_LISTEN_START:
			buzzTime = call LocalTime.read();
			state = STATE_LISTEN;
			break;

		case STATE_LISTEN_END:
			buzzTime = call LocalTime.read() - buzzTime;
			state = STATE_LISTEN_DONE;	// just in case
			// no break here

		case STATE_LISTEN:
			if( maxAmplitude > buzzMaxAmplitude )
				buzzMaxAmplitude = maxAmplitude;

			buzzLength += crossingLength;
			buzzCrossings++;

			break;
		}

		return state == STATE_LISTEN_DONE ? FAIL : SUCCESS;
	}

	task void report()
	{
		uint16_t buzzerFreq = ((uint32_t)buzzCrossings << 14) / buzzTime;
		uint16_t samplingFreq = ((uint32_t)buzzLength << 15) / buzzTime;

		if( call DiagMsg.record() == SUCCESS )
		{
			call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
			call DiagMsg.str("buzzer");
			call DiagMsg.uint16(buzzerFreq);
			call DiagMsg.uint8(buzzMaxAmplitude);
			call DiagMsg.str("samping");
			call DiagMsg.uint16(samplingFreq);
			call DiagMsg.uint8(silenceMaxEnergy);
			call DiagMsg.send();
		}

		timeout = TIMEOUT_WARMUP;
		state = STATE_WARMUP;
	}

	event void ZeroCrossings.samplingDone()
	{
		call Leds.redOff();
		call SounderControl.stop();
		post report();
	}
}
