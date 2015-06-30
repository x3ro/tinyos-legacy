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

module BeaconTrackerM
{
	provides
	{
		interface IeeeRequest<Mlme_SyncRequest> as MlmeRequestSync;
		interface IeeeIndication<Mlme_BeaconNotifyIndication> as MlmeIndicationBeaconNotify;
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface CapEvents as DeviceCap;
		interface CapEvents as DeviceCfp;
		interface Reset;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface AsyncAlarm<time_t> as TrackAlarm;
		interface AsyncAlarm<time_t> as CfpAlarm;
		interface PhyAttributes;
		interface CapTx as DeviceTx;
		interface FrameRx;
		interface RxFrame as BeaconFrame;
		interface PanConflict;
		interface Superframe;
		interface PollService;
		interface MacAddress;
		interface BeaconGtsService;
		interface CallbackService;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	void setBeaconTimeout();
	void disableBeaconMode();
	void beaconNotify(rxdata_t *data);
	void signalBeaconNotify(uint8_t *beaconNotifyInd);
	
	task void poll();
	task void missedBeacon();
	task void syncLoss();
	
	bool pollPosted = FALSE;
	bool pollExt;

	bool listening = FALSE;
	bool tracking = FALSE;
	bool waitingForCapEnd = FALSE;
	bool waitingForCfpEnd = FALSE;
	uint8_t numBeaconsLost = 0;
	uint8_t channel;
	time_t nextCommence;
	time_t capEnd;
	time_t cfpEnd;

	txHeader_t myTxHeader;

	command void Reset.reset()
	{
		pollPosted = FALSE;
		listening = FALSE;
		tracking = FALSE;
		waitingForCapEnd = FALSE;
		waitingForCfpEnd = FALSE;
		numBeaconsLost = 0;
	}

	command result_t MlmeRequestSync.request( Mlme_SyncRequest request )
	{
		// TODO: Make a queue so that we can have more than one sync request at
		//       a time.
		channel = request->msg.request.logicalChannel;
		tracking = request->msg.request.trackBeacon;
		
/*		if (channel > 26) {
			request->msg.confirm.status = IEEE802154_INVALID_PARAMETER;
			return FAIL;
		}
*/		
		// deallocate the primitive
		call BufferMng.release( sizeof(mlmeSyncRequestMsg_t), (uint8_t*)request );

		if (tracking) {
			if (SUCCESS != call PhyAttributes.setChannel(channel)) {
				DBG_STRINT("WARNING: BeaconTracker, could not change radio channel!",channel,1);
			}
			if (PHY_SUCCESS != call FrameRx.rxOnNow()) {
				DBG_STR("FATAL: BeaconTracker, Unable to enable receiver",1);
			}
			// Enable beacon mode.
			macBeaconEnabled = TRUE;
			deviceCapActive = FALSE;
			call PhyAttributes.setAckBackoffAlignment(TRUE);
			call PhyAttributes.setContentionWindow(2);
			
			atomic listening = TRUE;
	
			setBeaconTimeout();
		}
		return SUCCESS;
	}

	async event uint8_t *BeaconFrame.received(rxdata_t *data)
	{
		bool wasListening;
		time_t offset;
		uint8_t numGtsDesc;

		// stop the track alarm
		call TrackAlarm.stop();
		
		atomic {
			wasListening = listening;
			listening = FALSE;
		}
		if (!wasListening) { return data->frame; } // ignore stray beacons
		
		// Reset the lost beacon count.
		numBeaconsLost = 0;

		// unpack superframe info and update deviceSuperframe accordingly
		call Superframe.updateFromSpec( &deviceSuperframe,
		                                msduGetSuperframeSpec(data->frame),
		                                data->recvTime,
		                                data->length);		

		deviceCapActive = TRUE;
		signal DeviceCap.startNotification();
		
		nextCommence = call Superframe.getNextStart(&deviceSuperframe);
		capEnd = call Superframe.getCapEnd(&deviceSuperframe);
		// We end the cap 82 symbols before real cap end.
		// This is due to the fact, that the shortest tx packet takes
		// 30 symbols to transmit. Including both 2*CCA + SIFS makes 82 symbols.
		if (capEnd < nextCommence) {
			// We need to activate CFP or idle period at CAP end.
			call CfpAlarm.armAlarmClock(capEnd-82);
			waitingForCapEnd = TRUE;
		}
		//offset = data->recvTime + (8 + data->length)*2;
		//DBG_STRINT("CAP begining is:", offset,1);

		// Check GTS fields.
		numGtsDesc = msduGetGTSSpec(data->frame)->GTSDescriptorCount;
		if (numGtsDesc) {
			// Check if there are some changes for this device.
			uint8_t i;
			uint8_t gtsDirections = msduGTSDirectionMask(data->frame);
			msduGTSList_t *gtsList = msduGTSList(data->frame);

			for (i=0;i<numGtsDesc;i++) {
				if (gtsList->DeviceShortAddress == macShortAddress) {
					// We have a GTS update.
					call BeaconGtsService.gtsUpdate(gtsList->GTSStartingSlot, gtsList->GTSLength, gtsDirections & (1<<i));
				}
				gtsList += sizeof(msduGTSList_t);
			}
		}
		
		if (macAutoRequest) {
			// Check if we have pending data.
			uint8_t i,j;
			uint8_t numShortAddrs = msduNumShortAddrsPending(data->frame);
			uint8_t numExtAddrs = msduNumExtAddrsPending(data->frame);
			uint8_t *addrList = msduPendingAddrList(data->frame);

			//DBG_DUMP(data->frame, data->length, 1);

			// Check short addresses.
			for (i=0;i<numShortAddrs;i++) {
				if (*((uint16_t*)addrList) == macShortAddress) {
					if (!pollPosted && post poll() == SUCCESS) {
						pollPosted = TRUE;
						pollExt = FALSE;
					}
					DBG_STR("Pending for me, Short",1);
				}
				//DBG_STR("Short addr pending:",1);
				//DBG_DUMP(addrList,2,1);
				addrList += 2;
			}
			// Check extended addresses.
			for (i=0;i<numExtAddrs;i++) {
				bool match = TRUE;
				for (j=0;j<8;j++) {
					if (addrList[j] != aExtendedAddress[j]) {
						match = FALSE;
						break;
					}
				}
				if (match) {
					if (!pollPosted && post poll() == SUCCESS) {
						pollPosted = TRUE;
						pollExt = TRUE;
					}
					DBG_STR("Pending for me, Extended",1);
				}
				//DBG_STR("Extended addr pending:",1);
				//DBG_DUMP(addrList,8,1);
				addrList += 8;
			}
			
			// Check if we have beacon payload.
			if (addrList < (data->frame + data->length)) {
				DBG_STR("We have beacon payload!",1);
				beaconNotify(data);
			}
		} else {
			beaconNotify(data);
		}

		// Set up the track alarm to fire just before next beacon
		call TrackAlarm.armAlarmClock(nextCommence-50);
		call BeaconGtsService.beaconReceived();
		
		//DBG_STRINT("Cap end is:",capEnd,1);
		//DBG_STRINT("Next commence is:",nextCommence,1);
		
		// DEBUG: We need to be able to check, that all beacon frames are heard!
		//DBG_STRINT("Seqence number:",mhrSeqNumber(data->frame),1);
		return data->frame;
	}

	void beaconNotify(rxdata_t *data)
	{
		// TODO: Do we always copy the beacon primitive here? What about deallocation sizes?
		uint8_t *myBeacon;
		mlmeBeaconNotifyIndication_t *beaconNotifyInd;
		// create a beacon notify primitive
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeBeaconNotifyIndication_t),(uint8_t**)(&beaconNotifyInd))){
			DBG_STR("WARNING: BeaconTracker, Unable to claim buffer for beacon notification!",1);
			return;
		} else {
			// Get buffer for the beacon message.
			if (SUCCESS != call BufferMng.claim(data->length, &myBeacon)) {
				DBG_STR("FATAL: BeaconTracker, Unable to claim new receive buffer!",1);
			}
			memcpy(myBeacon, data->frame, data->length);
			beaconNotifyInd->msg.indication.beaconFrame = myBeacon;
			beaconNotifyInd->msg.indication.frameLength = data->length;
			beaconNotifyInd->msg.indication.logicalChannel = channel;
			beaconNotifyInd->msg.indication.linkQuality = data->linkQuality;
			beaconNotifyInd->msg.indication.timeStamp = data->recvTime;
			beaconNotifyInd->msg.indication.ACLEntry = 0x08; // TODO
			beaconNotifyInd->msg.indication.securityFailure = FALSE; // TODO
			// Notify upper layer with beacon
			call CallbackService.enqueue((uint8_t*)beaconNotifyInd, signalBeaconNotify);
		}
	}

	event void PollService.done(Ieee_Status status)
	{
		// Do nothing here. If we fail, we just retry next superframe.
	}

	async event result_t CfpAlarm.alarm()
	{
		if (waitingForCapEnd) {
			// CAP has ended.
			deviceCapActive = FALSE;
			if (call Superframe.cfpExists(&deviceSuperframe)) {
				// We start up the device CFP.
				signal DeviceCfp.startNotification();
				cfpEnd = call Superframe.getCfpEnd(&deviceSuperframe);
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
	}
	
	async event result_t TrackAlarm.alarm()
	{
		bool wasListening;
		DBG_STR("TrackAlarm",2);
		atomic {
			wasListening = listening;
			listening = FALSE;
		}
		if (wasListening) {
			// this is a timeout, beacon missed
			DBG_STR("BeaconTracker, beacon timeout!",1);
			post missedBeacon();
		} else {
			if (tracking) {
				// Disable all CAPs
				deviceCapActive = FALSE;
				// we need to start listening
				if (PHY_SUCCESS != call FrameRx.rxOn(nextCommence-10)) {
					DBG_STR("Warning: BeaconTracker, could not enable receiver!",1);
				}
				atomic {
					listening = TRUE;
				}
				setBeaconTimeout();
			} else {
				// Disable beacon mode.
				disableBeaconMode();
			}
		}
		return SUCCESS;
	}
	
	async event void PanConflict.conflictDetected()
	{
		// A PAN conflict was detected.
		// Report to coordinator.
		uint8_t *conflictNotification;
		// Allocate a buffer big enough for 2*extended addressing.
		if (SUCCESS != call BufferMng.claim(24, &conflictNotification)) {
			DBG_STR("FATAL: BeaconTracker, Unable to claim new receive buffer!",1);
		}
		
		mhrAckRequest(conflictNotification) = TRUE;
		mhrSecurityEnabled(conflictNotification) = FALSE;
		mhrFramePending(conflictNotification) = FALSE;
		call MacAddress.setDstCoordinator(conflictNotification);
		call MacAddress.setSrcLocal(conflictNotification, FALSE);
		
		mhrFrameType(conflictNotification) = macCommandFrame;
		msduCommandFrameIdent(conflictNotification) = macCommandPanIdConf;
		
		// Send the frame in the CAP, though not explicitly stated in the standard.
		// Build the txHeader.
		myTxHeader.addDsn = TRUE;
		myTxHeader.frame = conflictNotification;
		myTxHeader.length = mhrLengthFrame(conflictNotification) + 1;
		myTxHeader.isData = FALSE;
		
		call DeviceTx.sendFrame(&myTxHeader);
	}
	
	event void DeviceTx.done(txHeader_t *header)
	{
		// Deallocate the conflict notification frame!
		call BufferMng.release(24, header->frame);
	
		// We silently ignore transmission failures.
		if (tracking && myTxHeader.status == IEEE802154_SUCCESS) {
			// Indicate sync loss and disable beacon mode.
			disableBeaconMode();
			post syncLoss();
		}
	}
	
	task void syncLoss()
	{
		mlmeSyncLossIndication_t *syncLossInd;
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeSyncLossIndication_t),(uint8_t**)(&syncLossInd))) {
			DBG_STR("FATAL: BeaconTracker, Unable to claim buffer for sync loss indication!",1);
		} else {
			syncLossInd->msg.indication.lossReason = IEEE802154_BEACON_LOSS;
			signal MlmeIndicationSyncLoss.indication(syncLossInd);
		}
	}
	
	void signalBeaconNotify(uint8_t *beaconNotifyInd)
	{
		DBG_STR("beaconNotify",2);
		signal MlmeIndicationBeaconNotify.indication((Mlme_BeaconNotifyIndication)beaconNotifyInd);
	}

	task void poll()
	{	
		pollPosted = FALSE;
		call PollService.pollCoordinator(pollExt);
	}

	default event void MlmeIndicationBeaconNotify.indication( Mlme_BeaconNotifyIndication indication )
	{
	
	}

	void disableBeaconMode()
	{
		macBeaconEnabled = FALSE;
		deviceCapActive = TRUE;
		call PhyAttributes.setAckBackoffAlignment(FALSE);
		call PhyAttributes.setContentionWindow(1);
	}

	void setBeaconTimeout()
	{
		time_t timeout;
		// listen for aBaseSuperframeDuration * (1<<macBeaconOrder+1) symbols
		DBG_STR("listen",2);
		timeout = 1;
		timeout = ((timeout << macBeaconOrder)+1)*aBaseSuperframeDuration;

		// set up the alarm for track timeout
		if ( SUCCESS != call TrackAlarm.armCountdown(timeout) ){
			DBG_STR("FATAL: BeaconTracker, Unable to arm timeout alarm",1);
		}
		DBG_STR("listening",2);
	}
	
	task void missedBeacon()
	{
		DBG_STR("Missed a beacon",1);

		// Increase loss count, and see if we lost sync or we have to retry.
		numBeaconsLost++;
		if (numBeaconsLost == aMaxLostBeacons) {
			// Sync was lost.
			// Disable beacon mode.
			disableBeaconMode();
			post syncLoss();
		} else {
			// Receiver already enabled. Start listening again.
			atomic {
				listening = TRUE;
			}
			setBeaconTimeout();
		}
	}	
}
