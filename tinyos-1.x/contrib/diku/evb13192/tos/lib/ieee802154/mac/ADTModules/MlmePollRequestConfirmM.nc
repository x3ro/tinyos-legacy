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
module MlmePollRequestConfirmM
{
	provides
	{
		interface MlmePollRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface PibDatabase;
	}
}
implementation
{
	command result_t MlmePollRequestConfirm.create( Mlme_PollRequestConfirm *primitive,
	                                                Ieee_Address coordAddr )
	{
		ieeeAddress_t *myCoordAddr;

		if (FAIL == call BufferMng.claim(sizeof(mlmePollRequestConfirm_t), (uint8_t**)primitive)) {
			return FAIL;
		}
		
		myCoordAddr = &((*primitive)->msg.request.coordAddr);
		(*primitive)->msg.request.useSecurity = FALSE;
		
		// Copy the coordinator address.
		memcpy(myCoordAddr, coordAddr, sizeof(ieeeAddress_t));
	}
	
	command result_t MlmePollRequestConfirm.destroy( Mlme_PollRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(mlmePollRequestConfirm_t), (uint8_t*)primitive);
	}
	                           
	command void MlmePollRequestConfirm.setSecurityEnable( Mlme_PollRequestConfirm request )
	{
		request->msg.request.useSecurity = TRUE;
	}
	
	command Ieee_Status MlmePollRequestConfirm.getStatus( Mlme_PollRequestConfirm confirm )
	{
		return confirm->msg.confirm.status;
	}
}
