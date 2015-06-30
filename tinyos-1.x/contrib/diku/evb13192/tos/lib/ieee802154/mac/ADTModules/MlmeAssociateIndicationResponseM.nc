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

module MlmeAssociateIndicationResponseM
{
	provides
	{
		interface MlmeAssociateIndicationResponse;
	}
	uses
	{
		interface MacAddress;
	}
}
implementation
{	
	command void MlmeAssociateIndicationResponse.getDeviceAddress( Mlme_AssociateIndicationResponse indication,
	                                                               uint8_t *deviceAddr )
	{
		// Destination is always 64 bit for this type of frame.
		uint8_t *frame = indication->msg.indication.assocIndicationFrame;
		NTOUH64(mhrSrcAddr(frame), deviceAddr);
	}
	
	command uint8_t MlmeAssociateIndicationResponse.getCapabilityInformation( Mlme_AssociateIndicationResponse indication )
	{
		uint8_t *frame = indication->msg.indication.assocIndicationFrame;
		return *((uint8_t*)msduAssocCapabilityInfo(frame));
	}
	
	command bool MlmeAssociateIndicationResponse.getSecurityUse( Mlme_AssociateIndicationResponse indication )
	{
		uint8_t *frame = indication->msg.indication.assocIndicationFrame;
		return mhrSecurityEnabled(frame);
	}
	
	command uint8_t MlmeAssociateIndicationResponse.getAclEntry( Mlme_AssociateIndicationResponse indication )
	{
		return indication->msg.indication.ACLEntry;
	}

	// Be careful! When constructing a response, 
	// setDeviceAddress must be called before
	// setAssocShortAddress and setStatus is called.
	command void MlmeAssociateIndicationResponse.setDeviceAddress( Mlme_AssociateIndicationResponse response,
	                                                               uint8_t *deviceAddress )
	{
		// Always 64 bit addressing and intraPAN.
		uint8_t *frame = response->msg.response.assocResponseFrame;
		//uint16_t panId = call PibDatabase.getPANId();
		mhrIntraPAN(frame) = TRUE;
		mhrDestAddrMode(frame) = 3;
		NTOUH64(deviceAddress, mhrDestAddr(frame));
		*((uint16_t*)mhrDestPANId(frame)) = macPanId;
		call MacAddress.setSrcLocal(frame, TRUE);
		// Security not enabled by default.
		mhrSecurityEnabled(frame) = FALSE;
		msduCommandFrameIdent(frame) = maccommandAssocResp;
		response->inited = TRUE;
	}
	
	command result_t MlmeAssociateIndicationResponse.setAssocShortAddress( Mlme_AssociateIndicationResponse response,
	                                                                       uint16_t assocShortAddress )
	{
		uint8_t *frame = response->msg.response.assocResponseFrame;
		if (response->inited) {
			NTOUH16(((uint8_t*)&assocShortAddress), msduAssocResponseShortAddr(frame));
			return SUCCESS;
		}
		return FAIL;
	}
	
	command result_t MlmeAssociateIndicationResponse.setStatus( Mlme_AssociateIndicationResponse response,
	                                                            Ieee_Status status )
	{
		uint8_t *frame = response->msg.response.assocResponseFrame;
		if (response->inited) {
			msduAssocResponseStatus(frame) = status;
			return SUCCESS;
		}
		return FAIL;
	}
	
	command result_t MlmeAssociateIndicationResponse.setSecurityEnable( Mlme_AssociateIndicationResponse response )
	{
		uint8_t *frame = response->msg.response.assocResponseFrame;
		if (response->inited) {
			mhrSecurityEnabled(frame) = TRUE;
		}
	}
}
