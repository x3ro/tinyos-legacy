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
 * Date last modified: 05/08/03
 */

includes Timer;

module AcousticRangingSchedulerM
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
		interface SendMsg;
		interface ReceiveMsg;
		interface Random;
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
		TIMER_RATE = 32768u,	// 1 sec
		TIMER_SUBRATE = 32,
		INITIAL_DELAY = 2,
		ACTUATE_PERIOD = 12,
		BUZZ_LENGTH = 2,
		WARN_LENGTH = 2,
	};

	uint8_t state;
	int16_t timeout;
	TOS_Msg msg;
	uint16_t priority;

	command result_t StdControl.init() 
	{
		call Leds.init();
		call Random.init();
		state = STATE_IDLE;
		return SUCCESS; 
	}

	command result_t StdControl.start() 
	{ 
		timeout = INITIAL_DELAY;
		call Timer.start2(TIMER_RATE / TIMER_SUBRATE);

		return SUCCESS; 
	}

	command result_t StdControl.stop() 
	{
		call Leds.set(0);
		call Timer.stop();
		return SUCCESS;
	}

	uint8_t subRate;

	void retry()
	{
		priority = call Random.rand();
		timeout = ACTUATE_PERIOD;
	}

	event result_t Timer.fired()
	{
		if( ++subRate < TIMER_SUBRATE )
			return SUCCESS;
		subRate = 0;

		call Leds.yellowToggle();

		if( state == STATE_IDLE )
		{
			if( --timeout == 0 )
			{
				if( call AcousticRangingActuator.send() == SUCCESS )
				{
					call Leds.redOn();
					state = STATE_ACTUATING;
				}
				else
					retry();
			}
			else if( 0 < timeout && timeout < WARN_LENGTH )
			{
				AcousticRangingSchedulerMsg *schedule = (AcousticRangingSchedulerMsg*)msg.data;
				schedule->priority = priority;

				if( call SendMsg.send(TOS_BCAST_ADDR, sizeof(AcousticRangingSchedulerMsg), &msg) != SUCCESS )
					retry();
			}
		}

		return SUCCESS;
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		if( ! success )
			retry();

		return SUCCESS;
	}

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		AcousticRangingSchedulerMsg *schedule = (AcousticRangingSchedulerMsg*)p->data;
		if( schedule->priority <= priority && timeout <= BUZZ_LENGTH + 2 * WARN_LENGTH )
		{
			priority = call Random.rand();
			timeout = BUZZ_LENGTH + 2 * WARN_LENGTH + 1;
		}

		return p;
	}

	event void AcousticRangingActuator.sendDone()
	{
		call Leds.redOff();
		retry();
		state = STATE_IDLE;
	}

	event result_t AcousticRangingSensor.receive(uint16_t actuator)
	{
		if( timeout <= BUZZ_LENGTH + WARN_LENGTH )
		{
			priority = call Random.rand();
			timeout = BUZZ_LENGTH + WARN_LENGTH + 1;
		}
	
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
