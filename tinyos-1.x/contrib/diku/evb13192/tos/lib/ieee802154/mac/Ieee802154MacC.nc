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

#include "mac.h"

configuration Ieee802154MacC
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
		interface IeeeSyncRequestConfirm<Mlme_GetRequestConfirm> as MlmeRequestConfirmGet;
		interface IeeeIndication<Mlme_GtsIndication> as MlmeIndicationGts;		
		interface IeeeRequestConfirm<Mlme_GtsRequestConfirm> as MlmeRequestConfirmGts;
		interface IeeeIndicationResponse<Mlme_OrphanIndicationResponse> as MlmeIndicationResponseOrphan;
		interface IeeeRequestConfirm<Mlme_PollRequestConfirm> as MlmeRequestConfirmPoll;
		interface IeeeRequestConfirm<Mlme_ResetRequestConfirm> as MlmeRequestConfirmReset;
		interface IeeeRequestConfirm<Mlme_RxEnableRequestConfirm> as MlmeRequestConfirmRxEnable;
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface IeeeSyncRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
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
		interface PhyReset;
	
		// Alarms.
		interface AsyncAlarm<time_t> as ScanAlarm;
		interface AsyncAlarm<time_t> as EdAlarm;
		interface AsyncAlarm<time_t> as TrackAlarm;
		interface AsyncAlarm<time_t> as TrackerCfpAlarm;
		interface AsyncAlarm<time_t> as BeaconAlarm;
		interface AsyncAlarm<time_t> as GeneratorCfpAlarm;
		interface AsyncAlarm<time_t> as RxEnableAlarm;
		interface AsyncAlarm<time_t> as TimeoutAlarm1;
		interface AsyncAlarm<time_t> as TimeoutAlarm2;
		interface AsyncAlarm<time_t> as CfpAlarm;
		interface AsyncAlarm<time_t> as CfpAlarm2;
	
		interface LocalTime;
		
		// Fifo queueing support.
		interface FIFOQueue;
		
		// Buffer Management.
		interface IeeeBufferManagement as BufferMng;
		
		// Random
		interface Random;
		
		// Debug
		interface Debug;
	}
}
implementation
{
	components EdM,
	           FrameRxM,
	           FrameTxM,
	           MacAddressM,
	           MacPibDatabaseM,
	           ScanM,
	           ScanServiceM,
	           AssociateM,
	           BeaconGeneratorM,
	           BeaconTrackerM,
	           CapControlM,
	           CfpControlM,
	           CsmaM,
	           DataM,
	           GetSetM,
	           IndirectTxM,
	           OrphanHandlerM,
	           PollM,
	           PollServiceM,
	           RxEnableM,
	           StartM,
	           SuperframeM,
	           TimingServiceM,
	           CallbackServiceM,
	           DummyM,
	           
	           PibAttributeM,
	           PanDescriptorM,
	           SduM,
	           AddressM,
	           
	           McpsDataIndicationM,
	           McpsDataRequestConfirmM,
	           McpsPurgeRequestConfirmM,
	           
	           MlmeAssociateIndicationResponseM,
	           MlmeAssociateRequestConfirmM,
	           MlmeBeaconNotifyIndicationM,
	           MlmeCommStatusIndicationM,
	           MlmeDisassociateRequestConfirmM,
	           MlmeDisassociateIndicationM,
	           MlmeGetRequestConfirmM,
	           MlmeGtsRequestConfirmM,
	           MlmeGtsIndicationM,
	           MlmeOrphanIndicationResponseM,
	           MlmePollRequestConfirmM,
	           MlmeResetRequestConfirmM,
	           MlmeRxEnableRequestConfirmM,
	           MlmeScanRequestConfirmM,
	           MlmeSetRequestConfirmM,
	           MlmeStartRequestConfirmM,
	           MlmeSyncRequestM,
	           MlmeSyncLossIndicationM;

	StdControl = MacPibDatabaseM.StdControl;
	StdControl = FrameRxM.StdControl;
	StdControl = ScanM.StdControl;
	StdControl = CapControlM.StdControl;
	StdControl = CallbackServiceM.StdControl;


	// messaging wiring
	// MCPS
	McpsIndicationData = DataM.McpsIndicationData;
	McpsRequestConfirmData = DataM.McpsRequestConfirmData;
	McpsRequestConfirmPurge = IndirectTxM.McpsRequestConfirmPurge;
	
	McpsDataIndication = McpsDataIndicationM;
	McpsDataRequestConfirm = McpsDataRequestConfirmM;
	McpsPurgeRequestConfirm = McpsPurgeRequestConfirmM;
	
	//MLME
	MlmeIndicationResponseAssociate = AssociateM.MlmeIndicationResponseAssociate;
	MlmeRequestConfirmAssociate = AssociateM.MlmeRequestConfirmAssociate;
	MlmeIndicationDisassociate = AssociateM.MlmeIndicationDisassociate;
	MlmeRequestConfirmDisassociate = AssociateM.MlmeRequestConfirmDisassociate;
	MlmeIndicationCommStatus = AssociateM.MlmeIndicationCommStatus;
	
	MlmeIndicationBeaconNotify = BeaconTrackerM.MlmeIndicationBeaconNotify;
	MlmeIndicationSyncLoss = BeaconTrackerM.MlmeIndicationSyncLoss;
	MlmeRequestSync = BeaconTrackerM.MlmeRequestSync;
	

	MlmeIndicationGts = CfpControlM.MlmeIndicationGts;
	MlmeRequestConfirmGts = CfpControlM.MlmeRequestConfirmGts;

	MlmeRequestConfirmGet = GetSetM.MlmeRequestConfirmGet;
	MlmeRequestConfirmSet = GetSetM.MlmeRequestConfirmSet;
	MlmeRequestConfirmReset = GetSetM.MlmeRequestConfirmReset;

	MlmeRequestConfirmPoll = PollM.MlmeRequestConfirmPoll;
	MlmeRequestConfirmRxEnable = RxEnableM.MlmeRequestConfirmRxEnable;

	MlmeIndicationResponseOrphan = OrphanHandlerM.MlmeIndicationResponseOrphan;
	MlmeIndicationCommStatus = OrphanHandlerM.MlmeIndicationCommStatus;
	
	MlmeRequestConfirmScan = ScanM.MlmeRequestConfirmScan;

	MlmeRequestConfirmStart = StartM.MlmeRequestConfirmStart;

	
	// primitive handling wiring
	IeeePibAttribute = PibAttributeM;
	IeeePanDescriptor = PanDescriptorM;
	IeeeSdu = SduM;
	IeeeAddress = AddressM;
	
	MlmeAssociateIndicationResponse = MlmeAssociateIndicationResponseM;
	MlmeAssociateRequestConfirm = MlmeAssociateRequestConfirmM;
	MlmeBeaconNotifyIndication = MlmeBeaconNotifyIndicationM;
	MlmeCommStatusIndication = MlmeCommStatusIndicationM;
	MlmeDisassociateRequestConfirm = MlmeDisassociateRequestConfirmM;
	MlmeDisassociateIndication = MlmeDisassociateIndicationM;
	MlmeGetRequestConfirm = MlmeGetRequestConfirmM;
	MlmeGtsRequestConfirm = MlmeGtsRequestConfirmM;
	MlmeGtsIndication = MlmeGtsIndicationM;
	MlmeOrphanIndicationResponse = MlmeOrphanIndicationResponseM;
	MlmePollRequestConfirm = MlmePollRequestConfirmM;
	MlmeResetRequestConfirm = MlmeResetRequestConfirmM;
	MlmeRxEnableRequestConfirm = MlmeRxEnableRequestConfirmM;
	MlmeScanRequestConfirm = MlmeScanRequestConfirmM;
	MlmeSetRequestConfirm = MlmeSetRequestConfirmM;
	MlmeStartRequestConfirm = MlmeStartRequestConfirmM;
	MlmeSyncRequest = MlmeSyncRequestM;
	MlmeSyncLossIndication = MlmeSyncLossIndicationM;
	
	// Connect pib database.
	MlmePollRequestConfirmM.PibDatabase -> MacPibDatabaseM.PibDatabase;
	
	// Connect the PHY interfaces.
	EdM.PhyEnergyDetect = PhyEnergyDetect;
	FrameRxM.PhyReceive = PhyReceive;
	FrameRxM.PhyControl = PhyControl;
	FrameTxM.PhyTransmit = PhyTransmit;
	ScanServiceM.PhyAttributes = PhyAttributes;
	BeaconTrackerM.PhyAttributes = PhyAttributes;
	AssociateM.PhyAttributes = PhyAttributes;
	GetSetM.PhyReset = PhyReset;
	StartM.PhyAttributes = PhyAttributes;
	
	// Wire the buffer manager
	McpsDataIndicationM.BufferMng = BufferMng;
	McpsDataRequestConfirmM.BufferMng = BufferMng;
	McpsPurgeRequestConfirmM.BufferMng = BufferMng;

	MlmeAssociateRequestConfirmM.BufferMng = BufferMng;
	MlmeBeaconNotifyIndicationM.BufferMng = BufferMng;
	MlmeCommStatusIndicationM.BufferMng = BufferMng;
	MlmeDisassociateRequestConfirmM.BufferMng = BufferMng;
	MlmeDisassociateIndicationM.BufferMng = BufferMng;
	MlmeGetRequestConfirmM.BufferMng = BufferMng;
	MlmeGtsRequestConfirmM.BufferMng = BufferMng;
	MlmeGtsIndicationM.BufferMng = BufferMng;
	MlmeOrphanIndicationResponseM.BufferMng = BufferMng;
	MlmePollRequestConfirmM.BufferMng = BufferMng;
	MlmeResetRequestConfirmM.BufferMng = BufferMng;
	MlmeRxEnableRequestConfirmM.BufferMng = BufferMng;
	MlmeScanRequestConfirmM.BufferMng = BufferMng;
	MlmeSetRequestConfirmM.BufferMng = BufferMng;
	MlmeStartRequestConfirmM.BufferMng = BufferMng;
	MlmeSyncRequestM.BufferMng = BufferMng;
	MlmeSyncLossIndicationM.BufferMng = BufferMng;
	
	PibAttributeM.BufferMng = BufferMng;
	SduM.BufferMng = BufferMng;
	AddressM.BufferMng = BufferMng;
	
	ScanM.BufferMng = BufferMng;
	FrameRxM.BufferMng = BufferMng;
	BeaconTrackerM.BufferMng = BufferMng;
	AssociateM.BufferMng = BufferMng;
	DataM.BufferMng = BufferMng;
	BeaconGeneratorM.BufferMng = BufferMng;
	OrphanHandlerM.BufferMng = BufferMng;
	StartM.BufferMng = BufferMng;
	IndirectTxM.BufferMng = BufferMng;
	CfpControlM.BufferMng = BufferMng;
	
	// Wire fifo queue interface
	CallbackServiceM.Queue = FIFOQueue;
	
	// Wire the reset function.
	GetSetM.Reset -> AssociateM.Reset;
	GetSetM.Reset -> BeaconTrackerM.Reset;
	GetSetM.Reset -> CapControlM.Reset;
	GetSetM.Reset -> FrameRxM.Reset;
	GetSetM.Reset -> FrameTxM.Reset;
	GetSetM.Reset -> PollServiceM.Reset;
	GetSetM.Reset -> ScanServiceM.Reset;
	
	// Wire the timers.
	EdM.Alarm = EdAlarm;
	ScanServiceM.Alarm = ScanAlarm;
	BeaconTrackerM.TrackAlarm = TrackAlarm;
	BeaconTrackerM.CfpAlarm = TrackerCfpAlarm;
	BeaconGeneratorM.BeaconAlarm = BeaconAlarm;
	BeaconGeneratorM.CfpAlarm = GeneratorCfpAlarm;
	RxEnableM.RxEnableAlarm = RxEnableAlarm;
	TimingServiceM.ResponseWaitAlarm = TimeoutAlarm1;
	TimingServiceM.FrameResponseAlarm = TimeoutAlarm2;
	CfpControlM.CfpAlarm = CfpAlarm;
	CfpControlM.RxOffAlarm = CfpAlarm2;
	
	SuperframeM.LocalTime = LocalTime;
	CsmaM.LocalTime = LocalTime;
	CapControlM.LocalTime = LocalTime;
	CfpControlM.LocalTime = LocalTime;
	RxEnableM.LocalTime = LocalTime;
	BeaconGeneratorM.LocalTime = LocalTime;
	
	
	// Wire random number generator
	MacPibDatabaseM.Random = Random;
	CsmaM.Random = Random;
	
	// Wire the address module.
	MlmeAssociateRequestConfirmM.MacAddress -> MacAddressM.MacAddress;
	MlmeAssociateIndicationResponseM.MacAddress -> MacAddressM.MacAddress;
	MlmeDisassociateRequestConfirmM.MacAddress -> MacAddressM.MacAddress;
	McpsDataRequestConfirmM.MacAddress -> MacAddressM.MacAddress;
	MlmeGtsRequestConfirmM.MacAddress -> MacAddressM.MacAddress;
	
	ScanM.MacAddress -> MacAddressM.MacAddress;
	AssociateM.MacAddress -> MacAddressM.MacAddress;
	PollServiceM.MacAddress -> MacAddressM.MacAddress;
	BeaconTrackerM.MacAddress -> MacAddressM.MacAddress;
	BeaconGeneratorM.MacAddress -> MacAddressM.MacAddress;
	IndirectTxM.MacAddress -> MacAddressM.MacAddress;
	OrphanHandlerM.MacAddress -> MacAddressM.MacAddress;
	CfpControlM.MacAddress -> MacAddressM.MacAddress;
	
	// Wire the application callback service.
	AssociateM.CallbackService -> CallbackServiceM.CallbackService;
	CfpControlM.CallbackService -> CallbackServiceM.CallbackService;
	DataM.CallbackService -> CallbackServiceM.CallbackService;
	BeaconTrackerM.CallbackService -> CallbackServiceM.CallbackService;
	GetSetM.CallbackService -> CallbackServiceM.CallbackService;
	IndirectTxM.CallbackService -> CallbackServiceM.CallbackService;
	StartM.CallbackService -> CallbackServiceM.CallbackService;
	
	// Inter-MAC wiring
	ScanServiceM.BeaconFrame -> FrameRxM.ScanBeaconFrame;
	ScanServiceM.CoordRealignFrame -> FrameRxM.CoordRealignFrame;
	ScanServiceM.FrameRx -> FrameRxM.FrameRx;
	ScanServiceM.Ed -> EdM.Ed;
	ScanM.ScanService -> ScanServiceM.ScanService;
	BeaconTrackerM.FrameRx -> FrameRxM.FrameRx;
	BeaconTrackerM.BeaconFrame -> FrameRxM.BeaconFrame;
	BeaconTrackerM.Superframe -> SuperframeM.Superframe;
	BeaconTrackerM.PollService -> PollServiceM.PollService[1];
	BeaconTrackerM.BeaconGtsService -> CfpControlM.BeaconGtsService;
	GetSetM.PibDatabase -> MacPibDatabaseM.PibDatabase;
	AssociateM.AssocReqFrame -> FrameRxM.AssocReqFrame;
	AssociateM.AssocRespFrame -> FrameRxM.AssocRespFrame;
	AssociateM.DisassocNotFrame -> FrameRxM.DisassocNotFrame;
	AssociateM.TimingService -> TimingServiceM.TimingService[0];
	AssociateM.PollService -> PollServiceM.PollService[0];
	AssociateM.DeviceTx -> CapControlM.DeviceTx[0];
	PollServiceM.DeviceTx -> CapControlM.DeviceTx[1];
	DataM.DeviceTx -> CapControlM.DeviceTx[2];
	CfpControlM.DeviceTx -> CapControlM.DeviceTx[3];
	PollServiceM.DeviceRx -> CapControlM.DeviceRx;
	PollServiceM.TimingService -> TimingServiceM.TimingService[1];
	PollServiceM.PollEvents -> FrameRxM.PollEvents;
	CapControlM.Csma -> CsmaM.Csma;
	CapControlM.Superframe -> SuperframeM.Superframe;
	CapControlM.FrameRx -> FrameRxM.FrameRx;
	CapControlM.DeviceCap -> BeaconTrackerM.DeviceCap;
	CapControlM.CoordinatorCap -> BeaconGeneratorM.CoordinatorCap;
	CfpControlM.GtsReqFrame -> FrameRxM.GtsReqFrame;
	CfpControlM.Superframe -> SuperframeM.Superframe;
	CfpControlM.FrameRx -> FrameRxM.FrameRx;
	CfpControlM.DeviceCfp -> BeaconTrackerM.DeviceCfp;
	CfpControlM.CoordinatorCfp -> BeaconGeneratorM.CoordinatorCfp;
	ScanServiceM.FrameTx -> FrameTxM.FrameTx[0];
	CsmaM.FrameTx -> FrameTxM.FrameTx[1];
	BeaconGeneratorM.FrameTx -> FrameTxM.FrameTx[2];
	CfpControlM.FrameTx -> FrameTxM.FrameTx[3];
	CsmaM.Superframe -> SuperframeM.Superframe;
	PollM.PollService -> PollServiceM.PollService[2];
	DataM.DataFrame -> FrameRxM.DataFrame;
	DataM.CfpTx -> CfpControlM.CfpTx;
	GetSetM.FrameRx -> FrameRxM.FrameRx;
	RxEnableM.DeviceRx -> CapControlM.DeviceRx;
	RxEnableM.CoordinatorRx -> CapControlM.CoordinatorRx;
	RxEnableM.Superframe -> SuperframeM.Superframe;
	BeaconGeneratorM.Superframe -> SuperframeM.Superframe;
	BeaconGeneratorM.BeaconDataService -> IndirectTxM.BeaconDataService;
	BeaconGeneratorM.BeaconReqFrame -> FrameRxM.BeaconReqFrame;
	BeaconGeneratorM.CoordinatorTx -> CapControlM.CoordinatorTx[0];
	BeaconGeneratorM.BeaconGtsService -> CfpControlM.BeaconGtsService;
	StartM.BeaconGenerator -> BeaconGeneratorM.BeaconGenerator;
	StartM.CoordinatorTx -> CapControlM.CoordinatorTx[1];
	StartM.Realignment -> OrphanHandlerM.Realignment;
	IndirectTxM.CoordinatorTx -> CapControlM.CoordinatorTx[2];
	IndirectTxM.DataReqFrame -> FrameRxM.DataReqFrame;
	AssociateM.IndirectTx -> IndirectTxM.IndirectTx[0];
	DataM.IndirectTx -> IndirectTxM.IndirectTx[1];
	OrphanHandlerM.CoordinatorTx -> CapControlM.CoordinatorTx[3];
	OrphanHandlerM.OrphanNotFrame -> FrameRxM.OrphanNotFrame;
	MacPibDatabaseM.PibChange -> CapControlM.PibChange;
	
	MlmeOrphanIndicationResponseM.Realignment -> OrphanHandlerM.Realignment;
	
	// Debug wiring.
	EdM.Debug = Debug;
	FrameRxM.Debug = Debug;
	FrameTxM.Debug = Debug;
	MacAddressM.Debug = Debug;
	ScanM.Debug = Debug;
	ScanServiceM.Debug = Debug;
	BeaconTrackerM.Debug = Debug;
	SuperframeM.Debug = Debug;
	GetSetM.Debug = Debug;
	AssociateM.Debug = Debug;
	TimingServiceM.Debug = Debug;
	CapControlM.Debug = Debug;
	CfpControlM.Debug = Debug;
	CsmaM.Debug = Debug;
	PollServiceM.Debug = Debug;
	MacPibDatabaseM.Debug = Debug;
	PollM.Debug = Debug;
	DataM.Debug = Debug;
	RxEnableM.Debug = Debug;
	BeaconGeneratorM.Debug = Debug;
	StartM.Debug = Debug;
	IndirectTxM.Debug = Debug;
	OrphanHandlerM.Debug = Debug;
}
