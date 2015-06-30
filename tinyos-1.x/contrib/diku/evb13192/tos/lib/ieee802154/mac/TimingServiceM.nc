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

#include "MacSuperframes.h"

module TimingServiceM
{	
	provides
	{
		interface TimingService[uint8_t service];
	}
	uses
	{
		interface AsyncAlarm<time_t> as ResponseWaitAlarm;
		interface AsyncAlarm<time_t> as FrameResponseAlarm;
		interface Debug;
	}
	
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	typedef struct
	{
		bool active;
		uint8_t service;
		time_t waitTime;
		
	} waitEntry_t;
	
	waitEntry_t waitState[2];
	
	uint8_t responseWaitService;
	uint8_t frameResponseService;
	
	command void TimingService.waitForResponse[uint8_t service]()
	{
	//	waitState[0].active = TRUE;
	//	waitState[0].
		responseWaitService = service;
		call ResponseWaitAlarm.armCountdown(aResponseWaitTime);
	}

	command void TimingService.waitForFrame[uint8_t service](superframe_t sf)
	{
		frameResponseService = service;
		call FrameResponseAlarm.armCountdown(aMaxFrameResponseTime);
	}

	command void TimingService.stopTimer[uint8_t service]()
	{
		if (responseWaitService == service) {
			call ResponseWaitAlarm.stop();
		}
		if (frameResponseService == service) {
			call FrameResponseAlarm.stop();
		}
	}

	async event result_t ResponseWaitAlarm.alarm()
	{
		signal TimingService.responseTimeout[responseWaitService]();
		return SUCCESS;
	}
	
	async event result_t FrameResponseAlarm.alarm()
	{
		signal TimingService.responseTimeout[frameResponseService]();
		return SUCCESS;
	}
	
	default async event void TimingService.responseTimeout[uint8_t service]()
	{
		DBG_STRINT("TimingService.responseTimeout not wired for service:",service,1);
	}
	
}
