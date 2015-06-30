/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

module RTSchedulerM
{
	provides
	{
		interface RTScheduler;
		interface StdControl;
	}
	uses
	{
		interface IeeeRadioEvents as Events;
		interface FIFOQueue as Queue;
		interface AsyncAlarm<uint32_t> as Timer;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	uint8_t *taskBuffer[5];
	FIFOQueue_t taskQueue;
	bool pendingDefer = FALSE;
	uint32_t deferPeriod = 200;
	void (*deferFuncSlot)() = NULL;

	command result_t StdControl.init()
	{
		call Queue.initQueue(&taskQueue, taskBuffer, 5);
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	command result_t RTScheduler.deferExec(void (*deferredFunc)())
	{
		if (pendingDefer) {
			DBG_STR("We already have a pending defer!",1);
			return FAIL;
		}
		pendingDefer = TRUE;
		deferFuncSlot = deferredFunc;
		return call Timer.armCountdown(deferPeriod);
	}

	command result_t RTScheduler.doPost(void (*func)())
	{
		return call Queue.enqueue(&taskQueue, (uint8_t*)func);
	}
	
	command void RTScheduler.doSchedule()
	{
		uint8_t* fp = NULL;
		void (*func)();
		if (!(call Queue.isEmpty(&taskQueue)) && !pendingDefer) {
			call Queue.dequeue(&taskQueue, &fp);
			func = (void(*)())fp;
			call RTScheduler.deferExec(func);
		}
	}
	
	async event void Events.radioOperationDone()
	{
		call RTScheduler.doSchedule();
	}
	
	async event result_t Timer.alarm()
	{
		__nesc_enable_interrupt();
		pendingDefer = FALSE;
		deferFuncSlot();
		call RTScheduler.doSchedule();
		return SUCCESS;
	}
}
