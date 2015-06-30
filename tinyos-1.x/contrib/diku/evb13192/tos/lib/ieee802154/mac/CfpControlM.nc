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

module CfpControlM
{
	provides
	{
		interface IeeeIndication<Mlme_GtsIndication> as MlmeIndicationGts;		
		interface IeeeRequestConfirm<Mlme_GtsRequestConfirm> as MlmeRequestConfirmGts;
		interface CfpTx;
		interface BeaconGtsService;
	}
	uses
	{
		interface CapTx as DeviceTx;
		interface CapEvents as CoordinatorCfp;
		interface CapEvents as DeviceCfp;
		interface RxFrame as GtsReqFrame;
		interface FrameRx;
		interface FrameTx;
		interface AsyncAlarm<time_t> as CfpAlarm;
		interface AsyncAlarm<time_t> as RxOffAlarm;
		interface MacAddress;
		interface LocalTime;
		interface Superframe;
		interface IeeeBufferManagement as BufferMng;
		interface CallbackService;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	// Global variables.	
	#define COORDCFP    1
	#define DEVICECFP   2
	
	#define TXDIRECTION 0
	#define RXDIRECTION 1

	// Only one GTS request can be processed at a time.
	Mlme_GtsRequestConfirm gtsConfirm;

	// First two descriptors are for device operation.
	// Descriptor 0 = device transmit
	// Descriptor 1 = device receive
	// Descriptor 2-8 = coordinator GTS's
	gtsDescriptor_t descriptorSlots[9];

	cfpTx_t dataQueue[CFPTXQUEUESIZE];
	txDoneEntry_t doneQueue[NUMCFPDONESLOTS];
	uint8_t doneQueueCount = 0;
	bool donePosted = FALSE;
	txdata_t myTxData;
	uint8_t pendingDataSlot;
	uint8_t curCfp = DEVICECFP;
	uint8_t nextActiveSlot;
	bool cfpTimerArmed = FALSE;

	// Timeout variables.
	bool waitingForGtsUpdate = FALSE;
	uint8_t waitCount;

	task void txDoneTask();
	void tendDataSlots(uint8_t sfSlot);
	void createGtsIndication(uint8_t slot);
	void indicateGts(uint8_t *gtsIndication);

	command void BeaconGtsService.gtsUpdate(uint8_t start, uint8_t length, bool deviceRxSlot)
	{
		uint8_t mySlot = (deviceRxSlot?RXDIRECTION:TXDIRECTION);
		if (start != 0) {
			// If start != 0 this is either an allocation or reallocation.
			// Just update the slot.
			descriptorSlots[mySlot].shortAddr = macShortAddress;
			descriptorSlots[mySlot].startSlot = start;
			descriptorSlots[mySlot].duration = length;
			descriptorSlots[mySlot].direction = mySlot;
			descriptorSlots[mySlot].valid = TRUE;
			if (waitingForGtsUpdate) {
				waitingForGtsUpdate = FALSE;
				gtsConfirm->msg.confirm.status = IEEE802154_SUCCESS;
				signal MlmeRequestConfirmGts.confirm(gtsConfirm);
			}
		} else {
			// Else we have a failed allocation or a deallocation.
			if (waitingForGtsUpdate) {
				gtsConfirm->msg.confirm.status = IEEE802154_DENIED;
				signal MlmeRequestConfirmGts.confirm(gtsConfirm);
			} else {
				if (descriptorSlots[mySlot].valid) {
					// Just invalidate the entry.
					descriptorSlots[mySlot].valid = FALSE;
					// Signal a gts indication.
					createGtsIndication(mySlot);
					// TODO: if deviceTxSlot, fail all entries in the data queue.
				}
			}
		}
	}

	command void BeaconGtsService.beaconReceived()
	{
		// Check if we were waiting for a GTS update.
		if (waitingForGtsUpdate) {
			if (--waitCount == 0) {
				// Timeout!
				waitingForGtsUpdate = FALSE;
				gtsConfirm->msg.confirm.status = IEEE802154_NO_DATA;
				signal MlmeRequestConfirmGts.confirm(gtsConfirm);
			}
		}
	}

	command void BeaconGtsService.getPublishedGts(uint8_t *descriptorCount, uint8_t *data)
	{
		uint8_t i;
		msduGTSList_t *gtsList = (msduGTSList_t*)(data + 1);
		uint8_t gtsDirections = 0;
		uint8_t gtsCount = 0;
		// Check if we have coordinator GTS's that should be published.
		for (i=2;i<9;i++) {
			// We check if the GTS has timed out!
			if (descriptorSlots[i].valid && !(descriptorSlots[i].timeout--)) {
				descriptorSlots[i].valid = FALSE;
				descriptorSlots[i].startSlot = 0;
				
				// CAP length is increased and GTS's are reorganised if necessary.
				coordinatorSuperframe.capLength += descriptorSlots[i].duration;
				// TODO: Reorganise gts's.
				descriptorSlots[i].beaconPublishCount = aGTSDescPersistenceTime;
				createGtsIndication(i);
			}
			if (descriptorSlots[i].beaconPublishCount) {
				// We have a valid descriptor to be published.
				// Remember that directions are "reversed" on coordinator side.
				gtsDirections += !(descriptorSlots[i].direction) << gtsCount;
				gtsList->DeviceShortAddress = descriptorSlots[i].shortAddr;
				gtsList->GTSStartingSlot = descriptorSlots[i].startSlot;
				gtsList->GTSLength = descriptorSlots[i].duration;
				// Decrement publish count.
				descriptorSlots[i].beaconPublishCount--;
				gtsList++;
				gtsCount++;
			}
		}
		if (gtsCount) {
			*(data) = gtsDirections;
		}
		*(descriptorCount) = gtsCount;
	}

	command void CfpTx.dataReceived()
	{
		uint8_t curSlot, cfpStartSlot, i;
		
		if (curCfp == DEVICECFP) {
			// Devices does not keep track of slot timeouts.
			return;
		}
		
		curSlot = call Superframe.getCurrentSlot(&coordinatorSuperframe);
		cfpStartSlot = coordinatorSuperframe.capLength-1;
		
		if (curSlot < cfpStartSlot || curSlot > 0xF) {
			return;
		}
		
		// We have a data reception in cfp.
		for (i=2;i<9;i++) {
			if (descriptorSlots[i].valid && descriptorSlots[i].direction == RXDIRECTION
			    && descriptorSlots[i].startSlot <= curSlot
			    && (descriptorSlots[i].startSlot + descriptorSlots[i].duration - 1) >= curSlot) {
				// We have a winner :-)
				// Reset the descriptor timeout.
				descriptorSlots[i].timeout = call Superframe.gtsTimeout(&coordinatorSuperframe);
				break;
			}
		}
	}

	/* Transmit a frame in CFP. */
	command void CfpTx.sendFrame(txHeader_t *header)
	{
		uint8_t myDescriptor;
		bool descriptorFound = FALSE;
		ieeeAddress_t dstAddr;
		
		DBG_STR("Trying to enqueue data for GTS transmission",1);
		
		// Check destination address.
		call MacAddress.getDstAddr(header->frame, &dstAddr);
		if ((dstAddr.mode == 2 && *((uint16_t*)dstAddr.address) == macCoordShortAddress)
		    || (dstAddr.mode == 3 && int64Compare(dstAddr.address, macCoordExtendedAddress))) {
			// Check if we have a valid device GTS
			if (descriptorSlots[TXDIRECTION].valid) {
				// We have a valid descriptor.
				myDescriptor = TXDIRECTION;
				descriptorFound = TRUE;
			}
		} else if (macCoordinator && dstAddr.mode == 2) {
			uint8_t i;
			uint16_t shortAddr = *((uint16_t*)dstAddr.address);
			// Check if we have a valid coordinator GTS
			for (i=2;i<9;i++) {
				if (descriptorSlots[i].valid && descriptorSlots[i].shortAddr == shortAddr
				    && descriptorSlots[i].direction == TXDIRECTION) {
					// We have a valid descriptor.
					myDescriptor = i;
					descriptorFound = TRUE;
					break;
				}
			}
		}
		
		if (descriptorFound) {
			// Enqueue header.
			uint8_t i;
			for (i=0;i<CFPTXQUEUESIZE;i++) {
				if (dataQueue[i].status == SLOT_EMPTY) {
					dataQueue[i].status = SLOT_PENDING;
					dataQueue[i].header = header;
					dataQueue[i].gtsIndex = myDescriptor;
					// TODO: Check if we can transmit the frame at once, by running
					//       the tend command.
					DBG_STRINT("Data enqueued for transmission in data slot:",i,1);
					return;
				}
			}
			// If this point is reached, no queue space is left.
			header->status = IEEE802154_TRANSACTION_OVERFLOW;
			DBG_STR("Transaction overflow",1);
		} else {
			// Invalid request. No available GTS.
			header->status = IEEE802154_INVALID_GTS;
			DBG_STR("Invalid GTS request",1);
		}
		// If we get here, we need to report an error back.
		doneQueue[doneQueueCount++].header = header;
		if (!donePosted) {
			donePosted = post txDoneTask();
			DBG_STR("Send failed :-(",1);
		}
	}

	event void CoordinatorCfp.startNotification()
	{
//		time_t temp = call LocalTime.getTime();
//		time_t capEnd = call Superframe.getCapEnd(&coordinatorSuperframe);
//		DBG_STRINT("CAP ends at:",capEnd,1);
//		DBG_STRINT("CFP started at:",temp,1);
		uint8_t slot = call Superframe.getCurrentSlot(&coordinatorSuperframe);
		curCfp = COORDCFP;
		tendDataSlots(slot+1);
	}
	
	event void DeviceCfp.startNotification()
	{
//		time_t temp = call LocalTime.getTime();
//		time_t capEnd = call Superframe.getCapEnd(&deviceSuperframe);
//		DBG_STRINT("CAP ends at:",capEnd,1);
//		DBG_STRINT("CFP started at:",temp,1);
		uint8_t slot = call Superframe.getCurrentSlot(&deviceSuperframe);
		//DBG_STRINT("Current superframe slot is:",slot,1);
		curCfp = DEVICECFP;
		tendDataSlots(slot+1);
	}
	
	command result_t MlmeRequestConfirmGts.request(Mlme_GtsRequestConfirm request)
	{
		// We just transmit the gts request.
		txHeader_t *myTxHeader;
		
		// If no short address is assigned, we fail.
		if (macShortAddress == aBcastShortAddr || macShortAddress == aNoShortAddr) {
			request->msg.confirm.status = IEEE802154_NO_SHORT_ADDRESS;
			return FAIL;
		}
		
		gtsConfirm = request;
		
		// Allocate the txHeader.
		if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
			DBG_STR("FATAL: Data, could not claim memory for transmission header",1);
			return FAIL;
		}
		
		// Build the txHeader.
		myTxHeader->addDsn = TRUE;
		myTxHeader->frame = request->msg.request.GTSRequestFrame;
		myTxHeader->length = 9;
		myTxHeader->isData = FALSE;
		
		// Direct transfer.
		call DeviceTx.sendFrame(myTxHeader);
		return SUCCESS;
	}
	
