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

module CallbackServiceM
{
	provides
	{
		interface StdControl;
		interface CallbackService;
	}
	uses
	{
		interface FIFOQueue as Queue;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	// Primitive queues.
	uint8_t *primitiveBuffer[10];
	FIFOQueue_t primitiveQueue;
	uint8_t *primitiveFuncBuffer[10];
	FIFOQueue_t primitiveFuncQueue;
	
	bool serviceTaskPosted = FALSE;
	
	task void serviceQueueTask();
	
	command result_t StdControl.init()
	{
		call Queue.initQueue(&primitiveQueue, primitiveBuffer, 10);
		call Queue.initQueue(&primitiveFuncQueue, primitiveFuncBuffer, 10);
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
	
	command void CallbackService.enqueue(uint8_t *primitive, void(*callback)(uint8_t*))
	{
			call Queue.enqueue(&primitiveQueue, primitive);
			call Queue.enqueue(&primitiveFuncQueue, (uint8_t*)callback);
			if (!serviceTaskPosted) {
				serviceTaskPosted = TRUE;
				post serviceQueueTask();
			}
	}
	
	task void serviceQueueTask()
	{
		uint8_t *primitive = NULL, *fp = NULL;
		void (*func)(uint8_t*);
		
		while (!(call Queue.isEmpty(&primitiveQueue))) {
			// Dequeue function and primitive.
			call Queue.dequeue(&primitiveQueue, &primitive);
			call Queue.dequeue(&primitiveFuncQueue, &fp);
			func = (void(*)(uint8_t*))fp;
			// Call to signal the right event.
			func(primitive);
		}
		serviceTaskPosted = FALSE;
	}
	
}
