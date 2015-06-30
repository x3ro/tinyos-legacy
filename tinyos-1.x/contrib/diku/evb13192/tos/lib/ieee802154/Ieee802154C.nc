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

configuration Ieee802154C
{
	provides
	{
		interface StdControl;
		
		// interfaces for handling 802.15.4 messaging
		// MCPS
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
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface IeeeRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
		interface IeeeRequestConfirm<Mlme_StartRequestConfirm> as MlmeRequestConfirmStart;
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface IeeeRequest<Mlme_SyncRequest> as MlmeRequestSync;

		
		// interfaces for handling 802.15.4 primitive types		
		interface IeeeMacSdu as IeeeSdu;
		interface IeeeMacPibAttribute as IeeePibAttribute;
		interface IeeePanDescriptor;
		interface IeeeAddress;
		
		interface McpsDataIndication;
		interface McpsDataRequestConfirm;
		interface McpsPurgeRequestConfirm;
		
		interface MlmeAssociateIndicationResponse;
		interface MlmeAssociateRequestConfirm;
		interface MlmeBeaconNotifyIndication;
		interface MlmeCommStatusIndication;
		interface MlmeDisassociateRequestConfirm;
		interface MlmeDisassociateIndication;
		interface MlmeGetRequestConfirm;
		interface MlmeGtsRequestConfirm;
		interface MlmeGtsIndication;
		interface MlmeOrphanIndicationResponse;
		interface MlmePollRequestConfirm;
		interface MlmeResetRequestConfirm;
		interface MlmeRxEnableRequestConfirm;
		interface MlmeScanRequestConfirm;
		interface MlmeSetRequestConfirm;
		interface MlmeStartRequestConfirm;
		interface MlmeSyncRequest;
		interface MlmeSyncLossIndication;
	}
	uses
	{
		interface PhyAttributes;
		interface PhyControl;
		interface PhyEnergyDetect;
		interface PhyReceive;
		interface PhyTransmit;
		
		interface Debug;
	}
}

