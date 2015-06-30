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
module MlmeGtsRequestConfirmM
{
	provides
	{
		interface MlmeGtsRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface MacAddress;
	}
}
implementation
{

	command result_t MlmeGtsRequestConfirm.create( Mlme_GtsRequestConfirm *primitive )
	{
		uint8_t *frame;
		//uint16_t myPanId = call PibDatabase.getPANId();
		//uint16_t myShortAddr = call PibDatabase.getShortAddress();
		uint8_t frameSize = mhrFrameControlLength
		                    + mhrSequenceNumberLength
		                    + mhrSrcAddrModeLength(2, FALSE)
		                    + mhrDstAddrModeLength(0)
		                    + msduCommandFrameIdentLength
		                    + msduGtsRequestGtsCharacteristicsLength;
		if (FAIL == call BufferMng.claim(sizeof(mlmeGTSRequestConfirm_t), (uint8_t**)primitive)) {
			return FAIL;
		}
		if (FAIL == call BufferMng.claim(frameSize, &(((*primitive)->msg.request.GTSRequestFrame)))) {
			call BufferMng.release(sizeof(mlmeGTSRequestConfirm_t), (uint8_t*)(*primitive));
			return FAIL;
		}
		frame = (*primitive)->msg.request.GTSRequestFrame;
		mhrFramePending(frame) = FALSE;
		mhrAckRequest(frame) = TRUE;
		mhrSecurityEnabled(frame) = FALSE;
		mhrIntraPAN(frame) = FALSE;
		
		mhrDestAddrMode(frame) = 0;
		call MacAddress.setSrcLocal(frame, FALSE);
		
		mhrFrameType(frame) = macCommandFrame;
		msduCommandFrameIdent(frame) = macCommandGtsReq;
		return SUCCESS;
	}
	
	command result_t MlmeGtsRequestConfirm.destroy( Mlme_GtsRequestConfirm primitive )
	{
		// It's not good if this command returns FAIL!
		uint8_t *frame = primitive->msg.confirm.GTSRequestFrame;
		uint8_t frameSize = mhrLengthFrame(frame) + msduCommandFrameIdentLength +
		                    msduGtsRequestGtsCharacteristicsLength;
		if (SUCCESS == call BufferMng.release(frameSize, frame)) {
			return call BufferMng.release(sizeof(mlmeGTSRequestConfirm_t), (uint8_t*)primitive);
		}
		return FAIL;
	}
		
	command void MlmeGtsRequestConfirm.setGtsCharacteristics( Mlme_GtsRequestConfirm request,
	                                                          uint8_t gtsCharacteristics )
	{
		uint8_t *frame = request->msg.request.GTSRequestFrame;
		request->msg.request.gtsType = ((msduGtsCharacteristics_t*)&(gtsCharacteristics))->CharType;
		request->msg.request.gtsDirection = ((msduGtsCharacteristics_t*)&(gtsCharacteristics))->GTSDirection;
		*((uint8_t*)msduGtsRequestGtsCharacteristics(frame)) = gtsCharacteristics;
	}
	
	command void MlmeGtsRequestConfirm.combineGtsCharacteristics( Mlme_GtsRequestConfirm request,
	                                                              uint8_t length,
	                                                              uint8_t direction,
	                                                              uint8_t type )
	{
		uint8_t *frame = request->msg.request.GTSRequestFrame;
		msduGtsCharacteristics_t *gtsChars = msduGtsRequestGtsCharacteristics(frame);
		request->msg.request.gtsType = type;
		request->msg.request.gtsDirection = direction;
		gtsChars->GTSLength = length;
		gtsChars->GTSDirection = direction;
		gtsChars->CharType = type;
	}
	
	command void MlmeGtsRequestConfirm.setSecurityEnable( Mlme_GtsRequestConfirm request )
	{
		uint8_t *frame = request->msg.request.GTSRequestFrame;
		mhrSecurityEnabled(frame) = TRUE;
	}
	                                
	command uint8_t MlmeGtsRequestConfirm.getGtsCharacteristics( Mlme_GtsRequestConfirm confirm )
	{
		uint8_t *frame = confirm->msg.confirm.GTSRequestFrame;
		return *((uint8_t*)msduGtsRequestGtsCharacteristics(frame));
	}
	
	command Ieee_Status MlmeGtsRequestConfirm.getStatus( Mlme_GtsRequestConfirm confirm )
	{
		return confirm->msg.confirm.status;
	}
}
