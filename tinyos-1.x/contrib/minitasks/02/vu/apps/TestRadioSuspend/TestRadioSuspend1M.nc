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
 * Authors: Miklos Maroti, Branislav Kusy
 * Date last modified: 11/19/02
 */

module 	TestRadioSuspend1M
{
	provides 
	{

		interface StdControl;
	}
	uses
	{
		interface RadioSuspend;
		interface Leds;
		interface Timer;
		interface SendMsg as SendTestMsg;
	}
}

implementation
{
	// interrupt at every 16384/32768 seconds = 2 HZ ~ 500 ms
	enum{
		IS_SUSPENDED = 1,
		IS_RESUMED  = 0,
	};
		
	uint8_t suspended;
	TOS_Msg msg;

	task void sendTestMsg();

	command result_t StdControl.init()
	{
		call Leds.init();
		call RadioSuspend.init();
		suspended = IS_RESUMED;

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call Leds.redOn();
		call Leds.greenOff();
		call Timer.start(TIMER_REPEAT, 500);
		post sendTestMsg();
				
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	task void sendTestMsg()
	{
		if( (call SendTestMsg.send(TOS_BCAST_ADDR, sizeof(TestMsg), &msg)) != SUCCESS )
			post sendTestMsg();
	}
	
	
	event result_t SendTestMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		if( p == &msg && success == SUCCESS )
		{
			if( call RadioSuspend.suspend() == SUCCESS )
				call Leds.yellowOn();
			else
				call Leds.yellowOff();

			call Leds.redOff();
			suspended = IS_SUSPENDED;
		}
		else
			post sendTestMsg();

		return SUCCESS;
	}


	event result_t Timer.fired()
	{
		call Leds.greenToggle();

		if (suspended == IS_SUSPENDED)
		{
			call RadioSuspend.resume();
			call Leds.redOn();
			post sendTestMsg();
			suspended = IS_RESUMED;
		}

		return SUCCESS;
	}
}
