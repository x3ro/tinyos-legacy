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

#include "mac.h"
#include "MacSuperframes.h"
#include "MacPib.h"

module BeaconGeneratorM
{
	provides
	{
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface BeaconGenerator;
		interface CapEvents as CoordinatorCap;
		interface CapEvents as CoordinatorCfp;
		//interface Reset;
	}
	uses
	{
		interface CapTx as CoordinatorTx;
		interface RxFrame as BeaconReqFrame;
		interface IeeeBufferManagement as BufferMng;
		interface AsyncAlarm<time_t> as BeaconAlarm;
		interface AsyncAlarm<time_t> as CfpAlarm;
		interface BeaconDataService;
		interface BeaconGtsService;
		interface FrameTx;
		interface LocalTime;
		interface Superframe;
		//interface PanConflict;
		interface MacAddress;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	uint8_t *myBeacon;
	uint8_t msduLength = 0;
	msduSuperframeSpec_t *sfSpec;
	
	time_t nextCommence;
	time_t capEnd;
	time_t cfpEnd;
	bool waitingForCapEnd = FALSE;
	bool waitingForCfpEnd = FALSE;
	
	txdata_t myTxData;
	bool firstBeacon = FALSE;
	
	void generateBeacon();
	void transmitBeacon();
	
	command result_t BeaconGenerator.start()
	{
		if (macPanCoordinator) {
			firstBeacon = TRUE;
			coordinatorSuperframe.capLength = 16;
			generateBeacon();
			transmitBeacon();
		} else {
			// Align beacon to PAN Coordinator beacon.
		}
		return SUCCESS;
	}
	
	command result_t BeaconGenerator.stop()
	{
		return SUCCESS;
	}
	
	async event uint8_t *BeaconReqFrame.received(rxdata_t *data)
	{
		if (!macBeaconEnabled) {
			// Transmit beacon in CAP.
			txHeader_t *myTxHeader;
			
			generateBeacon();
			
			// Allocate the txHeader.
			if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
				DBG_STR("FATAL: Associate, could not claim memory for transmission header",1);
			}
			
			// Build the txHeader.
			myTxHeader->addDsn = TRUE;
			myTxHeader->frame = myBeacon;
			myTxHeader->length = mhrLengthFrame(myBeacon) + msduLength;
			myTxHeader->isData = FALSE;

			call CoordinatorTx.sendFrame(myTxHeader);
		}
		return data->frame;
	}
	
