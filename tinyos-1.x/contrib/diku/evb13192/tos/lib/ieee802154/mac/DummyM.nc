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

// Provide all the interfaces not implemented yet.
module DummyM
{
	provides
	{
		interface IeeeIndication<Mcps_DataIndication> as McpsIndicationData;
		interface IeeeRequestConfirm<Mcps_DataRequestConfirm> as McpsRequestConfirmData;
		interface IeeeRequestConfirm<Mcps_PurgeRequestConfirm> as McpsRequestConfirmPurge;
		// MLME
		interface IeeeIndicationResponse<Mlme_AssociateIndicationResponse> as MlmeIndicationResponseAssociate;
		interface IeeeRequestConfirm<Mlme_AssociateRequestConfirm> as MlmeRequestConfirmAssociate;
		interface IeeeIndication<Mlme_BeaconNotifyIndication> as MlmeIndicationBeaconNotify;
		interface IeeeIndication<Mlme_CommStatusIndication> as MlmeIndicationCommStatus;
		interface IeeeIndication<Mlme_DisassociateIndication> as MlmeIndicationDisassociate;
		interface IeeeRequestConfirm<Mlme_DisassociateRequestConfirm> as MlmeRequestConfirmDisassociate;						
		interface IeeeRequestConfirm<Mlme_GetRequestConfirm> as MlmeRequestConfirmGet;
		interface IeeeIndication<Mlme_GtsIndication> as MlmeIndicationGts;		
		interface IeeeRequestConfirm<Mlme_GtsRequestConfirm> as MlmeRequestConfirmGts;
		interface IeeeIndicationResponse<Mlme_OrphanIndicationResponse> as MlmeIndicationResponseOrphan;
		interface IeeeRequestConfirm<Mlme_PollRequestConfirm> as MlmeRequestConfirmPoll;
		interface IeeeRequestConfirm<Mlme_ResetRequestConfirm> as MlmeRequestConfirmReset;
		interface IeeeRequestConfirm<Mlme_RxEnableRequestConfirm> as MlmeRequestConfirmRxEnable;
//		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface IeeeRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
		interface IeeeRequestConfirm<Mlme_StartRequestConfirm> as MlmeRequestConfirmStart;
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface IeeeRequest<Mlme_SyncRequest> as MlmeRequestSync;
	}
	uses
	{
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	command result_t McpsRequestConfirmData.request(Mcps_DataRequestConfirm request)
	{
		return FAIL;
	}

	command result_t McpsRequestConfirmPurge.request(Mcps_PurgeRequestConfirm request)
	{
		return FAIL;
	}
	
	/***************************
	 *   Default MCPS events   *
	 ***************************/

	default event void McpsRequestConfirmData.confirm(Mcps_DataRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled McpsRequestConfirmData.confirm",1);
	}

	default event void McpsRequestConfirmPurge.confirm(Mcps_PurgeRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled McpsRequestConfirmPurge.confirm",1);
	}	
	
	/**********************************************************
	** MLME
	***********************************************************/
	
	inline command result_t MlmeRequestConfirmAssociate.request(Mlme_AssociateRequestConfirm request)
	{
		return FAIL;
	}

	inline command result_t MlmeIndicationResponseAssociate.response( Mlme_AssociateIndicationResponse response )
	{
		return FAIL;
	}
	
	command result_t MlmeRequestConfirmDisassociate.request(Mlme_DisassociateRequestConfirm request)
	{
		return FAIL;
	}

	command result_t MlmeRequestConfirmGet.request(Mlme_GetRequestConfirm request)
	{
		return FAIL;
	}
	
	command result_t MlmeRequestConfirmGts.request(Mlme_GtsRequestConfirm request)
	{
		return FAIL;
	}

	command result_t MlmeIndicationResponseOrphan.response( Mlme_OrphanIndicationResponse response )
	{
		return FAIL;
	}
		
	command result_t MlmeRequestConfirmPoll.request(Mlme_PollRequestConfirm request)
	{
		return FAIL;
	}

	command result_t MlmeRequestConfirmReset.request(Mlme_ResetRequestConfirm request)
	{
		return FAIL;
	}

	command result_t MlmeRequestConfirmRxEnable.request(Mlme_RxEnableRequestConfirm request)
	{
		return FAIL;
	}

	command result_t MlmeRequestConfirmSet.request(Mlme_SetRequestConfirm request)
	{
		return FAIL;
	}

	command result_t MlmeRequestConfirmStart.request(Mlme_StartRequestConfirm request)
	{
		return FAIL;
	}

	command result_t MlmeRequestSync.request(Mlme_SyncRequest request)
	{
		return FAIL;
	}
	
	default event void McpsIndicationData.indication(Mcps_DataIndication indication)
	{
		DBG_STR("WARNING: Unhandled McpsIndicationData.indication",1);
	}

	/***************************
	 *   Default MLME events   *
	 ***************************/

	default event void MlmeRequestConfirmAssociate.confirm(Mlme_AssociateRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmAssociate.confirm",1);
	}
	
	default async event void MlmeIndicationResponseAssociate.indication(Mlme_AssociateIndicationResponse indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationResponseAssociate.indication",1);
	}

	default event void MlmeIndicationBeaconNotify.indication(Mlme_BeaconNotifyIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationBeaconNotify.indication",1);
	}
	
	default event void MlmeIndicationCommStatus.indication(Mlme_CommStatusIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationCommStatus.indication",1);
	}

	default event void MlmeRequestConfirmDisassociate.confirm(Mlme_DisassociateRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmDisassociate.confirm",1);
	}
	
	default event void MlmeIndicationDisassociate.indication(Mlme_DisassociateIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationDisassociate.indication",1);
	}

	default event void MlmeRequestConfirmGts.confirm(Mlme_GtsRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmGts.confirm",1);
	}
	
	default event void MlmeIndicationGts.indication(Mlme_GtsIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationGts.indication",1);
	}
	
	default async event void MlmeIndicationResponseOrphan.indication(Mlme_OrphanIndicationResponse indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationResponseOrphan.indication",1);
	}

	default event void MlmeRequestConfirmPoll.confirm(Mlme_PollRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmPoll.confirm",1);
	}

	default event void MlmeRequestConfirmReset.confirm(Mlme_ResetRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmReset.confirm",1);
	}

	default event void MlmeRequestConfirmRxEnable.confirm(Mlme_RxEnableRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmRxEnable.confirm",1);
	}

	default event void MlmeRequestConfirmSet.confirm(Mlme_SetRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmSet.confirm",1);
	}

	default event void MlmeRequestConfirmStart.confirm(Mlme_StartRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmStart.confirm",1);
	}

	default event void MlmeIndicationSyncLoss.indication(Mlme_SyncLossIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationSyncLoss.indication",1);
	}
}
