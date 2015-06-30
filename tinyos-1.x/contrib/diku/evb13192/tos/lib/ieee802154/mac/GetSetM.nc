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

module GetSetM
{
	provides
	{
		interface IeeeSyncRequestConfirm<Mlme_GetRequestConfirm> as MlmeRequestConfirmGet;
		interface IeeeSyncRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
		interface IeeeRequestConfirm<Mlme_ResetRequestConfirm> as MlmeRequestConfirmReset;
	}
	uses
	{
		interface PibDatabase;
		interface Reset;
		interface PhyReset;
		interface FrameRx;
		interface CallbackService;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 0
	#include "Debug.h"

	void confirmSet(uint8_t *setPrimitive);
	void confirmGet(uint8_t *getPrimitive);
	void confirmReset(uint8_t *resetPrimitive);

	command Mlme_SetRequestConfirm MlmeRequestConfirmSet.request(Mlme_SetRequestConfirm request)
	{
		request->msg.confirm.status = call PibDatabase.set(request->msg.request.pibAttribute->value, request->msg.request.pibAttribute->attribute);
		call CallbackService.enqueue((uint8_t*)request, confirmSet);
		return request;
	}

	command Mlme_GetRequestConfirm MlmeRequestConfirmGet.request(Mlme_GetRequestConfirm request)
	{
		request->msg.confirm.status = call PibDatabase.get(request->msg.confirm.pibAttribute->value, request->msg.request.pibAttribute->attribute);
		call CallbackService.enqueue((uint8_t*)request, confirmGet);
		return request;
	}
	
	command result_t MlmeRequestConfirmReset.request(Mlme_ResetRequestConfirm request)
	{
		bool resetPib = request->msg.request.setDefaultPib;
		if (SUCCESS != call FrameRx.trxOff(FALSE)) {
			request->msg.confirm.status = IEEE802154_DISABLE_TRX_FAILURE;
			return FAIL;
		}

		call PhyReset.reset();
		call Reset.reset();
		if (resetPib) {
			call PibDatabase.reset();
		}
		request->msg.confirm.status = IEEE802154_SUCCESS;
		call CallbackService.enqueue((uint8_t*)request, confirmReset);
		return SUCCESS;
	}
	
	void confirmGet(uint8_t *getPrimitive)
	{
		signal MlmeRequestConfirmGet.confirm((Mlme_GetRequestConfirm)getPrimitive);
	}
	
	void confirmSet(uint8_t *setPrimitive)
	{
		signal MlmeRequestConfirmSet.confirm((Mlme_SetRequestConfirm)setPrimitive);
	}
	
	void confirmReset(uint8_t *resetPrimitive)
	{
		signal MlmeRequestConfirmReset.confirm((Mlme_ResetRequestConfirm)resetPrimitive);
	}
	
	default event void MlmeRequestConfirmSet.confirm(Mlme_SetRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmSet.confirm",1);
	}

	default event void MlmeRequestConfirmGet.confirm(Mlme_GetRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmGet.confirm",1);
	}
	
	default event void MlmeRequestConfirmReset.confirm(Mlme_ResetRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmReset.confirm",1);
	}
}
