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

module TestTimeSyncSuspM
{
	provides 
	{
		interface StdControl;
	}
	uses 
	{
		interface Timer as TimerSusp;
		interface Leds;
		interface RadioSuspend;
	}
}

implementation
{
	enum{
		TIMERSUSP_JIFFY = 32768u,
		INIT_PERIOD = 120,
		ON_PERIOD	= 60,
		OFF_PERIOD	=120,
		RADIO_SUSPENDED = 0,
		RADIO_WORKING	= 1,
	};

	uint8_t state, suspendCounter;


	command result_t StdControl.init(){
		call Leds.init();
		return SUCCESS;
	}
	command result_t StdControl.start(){
		state = RADIO_WORKING;
		
		suspendCounter=INIT_PERIOD;
		call TimerSusp.start2(TIMERSUSP_JIFFY);
		call Leds.yellowOn();

		return SUCCESS;
	}
	command result_t StdControl.stop(){
		return SUCCESS;
	}
	
	event result_t TimerSusp.fired()
	{
		if (--suspendCounter!=0)
			return SUCCESS;
		call Leds.yellowToggle();
		if (state==RADIO_WORKING){
			call RadioSuspend.suspend();
			suspendCounter = OFF_PERIOD;
			state = RADIO_SUSPENDED;
		}
		else{
			call RadioSuspend.resume();
			suspendCounter = ON_PERIOD;
			state = RADIO_WORKING;
		}
		return SUCCESS;
	}

}
