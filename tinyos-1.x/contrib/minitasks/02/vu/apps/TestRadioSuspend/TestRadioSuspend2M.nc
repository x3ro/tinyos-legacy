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
 * Date last modified: 12/03/02
 */

 /*	CONCULSION:

	if GenericComm is not started then the maximum rate for Timer1 is 2 jiffies
	if GenericComm is started but not suspended then the maximum rate for Timer1 is 10 jiffies
	if GenericComm is started and suspended then the maximum rate for Timer1 is 3 jiffies
*/

includes Timer;

module 	TestRadioSuspend2M
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface RadioSuspend;
		interface Leds;
		interface Timer as Timer1;
		interface Timer as Timer2;
		interface ReceiveMsg as ReceiveTestMsg;
	}
}

/*
 * Red LED:	on: if the radio is on/resumed, 
 * Yellow LED:	toggle when message is received
 * Green LED:	toggled at every 1 second, from Timer2
 */

implementation
{
	enum
	{
		// interrupt rate when radio is off
		TIMER1_JIFFIES = 3,
	
		// radio suspended for 1/4 second
		TIMER1_COUNTER = 32768u/TIMER1_JIFFIES/4,

		// must be small to have small clock skew when stopping/starting Timer1
		TIMER2_JIFFIES = 32,

		// LED is toggled at every 1 second
		TIMER2_COUNTER = 32768u/TIMER2_JIFFIES,
	};

	uint16_t counter1;
	uint16_t counter2;

	command result_t StdControl.init()
	{
		call Leds.init();
		call RadioSuspend.init();

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call Leds.redOn();
		call Leds.yellowOn();

		counter2 = TIMER2_COUNTER;
		call Timer2.start2(TIMER_REPEAT, TIMER2_JIFFIES);
				
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	task void suspendRadio()
	{
		if( call RadioSuspend.suspend() == SUCCESS )
		{
			call Leds.redOff();

			counter1 = TIMER1_COUNTER;
			call Timer1.start2(TIMER_REPEAT, TIMER1_JIFFIES);
		}
	}

	event TOS_MsgPtr ReceiveTestMsg.receive(TOS_MsgPtr p)
	{
		call Leds.yellowToggle();
		post suspendRadio();
		return p;
	}

	task void resumeRadio()
	{
		call RadioSuspend.resume();
		call Leds.redOn();
	}

	event result_t Timer1.fired()
	{
		if( --counter1 == 0 )
		{
			call Timer1.stop();
			post resumeRadio();
		}

		return SUCCESS;
	}

	event result_t Timer2.fired()
	{
		if( --counter2 == 0 )
		{
			counter2 = TIMER2_COUNTER;
			call Leds.greenToggle();
		}

		return SUCCESS;
	}
}
