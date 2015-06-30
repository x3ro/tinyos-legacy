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
 * Date last modified: 04/15/03
 */

includes Timer;

module BuzzerAndRecorderM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface AcousticBeacon;
		interface AcousticMultiSampler;
		interface Timer;
		interface SendBigMsg;
		interface Leds;
	}
}

implementation
{
	enum
	{
		STATE_IDLE,
		STATE_ACTUATING,
		STATE_SENSING,
	};

	enum
	{
		TIMER_RATE = 3276,	// 0.1 sec (in jiffies)
		INITIAL_DELAY = 32,	// in TIMER_RATE units
		ACTUATE_PERIOD = 1024,
		BUSY_BACKOFF = 64,
	};

	uint8_t state;
	int16_t timeout;

	enum
	{
		BASE_STATION = 1973,
		BUFFER_LENGTH = 1000,
		BEACON_RATE = 100,
		SAMPLER_RATE = 100,
	};

	uint8_t BEACON_TIMING[] __attribute__((C)) = 
	{
		// wait 0.5 sec for the mic to power up
		164,

		// 16 times 400 buzz with 1800-2500 jiffies silence
		4, 18, 4, 19, 4, 20, 4, 21, 4, 22, 4, 23, 4, 24, 4, 25,
		4, 25, 4, 24, 4, 23, 4, 22, 4, 21, 4, 20, 4, 19, 4, 18,

		// end
		0,
	};

	uint8_t SAMPLER_TIMING[] __attribute__((C)) = 
	{
		// wait 0.5 sec for the mic to power up
		164,

		// 16 times 2200-2900 jiffies recordings
		22, 23, 24, 25, 26, 27, 28, 29,
		29, 28, 27, 26, 25, 24, 23, 22,

		// this is the end my friend
		0,
	};

	uint16_t buffer[BUFFER_LENGTH];
	uint16_t bufferIndex;

	struct
	{
		uint16_t actuator;
		uint16_t sensor;
	} header;

	task void clearBuffer()
	{
		uint16_t i = BUFFER_LENGTH;
		do { buffer[--i] = 0; } 
		while( i != 0 );

		while( timeout < BUSY_BACKOFF )
			timeout += BUSY_BACKOFF;

		state = STATE_IDLE;
	}

	command result_t StdControl.init() 
	{
		state = STATE_IDLE;
		return SUCCESS; 
	}

	command result_t StdControl.start() 
	{ 
		call AcousticBeacon.setTiming(BEACON_RATE, BEACON_TIMING);
		call AcousticMultiSampler.setTiming(SAMPLER_RATE, SAMPLER_TIMING);

		timeout = INITIAL_DELAY;
		call Timer.start2(TIMER_REPEAT, TIMER_RATE);

		return SUCCESS; 
	}

	command result_t StdControl.stop() 
	{
		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		call Leds.yellowToggle();

		if( --timeout == 0 )
		{
			if( state == STATE_IDLE )
			{
				if( call AcousticBeacon.send() == SUCCESS )
				{
					call Leds.redOn();
					state = STATE_ACTUATING;
				}
				else
					timeout = BUSY_BACKOFF;
			}
		}

		return SUCCESS;
	}

	event void AcousticBeacon.sendDone()
	{
		call Leds.redOff();
		timeout = ACTUATE_PERIOD;
		state = STATE_IDLE;
	}

	event result_t AcousticMultiSampler.receive(uint16_t beacon)
	{
		if( state != STATE_IDLE )
			return FAIL;

		call AcousticMultiSampler.setGain(128);
		call Leds.greenOn();

		state = STATE_SENSING;
		bufferIndex = 0;
		header.actuator = beacon;

		return SUCCESS;
	}

	event result_t AcousticMultiSampler.dataReady(uint16_t sample)
	{
		if( bufferIndex < BUFFER_LENGTH )
		{
			buffer[bufferIndex++] += sample;
			return SUCCESS;
		}

		bufferIndex = 0;
		return FAIL;
	}

	task void process();

	event void AcousticMultiSampler.receiveDone()
	{
		call AcousticMultiSampler.setGain(0);

		post process();
	}

	task void process()
	{
		header.sensor = TOS_LOCAL_ADDRESS;

		if( call SendBigMsg.send2(BASE_STATION,
			&header, &header + 1,
			buffer, buffer + BUFFER_LENGTH) != SUCCESS )
		{
			signal SendBigMsg.sendDone(FAIL);
		}
	}

	event void SendBigMsg.sendDone(result_t success)
	{
		call Leds.greenOff();
		post clearBuffer();
	}
}
