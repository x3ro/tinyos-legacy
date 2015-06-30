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

module TestAcousticRangingM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface AcousticRangingActuator;
		interface AcousticRangingSensor;
		interface Timer;
		interface DiagMsg;
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
		ACTUATE_PERIOD = 640,
		BUSY_BACKOFF = 64,
	};

	uint8_t state;
	int16_t timeout;

	command result_t StdControl.init() 
	{
		state = STATE_IDLE;
		return SUCCESS; 
	}

	command result_t StdControl.start() 
	{ 
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
				if( call AcousticRangingActuator.send() == SUCCESS )
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

	event void AcousticRangingActuator.sendDone()
	{
		call Leds.redOff();
		timeout = ACTUATE_PERIOD;
		state = STATE_IDLE;
	}

	event result_t AcousticRangingSensor.receive(uint16_t actuator)
	{
		// this should always be true
		if( state == STATE_IDLE )
		{
			state = STATE_SENSING;
			call Leds.greenOn();
			return SUCCESS;
		}

		return FAIL;
	}

	event void AcousticRangingSensor.receiveDone(uint16_t actuator, int16_t distance)
	{
		call Leds.greenOff();
		while( timeout < BUSY_BACKOFF )
			timeout += BUSY_BACKOFF;
		state = STATE_IDLE;

		if( call DiagMsg.record() == SUCCESS )
		{
			call DiagMsg.str("ranging");
			call DiagMsg.uint16(actuator);
			call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
			call DiagMsg.int16(distance);
			call DiagMsg.send();
		}
	}
}
