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
 * Author: Miklos Maroti, Brano Kusy
 * Date last modified: 03/17/03
 */

includes Timer;
includes TestTimeSyncPollerMsg;

module TestTimeSyncPollerM
{
	provides 
	{
		interface StdControl;
	}
	uses 
	{
		interface SendMsg;
		interface Timer;
		interface Timer as PrecisionTimer;
		interface Leds;
		interface LocalTime;
		interface DiagMsg;
	}
}

implementation
{
	task void sendMsg();
	TOS_Msg msg; 	
	#define TimeSyncPollMsg ((TimeSyncPoll *)(msg.data))
	uint8_t counter;
	enum
	{
		INTERRUPT_RATE = 100,
		REAL_INTERRUPTS = 7200,
	};

	command result_t StdControl.init(){
		call Leds.init();
		TimeSyncPollMsg->senderAddr = GENERIC_BASE_ADDR;
		TimeSyncPollMsg->msgID = 0;
		counter=REAL_INTERRUPTS/INTERRUPT_RATE;
		return SUCCESS;
	}
	command result_t StdControl.start(){
		call PrecisionTimer.start2(TIMER_REPEAT, 200);
		call Timer.start(TIMER_REPEAT, INTERRUPT_RATE);
		return SUCCESS;
	}
	command result_t StdControl.stop(){
		return SUCCESS;
	}
	
	event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success){
		return SUCCESS;
	}
	event result_t Timer.fired(){
		if (--counter!=0)
			return SUCCESS;

		call Leds.greenToggle();
		counter=REAL_INTERRUPTS/INTERRUPT_RATE;
		call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCPOLL_LEN, &msg);
		++(TimeSyncPollMsg->msgID);
		
		return SUCCESS;
	}
	event result_t PrecisionTimer.fired(){
		return SUCCESS;
	}

}
