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

#include "MacPib.h"
module MlmeDisassociateRequestConfirmM
{
	provides
	{
		interface MlmeDisassociateRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface MacAddress;
	}
}
implementation
{
	
	command result_t MlmeDisassociateRequestConfirm.create( Mlme_DisassociateRequestConfirm *primitive )
	{
		uint8_t *frame;
		//uint16_t myPanId = call PibDatabase.getPANId();
		uint8_t frameSize = mhrFrameControlLength
		                    + mhrSequenceNumberLength
		                    + mhrSrcAddrModeLength(3, TRUE)
		                    + mhrDstAddrModeLength(3)
		                    + msduCommandFrameIdentLength
		                    + msduDisassocReasonLength;
		if (FAIL == call BufferMng.claim(sizeof(mlmeDisassociateRequestConfirm_t), (uint8_t**)primitive)) {
			return FAIL;
		}
		if (FAIL == call BufferMng.claim(frameSize, &((uint8_t*)((*primitive)->msg.request.disassocNotificationFrame)))) {
			call BufferMng.release(sizeof(mlmeDisassociateRequestConfirm_t), (uint8_t*)(*primitive));
			return FAIL;
		}
		(*primitive)->msg.request.frameLength = frameSize;
		frame = (*primitive)->msg.request.disassocNotificationFrame;
		mhrFramePending(frame) = FALSE;
		mhrAckRequest(frame) = TRUE;
		mhrSecurityEnabled(frame) = FALSE;
		mhrIntraPAN(frame) = TRUE;
		
		mhrDestAddrMode(frame) = 3;
		*((uint16_t*)mhrDestPANId(frame)) = macPanId;
		
		call MacAddress.setSrcLocal(frame, TRUE);

		mhrFrameType(frame) = macCommandFrame;
		msduCommandFrameIdent(frame) = macCommandDisassocNot;
	}
	
	command result_t MlmeDisassociateRequestConfirm.destroy( Mlme_DisassociateRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(mlmeDisassociateRequestConfirm_t), (uint8_t*)primitive);
	}
	
	command void MlmeDisassociateRequestConfirm.setDeviceAddress( Mlme_DisassociateRequestConfirm request,
	                                                              uint8_t *deviceAddress )
	{
		uint8_t *frame = request->msg.request.disassocNotificationFrame;
		NTOUH64(deviceAddress, mhrDestAddr(frame));
	}
	
	command void MlmeDisassociateRequestConfirm.setDisassociateReason( Mlme_DisassociateRequestConfirm request,
	                                                                   Ieee_Status disassociateReason )
	{
		uint8_t *frame = request->msg.request.disassocNotificationFrame;
		msduDisassocReason(frame) = disassociateReason;
	}
	
	command void MlmeDisassociateRequestConfirm.setSecurityEnable( Mlme_DisassociateRequestConfirm request )
	{
		uint8_t *frame = request->msg.request.disassocNotificationFrame;
		mhrSecurityEnabled(frame) = TRUE;
	}

	command Ieee_Status MlmeDisassociateRequestConfirm.getStatus( Mlme_DisassociateRequestConfirm confirm )
	{
		return confirm->msg.confirm.status;
	}
}
