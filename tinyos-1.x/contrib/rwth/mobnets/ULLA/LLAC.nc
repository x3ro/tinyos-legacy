/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
/**
 *
 * WSN Link Layer Adapter - a proxy interface on the existing driver that
 * implements an interface known by the ULLA (methods and queries), enabling
 * the ULLA to forward queries and method calls to the driver through the LLA.
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;
includes UllaQuery;
includes MultiHop;
includes AMTypes;

configuration LLAC {
  provides {
    //interface ProcessCmd as RequestUpdate;
    //interface RequestUpdate;
    interface LinkProviderIf[uint8_t id]; // replacement of RequestUpdate
    interface StdControl;
    ///interface CC2420Control;
    interface ProcessCmd as Control;

    // for TransceiverM
    //interface StdControl as TransControl;
    interface Send as SendInf[uint8_t id];
    ///interface Receive as ReceiveInf[uint8_t id];
		
  }
	
}
implementation {

  components 
      Main
    , LLAM
		, UllaCoreC
    , EventProcessorC
#ifdef ULLA_STORAGE
    , StorageC
#endif
    , TimerC
    , LedsC
#ifndef MAKE_PC_PLATFORM
    , CC2420ControlM
		, CC2420RadioC
#endif

#ifdef OSCOPE
    , OscopeC
#endif
    , GenericComm as Comm
    , TransceiverM
		, ULLAStorageC
    //, SensorMeterM
    //, GenericCommPromiscuous as Comm
    , RandomLFSR
		//, LQIMultiHopRouter as multihop
    //, QueuedSend
    ;

  Main.StdControl -> LLAM;
  Main.StdControl -> TimerC;
	//Main.StdControl -> multihop;
  //Main.StdControl -> Comm;
  //Main.StdControl -> QueuedSend;

  StdControl = LLAM;

  LLAM.Timer -> TimerC.Timer[unique("Timer")];
  LLAM.Leds -> LedsC;
  TransceiverM.Leds -> LedsC;
  
  //RequestUpdate = LLAM;
  LinkProviderIf = LLAM;

  LLAM.AttributeEvent   -> EventProcessorC.ProcessEvent[0];
  LLAM.LinkEvent        -> EventProcessorC.ProcessEvent[1];
  LLAM.CompleteCmdEvent -> EventProcessorC.ProcessEvent[2];
  
#ifdef ULLA_STORAGE
  LLAM.WriteToStorage  -> StorageC;
#endif
  
  Control = LLAM;
#if defined(TELOS_PLATFORM) || defined(SIM_TELOS_PLATFORM)
  LLAM.CC2420Control -> CC2420ControlM;


#endif

#ifdef OSCOPE
  LLAM.ORFPower -> OscopeC.Oscope[6];
  LLAM.OLQI -> OscopeC.Oscope[7];
  LLAM.ORSSI -> OscopeC.Oscope[8];
#endif

  StdControl  = TransceiverM;

  TransceiverM.LinkEstimation -> LLAM;
  //TransceiverM.CommControl -> Comm;
  TransceiverM.CommStdControl -> Comm;
	TransceiverM.MacControl -> CC2420RadioC;
	
  TransceiverM.GetLinkInfo -> LLAM;  // 2006/03/14
  //TransceiverM.GetSensorInfo -> SensorMeterM;  // 2006/03/14
  
  TransceiverM.Random -> RandomLFSR;

  SendInf    = TransceiverM;
  //ReceiveInf = TransceiverM;
	TransceiverM.ReceivePacket -> UllaCoreC;
	
	LLAM.StorageIf -> ULLAStorageC;
  
  LLAM.SendScanLinks -> TransceiverM.SendInf[AM_SCAN_LINKS];
	LLAM.SendGetInfo -> TransceiverM.SendInf[AM_GETINFO_MESSAGE];
	LLAM.SendProbingMsg -> TransceiverM.SendInf[AM_PROBING];
  /////LLAM.Receive -> TransceiverM.ReceiveInf; //2006/03/07 avoid pan-out
  //LLAM.SendMsg -> Comm.SendMsg[AM_GETINFO_MESSAGE];

	TransceiverM.SendMsg -> Comm;
	TransceiverM.ReceiveMsg -> Comm;

	
}