implementation
{
	components Ieee802154PhyC,
	           Ieee802154MacC,
	           FIFOQueueM,
	           SimpleBufferManM,
	           RandomLFSR;

	StdControl = SimpleBufferManM.StdControl;
	StdControl = Ieee802154PhyC.StdControl;
	StdControl = Ieee802154MacC.StdControl;
	
	// Debug.
	Ieee802154PhyC.Debug = Debug;
	Ieee802154MacC.Debug = Debug;
	SimpleBufferManM.Debug = Debug;
	FIFOQueueM.Debug = Debug;
	
	// messaging wiring
	// MCPS
	McpsIndicationData = Ieee802154MacC.McpsIndicationData;
	McpsRequestConfirmData = Ieee802154MacC.McpsRequestConfirmData;
	McpsRequestConfirmPurge = Ieee802154MacC.McpsRequestConfirmPurge;
	
	McpsDataIndication = Ieee802154MacC.McpsDataIndication;
	McpsDataRequestConfirm = Ieee802154MacC.McpsDataRequestConfirm;
	McpsPurgeRequestConfirm = Ieee802154MacC.McpsPurgeRequestConfirm;
	
	//MLME
	MlmeIndicationResponseAssociate = Ieee802154MacC.MlmeIndicationResponseAssociate;
	MlmeRequestConfirmAssociate = Ieee802154MacC.MlmeRequestConfirmAssociate;
	MlmeIndicationBeaconNotify = Ieee802154MacC.MlmeIndicationBeaconNotify;
	MlmeIndicationCommStatus = Ieee802154MacC.MlmeIndicationCommStatus;
	MlmeIndicationDisassociate = Ieee802154MacC.MlmeIndicationDisassociate;
	MlmeRequestConfirmDisassociate = Ieee802154MacC.MlmeRequestConfirmDisassociate;
	MlmeRequestConfirmGet = Ieee802154MacC.MlmeRequestConfirmGet;
	MlmeIndicationGts = Ieee802154MacC.MlmeIndicationGts;
	MlmeRequestConfirmGts = Ieee802154MacC.MlmeRequestConfirmGts;
	MlmeIndicationResponseOrphan = Ieee802154MacC.MlmeIndicationResponseOrphan;
	MlmeRequestConfirmPoll = Ieee802154MacC.MlmeRequestConfirmPoll;
	MlmeRequestConfirmReset = Ieee802154MacC.MlmeRequestConfirmReset;
	MlmeRequestConfirmRxEnable = Ieee802154MacC.MlmeRequestConfirmRxEnable;
	MlmeRequestConfirmScan = Ieee802154MacC.MlmeRequestConfirmScan;
	MlmeRequestConfirmSet = Ieee802154MacC.MlmeRequestConfirmSet;
	MlmeRequestConfirmStart = Ieee802154MacC.MlmeRequestConfirmStart;
	MlmeIndicationSyncLoss = Ieee802154MacC.MlmeIndicationSyncLoss;
	MlmeRequestSync = Ieee802154MacC.MlmeRequestSync;
	
	// primitive handling wiring
	IeeePibAttribute = Ieee802154MacC.IeeePibAttribute;
	IeeePanDescriptor = Ieee802154MacC.IeeePanDescriptor;
	IeeeSdu = Ieee802154MacC.IeeeSdu;
	IeeeAddress = Ieee802154MacC.IeeeAddress;
	
	MlmeAssociateIndicationResponse = Ieee802154MacC.MlmeAssociateIndicationResponse;
	MlmeAssociateRequestConfirm = Ieee802154MacC.MlmeAssociateRequestConfirm;
	MlmeBeaconNotifyIndication = Ieee802154MacC.MlmeBeaconNotifyIndication;
	MlmeCommStatusIndication = Ieee802154MacC.MlmeCommStatusIndication;
	MlmeDisassociateRequestConfirm = Ieee802154MacC.MlmeDisassociateRequestConfirm;
	MlmeDisassociateIndication = Ieee802154MacC.MlmeDisassociateIndication;
	MlmeGetRequestConfirm = Ieee802154MacC.MlmeGetRequestConfirm;
	MlmeGtsRequestConfirm = Ieee802154MacC.MlmeGtsRequestConfirm;
	MlmeGtsIndication = Ieee802154MacC.MlmeGtsIndication;
	MlmeOrphanIndicationResponse = Ieee802154MacC.MlmeOrphanIndicationResponse;
	MlmePollRequestConfirm = Ieee802154MacC.MlmePollRequestConfirm;
	MlmeResetRequestConfirm = Ieee802154MacC.MlmeResetRequestConfirm;
	MlmeRxEnableRequestConfirm = Ieee802154MacC.MlmeRxEnableRequestConfirm;
	MlmeScanRequestConfirm = Ieee802154MacC.MlmeScanRequestConfirm;
	MlmeSetRequestConfirm = Ieee802154MacC.MlmeSetRequestConfirm;
	MlmeStartRequestConfirm = Ieee802154MacC.MlmeStartRequestConfirm;
	MlmeSyncRequest = Ieee802154MacC.MlmeSyncRequest;
	MlmeSyncLossIndication = Ieee802154MacC.MlmeSyncLossIndication;
	
	// Wire timers.
	Ieee802154MacC.ScanTimer = Timer[unique("Timer")];
	Ieee802154MacC.AckTimer = Timer[unique("Timer")];
	Ieee802154MacC.ResponseTimer = Timer[unique("Timer")];
//	Ieee802154MacC.UnslottedCsmaTimer = Timer[unique("Timer")];
	
	// Wire random number generator
	Ieee802154MacC.Random -> RandomLFSR.Random;
	
	// Wire the queue module.
	SimpleBufferManM.Queue -> FIFOQueueM.FIFOQueue;
	Ieee802154PhyC.Queue -> FIFOQueueM.FIFOQueue;
	Ieee802154MacC.Queue -> FIFOQueueM.FIFOQueue;
	
	// Wire the buffer manager.
	Ieee802154PhyC.BufferMng -> SimpleBufferManM.BufferMng;
	Ieee802154MacC.BufferMng -> SimpleBufferManM.BufferMng;
}
