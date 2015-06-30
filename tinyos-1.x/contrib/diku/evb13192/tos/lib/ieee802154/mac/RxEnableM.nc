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

module RxEnableM
{
	provides
	{
		interface IeeeRequestConfirm<Mlme_RxEnableRequestConfirm> as MlmeRequestConfirmRxEnable;
	}
	uses
	{
		interface CapRx as DeviceRx;
		interface CapRx as CoordinatorRx;
		interface Superframe;
		interface AsyncAlarm<time_t> as RxEnableAlarm;
		interface LocalTime;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	Mlme_RxEnableRequestConfirm primitiveQueue[RXENABLEQUEUESIZE];
	uint8_t primitiveQueueCount = 0;

	Mlme_RxEnableRequestConfirm myPrimitive = NULL;
	bool doArmReceiver;
	bool receiverOn = FALSE;

	void turnOnReceiver();
	void turnOffReceiver();
	void processPrimitive();
	task void confirmRxEnable();

	command result_t MlmeRequestConfirmRxEnable.request(Mlme_RxEnableRequestConfirm request)
	{
		if (myPrimitive == NULL) {
			// No pending requests. Process request immediately.
			DBG_STR("Process immediately",1);
			myPrimitive = request;
			processPrimitive();	
		} else {
			// Add to queue.
			DBG_STR("Defer processing",1);
			primitiveQueue[primitiveQueueCount++] = request;
		}
		return SUCCESS;
	}
	
	void processPrimitive()
	{
		time_t onTime = myPrimitive->msg.request.rxOnTime;
		time_t duration = myPrimitive->msg.request.rxOnDuration;
		superframe_t *sf;
	
		if (!duration) {
			DBG_STR("Turn off receiver",1);
			// We turn the receiver off if currently on.
			if (receiverOn) turnOffReceiver();
			myPrimitive->msg.confirm.status = IEEE802154_SUCCESS;
			post confirmRxEnable();
			return;
		}

		if (!macBeaconEnabled) {
			DBG_STR("No beacon. Turn on receiver.",1);
			// Just enable the receiver for RxOnDuration symbols.
			turnOnReceiver();
			return;
		}
			
		// Find out to which superframe we apply this request.
		// If we are not a PAN coordinator this will be the device superframe.
		if (macPanCoordinator) {
			sf = &coordinatorSuperframe;
		} else {
			sf = &deviceSuperframe;
		}
		// Check if the rxEnable interval fits within two beacons.
		if (sf->beaconInterval < onTime + duration) {
			// We can't overlap a beacon period.
			myPrimitive->msg.confirm.status = IEEE802154_INVALID_PARAMETER;
			post confirmRxEnable();
			return;
		}
		// Check if we have already passed the onTime in the current superframe.
		// TODO: How much margin do we need? 50 is probably too much, while aTurnAroundTime
		//       is too little?
		if ((call LocalTime.getTime() - sf->startTime + 50) > onTime) {
			if (myPrimitive->msg.request.deferPermit) {
				// Defer until next superframe.
				doArmReceiver = TRUE;
				call RxEnableAlarm.armCountdown(call Superframe.getNextStart(sf) + onTime -50);
				return;
			} else {
				// We return fail with status OUT_OF_CAP.
				myPrimitive->msg.confirm.status = IEEE802154_OUT_OF_CAP;
				post confirmRxEnable();
				return;
			}
		}
		// We are able to enable the receiver in the current superframe.
		doArmReceiver = TRUE;
		call RxEnableAlarm.armCountdown(sf->startTime + onTime -50);
	}
	
	async event result_t RxEnableAlarm.alarm()
	{
		if (doArmReceiver) {
			// Turn on the receiver.
			turnOnReceiver();
		} else {
			// Turn receiver off.
			turnOffReceiver();
		}
		return SUCCESS;
	}
	
	void turnOnReceiver()
	{
		DBG_STR("In turnOnReceiver...",1);
		// Only turn on receiver if CAP is active.
		if (macPanCoordinator) {
			DBG_STR("I am PAN coordinator",1);
			// We operate on the coordinator superframe.
			if (call Superframe.capActive(&coordinatorSuperframe)) {
				DBG_STR("Turn on receiver in coordinator superframe.",1);
				call CoordinatorRx.rxOn();
				receiverOn = TRUE;
			}
		} else {
			DBG_STR("I am coordinator or device",1);
			// We operate on the device superframe.
			if (call Superframe.capActive(&deviceSuperframe)) {
				DBG_STR("Turn on receiver in device superframe.",1);
				call DeviceRx.rxOn();
				DBG_STR("Rx should be on now.",1);
				receiverOn = TRUE;
			}
			DBG_STR("Done.",1);
		}
		if (receiverOn) {
			DBG_STR("Receiver was turned on",1);
			// Program timeout and signal success.
			doArmReceiver = FALSE;
			call RxEnableAlarm.armCountdown(myPrimitive->msg.request.rxOnDuration);
			myPrimitive->msg.confirm.status = IEEE802154_SUCCESS;
			post confirmRxEnable();
		} else {
			DBG_STR("We were out of cap",1);
			// Signal confirm with status OUT_OF_CAP.
			myPrimitive->msg.confirm.status = IEEE802154_OUT_OF_CAP;
			post confirmRxEnable();
		}
	}
	
	void turnOffReceiver()
	{
		if (macPanCoordinator) {
			call CoordinatorRx.rxOff();
		} else {
			call DeviceRx.rxOff();
		}
		receiverOn = FALSE;
	}
	
	task void confirmRxEnable()
	{
		signal MlmeRequestConfirmRxEnable.confirm(myPrimitive);
		// Check the queue for pending requests.
		if (primitiveQueueCount) {
			myPrimitive = primitiveQueue[--primitiveQueueCount];
			processPrimitive();
		} else {
			myPrimitive = NULL;
		}
	}
	
	default event void MlmeRequestConfirmRxEnable.confirm(Mlme_RxEnableRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmRxEnable.confirm",1);
	}
}
