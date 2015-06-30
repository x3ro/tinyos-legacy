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
 * Author: Miklos Maroti, Branislav Kusy
 * Date last modified: 03/03/03
 */

includes AcousticBeaconMsg;

module AcousticBeaconM
{
	provides 
	{
		interface AcousticBeacon;
		interface StdControl;
	}
	uses
	{
		interface Timer;
		interface SendMsg as SendBeaconMsg;
		interface RadioSuspend;
		interface StdControl as SounderControl;
	}
}

implementation
{
	enum
	{
		STATE_NOTIMING = 0,
		STATE_IDLE = 1,
		STATE_RADIO = 2,
		STATE_SOUNDER = 3,
	};

	uint8_t state;		// the current state of the component
	uint8_t timerRate;	// the interrupt rate of the timer
	uint8_t *buzzerTiming;	// length of off and on periods
	uint8_t timingIndex;	// the index of the current timing value
	uint8_t tickCount;	// the number of timer ticks remaining

	TOS_Msg msg;			// holds the AcousticBeaconMsg

#define msgNodeId (((AcousticBeaconMsg*)msg.data)->nodeId)
#define msgTime (((AcousticBeaconMsg*)msg.data)->time)

	command result_t StdControl.init()
	{
		msgNodeId = TOS_LOCAL_ADDRESS;
		state = STATE_NOTIMING;

		return call SounderControl.init();
	}

	command result_t StdControl.start() { return SUCCESS; }
	command result_t StdControl.stop() { return SUCCESS; }

	command void AcousticBeacon.setTiming(uint8_t rate, uint8_t *timing)
	{
		timerRate = rate;
		buzzerTiming = timing;

		if( state == STATE_NOTIMING )
			state = STATE_IDLE;
	}

	task void sendRadioSignal()
	{
		if( (call SendBeaconMsg.send(TOS_BCAST_ADDR, sizeof(AcousticBeaconMsg), &msg)) != SUCCESS )
			post sendRadioSignal();
	}

	command result_t AcousticBeacon.send()
	{
		if( state != STATE_IDLE )
			return FAIL;

		state = STATE_RADIO;
		post sendRadioSignal();

		return SUCCESS;
	}

	event result_t SendBeaconMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		// we might get the sendDone twice on MICA2s
		if( state != STATE_RADIO )
			return FAIL;

		if( p == &msg && success == SUCCESS )
		{
			state = STATE_SOUNDER;
			timingIndex = 0;
			tickCount = buzzerTiming[0];

			call Timer.start2(timerRate);
			call SounderControl.stop();
		}
		else
			post sendRadioSignal();

		return SUCCESS;
	}

	task void signalDone()
	{
		call SounderControl.stop();
		state = STATE_IDLE;
		signal AcousticBeacon.sendDone();
	}

	event result_t Timer.fired()
	{
		if( --tickCount == 0 )
		{
			tickCount = buzzerTiming[++timingIndex];

			if( tickCount == 0 )
			{
				call Timer.stop();
				post signalDone();
			}
			else
			{
				if( (timingIndex & 0x01) != 0 )
					call SounderControl.start();
				else
					call SounderControl.stop();
			}
		}

		return SUCCESS;
	}
}
