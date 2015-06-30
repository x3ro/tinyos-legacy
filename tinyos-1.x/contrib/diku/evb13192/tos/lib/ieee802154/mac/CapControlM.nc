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

module CapControlM
{	
	provides
	{
		// TODO:
		interface CapTx as CoordinatorTx[uint8_t token];
		interface CapTx as DeviceTx[uint8_t token];
		interface CapRx as DeviceRx;
		interface CapRx as CoordinatorRx;
		interface CapRx as PibChange;
		interface Reset;
		interface StdControl;
	}
	uses
	{
		interface CapEvents as CoordinatorCap;
		interface CapEvents as DeviceCap;
		interface FrameRx;
		interface Superframe;
		interface Csma;
		interface LocalTime;
		interface Debug;
	}
	
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	// Global variables.	
	#define COORDCAP    1
	#define DEVICECAP   2

	// Rx control.
	uint8_t coordCapRxOnCount = 0;
	uint8_t deviceCapRxOnCount = 0;
	
	// Tx control.
	capTx_t coordSlots[NUMCOORDCAPSLOTS];
	capTx_t deviceSlots[NUMDEVICECAPSLOTS];
	txDoneEntry_t doneQueue[NUMCAPDONESLOTS];
	uint8_t doneQueueCount = 0;
	bool donePosted = FALSE;

	uint8_t nextSlot;
	bool isPending = FALSE;
	uint8_t txPending;
	uint8_t pendingCap;
	
	task void sendDone();	
	void enqueueTx(txHeader_t *header, uint8_t cap, uint8_t token);
	void tendOperationQueue(uint8_t slot, uint8_t cap);
	bool prepareTxHeader(txHeader_t *header);
	void moveToDoneQueue(txHeader_t *header, uint8_t token);
	void tryRxOff();
	void tryRxOn();
	
