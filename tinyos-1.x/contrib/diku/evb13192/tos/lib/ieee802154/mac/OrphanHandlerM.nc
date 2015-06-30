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

module OrphanHandlerM
{
	provides
	{
		interface IeeeIndicationResponse<Mlme_OrphanIndicationResponse> as MlmeIndicationResponseOrphan;
		interface IeeeIndication<Mlme_CommStatusIndication> as MlmeIndicationCommStatus;
		interface Realignment;
	}
	uses
	{
		interface MacAddress;
		interface CapTx as CoordinatorTx;
		interface RxFrame as OrphanNotFrame;
		interface IeeeBufferManagement as BufferMng;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	command void Realignment.create(uint8_t *frame, bool broadcast, uint8_t *address)
	{
		mhrFramePending(frame) = FALSE;
		mhrAckRequest(frame) = !broadcast;
		mhrIntraPAN(frame) = FALSE;

		if (broadcast) {
			mhrDestAddrMode(frame) = 2;
			*((uint16_t*)mhrDestAddr(frame)) = aBcastShortAddr;
		} else {
			mhrDestAddrMode(frame) = 3;	
			NTOUH64(address, mhrDestAddr(frame));
		}
		*((uint16_t*)mhrDestPANId(frame)) = aBcastPANId;
		
		call MacAddress.setSrcLocal(frame, TRUE);
		
		mhrSecurityEnabled(frame) = FALSE;
		
		mhrFrameType(frame) = macCommandFrame;
		msduCommandFrameIdent(frame) = macCommandCoordRealign;
		*((uint16_t*)msduCoordRealignPANId(frame)) = macPanId;
		*((uint16_t*)msduCoordRealignCoordShortAddr(frame)) = macShortAddress;
		// TODO: Where to fetch the current channel?
		msduCoordRealignLogicalChannel(frame) = 0x0B;
		if (broadcast) {
			// Set short address to broadcast short address.
			*((uint16_t*)msduCoordRealignShortAddr(frame)) = aBcastShortAddr;
		}
	}

	command result_t MlmeIndicationResponseOrphan.response( Mlme_OrphanIndicationResponse response )
	{
		txHeader_t *myTxHeader;
		
		// Allocate the txHeader.
		if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
			DBG_STR("FATAL: Associate, could not claim memory for transmission header",1);
		}
		
		// Build the txHeader.
		myTxHeader->addDsn = TRUE;
		myTxHeader->frame = response->msg.response.coordRealignFrame;
		myTxHeader->length = mhrLengthFrame(myTxHeader->frame) + 8;
		myTxHeader->isData = FALSE;

		// Destroy primitive.
		call BufferMng.release(sizeof(mlmeAssociateIndicationResponse_t), (uint8_t*)response);
		//DBG_DUMP(myTxHeader->frame, myTxHeader->length, 1);
		call CoordinatorTx.sendFrame(myTxHeader);
		return SUCCESS;
	}

	event void CoordinatorTx.done(txHeader_t *header)
	{
		// Transmission completed. Signal comm status with tx status.
		mlmeCommStatusIndication_t *commStatusIndication;
		
		DBG_STRINT("Tx status was:",header->status,1);
		
		// Allocate space for a comm status indication
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeCommStatusIndication_t), (uint8_t**)&commStatusIndication)) {
			DBG_STR("FATAL: OrphanHandler, could not claim memory for comm status indication",1);
		}
		// NOTE: Notification frames are always reused for response frames, meaning that
		//       the frame length in the comm status indication must be the max frame length.
		commStatusIndication->msg.indication.responseFrame = header->frame;
		commStatusIndication->msg.indication.frameLength = 126;
		commStatusIndication->msg.indication.status = header->status;
		
		// Deallocate txHeader.
		call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header);
		signal MlmeIndicationCommStatus.indication(commStatusIndication);
	}
	
	async event uint8_t *OrphanNotFrame.received(rxdata_t *data)
	{
		// NOTE: This is signalled to the upper layer in async context.
		uint8_t *newBuffer;
		mlmeOrphanIndicationResponse_t *orphanIndication;
		
		if (SUCCESS != call BufferMng.claim(sizeof(mlmeOrphanIndicationResponse_t), (uint8_t**)&orphanIndication)) {
			DBG_STR("FATAL: Associate, could not claim memory for Disassociate Indication",1);
		}

		orphanIndication->msg.indication.orphanNotificationFrame = data->frame;
		signal MlmeIndicationResponseOrphan.indication(orphanIndication);
		
		// Frame buffer is reused for association response.
		if (SUCCESS != call BufferMng.claim(126, &newBuffer)) {
			DBG_STR("FATAL: Associate, could not claim memory for new receive buffer",1);
		}
		
		return newBuffer;
	}

	default event void MlmeIndicationCommStatus.indication(Mlme_CommStatusIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationCommStatus.indication",1);
	}
	
	default async event void MlmeIndicationResponseOrphan.indication(Mlme_OrphanIndicationResponse indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationResponseOrphan.indication",1);
	}
}
