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

#include "PhyTypes.h"
#include "mac.h"

module PollServiceM
{
	provides
	{
		interface PollService[uint8_t service];
		interface Reset;
	}
	uses
	{
		interface CapTx as DeviceTx;
		interface CapRx as DeviceRx;
		interface TimingService;
		interface PollEvents;
		interface MacAddress;
		interface Debug;
	}

}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	// Note that this module can only handle one poll at a time.
	// It would be possible to create two request queues, one for each poll type,
	// and handle subsequent requests upon poll completion.
	uint8_t dataRequestFrame[22];
	txHeader_t dataRequest;
	uint8_t pendingService;
	bool isPolling = FALSE;
	
	bool initPoll();
	bool doPoll();
	
	command void Reset.reset()
	{
		isPolling = FALSE;
	}
	
	command result_t PollService.pollCoordinator[uint8_t service](bool pollExtended)
	{
		if (!initPoll()) return FAIL;
		DBG_STRINT("Polling for service: ",service,1);
		pendingService = service;
		call MacAddress.setDstCoordinator(dataRequestFrame);
		call MacAddress.setSrcLocal(dataRequestFrame, pollExtended);
		if (!doPoll()) return FAIL;
		return SUCCESS;
	}
	
	command result_t PollService.pollAddress[uint8_t service](ieeeAddress_t *coordAddr)
	{
		if (!initPoll()) return FAIL;
		DBG_STRINT("Polling for service: ",service,1);
		pendingService = service;
		call MacAddress.setDstAddr(dataRequestFrame, coordAddr);
		call MacAddress.setSrcLocal(dataRequestFrame, FALSE);
		if (!doPoll()) return FAIL;
		return SUCCESS;
	}
	
	bool initPoll()
	{
		bool wasPolling;
		
		atomic {
			wasPolling = isPolling;
			isPolling = TRUE;
		}
		
		if (wasPolling) return FALSE;

		// Init the data request frame.
		mhrFrameType(dataRequestFrame) = macCommandFrame;
		mhrIntraPAN(dataRequestFrame) = TRUE;
	}
	
	bool doPoll()
	{
		uint8_t frameLength;
		
		msduCommandFrameIdent(dataRequestFrame) = macCommandDataReq;
		frameLength = mhrLengthFrame(dataRequestFrame) + 1;

		DBG_DUMP(dataRequestFrame, frameLength, 1);

		// Build the txHeader.
		dataRequest.addDsn = TRUE;
		dataRequest.frame = dataRequestFrame;
		dataRequest.length = frameLength;
		dataRequest.isData = FALSE;
		
		// Call cap control to transmit the data request frame.
		call DeviceTx.sendFrame(&dataRequest);
		call DeviceRx.rxOn();
		return TRUE;
	}

	event void DeviceTx.done(txHeader_t *header)
	{
		if (dataRequest.status != IEEE802154_SUCCESS) {
			isPolling = FALSE;
			call DeviceRx.rxOff();
			DBG_STRINT("Poll, could not transmit! ",pendingService,1);
			signal PollService.done[pendingService](dataRequest.status);
		} else {
			// We have to wait for the polled frame.
			call PollEvents.waitForPolledFrame();
			call TimingService.waitForFrame(deviceSuperframe);
		}
	}
	
	async event void TimingService.responseTimeout()
	{
		isPolling = FALSE;
		call PollEvents.pollTimedOut();
		// No data was available.
		call DeviceRx.rxOff();
		DBG_STRINT("Poll, timeout! ",pendingService,1);
		signal PollService.done[pendingService](IEEE802154_NO_DATA);
	}
	
	async event void PollEvents.noDataAvailable()
	{
		isPolling = FALSE;
		// No data was available.
		call DeviceRx.rxOff();
		DBG_STRINT("Poll, no data!",pendingService,1);
		signal PollService.done[pendingService](IEEE802154_NO_DATA);
	}
	
	async event void PollEvents.gotPolledFrame()
	{
		isPolling = FALSE;
		call TimingService.stopTimer();
		// Everything is good.
		call DeviceRx.rxOff();
		DBG_STRINT("Poll, success! ",pendingService, 1);
		signal PollService.done[pendingService](IEEE802154_SUCCESS);
	}
	
	default event void PollService.done[uint8_t service](Ieee_Status status)
	{
		DBG_STRINT("PollService.done not connected for service:",service,1);
	}
}
