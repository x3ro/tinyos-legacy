/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Date last modified: 05/13/03
 */

includes RadioCollisionMsg;

module 	RadioCollisionBeaconM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface Leds;
		interface SendMsg;
		interface Timer;
	}
}

implementation
{
	TOS_Msg msg;

	task void sendMsg()
	{
		if( call SendMsg.send(TOS_BCAST_ADDR, sizeof(RadioBeaconMsg), &msg) != SUCCESS )
		{
			call Leds.yellowToggle();
			post sendMsg();
		}
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
	{
		if( success == SUCCESS )
			call Leds.greenToggle();
		else
			call Leds.redToggle();

		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		post sendMsg();
		return SUCCESS;
	}

	command result_t StdControl.init()
	{
		call Leds.init();
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call Timer.start(TIMER_REPEAT, 5000);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
}
