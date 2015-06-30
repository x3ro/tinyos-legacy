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

includes macTypes;

module MlmeAssociateRequestConfirmM
{
	provides
	{
		interface MlmeAssociateRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface MacAddress;
	}
}
implementation
{
	command result_t MlmeAssociateRequestConfirm.create( Mlme_AssociateRequestConfirm *primitive,
	                                                     Ieee_Address coordAddr )
	{
		uint8_t *frame;
		uint8_t frameSize = mhrFrameControlLength + mhrSequenceNumberLength
		                    + mhrSrcAddrModeLength(3, FALSE)
		                    + mhrDstAddrModeLength(coordAddr->mode)
		                    + msduCommandFrameIdentLength
		                    + msduAssocRequestLength;
		if (FAIL == call BufferMng.claim(sizeof(mlmeAssociateRequestConfirm_t), (uint8_t**)primitive)) {
			return FAIL;
		}
		if (FAIL == call BufferMng.claim(frameSize, &(((*primitive)->msg.request.assocRequestFrame)))) {
			call BufferMng.release(sizeof(mlmeAssociateRequestConfirm_t), (uint8_t*)(*primitive));
			return FAIL;
		}
		frame = (*primitive)->msg.request.assocRequestFrame;
		(*primitive)->msg.request.frameLength = frameSize;
		mhrFramePending(frame) = FALSE;
		mhrAckRequest(frame) = TRUE;
		mhrIntraPAN(frame) = FALSE;
		// Security disabled by default.
		mhrSecurityEnabled(frame) = FALSE;
		
		// Set address info.
		call MacAddress.setDstAddr(frame, coordAddr);
		call MacAddress.setSrcLocal(frame, TRUE);
		
		mhrFrameType(frame) = macCommandFrame;
		msduCommandFrameIdent(frame) = macCommandAssocReq;
		return SUCCESS;
	}
	
	command result_t MlmeAssociateRequestConfirm.destroy( Mlme_AssociateRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(mlmeAssociateRequestConfirm_t), (uint8_t*)primitive);
	}
	
	command void MlmeAssociateRequestConfirm.setLogicalChannel( Mlme_AssociateRequestConfirm request,
	                                                            uint8_t logicalChannel )
	{
		request->msg.request.logicalChannel = logicalChannel;
	}
	
	command void MlmeAssociateRequestConfirm.setCapabilityInformation( Mlme_AssociateRequestConfirm request,
	                                                                   uint8_t capabilityInformation )
	{
		uint8_t *frame = request->msg.request.assocRequestFrame;
		*((uint8_t*)msduAssocCapabilityInfo(frame)) = capabilityInformation;
	}
	                                       
	command void MlmeAssociateRequestConfirm.setSecurityEnable( Mlme_AssociateRequestConfirm request )
	{
		uint8_t *frame = request->msg.request.assocRequestFrame;
		mhrSecurityEnabled(frame) = TRUE;
	}

	command uint16_t MlmeAssociateRequestConfirm.getAssocShortAddress( Mlme_AssociateRequestConfirm confirm )
	{
		uint16_t ret;
		NTOUH16((uint8_t*)(&(confirm->msg.confirm.assocShortAddr)), (uint8_t*)(&ret));
		return ret;
	}
	
	command Ieee_Status MlmeAssociateRequestConfirm.getStatus( Mlme_AssociateRequestConfirm confirm )
	{
		return confirm->msg.confirm.status;
	}
}
