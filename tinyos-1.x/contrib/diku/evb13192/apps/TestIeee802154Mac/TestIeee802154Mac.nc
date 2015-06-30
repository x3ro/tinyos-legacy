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
includes mcuToRadioPorts;

configuration TestIeee802154Mac
{

}

implementation
{
	components Main,
	           TestIeee802154MacM,
	           mc13192PhyDriverC,
	           HPLSPIM as mcuSPI,
	           Ieee802154MacC,
	           HPLTimer2M,
	           AsyncAlarmC,
	           RandomLFSR,
	           SimpleBufferManM,
	           FIFOQueueM,
	           ConsoleDebugM,
	           ConsoleC;

	Main.StdControl -> mcuSPI.StdControl;
	Main.StdControl -> HPLTimer2M.StdControl;
	Main.StdControl -> mc13192PhyDriverC.StdControl;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> AsyncAlarmC.StdControl;
	Main.StdControl -> SimpleBufferManM.StdControl;
	Main.StdControl -> Ieee802154MacC.StdControl;
	Main.StdControl -> TestIeee802154MacM.StdControl;

	// Connect debug.
	ConsoleDebugM.ConsoleOut -> ConsoleC.ConsoleOut;
	Ieee802154MacC.Debug -> ConsoleDebugM.Debug;
	mc13192PhyDriverC.Debug -> ConsoleDebugM.Debug;
	FIFOQueueM.Debug -> ConsoleDebugM.Debug;
	SimpleBufferManM.Debug -> ConsoleDebugM.Debug;
	AsyncAlarmC.Debug -> ConsoleDebugM.Debug;
	TestIeee802154MacM.Debug -> ConsoleDebugM.Debug;
	
	// Connect Phy.
	mc13192PhyDriverC.SPI -> mcuSPI.SPI;
	mc13192PhyDriverC.MCUTime -> AsyncAlarmC.LocalTime;

	Ieee802154MacC.PhyReceive -> mc13192PhyDriverC.PhyReceive;
	Ieee802154MacC.PhyTransmit -> mc13192PhyDriverC.PhyTransmit;
	Ieee802154MacC.PhyEnergyDetect -> mc13192PhyDriverC.PhyEnergyDetect;
	Ieee802154MacC.PhyAttributes -> mc13192PhyDriverC.PhyAttributes;
	Ieee802154MacC.PhyControl -> mc13192PhyDriverC.PhyControl;
	Ieee802154MacC.PhyReset -> mc13192PhyDriverC.PhyReset;

	// Wire alarms
	Ieee802154MacC.ScanAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.EdAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.TrackAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.TrackerCfpAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.BeaconAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.GeneratorCfpAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.RxEnableAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.TimeoutAlarm1 -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.TimeoutAlarm2 -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.CfpAlarm -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	Ieee802154MacC.CfpAlarm2 -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	
	Ieee802154MacC.LocalTime -> AsyncAlarmC.LocalTime;
 	
 	// Wire random generator
 	Ieee802154MacC.Random -> RandomLFSR.Random;
 	
 	// Wire buffer manager and queue
 	SimpleBufferManM.Queue -> FIFOQueueM.FIFOQueue;
 	Ieee802154MacC.FIFOQueue -> FIFOQueueM.FIFOQueue;
 	Ieee802154MacC.BufferMng -> SimpleBufferManM.BufferMng;
 //	TestIeee802154MacM.BufferManDebug -> SimpleBufferManM.BufferManDebug;
 	
 	
 	// Wire other.
	TestIeee802154MacM.IeeePibAttribute -> Ieee802154MacC;
	TestIeee802154MacM.IeeePanDescriptor -> Ieee802154MacC;
	TestIeee802154MacM.IeeeSdu -> Ieee802154MacC;
	TestIeee802154MacM.IeeeAddress -> Ieee802154MacC;
	
	// MCPS
	TestIeee802154MacM.McpsIndicationData -> Ieee802154MacC.McpsIndicationData;
	TestIeee802154MacM.McpsRequestConfirmData -> Ieee802154MacC.McpsRequestConfirmData;
	TestIeee802154MacM.McpsRequestConfirmPurge -> Ieee802154MacC.McpsRequestConfirmPurge;
	
	TestIeee802154MacM.McpsDataIndication -> Ieee802154MacC.McpsDataIndication;
	TestIeee802154MacM.McpsDataRequestConfirm -> Ieee802154MacC.McpsDataRequestConfirm;
	TestIeee802154MacM.McpsPurgeRequestConfirm -> Ieee802154MacC.McpsPurgeRequestConfirm;
	
	// MLME
	TestIeee802154MacM.MlmeIndicationResponseAssociate -> Ieee802154MacC.MlmeIndicationResponseAssociate;
	TestIeee802154MacM.MlmeRequestConfirmAssociate -> Ieee802154MacC.MlmeRequestConfirmAssociate;
	TestIeee802154MacM.MlmeIndicationDisassociate -> Ieee802154MacC.MlmeIndicationDisassociate;
	TestIeee802154MacM.MlmeRequestConfirmDisassociate -> Ieee802154MacC.MlmeRequestConfirmDisassociate;
	TestIeee802154MacM.MlmeRequestConfirmGet -> Ieee802154MacC.MlmeRequestConfirmGet;
	TestIeee802154MacM.MlmeIndicationGts -> Ieee802154MacC.MlmeIndicationGts;
	TestIeee802154MacM.MlmeRequestConfirmGts -> Ieee802154MacC.MlmeRequestConfirmGts;
	TestIeee802154MacM.MlmeRequestConfirmScan -> Ieee802154MacC.MlmeRequestConfirmScan;
	TestIeee802154MacM.MlmeRequestConfirmSet -> Ieee802154MacC.MlmeRequestConfirmSet;
	TestIeee802154MacM.MlmeRequestConfirmStart -> Ieee802154MacC.MlmeRequestConfirmStart;
	TestIeee802154MacM.MlmeIndicationSyncLoss -> Ieee802154MacC.MlmeIndicationSyncLoss;
	TestIeee802154MacM.MlmeRequestConfirmRxEnable -> Ieee802154MacC.MlmeRequestConfirmRxEnable;
	TestIeee802154MacM.MlmeRequestConfirmPoll -> Ieee802154MacC.MlmeRequestConfirmPoll;
	TestIeee802154MacM.MlmeRequestSync -> Ieee802154MacC.MlmeRequestSync;
	TestIeee802154MacM.MlmeIndicationBeaconNotify -> Ieee802154MacC.MlmeIndicationBeaconNotify;
	TestIeee802154MacM.MlmeRequestConfirmReset -> Ieee802154MacC.MlmeRequestConfirmReset;
	TestIeee802154MacM.MlmeIndicationCommStatus -> Ieee802154MacC.MlmeIndicationCommStatus;
	TestIeee802154MacM.MlmeIndicationResponseOrphan -> Ieee802154MacC.MlmeIndicationResponseOrphan;
	
	TestIeee802154MacM.MlmeAssociateIndicationResponse -> Ieee802154MacC.MlmeAssociateIndicationResponse;
	TestIeee802154MacM.MlmeAssociateRequestConfirm -> Ieee802154MacC.MlmeAssociateRequestConfirm;
	TestIeee802154MacM.MlmeDisassociateIndication -> Ieee802154MacC.MlmeDisassociateIndication;
	TestIeee802154MacM.MlmeDisassociateRequestConfirm -> Ieee802154MacC.MlmeDisassociateRequestConfirm;
	TestIeee802154MacM.MlmeGetRequestConfirm -> Ieee802154MacC.MlmeGetRequestConfirm;
	TestIeee802154MacM.MlmeGtsIndication -> Ieee802154MacC.MlmeGtsIndication;
	TestIeee802154MacM.MlmeGtsRequestConfirm -> Ieee802154MacC.MlmeGtsRequestConfirm;
	TestIeee802154MacM.MlmeScanRequestConfirm -> Ieee802154MacC.MlmeScanRequestConfirm;	
	TestIeee802154MacM.MlmeSetRequestConfirm -> Ieee802154MacC.MlmeSetRequestConfirm;
	TestIeee802154MacM.MlmeStartRequestConfirm -> Ieee802154MacC.MlmeStartRequestConfirm;
	TestIeee802154MacM.MlmeSyncLossIndication -> Ieee802154MacC.MlmeSyncLossIndication;
	TestIeee802154MacM.MlmeRxEnableRequestConfirm -> Ieee802154MacC.MlmeRxEnableRequestConfirm;
	TestIeee802154MacM.MlmePollRequestConfirm -> Ieee802154MacC.MlmePollRequestConfirm;
	TestIeee802154MacM.MlmeSyncRequest -> Ieee802154MacC.MlmeSyncRequest;
	TestIeee802154MacM.MlmeBeaconNotifyIndication -> Ieee802154MacC.MlmeBeaconNotifyIndication;
	TestIeee802154MacM.MlmeResetRequestConfirm -> Ieee802154MacC.MlmeResetRequestConfirm;
	TestIeee802154MacM.MlmeCommStatusIndication -> Ieee802154MacC.MlmeCommStatusIndication;
	TestIeee802154MacM.MlmeOrphanIndicationResponse -> Ieee802154MacC.MlmeOrphanIndicationResponse;

	TestIeee802154MacM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestIeee802154MacM.ConsoleIn -> ConsoleC.ConsoleIn;
}
