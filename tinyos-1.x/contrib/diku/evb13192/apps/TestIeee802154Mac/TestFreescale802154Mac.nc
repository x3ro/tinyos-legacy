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

includes macConstants;

configuration TestFreescale802154Mac
{

}

implementation
{
	components Main,
	           TestIeee802154MacM,
	           Freescale802154C,
	           ConsoleDebugM,
	           ConsoleC;

	ConsoleDebugM.ConsoleOut -> ConsoleC.ConsoleOut;
	Freescale802154C.Debug -> ConsoleDebugM.Debug;
	TestIeee802154MacM.Debug -> ConsoleDebugM.Debug;
	
	Main.StdControl -> Freescale802154C.StdControl;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> TestIeee802154MacM.StdControl;
 	
	TestIeee802154MacM.IeeePibAttribute -> Freescale802154C;
	TestIeee802154MacM.IeeePanDescriptor -> Freescale802154C;
	TestIeee802154MacM.IeeeSdu -> Freescale802154C;
	TestIeee802154MacM.IeeeAddress -> Freescale802154C;
	
	// MCPS
	TestIeee802154MacM.McpsIndicationData -> Freescale802154C.McpsIndicationData;
	TestIeee802154MacM.McpsRequestConfirmData -> Freescale802154C.McpsRequestConfirmData;
	TestIeee802154MacM.McpsRequestConfirmPurge -> Freescale802154C.McpsRequestConfirmPurge;
	
	TestIeee802154MacM.McpsDataIndication -> Freescale802154C.McpsDataIndication;
	TestIeee802154MacM.McpsDataRequestConfirm -> Freescale802154C.McpsDataRequestConfirm;
	TestIeee802154MacM.McpsPurgeRequestConfirm -> Freescale802154C.McpsPurgeRequestConfirm;
	
	// MLME
	TestIeee802154MacM.MlmeIndicationResponseAssociate -> Freescale802154C.MlmeIndicationResponseAssociate;
	TestIeee802154MacM.MlmeRequestConfirmAssociate -> Freescale802154C.MlmeRequestConfirmAssociate;
	TestIeee802154MacM.MlmeIndicationDisassociate -> Freescale802154C.MlmeIndicationDisassociate;
	TestIeee802154MacM.MlmeRequestConfirmDisassociate -> Freescale802154C.MlmeRequestConfirmDisassociate;
	TestIeee802154MacM.MlmeRequestConfirmGet -> Freescale802154C.MlmeRequestConfirmGet;
	TestIeee802154MacM.MlmeIndicationGts -> Freescale802154C.MlmeIndicationGts;
	TestIeee802154MacM.MlmeRequestConfirmGts -> Freescale802154C.MlmeRequestConfirmGts;
	TestIeee802154MacM.MlmeRequestConfirmScan -> Freescale802154C.MlmeRequestConfirmScan;
	TestIeee802154MacM.MlmeRequestConfirmSet -> Freescale802154C.MlmeRequestConfirmSet;
	TestIeee802154MacM.MlmeRequestConfirmStart -> Freescale802154C.MlmeRequestConfirmStart;
	TestIeee802154MacM.MlmeIndicationSyncLoss -> Freescale802154C.MlmeIndicationSyncLoss;	
	TestIeee802154MacM.MlmeRequestConfirmRxEnable -> Freescale802154C.MlmeRequestConfirmRxEnable;
	TestIeee802154MacM.MlmeRequestConfirmPoll -> Freescale802154C.MlmeRequestConfirmPoll;
	TestIeee802154MacM.MlmeRequestSync -> Freescale802154C.MlmeRequestSync;
	TestIeee802154MacM.MlmeIndicationCommStatus -> Freescale802154C.MlmeIndicationCommStatus;
	TestIeee802154MacM.MlmeIndicationBeaconNotify -> Freescale802154C.MlmeIndicationBeaconNotify;
	TestIeee802154MacM.MlmeRequestConfirmReset -> Freescale802154C.MlmeRequestConfirmReset;
	TestIeee802154MacM.MlmeIndicationResponseOrphan -> Freescale802154C.MlmeIndicationResponseOrphan;

	TestIeee802154MacM.MlmeAssociateIndicationResponse -> Freescale802154C.MlmeAssociateIndicationResponse;
	TestIeee802154MacM.MlmeAssociateRequestConfirm -> Freescale802154C.MlmeAssociateRequestConfirm;
	TestIeee802154MacM.MlmeDisassociateIndication -> Freescale802154C.MlmeDisassociateIndication;
	TestIeee802154MacM.MlmeDisassociateRequestConfirm -> Freescale802154C.MlmeDisassociateRequestConfirm;
	TestIeee802154MacM.MlmeGetRequestConfirm -> Freescale802154C.MlmeGetRequestConfirm;
	TestIeee802154MacM.MlmeGtsIndication -> Freescale802154C.MlmeGtsIndication;
	TestIeee802154MacM.MlmeGtsRequestConfirm -> Freescale802154C.MlmeGtsRequestConfirm;
	TestIeee802154MacM.MlmeScanRequestConfirm -> Freescale802154C.MlmeScanRequestConfirm;	
	TestIeee802154MacM.MlmeSetRequestConfirm -> Freescale802154C.MlmeSetRequestConfirm;
	TestIeee802154MacM.MlmeStartRequestConfirm -> Freescale802154C.MlmeStartRequestConfirm;
	TestIeee802154MacM.MlmeSyncLossIndication -> Freescale802154C.MlmeSyncLossIndication;
	TestIeee802154MacM.MlmeRxEnableRequestConfirm -> Freescale802154C.MlmeRxEnableRequestConfirm;
	TestIeee802154MacM.MlmePollRequestConfirm -> Freescale802154C.MlmePollRequestConfirm;
	TestIeee802154MacM.MlmeSyncRequest -> Freescale802154C.MlmeSyncRequest;
	TestIeee802154MacM.MlmeCommStatusIndication -> Freescale802154C.MlmeCommStatusIndication;
	TestIeee802154MacM.MlmeBeaconNotifyIndication -> Freescale802154C.MlmeBeaconNotifyIndication;
	TestIeee802154MacM.MlmeResetRequestConfirm -> Freescale802154C.MlmeResetRequestConfirm;
	TestIeee802154MacM.MlmeOrphanIndicationResponse -> Freescale802154C.MlmeOrphanIndicationResponse;

	TestIeee802154MacM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestIeee802154MacM.ConsoleIn -> ConsoleC.ConsoleIn;
}
