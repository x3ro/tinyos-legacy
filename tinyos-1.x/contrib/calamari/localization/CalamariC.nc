/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
	     UC Berkeley
 *
 */

includes MostConfidentMultihopAnchors;
includes Routing;
includes Localization;
includes LocalizationConfig;
includes Config;
includes DiagMsg;
includes ResetMsgs;

configuration CalamariC
{
  provides interface StdControl;
}
implementation
{
	components 
		CalamariM
		, AnchorHoodC
		, RangingHoodC
		, GenericComm 
		, LocalizationByMultilaterationC
		, MostConfidentMultihopAnchorsC //@@ NEWLY ADDED
		, RangingC
		, RangingReflC
		, RangingReflM
		, DistanceReflC
		, LocationReflC
	        , HopCountReflC 
	        , ShortestPathNodeReflC 
	        , RangingMovingWindowReflC 
		, LocationAttrC
		, RoutingC
	        , CorrectionC
		, LedsC
		, TimerC
		, RandomLFSR
//		, LocalizationControlC
		, DiagMsgC
		, MsgBuffersC
		, CalamariRangeOnceCmdC
		, CalamariReportAnchorsCmdC
		, CalamariReportRangingCmdC
		, CalamariReportRangingValuesCmdC
		, CalamariStopCmdC
		, CalamariStartCmdC
	        , CalamariResumeCmdC		
	        , CalamariRangingCmdC
	        , CalamariRangingExchangeCmdC
	        , CalamariResetRangingCmdC		
	        , CalamariShortestPathCmdC
	        , CalamariSendAllAnchorsCmdC
	        , CalamariResetShortestPathCmdC		
		, CalamariLocalizationCmdC
	        , CalamariResetLocalizationCmdC		
		, CalamariCorrectionCmdC
	        , CalamariResetCorrectionCmdC		
	        , CalamariToggleLedCmdC		
	        , CalamariSetRangingCmdC		
//		, PositionStore
	  //		, MonitorC
		;
	
	
	StdControl = CalamariM;
    	StdControl = AnchorHoodC;
    	StdControl = LocalizationByMultilaterationC;
    	StdControl = MostConfidentMultihopAnchorsC;
    	StdControl = RangingC;
  //	StdControl = MonitorC;

	CalamariM.LocationRefl->LocationReflC;
	CalamariM.DistanceRefl->DistanceReflC;
	CalamariM.RangingRefl->RangingReflC;
	CalamariM.HopCountRefl->HopCountReflC;
	CalamariM.ShortestPathNodeRefl->ShortestPathNodeReflC;
	CalamariM.RangingMovingWindowRefl->RangingMovingWindowReflC;
	
	CalamariM.AnchorHood->AnchorHoodC;
	CalamariM.RangingHood->RangingHoodC;
	
	CalamariM.AnchorHoodControl->AnchorHoodC.StdControl;
	CalamariM.RangingHoodControl->RangingHoodC.StdControl;
	CalamariM.LocalizationStdControl->LocalizationByMultilaterationC.StdControl;
	CalamariM.Leds->LedsC;
	CalamariM.Timer->TimerC.Timer[unique("Timer")];
	CalamariM.Localization->LocalizationByMultilaterationC;
  	CalamariM.Correction->CorrectionC;
	CalamariM.Random -> RandomLFSR;
	CalamariM.AnchorInfoPropagation -> MostConfidentMultihopAnchorsC.AnchorInfoPropagation;
	CalamariM.DiagMsg -> DiagMsgC;

	CalamariM.LocationAttr->LocationAttrC;

	
	CalamariM.CalamariRangeOnceCmd -> CalamariRangeOnceCmdC;
	CalamariM.CalamariReportAnchorsCmd -> CalamariReportAnchorsCmdC;
	CalamariM.CalamariReportRangingCmd -> CalamariReportRangingCmdC;
	CalamariM.CalamariReportRangingValuesCmd -> CalamariReportRangingValuesCmdC;
	CalamariM.CalamariStopCmd -> CalamariStopCmdC;
	CalamariM.CalamariStartCmd -> CalamariStartCmdC;
	CalamariM.CalamariResumeCmd -> CalamariResumeCmdC;
	CalamariM.CalamariRangingCmd -> CalamariRangingCmdC;
	CalamariM.CalamariRangingExchangeCmd -> CalamariRangingExchangeCmdC;
	CalamariM.CalamariResetRangingCmd -> CalamariResetRangingCmdC;
	CalamariM.CalamariShortestPathCmd -> CalamariShortestPathCmdC;
	CalamariM.CalamariSendAllAnchorsCmd -> CalamariSendAllAnchorsCmdC;
	CalamariM.CalamariResetShortestPathCmd -> CalamariResetShortestPathCmdC;
	CalamariM.CalamariLocalizationCmd -> CalamariLocalizationCmdC;
	CalamariM.CalamariResetLocalizationCmd -> CalamariResetLocalizationCmdC;
	CalamariM.CalamariCorrectionCmd -> CalamariCorrectionCmdC;
	CalamariM.CalamariResetCorrectionCmd -> CalamariResetCorrectionCmdC;
	CalamariM.CalamariToggleLedCmd -> CalamariToggleLedCmdC;
	CalamariM.CalamariSetRangingCmd -> CalamariSetRangingCmdC;
        CalamariM.setRanging -> RangingReflM.setRanging;
	
	//CalamariM.LocalizationControl -> LocalizationControlC.LocalizationControl;
	CalamariM.RangingControl -> RangingReflC;
	
	CalamariM.MsgBuffers -> MsgBuffersC;

	CalamariM.AnchorReportSend -> GenericComm.SendMsg[AM_ANCHORREPORTMSG];
	CalamariM.RangingReportSend -> GenericComm.SendMsg[AM_RANGINGREPORTMSG];
	CalamariM.RangingValuesSend -> GenericComm.SendMsg[AM_RANGINGREPORTVALUESMSG];

//	LocalizationByMultilaterationC.EvaderDemoStore -> PositionStore.EvaderDemoStore;
	
}
