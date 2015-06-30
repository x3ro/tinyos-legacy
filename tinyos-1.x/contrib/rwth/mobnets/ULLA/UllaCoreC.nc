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
 * UllaCore - This application is the core of the ULLA architecture
 * which consists of Ulla Query Processing (UQP), Ulla Command
 * Processing (UCP), Ulla Event Processing (UEP), and Link Layer
 * Adapter (LLA).
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/


includes UQLCmdMsg;
includes UllaQuery;

configuration UllaCoreC {
   provides {
    interface StdControl;
    
    interface UqpIf[uint8_t id];
    interface UcpIf;
    
    interface CommandInf;
    interface InfoRequest;
    interface Receive[uint8_t id];  // general interface in /tos/interface
    interface Send[uint8_t id];     // general interface in /tos/interface
		interface ReceivePacket[uint8_t id];
  }
}

implementation {

  components
      Main
    , QueryProcessorC
    , QueryAssemblerC
		, QauAdapterC
    , CommandProcessorC
    , EventProcessorC
		, ULLAStorageC
    , SensorMeterC
    , UllaCoreM
    , LLAC
		, TimerC
    , LedsC
    ;

  Main.StdControl -> UllaCoreM;
  Main.StdControl -> QueryProcessorC;
  Main.StdControl -> CommandProcessorC;
  Main.StdControl -> EventProcessorC;
  Main.StdControl -> LLAC;
  Main.StdControl -> SensorMeterC;
  Main.StdControl -> QueryAssemblerC;
	Main.StdControl -> QauAdapterC;
	Main.StdControl -> TimerC;
	Main.StdControl -> ULLAStorageC;

  StdControl  = UllaCoreM;
  CommandInf  = CommandProcessorC;
  InfoRequest = UllaCoreM;
  Receive     = UllaCoreM;
  Send        = UllaCoreM;
  
  UqpIf = QueryProcessorC; // LOCAL_LU
  UcpIf = CommandProcessorC;
	
	UllaCoreM.ProcessNotification -> QauAdapterC.ProcessCmd[1];
  UllaCoreM.ProcessQuery -> QauAdapterC.ProcessCmd[2];
  UllaCoreM.ProcessCommand -> CommandProcessorC;
  
  UllaCoreM.ProcessResultGetInfo -> QueryProcessorC;
  UllaCoreM.ProcessScanLinks -> CommandProcessorC;
	
	UllaCoreM.StorageIf -> ULLAStorageC;
  
  UllaCoreM.LLAControl -> LLAC;
  UllaCoreM.SendInf -> LLAC;
	ReceivePacket = UllaCoreM;
  
  UllaCoreM.Leds -> LedsC;
	
	UllaCoreM.BeaconTimer -> TimerC.Timer[unique("Timer")];
}
 