	event void DeviceTx.done(txHeader_t *header)
	{
		// Set status and frame.
		// NOTE: GTS request is deallocated with the confirm primitive.
		gtsConfirm->msg.confirm.status = header->status;
		gtsConfirm->msg.confirm.GTSRequestFrame = header->frame;
		
		// Deallocate the tx header.
		if (SUCCESS != call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header)) {
			DBG_STR("WARNING: Data, could not release memory for transmission header",1);
		}
		
		if (gtsConfirm->msg.confirm.status == IEEE802154_SUCCESS && gtsConfirm->msg.confirm.gtsType) {
			waitingForGtsUpdate = TRUE;
			waitCount = aGTSDescPersistenceTime;
			// TODO: Handle sync loss!
		} else {
			// An error was encountered while sending the GTS request
			// or the request was a deallocation.
			if (gtsConfirm->msg.confirm.gtsType == 0) {
				// If deallocation, invalidate the descriptor slot.
				descriptorSlots[gtsConfirm->msg.confirm.gtsDirection].valid = FALSE;
			}
			signal MlmeRequestConfirmGts.confirm(gtsConfirm);
		}
	}
	
	async event uint8_t *GtsReqFrame.received(rxdata_t *data)
	{
		msduGtsCharacteristics_t *myGtsChar = msduGtsRequestGtsCharacteristics(data->frame);
		uint16_t deviceAddr = *((uint16_t*)mhrSrcAddr(data->frame));
		bool indicateEvent = FALSE;
		DBG_STR("Received GTS request frame",1);
		if (!macGtsPermit) {
			// We do not permit allocation of GTS slots. Just ignore the request.
			return data->frame;
		}
		if (myGtsChar->CharType == 1) {
			// Try to allocate GTS.
			uint8_t myDescriptor;
			bool descriptorFound = FALSE;
			uint8_t i;
			DBG_STR("Try to allocate GTS",1);
			// Find an available descriptor slot.
			for (i=2;i<9;i++) {
				if (!(descriptorSlots[i].valid) && !(descriptorSlots[i].beaconPublishCount)) {
					// We have a available descriptor slot.
					myDescriptor = i;
					descriptorFound = TRUE;
					break;
				}
			}
			if (!descriptorFound) {
				// We have no free descriptors...
				DBG_STR("No free descriptors..",1);
				// TODO: Can we just ignore this and let the requesting device fail
				//       with status NO_DATA?
				return data->frame;
			}
			if ((coordinatorSuperframe.capLength - myGtsChar->GTSLength)*coordinatorSuperframe.slotLength
			    < aMinCAPLength) {
				// We can't allocate this GTS without making the CAP too small.
				DBG_STR("GTS allocation makes CAP too small",1);
				descriptorSlots[i].valid = FALSE;
				descriptorSlots[i].startSlot = 0;
				descriptorSlots[i].duration = aNumSuperframeSlots;
				// Remember that GTS directions are "reversed" on coordinator side.
				descriptorSlots[i].direction = !(myGtsChar->GTSDirection);
				descriptorSlots[i].shortAddr = deviceAddr;
				descriptorSlots[i].beaconPublishCount = aGTSDescPersistenceTime;
			} else {
				DBG_STR("We allocate the GTS",1);
				// Update the coordinator superframe cap.
				coordinatorSuperframe.capLength -= myGtsChar->GTSLength;
				// Just go ahead and allocate the GTS
				descriptorSlots[i].valid = TRUE;
				// We count superframe slots from 0. So CapLength is actually equal to
				// the slot index of the start of the CFP.
				descriptorSlots[i].startSlot = coordinatorSuperframe.capLength;
				descriptorSlots[i].duration = myGtsChar->GTSLength;
				// Remember that GTS directions are "reversed" on coordinator side.
				descriptorSlots[i].direction = !(myGtsChar->GTSDirection);
				descriptorSlots[i].shortAddr = deviceAddr;
				descriptorSlots[i].beaconPublishCount = aGTSDescPersistenceTime;
				descriptorSlots[i].timeout = call Superframe.gtsTimeout(&coordinatorSuperframe);
				createGtsIndication(i);
			}
		} else {
			// Try to deallocate GTS.
			uint8_t i;
			DBG_STR("Try to deallocate GTS",1);
			// Find GTS to deallocate.
			for (i=2;i<9;i++) {
				if (descriptorSlots[i].valid && descriptorSlots[i].shortAddr == deviceAddr
				    && descriptorSlots[i].direction == !(myGtsChar->GTSDirection)) {
					// We have match. Invalidate descriptor.
					DBG_STR("Got a matching descriptor",1);
					descriptorSlots[i].valid = FALSE;
					// CAP length is increased and GTS's are reorganised if necessary.
					coordinatorSuperframe.capLength += descriptorSlots[i].duration;
					// TODO: Reorganise gts's.
					// NOTE: Deallocation is not publish in the beacon.
					descriptorSlots[i].beaconPublishCount = 0;
					createGtsIndication(i);
					break;
				}
			}
		}
		return data->frame;
	}
	
	task void txDoneTask()
	{
		while(doneQueueCount) {
			signal CfpTx.done(doneQueue[--doneQueueCount].header);
		}
		donePosted = FALSE;
	}

	void tendDataSlots(uint8_t sfSlot)
	{
		time_t slotStart;
		uint8_t i, myMin, myMax;
		superframe_t *mySuperframe;
		bool activeDescriptorFound = FALSE;
		
		if (sfSlot > 0xF) {
			return;
		}
		
		if (curCfp == DEVICECFP) {
			myMin = 0;
			myMax = 2;
			mySuperframe = &deviceSuperframe;
		} else {
			// Assume coordinator cfp.
			myMin = 2;
			myMax = 9;
			mySuperframe = &coordinatorSuperframe;
		}
		
		// We arm the timer for the next relevant GTS slot.
		if (!cfpTimerArmed) {
			uint8_t nextSlot = 0;
			nextActiveSlot = 0;
			// Find next active slot.
			for (i = myMin; i < myMax; i++) {
				if (descriptorSlots[i].valid && descriptorSlots[i].startSlot > sfSlot
				    && descriptorSlots[i].startSlot < nextSlot) {
					nextSlot = descriptorSlots[i].startSlot;
				}
			}
			if (nextSlot) {
				// Arm the alarm to fire just before we reach the next active slot.
				time_t nextSlotStart = call Superframe.getSlotStartTime(mySuperframe, nextSlot);
				nextActiveSlot = nextSlot;
				call CfpAlarm.armAlarmClock(nextSlotStart-82);
				cfpTimerArmed = TRUE;
			}
		}
		
		slotStart = call Superframe.getSlotStartTime(mySuperframe, sfSlot);
		
		// Find GTS active in current superframe slot.
		for (i=myMin;i<myMax;i++) {
			if (descriptorSlots[i].valid) {
				if (descriptorSlots[i].direction == RXDIRECTION) {
					// We have a receive GTS.
					if (descriptorSlots[i].startSlot == sfSlot) {
						uint8_t endSlot = sfSlot + descriptorSlots[i].duration - 1;
						// Start the receiver at the slot boundary.
						if (PHY_SUCCESS != call FrameRx.rxOn(slotStart-12)) {
							DBG_STR("Warning: CfpControl, could not enable receiver!",1);
						}
						// Turn of receiver at the end of the GTS if not followed by an active slot.
						if (endSlot != nextActiveSlot-1 && endSlot < 0xF) {
							// Turn off receiver at end of GTS.
							time_t offTime = call Superframe.getSlotStartTime(mySuperframe, endSlot+1);
							call RxOffAlarm.armAlarmClock(offTime);
							DBG_STRINT("Need to turn off receiver in end of slot:",endSlot,1);
						}
						//DBG_STRINT("Found active rx slot in descriptor:",i,1);
						activeDescriptorFound = TRUE;
						break;
					}
				} else {
					// Must be a transmit GTS.
					if (descriptorSlots[i].startSlot <= sfSlot && (descriptorSlots[i].startSlot + descriptorSlots[i].duration - 1) >= sfSlot) {
						// Check if we have something to send.
						uint8_t j;
						//DBG_STR("Check if we have something to transmit",1);
						for (j=0;j<CFPTXQUEUESIZE;j++) {
							if (dataQueue[j].gtsIndex == i && dataQueue[j].status == SLOT_PENDING) {
								// We send the data if it fits in the current gts.
								// TODO: Check that tx fits in gts.
								
								// We have data. Reset timeout interval.
								descriptorSlots[i].timeout = call Superframe.gtsTimeout(mySuperframe);
								//DBG_STRINT("Valid data in queue index:",i,1);
								myTxData.frame = dataQueue[j].header->frame;
								myTxData.length = dataQueue[j].header->length;
								myTxData.cca = FALSE;
								
								// Check time.
								// TODO: Use isPast command in localtime.
								if (slotStart < call LocalTime.getTime()) {
									myTxData.immediateCommence = TRUE;
									//DBG_STR("Sending at once!",1);
								} else {
									myTxData.immediateCommence = FALSE;
									myTxData.commenceTime = slotStart;
									//DBG_STR("Sending in future!",1);
								}
								pendingDataSlot = j;
								call FrameTx.tx(&myTxData);
								activeDescriptorFound = TRUE;
								//DBG_STRINT("Sending data in data slot:",j,1);
								break;
							}
						}
						// Active slot found.. No need to search further.
						//DBG_STRINT("Found active tx slot in descriptor:",i,1);
						break;
					}
				}
			}
		}
		if (!activeDescriptorFound) {
			// Disable the transciever.
			call FrameRx.trxOff(TRUE);
		}
	}
	
	async event void FrameTx.txDone(phy_error_t error)
	{
		DBG_STRINT("Send done with status",error,1);
		if (error == PHY_SUCCESS) {
			dataQueue[pendingDataSlot].header->status = TX_SUCCESS;
			doneQueue[doneQueueCount++].header = dataQueue[pendingDataSlot].header;
			dataQueue[pendingDataSlot].status = SLOT_EMPTY;
		} else if (error == PHY_ACK_FAIL) {
			if (dataQueue[pendingDataSlot].header->txRetries) {
				// Retry transmission.
				dataQueue[pendingDataSlot].header->txRetries--;
				dataQueue[pendingDataSlot].status = SLOT_PENDING;
				// TODO: Call tend operation once more.
				return;
			} else {
				// Entry failed ack too many times.
				dataQueue[pendingDataSlot].header->status = TX_NO_ACK;
				doneQueue[doneQueueCount++].header = dataQueue[pendingDataSlot].header;
				dataQueue[pendingDataSlot].status = SLOT_EMPTY;
			}
		}
		
		// Tend the pending enties in the done queue.
		if (!donePosted) {
			donePosted = post txDoneTask();
		}
		post txDoneTask();
	}
	
	void createGtsIndication(uint8_t slot)
	{
		// Signal a gts indication.
		mlmeGTSIndication_t *myGtsIndication;
		msduGtsCharacteristics_t *myChars;
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeGTSIndication_t),(uint8_t**)(&myGtsIndication))){
			DBG_STR("WARNING: CfpControl, Unable to claim buffer for gts indication!",1);
			return;
		}
		myGtsIndication->msg.indication.address = descriptorSlots[slot].shortAddr;
		myChars = (msduGtsCharacteristics_t*)&(myGtsIndication->msg.indication.gtsCharacteristics);
		
		if (slot < 2) {
			myChars->GTSDirection = descriptorSlots[slot].direction;
		} else {
			// Directions are "reversed" on coordinator side.
			myChars->GTSDirection = !(descriptorSlots[slot].direction);
		}
		if (descriptorSlots[slot].valid) {
			myChars->GTSLength = descriptorSlots[slot].duration;
			myChars->CharType = 1;
		} else {
			myChars->GTSLength = 0;
			myChars->CharType = 0;
		}
		// Support security some day.
		myGtsIndication->msg.indication.securityUse = FALSE;
		myGtsIndication->msg.indication.ACLEntry = 0x08;
		call CallbackService.enqueue((uint8_t*)myGtsIndication, indicateGts);
	}
	
	async event result_t RxOffAlarm.alarm()
	{
		// Turn off the receiver.
		call FrameRx.trxOff(TRUE);
	}
	
	async event result_t CfpAlarm.alarm()
	{
		cfpTimerArmed = FALSE;
		tendDataSlots(nextActiveSlot);
		return SUCCESS;
	}
	
	// Gts indication callback.
	void indicateGts(uint8_t *gtsIndication)
	{
		signal MlmeIndicationGts.indication((Mlme_GtsIndication)gtsIndication);
	}
	
	default event void MlmeRequestConfirmGts.confirm(Mlme_GtsRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmGts.confirm",1);
	}
	
	default event void MlmeIndicationGts.indication(Mlme_GtsIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationGts.indication",1);
	}
}