	event void CoordinatorTx.done(txHeader_t *header)
	{
		// Release frame and tx header.
		call BufferMng.release(126, header->frame);
		call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header);
	}
	
	void generateBeacon()
	{
		// Here we generate a beacon msg.
		msduGTSSpec_t *gtsSpec;
		uint8_t descriptorCount;
		msduPendingAddrSpec_t *pendingSpec;
		uint8_t numShortAddrs;
		uint8_t numExtAddrs;
		
		// Allocate memory for the beacon frame.
		if (SUCCESS != call BufferMng.claim(126,&myBeacon)) {
			DBG_STR("WARNING: BeaconGenerator, Unable to claim buffer for beacon frame!",1);
			return;
		}
		
		// First we clear the first two bytes. Only the src addressing mode needs to be set
		// there! (Beacon frame = 0x00).
		myBeacon[0] = 0;
		myBeacon[1] = 0;
		// Set source address.
		call MacAddress.setSrcLocal(myBeacon, FALSE);
		// Set sequence number
		mhrSeqNumber(myBeacon) = macBsn;
		macBsn++;
		
		// Create the beacon msdu content.
		msduLength = 0;
		
		// Fill GTS spec.
		// NOTE: GTS specs needs to be set first, because the GTS publishing can
		//       alter the capLength;
		gtsSpec = msduGetGTSSpec(myBeacon);
		call BeaconGtsService.getPublishedGts(&descriptorCount, (uint8_t*)(gtsSpec+1));
		gtsSpec->GTSDescriptorCount = descriptorCount;
		gtsSpec->GTSPermit = macGtsPermit;
		if (descriptorCount) {
			msduLength += 2 + descriptorCount*3;
		} else {
			msduLength += 1;
		}
		
		// Fill in superframe spec.
		msduLength += 2;
		sfSpec = msduGetSuperframeSpec(myBeacon);
		sfSpec->BeaconOrder = macBeaconOrder;
		sfSpec->SuperframeOrder = macSuperframeOrder;
		sfSpec->FinalCAPSlot = coordinatorSuperframe.capLength - 1;
		sfSpec->BatteryLifeExtension = macBattLifeExt;
		sfSpec->PANCoordinator = macPanCoordinator;
		sfSpec->AssociationPermit = macAssociationPermit;
		
		// Fill pending addresses.
		pendingSpec = msduPendingAddrSpec(myBeacon);
		call BeaconDataService.getPendingAddrs(&(numShortAddrs),
		                                       &(numExtAddrs),
		                                       msduPendingAddrList(myBeacon));
		pendingSpec->NumShortAddrsPending = numShortAddrs;
		pendingSpec->NumExtAddrsPending = numExtAddrs;
		msduLength += 1 + 2*numShortAddrs + 8*numExtAddrs;
		
		// TODO: Append beacon payload.
	}
	
	void transmitBeacon()
	{
		// Transmit the frame.
		myTxData.frame = myBeacon;
		myTxData.length = mhrLengthFrame(myBeacon) + msduLength;
		myTxData.cca = FALSE;
		myTxData.immediateCommence = FALSE;
		// If first beacon, commence 100 symbol periods from now.
		if (firstBeacon) {
			firstBeacon = FALSE;
			myTxData.commenceTime = call LocalTime.getTime() + 100;
		} else {
			myTxData.commenceTime = nextCommence;
		}
		
		if (PHY_SUCCESS != call FrameTx.tx(&myTxData)) {
			DBG_STR("WARNING: BeaconGenerator, could not transmit beacon!",1);
			// Release the memory for the beacon frame.
			call BufferMng.release(126, myBeacon);
			return;
		}		
		// Update coordinator superframe.
		call Superframe.updateFromSpec(&coordinatorSuperframe, sfSpec,
		                               myTxData.commenceTime, myTxData.length);
		
		macBeaconTxTime = myTxData.commenceTime;
		
		nextCommence = call Superframe.getNextStart(&coordinatorSuperframe);
		
		// Set up the beacon alarm to fire just before next beacon transmission
		call BeaconAlarm.armAlarmClock(nextCommence-100);
	}
	
	async event void FrameTx.txDone(phy_error_t error)
	{
		// Release the memory for the beacon frame.
		call BufferMng.release(126, myBeacon);
		if (error == PHY_SUCCESS) {
			coordCapActive = TRUE;
			signal CoordinatorCap.startNotification();

			capEnd = call Superframe.getCapEnd(&coordinatorSuperframe);
			// We end the cap 82 symbols before real cap end.
			// This is due to the fact, that the shortest tx packet takes
			// 30 symbols to transmit. Including both 2*CCA + SIFS makes 82 symbols.
			if (capEnd < nextCommence) {
				// We need to activate CFP or idle period at CAP end.
				call CfpAlarm.armAlarmClock(capEnd-82);
				waitingForCapEnd = TRUE;
			}
			// Expire old indirect tx slots.
			call BeaconDataService.expireSlots();
		}
	}
	
	async event result_t BeaconAlarm.alarm()
	{
		// Time to transmit beacon.
		coordCapActive = FALSE;
		generateBeacon();
		transmitBeacon();
		return SUCCESS;
	}

	async event result_t CfpAlarm.alarm()
	{
		if (waitingForCapEnd) {
			// CAP has ended.
			coordCapActive = FALSE;
			if (call Superframe.cfpExists(&coordinatorSuperframe)) {
				// We start up the device CFP.
				signal CoordinatorCfp.startNotification();
				cfpEnd = call Superframe.getCfpEnd(&coordinatorSuperframe);
				if (cfpEnd < nextCommence) {
					call CfpAlarm.armAlarmClock(cfpEnd-82);
					waitingForCfpEnd = TRUE;
				}
			} else {
				// TODO: Below note could be a problem.
				// NOTE: Coordinator CAP and CFP can be active in the idle period.
				// Idle period.
			}
			waitingForCapEnd = FALSE;
		} else if (waitingForCfpEnd) {
			// TODO: Below note could be a problem.
			// NOTE: Coordinator CAP and CFP can be active in the idle period.
			// Idle period.
			waitingForCfpEnd = FALSE;
		}
		return SUCCESS;
	}
}
