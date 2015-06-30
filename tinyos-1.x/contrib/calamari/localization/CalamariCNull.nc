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

configuration CalamariCNull
{
  provides interface StdControl;
}
implementation
{
	components 
		CalamariMNull
		, AnchorHoodC
		, RangingHoodC
		, SystemGenericCommC as GenericComm 
		, LocalizationByMultilaterationC
		, MostConfidentMultihopAnchorsC //@@ NEWLY ADDED
		, RangingC
		, RangingReflC
		, DistanceReflC
		, LocationReflC
	        , HopCountReflC 
		, LocationAttrC
		, RoutingC
  	        , CorrectionC
		, LedsC
		, TimerC
		, RandomLFSR
//		, LocalizationControlC
		, DiagMsgC
		, MsgBuffersC
		, CalamariReportAnchorsCmdC
		, CalamariReportRangingCmdC
		, CalamariStopCmdC
		, CalamariStartCmdC
	        , CalamariResumeCmdC		
	        , CalamariRangingCmdC
	        , CalamariResetRangingCmdC		
	        , CalamariShortestPathCmdC
	        , CalamariResetShortestPathCmdC		
		, CalamariLocalizationCmdC
	        , CalamariResetLocalizationCmdC		
		, CalamariCorrectionCmdC
	        , CalamariResetCorrectionCmdC		
//		, PositionStore
		, ReceiverC
		, MonitorC
		;
	
	
	StdControl = CalamariMNull;
	StdControl = AnchorHoodC;
	StdControl = LocalizationByMultilaterationC;
	StdControl = MostConfidentMultihopAnchorsC;
	StdControl = RangingC;
	StdControl = MonitorC;

	CalamariMNull.LocationRefl->LocationReflC;
	CalamariMNull.DistanceRefl->DistanceReflC;
	CalamariMNull.RangingRefl->RangingReflC;
	CalamariMNull.HopCountRefl->HopCountReflC;
	
	CalamariMNull.AnchorHood->AnchorHoodC;
	CalamariMNull.RangingHood->RangingHoodC;
	
	CalamariMNull.AnchorHoodControl->AnchorHoodC.StdControl;
	CalamariMNull.RangingHoodControl->RangingHoodC.StdControl;
	CalamariMNull.LocalizationStdControl->LocalizationByMultilaterationC.StdControl;
	CalamariMNull.Leds->LedsC;
	CalamariMNull.Timer->TimerC.Timer[unique("Timer")];
	CalamariMNull.Localization->LocalizationByMultilaterationC;
	CalamariMNull.Correction->CorrectionC;
	CalamariMNull.Random -> RandomLFSR;
	CalamariMNull.AnchorInfoPropagation -> RangingReflC.AnchorInfoPropagation;
	CalamariMNull.AnchorInfoPropagation -> MostConfidentMultihopAnchorsC.AnchorInfoPropagation;
	CalamariMNull.DiagMsg -> DiagMsgC;

	CalamariMNull.LocationAttr->LocationAttrC;

	
	CalamariMNull.CalamariReportAnchorsCmd -> CalamariReportAnchorsCmdC;
	CalamariMNull.CalamariReportRangingCmd -> CalamariReportRangingCmdC;
	CalamariMNull.CalamariStopCmd -> CalamariStopCmdC;
	CalamariMNull.CalamariStartCmd -> CalamariStartCmdC;
	CalamariMNull.CalamariResumeCmd -> CalamariResumeCmdC;
	CalamariMNull.CalamariRangingCmd -> CalamariRangingCmdC;
	CalamariMNull.CalamariResetRangingCmd -> CalamariResetRangingCmdC;
	CalamariMNull.CalamariShortestPathCmd -> CalamariShortestPathCmdC;
	CalamariMNull.CalamariResetShortestPathCmd -> CalamariResetShortestPathCmdC;
	CalamariMNull.CalamariLocalizationCmd -> CalamariLocalizationCmdC;
	CalamariMNull.CalamariResetLocalizationCmd -> CalamariResetLocalizationCmdC;
	CalamariMNull.CalamariCorrectionCmd -> CalamariCorrectionCmdC;
	CalamariMNull.CalamariResetCorrectionCmd -> CalamariResetCorrectionCmdC;

	
	//CalamariMNull.LocalizationControl -> LocalizationControlC.LocalizationControl;
	CalamariMNull.RangingControl -> RangingReflC;
	
	CalamariMNull.MsgBuffers -> MsgBuffersC;

	CalamariMNull.AnchorReportSend -> GenericComm.SendMsg[AM_ANCHORREPORTMSG];
	CalamariMNull.RangingReportSend -> GenericComm.SendMsg[AM_RANGINGREPORTMSG];

//	LocalizationByMultilaterationC.EvaderDemoStore -> PositionStore.EvaderDemoStore;
	
}
