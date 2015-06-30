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

module DataM
{
	provides
	{
		interface IeeeIndication<Mcps_DataIndication> as McpsIndicationData;
		interface IeeeRequestConfirm<Mcps_DataRequestConfirm> as McpsRequestConfirmData;
	}
	uses
	{
		interface CapTx as DeviceTx;
		interface CfpTx;
		interface IndirectTx;
		interface RxFrame as DataFrame;
		interface CallbackService;
		interface IeeeBufferManagement as BufferMng;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	void doDataConfirm(txHeader_t *header);
	void indicateData(uint8_t *dataIndication);

	command result_t McpsRequestConfirmData.request(Mcps_DataRequestConfirm request)
	{
		uint8_t txOptions = request->msg.request.txOptions;
		txHeader_t *myTxHeader;
		
		if (request->msg.request.dataFrameLen > aMaxPHYPacketSize) {
			// Too much data!
			request->msg.confirm.status = IEEE802154_INVALID_PARAMETER;
			return FAIL;
		}
		
		// Allocate the txHeader.
		if (SUCCESS != call BufferMng.claim(sizeof(txHeader_t), (uint8_t**)&myTxHeader)) {
			DBG_STR("FATAL: Data, could not claim memory for transmission header",1);
			return FAIL;
		}
		
		// Build the txHeader.
		myTxHeader->addDsn = TRUE;
		myTxHeader->frame = request->msg.request.dataFrame;
		myTxHeader->length = request->msg.request.dataFrameLen;
		myTxHeader->msduHandle = request->msg.request.msduHandle;
		myTxHeader->isData = TRUE;

		// Now we can safely destroy the request header. For data, this is not stored.
		if (SUCCESS != call BufferMng.release(sizeof(mcpsDataRequestConfirm_t), (uint8_t*)request)) {
			DBG_STR("WARNING: Data, could not release memory for data request",1);
		}

		// Note that GTS transfer option takes precedence over the
		// indirect transfer option.
		if (txOptions & 0x02) {
			// GTS transfer.
			call CfpTx.sendFrame(myTxHeader);
		} else if ((txOptions & 0x04) && macCoordinator) {
			// Indirect transfer.
			// TODO: Check if destination is not present.
			call IndirectTx.send(myTxHeader);
		} else {
			// Direct transfer.
			call DeviceTx.sendFrame(myTxHeader);
		}
		return SUCCESS;
	}

	async event uint8_t *DataFrame.received(rxdata_t *data)
	{
		uint8_t *newBuffer;
		Mcps_DataIndication dataIndication;
		
		// Data reception is indicated to CFP control.
		call CfpTx.dataReceived();
		
		// Just build an indication primitive containing the data.
		if (SUCCESS != call BufferMng.claim(sizeof(mcpsDataIndicationMsg_t), (uint8_t**)&dataIndication)) {
			DBG_STR("FATAL: Data, could not claim memory for Data Indication",1);
		}
		
		// If message is < 64 bytes we copy content into a smaller buffer to save space.
		if (data->length < 64) {
			uint8_t *myMsg;
			if (SUCCESS != call BufferMng.claim(data->length, &myMsg)) {
				DBG_STR("FATAL: Data, could not claim memory for new receive buffer",1);
			}
			memcpy(myMsg, data->frame, data->length);
			dataIndication->msg.indication.dataFrame = myMsg;
			newBuffer = data->frame;
		} else {
			dataIndication->msg.indication.dataFrame = data->frame;
			if (SUCCESS != call BufferMng.claim(126, &newBuffer)) {
				DBG_STR("FATAL: Data, could not claim memory for new receive buffer",1);
			}
		}
		
		dataIndication->msg.indication.dataFrameLen = data->length;
		dataIndication->msg.indication.mpduLinkQuality = data->linkQuality;
		dataIndication->msg.indication.ACLEntry = 0x08; // TODO: Support security at some point.
		call CallbackService.enqueue((uint8_t*)dataIndication, indicateData);
		return newBuffer;
	}
	
	event void DeviceTx.done(txHeader_t *header)
	{
		doDataConfirm(header);
	}
	
	event void IndirectTx.done(txHeader_t *header)
	{
		doDataConfirm(header);
	}
	
	event void CfpTx.done(txHeader_t *header)
	{
		doDataConfirm(header);
	}
	
	void indicateData(uint8_t *dataIndication)
	{
		signal McpsIndicationData.indication((Mcps_DataIndication)dataIndication);
	}
	
	void doDataConfirm(txHeader_t *header)
	{
		Mcps_DataRequestConfirm confirm;

		// Allocate the confirm primitive.
		if (SUCCESS != call BufferMng.claim(sizeof(mcpsDataRequestConfirm_t), (uint8_t**)&confirm)) {
			DBG_STR("FATAL: Data, could not claim memory for confirm primitive",1);
		}
		// Set status and msduHandle.
		confirm->msg.confirm.status = header->status;
		confirm->msg.confirm.msduHandle = header->msduHandle;

		// Deallocate the transmitted frame.
		if (SUCCESS != call BufferMng.release(header->length, header->frame)) {
			DBG_STR("WARNING: Data, could not release memory for transmitted data buffer",1);
		}
		
		// Deallocate the tx header.
		if (SUCCESS != call BufferMng.release(sizeof(txHeader_t), (uint8_t*)header)) {
			DBG_STR("WARNING: Data, could not release memory for transmission header",1);
		}

		signal McpsRequestConfirmData.confirm(confirm);
	}
	
	/***************************
	 *   Default MCPS events   *
	 ***************************/

	default event void McpsRequestConfirmData.confirm(Mcps_DataRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled McpsRequestConfirmData.confirm",1);
	}
}
