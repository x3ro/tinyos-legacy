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

module StartM
{
	provides
	{
		interface IeeeRequestConfirm<Mlme_StartRequestConfirm> as MlmeRequestConfirmStart;
	}
	uses
	{
		interface CapTx as CoordinatorTx;
		interface IeeeBufferManagement as BufferMng;
		interface Realignment;
		interface BeaconGenerator;
		interface PhyAttributes;
		interface CallbackService;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	void confirmStart(uint8_t *primitive);
	
	command result_t MlmeRequestConfirmStart.request(Mlme_StartRequestConfirm request)
	{
		mlmeStartRequestMsg_t *req = &(request->msg.request);
		mlmeStartConfirmMsg_t *conf = &(request->msg.confirm);
		
		// If any parameters in primitive are not supported or out of range,
		// signal confirm with status INVALID_PARAMETER.
		if (req->logicalChannel > 26 || req->beaconOrder > 15 ||
		    (req->superframeOrder > req->beaconOrder && req->superframeOrder != 15)) {
			conf->status = IEEE802154_INVALID_PARAMETER;
			return FAIL;
		}
		
		// If macShortAddress is set to 0xFFFF, confirm with status NO_SHORT_ADDRESS.
		if (macShortAddress == *((uint16_t*)aBcastShortAddr)) {
			conf->status = IEEE802154_NO_SHORT_ADDRESS;
			return FAIL;
		}

		// Set macBeaconOrder to the value of the BeaconOrder parameter. If
		// macBeaconOrder = 15, set macSuperframeOrder = 15, else set
		// macSuperframeOrder to the value of the SuperframeOrder parameter.
		// Set value of macBattLifeExt to the value of the BatteryLifeExtension
		// parameter.
		macBeaconOrder = req->beaconOrder;
		if (req->beaconOrder == 15) {
			macSuperframeOrder = 15;
		} else {
			macSuperframeOrder = req->superframeOrder;
		}
		macBattLifeExt = req->battLifeExt;
		
		// If the PANCoordinator parameter is TRUE, update macPANId with value of
		// the PANId parameter and phyCurrentChannel with the value of the
		// LogicalChannel parameter.
		if (req->PANCoordinator) {
			// Set the channel
			if (SUCCESS != call PhyAttributes.setChannel(req->logicalChannel)) {
				DBG_STRINT("WARNING: Start, could not change radio channel!",req->logicalChannel,1);
			}
			NTOUH16((uint8_t*)&(req->PANId), (uint8_t*)&macPanId);
			macPanCoordinator = TRUE;
			macCoordinator = TRUE;
			if (!macBeaconEnabled && macBeaconOrder < 15) {
				// Enable beacon mode.
				macBeaconEnabled = TRUE;
				deviceCapActive = FALSE;
				call PhyAttributes.setAckBackoffAlignment(TRUE);
				call PhyAttributes.setContentionWindow(2);
				call BeaconGenerator.start();
			} else {
				macBeaconEnabled = FALSE;
				deviceCapActive = FALSE;
				coordCapActive = TRUE;
			}
		} else {
			macPanCoordinator = FALSE;
			macCoordinator = TRUE;
			// TODO: How do we check if we need to start the generator?
		}
		
		if (req->coordRealign) {
			// If the coordinator realignment parameter is set, send out
			// a coordinator realignment frame.
			txHeader_t *myTxHeader;
			uint8_t *myFrame;
			
			// Allocate space for my frame.
			if (SUCCESS != call BufferMng.claim(27, &myFrame)) {
				DBG_STR("FATAL: Start, could not claim memory for realignment frame",1);
			}
			
			call Realignment.create(myFrame, TRUE, NULL);
			
			// Allocate the txHeader.
			if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
				DBG_STR("FATAL: Start, could not claim memory for transmission header",1);
			}
			
			// Build the txHeader.
			myTxHeader->addDsn = TRUE;
			myTxHeader->frame = myFrame;
			myTxHeader->length = 25;
			myTxHeader->isData = FALSE;
			
			// NOTE: Even though not explicitly stated in the standard, the
			//       realignment is send during the CAP.
			call CoordinatorTx.sendFrame(myTxHeader);
		}

		// We are done, confirm the request.
		conf->status = IEEE802154_SUCCESS;
		call CallbackService.enqueue((uint8_t*)request, confirmStart);

		DBG_STR("MlmeRequestConfirmStart.request",1);
		return SUCCESS;
	}

	event void CoordinatorTx.done(txHeader_t *header)
	{
		// Release frame and tx header.
		call BufferMng.release(25, header->frame);
		call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header);
	}

	void confirmStart(uint8_t *primitive)
	{
		signal MlmeRequestConfirmStart.confirm((Mlme_StartRequestConfirm)primitive);
	}

	default event void MlmeRequestConfirmStart.confirm(Mlme_StartRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmStart.confirm",1);
	}

}
