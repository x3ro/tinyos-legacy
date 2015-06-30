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

module IndirectTxM
{
	provides
	{
		interface IeeeRequestConfirm<Mcps_PurgeRequestConfirm> as McpsRequestConfirmPurge;
		interface IndirectTx as IndirectTx[uint8_t token];
		interface BeaconDataService;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface RxFrame as DataReqFrame;
		interface CapTx as CoordinatorTx;
		interface MacAddress;
		interface CallbackService;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	indirectTxQueue_t myQueue[NUMINDIRECTSLOTS];
	txDoneEntry_t doneQueue[NUMINDIRECTDONESLOTS];
	uint8_t doneQueueCount = 0;
	bool donePosted = FALSE;
	
	void checkQueue(uint8_t mode, uint8_t *address);
	bool matchEntry(uint8_t entry, uint8_t *address);
	uint8_t getAddresses(uint8_t mode, uint8_t *dest);
	void confirmPurge(uint8_t *primitive);
	
	task void txDoneTask();
	
	command result_t McpsRequestConfirmPurge.request(Mcps_PurgeRequestConfirm request)
	{
		uint8_t i;
		uint8_t myHandle = request->msg.request.msduHandle;
		
		for (i=0;i<NUMINDIRECTSLOTS;i++) {
			if (myQueue[i].status == SLOT_PENDING && myQueue[i].data->isData &&
			    myQueue[i].data->msduHandle == myHandle) {
				// We purge this entry.
				// Release frame and tx header.
				call BufferMng.release(myQueue[i].data->length, myQueue[i].data->frame);
				call BufferMng.release(sizeof(txHeader_t), (uint8_t*)myQueue[i].data);
				myQueue[i].status = SLOT_EMPTY;
				request->msg.confirm.status = IEEE802154_SUCCESS;
				call CallbackService.enqueue((uint8_t*)request, confirmPurge);
				return SUCCESS;
			}
		}
		request->msg.confirm.status = IEEE802154_INVALID_HANDLE;
		return FAIL;
	}
	
	command void IndirectTx.send[uint8_t token](txHeader_t *header)
	{
		uint8_t i;
		// Find an empty slot.
		for (i=0;i<NUMINDIRECTSLOTS;i++) {
			if (myQueue[i].status == SLOT_EMPTY) {
				// This slot is empty and ready for use.
				myQueue[i].status = SLOT_PENDING;
				myQueue[i].token = token;
				myQueue[i].data = header;
				myQueue[i].address = mhrDestAddr(header->frame);
				myQueue[i].expiryCount = macTransactionPersistenceTime;
				myQueue[i].addrMode = mhrDestAddrMode(header->frame);
				return;
			}
		}
		// If we get here, no slots are available!
		header->status = IEEE802154_TRANSACTION_OVERFLOW;
		doneQueue[doneQueueCount].header = header;
		doneQueue[doneQueueCount++].doneToken = token;
		if (!donePosted) {
			donePosted = post txDoneTask();
		}
	}
	
	command void BeaconDataService.getPendingAddrs(uint8_t *shortCnt, uint8_t *extCnt, uint8_t *data)
	{
		// This command extracts the pending addresses into the "data" pointer,
		// indicating the number of pending addresses of each type in shortCnt and extCnt.
		
		// TODO: When more than 7 pending addresses, the addresses should be
		//       published on a first-come-first-served basis!
		*shortCnt = getAddresses(2, data);
		if (*shortCnt < 7) {
			data += (*shortCnt)*2;
			*extCnt = getAddresses(3, data);
			if (*extCnt + *shortCnt > 7) {
				*extCnt = 7 - *shortCnt;
			}
		} else {
			*shortCnt = 7;
			*extCnt = 0;
		}
	}
	
	command void BeaconDataService.expireSlots()
	{
		uint8_t i;
		// This is called once each superframe.
		for (i=0;i<NUMINDIRECTSLOTS;i++) {
			if (myQueue[i].status == SLOT_PENDING) {
				myQueue[i].expiryCount--;
				if (!(myQueue[i].expiryCount)) {
					// Expire this entry.
					myQueue[i].data->status = IEEE802154_TRANSACTION_EXPIRED;
					signal IndirectTx.done[myQueue[i].token](myQueue[i].data);
					myQueue[i].status = SLOT_EMPTY;
				}
			}
		}
	}
	
	uint8_t getAddresses(uint8_t mode, uint8_t *dest)
	{
		uint8_t i;
		uint8_t count = 0;
		uint8_t addrLen = (((mode)&1)?8:(mode));
		for (i=0;i<NUMINDIRECTSLOTS;i++) {
			if (myQueue[i].status == SLOT_PENDING && myQueue[i].addrMode == mode) {
				memcpy(dest, myQueue[i].address, addrLen);
				dest += addrLen;
				count++;
			}
		}
		return count;
	}
	
	bool matchEntry(uint8_t entry, uint8_t *address)
	{
		if (myQueue[entry].addrMode == 3) {
			if (int64Compare(address, myQueue[entry].address)) return TRUE;
		} else {
			// Assume mode == 2.
			if (*((uint16_t*)myQueue[entry].address) == *((uint16_t*)address)) return TRUE;
		}
		return FALSE;
	}
	
	void checkQueue(uint8_t mode, uint8_t *address)
	{
		uint8_t best, i;
		bool found = FALSE;
		bool multiple = FALSE;
		for (i=0;i<NUMINDIRECTSLOTS;i++) {
			if (myQueue[i].status == SLOT_PENDING && myQueue[i].addrMode == mode) {
				// We have an entry matching the addressing mode.
				if (matchEntry(i, address)) {
					// We have a match.
					if (found) {
						multiple = TRUE;
						if (myQueue[best].expiryCount > myQueue[i].expiryCount) {
							// We pick the oldest entry.
							best = i;
						}
					} else {
						found = TRUE;
						best = i;
					}
				}
			}
		}
		if (found) {
			if (multiple) {
				// There is more than one pending frame for the requesting device
				// Set frame pending bit in frame control.
				mhrFramePending(myQueue[best].data->frame) = TRUE;
			}
			// Send frame in cap.
			call CoordinatorTx.sendFrame(myQueue[best].data);
		}
	}
	
	event void CoordinatorTx.done(txHeader_t *header)
	{
		if (header->status == IEEE802154_SUCCESS) {
			// Make slot available and signal tx done.
			uint8_t i;
			for (i=0;i<NUMINDIRECTSLOTS;i++) {
				if (myQueue[i].status == SLOT_PENDING && myQueue[i].data == header) {
					signal IndirectTx.done[myQueue[i].token](header);
					myQueue[i].status = SLOT_EMPTY;
					return;
				}
			}
		}
	}
	
	async event uint8_t *DataReqFrame.received(rxdata_t *data)
	{
		ieeeAddress_t requester;
		call MacAddress.getSrcAddr(data->frame, &requester);
		checkQueue(requester.mode, requester.address);
		return data->frame;
	}
	
	task void txDoneTask()
	{
		while(doneQueueCount) {
			signal IndirectTx.done[doneQueue[--doneQueueCount].doneToken](doneQueue[doneQueueCount].header);
		}
		donePosted = FALSE;
	}
	
	void confirmPurge(uint8_t *primitive)
	{
		signal McpsRequestConfirmPurge.confirm((Mcps_PurgeRequestConfirm)primitive);
	}
	
	default event void IndirectTx.done[uint8_t token](txHeader_t *header)
	{
		DBG_STRINT("IndirectTx done not connected for module:",token,1);
	}
	
	default event void McpsRequestConfirmPurge.confirm(Mcps_PurgeRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled McpsRequestConfirmPurge.confirm",1);
	}
}
