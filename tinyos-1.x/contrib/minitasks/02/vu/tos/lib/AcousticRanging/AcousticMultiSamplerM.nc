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
 * Date last modified: 03/21/03
 */

includes Timer;
includes AcousticBeaconMsg;

module AcousticMultiSamplerM
{
	provides 
	{
		interface AcousticMultiSampler;
		interface StdControl;
	}
	uses
	{
		interface Timer;
		interface RadioSuspend;
		interface ADC as MicADC;
		interface Mic;
		interface StdControl as MicControl;
		interface ReceiveMsg;
	}
}

implementation
{
	enum
	{
		STATE_NOTIMING,
		STATE_IDLE,
		STATE_SAMPLING,
		STATE_IGNORING,
		STATE_DONE,
	};

	uint8_t state;

	uint8_t timerRate;	// the interrupt rate of the timer
	uint8_t *rangerTiming;	// length of ignore and sample periods
	uint8_t timingIndex;	// the index of the current timing value
	uint8_t tickCount;	// the number of timer ticks remaining

	command result_t StdControl.init()
	{
		state = STATE_NOTIMING;

		call RadioSuspend.init();
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

	command void AcousticMultiSampler.setGain(uint8_t gain)
	{
		if( gain != 0 )
		{
			call MicControl.start();
			call Mic.muxSel(1);		// get mic before the bandpass filter
			call Mic.gainAdjust(gain);
		}
		else
			call MicControl.stop();
	}

	command void AcousticMultiSampler.setTiming(uint8_t rate, uint8_t *timing)
	{
		timerRate = rate;
		rangerTiming = timing;

		if( state == STATE_NOTIMING )
			state = STATE_IDLE;
	}

	task void suspendRadio();

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		// no sampling is running
		if( state == STATE_IDLE  )
		{
			AcousticBeaconMsg *msg = (AcousticBeaconMsg*)&p->data;
			if( signal AcousticMultiSampler.receive(msg->nodeId) == SUCCESS )
			{
				state = STATE_IGNORING;
				post suspendRadio();
			}
		}

		return p;
	}

	// must suspend the radio from a task
	task void suspendRadio()
	{
		if( call RadioSuspend.suspend() == SUCCESS )
		{
			// this is the initial waiting period
			timingIndex = 0;
			tickCount = rangerTiming[0];

			// start the timer
			call Timer.start2(TIMER_REPEAT, timerRate);
		}
		else
		{
			// bail out
			state = STATE_IDLE;
			signal AcousticMultiSampler.receiveDone();
		}
	}

	task void resumeRadio();

	event result_t Timer.fired()
	{
		if( --tickCount == 0 )
		{
			tickCount = rangerTiming[++timingIndex];
			if( tickCount == 0 )
			{
				// this will stop the ADC
				state = STATE_DONE;

				call Timer.stop();
				post resumeRadio();
			}
			else if( state == STATE_IGNORING )
			{
				state = STATE_SAMPLING;

				// start sampling
				call MicADC.getContinuousData();
			}
		}

		return SUCCESS;
	}

	event result_t MicADC.dataReady(uint16_t mic)
	{
		if( state == STATE_SAMPLING )
		{
			if( signal AcousticMultiSampler.dataReady(mic) == SUCCESS )
				return SUCCESS;

			state = STATE_IGNORING;
		}

		return FAIL;
	}

	task void resumeRadio()
	{
		call RadioSuspend.resume();
		state = STATE_IDLE;

		signal AcousticMultiSampler.receiveDone();
	}
}