	command result_t StdControl.init()
	{
		uint8_t i;
		for (i=0;i<NUMDEVICECAPSLOTS;i++) {
			deviceSlots[i].status = SLOT_EMPTY;
		}
		for (i=0;i<NUMCOORDCAPSLOTS;i++) {
			coordSlots[i].status = SLOT_EMPTY;
		}
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
	
	command void Reset.reset()
	{
		coordCapRxOnCount = 0;
		deviceCapRxOnCount = 0;
	}
	
	command void CoordinatorRx.rxOn()
	{
		coordCapRxOnCount++;
		tryRxOn();
	}

	command void CoordinatorRx.rxOff()
	{
		if (coordCapRxOnCount > 0) {
			coordCapRxOnCount--;
			tryRxOff();
		}
	}

	command void DeviceRx.rxOn()
	{
		deviceCapRxOnCount++;
		tryRxOn();
	}
	
	command void DeviceRx.rxOff()
	{
		if (deviceCapRxOnCount > 0) {
			deviceCapRxOnCount--;
			tryRxOff();
		}
	}
	
	command void PibChange.rxOn()
	{
		tryRxOn();
	}
	
	command void PibChange.rxOff()
	{
		tryRxOff();
	}

	event void CoordinatorCap.startNotification()
	{
//		time_t temp = call LocalTime.getTime();
//		DBG_STRINT("CAP started at:",temp,1);
		tendOperationQueue(0, COORDCAP);
	}
	
	event void DeviceCap.startNotification()
	{
		//time_t temp = call LocalTime.getTime();
		//DBG_STRINT("CAP started at:",temp,1);

		tendOperationQueue(0, DEVICECAP);
	}
	
	async event void Csma.done()
	{
		capTx_t *pendingEntry;
		
		if (pendingCap == DEVICECAP) {
			pendingEntry = &deviceSlots[txPending];
		} else {
			pendingEntry = &coordSlots[txPending];
		}
		
		if (pendingEntry->header->status == TX_NO_ACK &&
		    pendingEntry->header->txRetries) {
			DBG_STR("No ack was received!",1);
			DBG_STRINT("Retries left: ",pendingEntry->header->txRetries,1);
			// No ack was received. We just retry the frame.
			pendingEntry->status = SLOT_PENDING;
		}
		// Find out what to do with the frame based on status and retry info
		if (!(pendingEntry->header->txRetries) ||
		    pendingEntry->header->status == TX_SUCCESS ||
		    pendingEntry->header->status == TX_CHANNEL_ACCESS_FAILURE ) {
			
			// Move to done queue.
			moveToDoneQueue(pendingEntry->header, pendingEntry->doneToken);
			pendingEntry->status = SLOT_EMPTY;
			//DBG_STRINT("Transmission was done, slot:",txPending,1);
		}
		atomic isPending = FALSE;

		if (call Superframe.capActive(pendingEntry->header->superframe)) {
			// Serve next slot.
			tendOperationQueue(nextSlot, pendingCap);
		}
	}
	
	void enqueueTx(txHeader_t *header, uint8_t cap, uint8_t token)
	{
		uint8_t mySlot, i;
		bool emptySlotFound = FALSE;
		uint8_t maxSlots;
		capTx_t *queue;
		
		if (cap == DEVICECAP) {
			maxSlots = NUMDEVICECAPSLOTS;
			queue = deviceSlots;
		} else {
			maxSlots = NUMCOORDCAPSLOTS;
			queue = coordSlots;
		}
		
		// Find available transmission slot
		for (i=0;i<maxSlots;i++) {
			if (queue[i].status == SLOT_EMPTY) {
				// We have an empty slot!
				mySlot = i;
				emptySlotFound = TRUE;
				break;
			}
		}
		if (!emptySlotFound) {
			header->status = TX_CHANNEL_ACCESS_FAILURE;
			// Move to done queue.
			moveToDoneQueue(header, token);
			return;
		}
		
		// prepare the header	
		if (!prepareTxHeader(header)) {
			// The transmission does not fit in CAP!
			header->status = TX_FRAME_TOO_LONG;
			// Move to done queue.
			moveToDoneQueue(header, token);
			return;
		}
		queue[mySlot].status = SLOT_PENDING;
		queue[mySlot].header = header;
		queue[mySlot].doneToken = token;
		
		if (!isPending && call Superframe.capActive(header->superframe)) {
			tendOperationQueue(mySlot, cap);
		}
	}
	
	command void CoordinatorTx.sendFrame[uint8_t token]( txHeader_t *header )
	{
		header->superframe = &coordinatorSuperframe;
		enqueueTx(header, COORDCAP, token);
	}
	
	command void DeviceTx.sendFrame[uint8_t token]( txHeader_t *header )
	{
		header->superframe = &deviceSuperframe;
		enqueueTx(header, DEVICECAP, token);
	}
	
	task void sendDone()
	{
		uint8_t i;
		txHeader_t *header;
		uint8_t token;
		
		// We empty the done queue.
		while (doneQueueCount) {
			atomic {
				doneQueueCount--;
				header = doneQueue[doneQueueCount].header;
				token = doneQueue[doneQueueCount].doneToken;
			}
			if (header->superframe == &deviceSuperframe) {
				signal DeviceTx.done[token](header);
			} else {
				signal CoordinatorTx.done[token](header);
			}
		}
		atomic donePosted = FALSE;
	}
	
	void tendOperationQueue(uint8_t slot, uint8_t cap)
	{
		uint8_t i,s;
		uint8_t maxSlots;
		capTx_t *queue;
		
		if (cap == DEVICECAP) {
			maxSlots = NUMDEVICECAPSLOTS;
			queue = deviceSlots;
		} else {
			maxSlots = NUMCOORDCAPSLOTS;
			queue = coordSlots;
		}
		
		for (i=0;i<maxSlots;i++) {
			s = (slot+i)%maxSlots;
			if (queue[s].status == SLOT_PENDING || queue[s].status == CSMA_DEFERRED) {
				atomic {
					isPending = TRUE;
					txPending = s;
					pendingCap = cap;
				}
				DBG_STRINT("Sending data in slot:",s,1);
				call Csma.send(&queue[s]);
				nextSlot = (s+1)%maxSlots;
				return;
			}
		}
		
		// Nothing to be sent. We are idle!
		// Now try to enable the receiver.
		tryRxOn();
	}

	void tryRxOff()
	{
		// First we check if the receiver is really on.
		if (!phyIsReceiving) {
			// Can't turn it off if it ain't on ;-)
			return;
		}
		// Check each of the CAPs
		// NOTE: We do not allow both CAPs to be active at the same time!
		if (deviceCapActive && (deviceCapRxOnCount || macRxOnWhenIdle)) {
			// Receiver should in fact be on.
			return;
		}
		if (coordCapActive && (coordCapRxOnCount || macRxOnWhenIdle)) {
			// Receiver should in fact be on.
			return;
		}
		
		// Else we can safely turn off the receiver.
		call FrameRx.trxOff(FALSE);
		DBG_STR("Receiver disabled",1);
	}

	void tryRxOn()
	{
		// First we check that we are not already receiving
		if (phyIsReceiving || phyIsTransmitting) return;
		
		// Check each of the CAPs
		// NOTE: We do not allow both CAPs to be active at the same time!
		// NOTE: If we operate as a coordinator in a cluster-tree network,
		//       macRxOnWhenIdle only applies to the coordinator superframe.
		if (deviceCapActive && (deviceCapRxOnCount || (macRxOnWhenIdle && !macCoordinator))) {
			// Turn on receiver.
			if (PHY_SUCCESS != call FrameRx.rxOnNow()) {
				DBG_STR("Warning: CapControl, could not enable receiver!",1);
			}
			return;
		}
		if (coordCapActive && (coordCapRxOnCount || macRxOnWhenIdle)) {
			// Turn on receiver.
			if (PHY_SUCCESS != call FrameRx.rxOnNow()) {
				DBG_STR("Warning: CapControl, could not enable receiver!",1);
			}
			return;
		}
	}

	bool prepareTxHeader(txHeader_t *header)
	{
		header->txRetries = aMaxFrameRetries;
		header->status = TX_PENDING;
		return call Superframe.fitsInCap(header);
	}

	void moveToDoneQueue(txHeader_t *header, uint8_t token)
	{
		bool wasPosted;
		
		atomic {
			doneQueue[doneQueueCount].header = header;
			doneQueue[doneQueueCount].doneToken = token;
			doneQueueCount++;
			wasPosted = donePosted;
			donePosted = TRUE;
		}
		if (!wasPosted) {
			post sendDone();
		}
	}

	default event void CoordinatorTx.done[uint8_t token](txHeader_t *header)
	{
		DBG_STRINT("WARNING: CapControl, event CoordinatorTx.done not connected for token ",token,1);
	}
	
	default event void DeviceTx.done[uint8_t token](txHeader_t *header)
	{
		DBG_STRINT("WARNING: CapControl, event DeviceTx.done not connected for token ",token,1);
	}	
}
