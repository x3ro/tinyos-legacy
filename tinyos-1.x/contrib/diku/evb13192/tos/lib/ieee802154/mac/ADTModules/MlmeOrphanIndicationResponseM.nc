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
module MlmeOrphanIndicationResponseM
{
	provides
	{
		interface MlmeOrphanIndicationResponse;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface Realignment;
	}
}
implementation
{	
	command void MlmeOrphanIndicationResponse.getOrphanAddress( Mlme_OrphanIndicationResponse indication,
	                                                            uint8_t *addr )
	{
		uint8_t *frame = indication->msg.indication.orphanNotificationFrame;
		NTOUH64(mhrSrcAddr(frame), addr);
	}
	
	command bool MlmeOrphanIndicationResponse.getSecurityUse( Mlme_OrphanIndicationResponse indication )
	{
		uint8_t *frame = indication->msg.indication.orphanNotificationFrame;
		return mhrSecurityEnabled(frame);
	}
	
	command uint8_t MlmeOrphanIndicationResponse.getAclEntry( Mlme_OrphanIndicationResponse indication )
	{
		return indication->msg.indication.ACLEntry;
	}


	// Ensure that this is set prior to setting anything else.
	command void MlmeOrphanIndicationResponse.setOrphanAddress( Mlme_OrphanIndicationResponse response,
	                                                            uint8_t *orphanAddress )
	{
		call Realignment.create(response->msg.response.coordRealignFrame, FALSE, orphanAddress);
		response->inited = TRUE;
	}
	                                                            
	command result_t MlmeOrphanIndicationResponse.setShortAddress( Mlme_OrphanIndicationResponse response,
	                                                               uint16_t shortAddress )
	{
		uint8_t *frame = response->msg.response.coordRealignFrame;
		if (response->inited) {
			NTOUH16((uint8_t*)&shortAddress, msduCoordRealignShortAddr(frame));
			return SUCCESS;
		}
		return FAIL;
	}
	
	command void MlmeOrphanIndicationResponse.setAssociatedMember( Mlme_OrphanIndicationResponse response,
	                                                               bool associatedMember )
	{
		response->msg.response.associatedMember = associatedMember;
	}
	
	command void MlmeOrphanIndicationResponse.setSecurityEnable( Mlme_OrphanIndicationResponse response )
	{
		uint8_t *frame = response->msg.response.coordRealignFrame;
		mhrSecurityEnabled(frame) = TRUE;
	}
}
