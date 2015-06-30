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
#include <Int64Compare.h>

module AssociateM
{
	provides
	{
		interface IeeeIndicationResponse<Mlme_AssociateIndicationResponse> as MlmeIndicationResponseAssociate;
		interface IeeeRequestConfirm<Mlme_AssociateRequestConfirm> as MlmeRequestConfirmAssociate;
		interface IeeeIndication<Mlme_DisassociateIndication> as MlmeIndicationDisassociate;
		interface IeeeRequestConfirm<Mlme_DisassociateRequestConfirm> as MlmeRequestConfirmDisassociate;
		interface IeeeIndication<Mlme_CommStatusIndication> as MlmeIndicationCommStatus;
		interface Reset;
	}
	uses
	{
		interface RxFrame as AssocReqFrame;
		interface RxFrame as AssocRespFrame;
		interface RxFrame as DisassocNotFrame;
		
		interface PhyAttributes;
		interface CapTx as DeviceTx;
		interface IndirectTx;
		interface PollService;
		interface TimingService;
		interface MacAddress;
		
		interface CallbackService;
		interface IeeeBufferManagement as BufferMng;
		
		// Debug
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	// Associate variables.
	// Only one associate request at a time is allowed.
	// I recon that this limitation should be acceptable.
	Mlme_AssociateRequestConfirm assocPrimitive;
	
	bool waitAssocResponse = FALSE;
	bool waitingToPoll = FALSE;
	
	void confirmAssociation(uint8_t *primitive);
	void indicateDisassoc(uint8_t *primitive);
	void confirmDisassoc(txHeader_t *header);
	
	command void Reset.reset()
	{
		waitAssocResponse = FALSE;
		waitingToPoll = FALSE;
	}
	
	command result_t MlmeRequestConfirmAssociate.request(Mlme_AssociateRequestConfirm request)
	{
		uint8_t *assocFrame = request->msg.request.assocRequestFrame;
		uint8_t *coordAddrPtr = mhrDestAddr(assocFrame);
		uint8_t channel = request->msg.request.logicalChannel;
		txHeader_t *myTxHeader;
		
		if (channel > 26) {
			// Unsupported channel specified.
			request->msg.confirm.status = IEEE802154_INVALID_PARAMETER;
			return FAIL;
		}
		
		// Allocate the txHeader.
		if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
			DBG_STR("FATAL: Associate, could not claim memory for transmission header",1);
		}
		
		assocPrimitive = request;

		// Set PAN Id.
		macPanId = *((uint16_t*)mhrDestPANId(assocFrame));
		if (mhrDestAddrMode(assocFrame) == 2) {
			macCoordShortAddress = *((uint16_t*)coordAddrPtr);
		} else {
			// Coordinator has no short address.
			macCoordShortAddress = 0xFEFF;
			memcpy(macCoordExtendedAddress, coordAddrPtr, 8);
		}
		
		// Build the txHeader.
		myTxHeader->addDsn = TRUE;
		myTxHeader->frame = assocFrame;
		myTxHeader->length = request->msg.request.frameLength;
		myTxHeader->isData = FALSE;
		
		// Change to the right channel.
		call PhyAttributes.setChannel(channel);
		
		// Call cap control to transmit the associate frame.
		call DeviceTx.sendFrame(myTxHeader);
		
		DBG_STR("MlmeRequestConfirmAssociate.request",1);
		return SUCCESS;
	}

	command result_t MlmeIndicationResponseAssociate.response( Mlme_AssociateIndicationResponse response )
	{
		txHeader_t *myTxHeader;
		
		// Allocate the txHeader.
		if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
			DBG_STR("FATAL: Associate, could not claim memory for transmission header",1);
		}
		
		// Build the txHeader.
		myTxHeader->addDsn = TRUE;
		myTxHeader->frame = response->msg.response.assocResponseFrame;
		myTxHeader->length = mhrLengthFrame(myTxHeader->frame) + 4;
		myTxHeader->isData = FALSE;

		// Destroy primitive.
		call BufferMng.release(sizeof(mlmeAssociateIndicationResponse_t), (uint8_t*)response);

		call IndirectTx.send(myTxHeader);
		
