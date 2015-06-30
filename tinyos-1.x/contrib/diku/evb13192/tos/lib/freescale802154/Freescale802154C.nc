/*
    Console configurations - module that buffers and perhaps
    eventually will do some printf like thing.  

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
/**
 * Simple Freescale802154 component that uses Uart interface.  
 *
 * <p>This configuration maps onto the uart that is normally used to
 * connect onto a pc.</p>
 *
 * 

 */
includes Ieee802154Adts;
configuration Freescale802154C
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
		interface Debug;
	}
}

implementation
{
	components Freescale802154M,
	           FreescaleBufferMngM,
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

	Freescale802154M.Debug = Debug;
	StdControl = Freescale802154M.Control;


	// messaging wiring
	// MCPS
	McpsIndicationData = Freescale802154M.McpsIndicationData;
	McpsRequestConfirmData = Freescale802154M.McpsRequestConfirmData;
	McpsRequestConfirmPurge = Freescale802154M.McpsRequestConfirmPurge;
	
	McpsDataIndication = McpsDataIndicationM;
	McpsDataRequestConfirm = McpsDataRequestConfirmM;
	McpsPurgeRequestConfirm = McpsPurgeRequestConfirmM;
	
	//MLME
	MlmeIndicationResponseAssociate = Freescale802154M.MlmeIndicationResponseAssociate;
	MlmeRequestConfirmAssociate = Freescale802154M.MlmeRequestConfirmAssociate;
	MlmeIndicationBeaconNotify = Freescale802154M.MlmeIndicationBeaconNotify;
	MlmeIndicationCommStatus = Freescale802154M.MlmeIndicationCommStatus;
	MlmeIndicationDisassociate = Freescale802154M.MlmeIndicationDisassociate;
	MlmeRequestConfirmDisassociate = Freescale802154M.MlmeRequestConfirmDisassociate;
	MlmeRequestConfirmGet = Freescale802154M.MlmeRequestConfirmGet;
	MlmeIndicationGts = Freescale802154M.MlmeIndicationGts;
	MlmeRequestConfirmGts = Freescale802154M.MlmeRequestConfirmGts;
	MlmeIndicationResponseOrphan = Freescale802154M.MlmeIndicationResponseOrphan;
	MlmeRequestConfirmPoll = Freescale802154M.MlmeRequestConfirmPoll;
	MlmeRequestConfirmReset = Freescale802154M.MlmeRequestConfirmReset;
	MlmeRequestConfirmRxEnable = Freescale802154M.MlmeRequestConfirmRxEnable;
	MlmeRequestConfirmScan = Freescale802154M.MlmeRequestConfirmScan;
	MlmeRequestConfirmSet = Freescale802154M.MlmeRequestConfirmSet;
	MlmeRequestConfirmStart = Freescale802154M.MlmeRequestConfirmStart;
	MlmeIndicationSyncLoss = Freescale802154M.MlmeIndicationSyncLoss;
	MlmeRequestSync = Freescale802154M.MlmeRequestSync;
	
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
	
	// Wire the buffer manager
	McpsDataIndicationM.BufferMng -> FreescaleBufferMngM.BufferMng;
	McpsDataRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	McpsPurgeRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	           
	MlmeAssociateIndicationResponseM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeAssociateRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeBeaconNotifyIndicationM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeCommStatusIndicationM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeDisassociateRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeDisassociateIndicationM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeGetRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeGtsRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeGtsIndicationM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeOrphanIndicationResponseM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmePollRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeResetRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeRxEnableRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeScanRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeSetRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeStartRequestConfirmM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeSyncRequestM.BufferMng -> FreescaleBufferMngM.BufferMng;
	MlmeSyncLossIndicationM.BufferMng -> FreescaleBufferMngM.BufferMng;
	
	PibAttributeM.BufferMng -> FreescaleBufferMngM.BufferMng;
	SduM.BufferMng -> FreescaleBufferMngM.BufferMng;
	AddressM.BufferMng -> FreescaleBufferMngM.BufferMng;
}