		DBG_STR("MlmeIndicationResponseAssociate.response",1);
		return SUCCESS;
	}

	command result_t MlmeRequestConfirmDisassociate.request(Mlme_DisassociateRequestConfirm request)
	{
		uint8_t *destAddr;
		txHeader_t *myTxHeader;
		result_t myResult;
		
		// Allocate the txHeader.
		if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
			DBG_STR("FATAL: Disassociate, could not claim memory for transmission header",1);
		}
		
		// Build the txHeader.
		myTxHeader->addDsn = TRUE;
		myTxHeader->frame = request->msg.request.disassocNotificationFrame;
		myTxHeader->length = request->msg.request.frameLength;
		myTxHeader->isData = FALSE;
		
		destAddr = mhrDestAddr(myTxHeader->frame);
		
		if (int64Compare(destAddr, macCoordExtendedAddress)) {
			// Call cap control to transmit the associate frame.
			call DeviceTx.sendFrame(myTxHeader);
		} else if (macCoordinator) {
			// We do an indirect transmission.
			call IndirectTx.send(myTxHeader);
		} else {
			// Else, return fail with status INVALID_PARAMETER.
			request->msg.confirm.status = IEEE802154_INVALID_PARAMETER;
			// Deallocate frame.
			call BufferMng.release(myTxHeader->length, myTxHeader->frame);
			// Deallocate txHeader.
			call BufferMng.release(sizeof(txHeader_t), (uint8_t*)myTxHeader);
			return FAIL;
		}
		
		// Destroy primitive.
		call BufferMng.release(sizeof(mlmeDisassociateRequestConfirm_t), (uint8_t*)request);
		return SUCCESS;
	}

	event void DeviceTx.done(txHeader_t *header)
	{
		uint8_t operation = msduCommandFrameIdent(header->frame);
		
		if (	operation == macCommandAssocReq) {
			DBG_STR("Assoc Request transmitted",1);
			// Deallocate the transmitted frame!
			call BufferMng.release(header->length, header->frame);
			// Deallocate txHeader.
			call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header);
			if (header->status == IEEE802154_SUCCESS) {
				// Wait for the coordinator to generate a response.
				call TimingService.waitForResponse();
				if (macBeaconEnabled) {
					// Poll may happen when the pending data appear in the beacon.
					waitAssocResponse = TRUE;
				}
				waitingToPoll = TRUE;
			} else {
				assocPrimitive->msg.confirm.status = header->status;
				call CallbackService.enqueue((uint8_t*)assocPrimitive, confirmAssociation);
			}
		} else if (operation == macCommandDisassocNot) {
			confirmDisassoc(header);
		}
	}

	event void IndirectTx.done(txHeader_t *header)
	{
		uint8_t operation = msduCommandFrameIdent(header->frame);
		
		if (operation == maccommandAssocResp) {
			// We are done transmitting our associate response.
			mlmeCommStatusIndication_t *commStatusIndication;
				
			// Allocate space for a comm status indication
			if (SUCCESS != call BufferMng.claim(sizeof(mlmeCommStatusIndication_t), (uint8_t**)&commStatusIndication)) {
				DBG_STR("FATAL: Associate, could not claim memory for comm status indication",1);
			}
			// NOTE: Notification frames are always reused for response frames, meaning that
			//       the frame length in the comm status indication must be the max frame length.
			commStatusIndication->msg.indication.responseFrame = header->frame;
			commStatusIndication->msg.indication.frameLength = 126;
			commStatusIndication->msg.indication.status = header->status;
			
			// Deallocate txHeader.
			call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header);
			signal MlmeIndicationCommStatus.indication(commStatusIndication);
		} else if (operation == macCommandDisassocNot) {
			// We are done transmitting our disassociate notification.
			confirmDisassoc(header);
		}
	}

	async event void TimingService.responseTimeout()
	{
		DBG_STR("Response timeout",1);
		if (waitingToPoll) {
			waitingToPoll = FALSE;
			waitAssocResponse = TRUE;

			if (SUCCESS != call PollService.pollCoordinator(FALSE)) {
				assocPrimitive->msg.confirm.status = IEEE802154_CHANNEL_ACCESS_FAILURE;
				call CallbackService.enqueue((uint8_t*)assocPrimitive, confirmAssociation);
			}
		}
	}

	event void PollService.done(Ieee_Status status)
	{
		DBG_STR("Associate poll done!",1);
		// Check the status and take action.
		if (status != IEEE802154_SUCCESS) {
			waitAssocResponse = FALSE;
			assocPrimitive->msg.confirm.status = status;
			call CallbackService.enqueue((uint8_t*)assocPrimitive, confirmAssociation);
		}
	}

	async event uint8_t *AssocRespFrame.received(rxdata_t *data)
	{
		if (waitAssocResponse) {
			// Signal associate confirm with the status of the association request.
			uint16_t shortAddr;
			uint8_t status = msduAssocResponseStatus(data->frame);
			
			// Stop waiting.
			waitAssocResponse = FALSE;
			waitingToPoll = FALSE;
			call TimingService.stopTimer();
			
			shortAddr = *((uint16_t*)msduAssocResponseShortAddr(data->frame));
			if (!status) {
				macShortAddress = shortAddr;
			} else {
				macShortAddress = 0xFFFF;
			}
			// Also set coordinator extended addresses.
			memcpy(macCoordExtendedAddress, mhrSrcAddr(data->frame), 8);
			assocPrimitive->msg.confirm.assocShortAddr = shortAddr;
			assocPrimitive->msg.confirm.status = status;
			call CallbackService.enqueue((uint8_t*)assocPrimitive, confirmAssociation);
		}
		return data->frame;
	}
	
	async event uint8_t *AssocReqFrame.received(rxdata_t *data)
	{
		// NOTE: This is signalled to the upper layer in async context.
		uint8_t *newBuffer;
		mlmeAssociateIndicationResponse_t *assocIndication;
		
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeAssociateIndicationResponse_t), (uint8_t**)&assocIndication)) {
			DBG_STR("FATAL: Associate, could not claim memory for Disassociate Indication",1);
		}

		assocIndication->msg.indication.assocIndicationFrame = data->frame;
		// This is time critical and therefore signalled in async
		signal MlmeIndicationResponseAssociate.indication(assocIndication);
		
		// Frame buffer is reused for association response.
		if (SUCCESS != call BufferMng.claim(126, &newBuffer)) {
			DBG_STR("FATAL: Associate, could not claim memory for new receive buffer",1);
		}

		return newBuffer;
	}

	async event uint8_t *DisassocNotFrame.received(rxdata_t *data)
	{
		uint8_t *newBuffer;
		mlmeDisassociateIndication_t *disassocIndication;
		
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeDisassociateIndication_t), (uint8_t**)&disassocIndication)) {
			DBG_STR("FATAL: Disassociate, could not claim memory for Disassociate Indication",1);
		}
		
		disassocIndication->type = MLME_Disassociate_Indication;
		disassocIndication->msg.indication.disassocNotificationFrame = data->frame;
		call CallbackService.enqueue((uint8_t*)disassocIndication, indicateDisassoc);
		
		if (SUCCESS != call BufferMng.claim(126, &newBuffer)) {
			DBG_STR("FATAL: Disassociate, could not claim memory for new receive buffer",1);
		}
		
		return newBuffer;
	}


	void confirmAssociation(uint8_t *primitive)
	{
		signal MlmeRequestConfirmAssociate.confirm((Mlme_AssociateRequestConfirm)primitive);
	}
	
	void indicateDisassoc(uint8_t *primitive)
	{
		signal MlmeIndicationDisassociate.indication((mlmeDisassociateIndication_t*)primitive);
	}

	void confirmDisassoc(txHeader_t *header)
	{
		mlmeDisassociateRequestConfirm_t *disassocConfirm;
		// Allocate space for a disassociate confirm primitive
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeDisassociateRequestConfirm_t), (uint8_t**)&disassocConfirm)) {
			DBG_STR("FATAL: Disassociate, could not claim memory for disassociate confirm",1);
		}
		disassocConfirm->msg.confirm.status = header->status;
		// Deallocate frame.
		call BufferMng.release(header->length, header->frame);
		// Deallocate txHeader.
		call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header);
		signal MlmeRequestConfirmDisassociate.confirm(disassocConfirm);
	}

	default async event void MlmeIndicationResponseAssociate.indication(Mlme_AssociateIndicationResponse indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationResponseAssociate.indication",1);
	}

	default event void MlmeIndicationDisassociate.indication(Mlme_DisassociateIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationDisassociate.indication",1);
	}

	default event void MlmeRequestConfirmAssociate.confirm(Mlme_AssociateRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmAssociate.confirm",1);
	}

	default event void MlmeRequestConfirmDisassociate.confirm(Mlme_DisassociateRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmDisassociate.confirm",1);
	}
	
	default event void MlmeIndicationCommStatus.indication(Mlme_CommStatusIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationCommStatus.indication",1);
	}
}
