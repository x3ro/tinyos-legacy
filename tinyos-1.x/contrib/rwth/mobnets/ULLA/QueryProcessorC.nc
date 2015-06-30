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
 * Ulla Query Processing - implements the direct interface with the link
 * users and also handles all the requests from them. The UQP therefore
 * processes requests for information or notification regarding one or
 * more link attributes.
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;
includes AMTypes;


configuration QueryProcessorC {
  provides {
    interface StdControl;
    //interface ProcessCmd as ProcessQuery;
    interface UqpIf[uint8_t id];
    interface ProcessData as ProcessResultGetInfo;
  }
}
implementation {
  components
     // Main
      QueryProcessorM
    , QueryM
		, NotificationTimerC
		, UllaCoreC
    
    , ConditionM
    //, ExprEvalM
    , LLAC
		, UllaLinkProviderC
    , SensorMeterC
    
    //, HistoricalStorageC
    , ULLAStorageC
    
    //, TinyAlloc
    //, UllaAllocM
    
  //, GenericComm as Comm
    , LedsC
    ;

  //Main.StdControl -> QueryProcessorM;
  StdControl = QueryProcessorM;
  UqpIf = QueryProcessorM;
  
  ProcessResultGetInfo = QueryProcessorM;
  
  
  QueryProcessorM.Query -> QueryM;

  QueryProcessorM.Condition -> ConditionM;
  //ConditionM.ExprEval -> ExprEvalM;
	
	QueryProcessorM.RNTimer -> NotificationTimerC;
	QueryProcessorM.RNControl -> NotificationTimerC;

  QueryProcessorM.Leds -> LedsC;
  
  /*
  QueryProcessorM.ReadFromStorage -> HistoricalStorageC;
  QueryProcessorM.WriteToStorage  -> HistoricalStorageC;
  */
  
  QueryProcessorM.StorageIf -> ULLAStorageC;
	//QueryProcessorM.StorageControl -> ULLAStorageC;
  /////QueryProcessorM.RequestUpdate -> LLAC;    // will be replaced with LinkProviderIf
  QueryProcessorM.LinkProviderIf -> LLAC;
  //QueryProcessorM.Receive -> LLAC.ReceiveInf[AM_RESULT_GETINFO_MESSAGE];
  QueryProcessorM.UllaLinkProviderIf -> UllaLinkProviderC;
	// FIXME 01.08.06
	// Fix fan-out problem (ULLACore+UQP share Send interface)
	////QueryProcessorM.Send -> LLAC.SendInf;
	QueryProcessorM.SendResult -> UllaCoreC.Send[AM_QUERY_REPLY];
	QueryProcessorM.SendTest -> UllaCoreC.Send[99];
	QueryProcessorM.SendFixedAttrMsg -> UllaCoreC.Send[AM_FIXEDATTR];

  ///QueryProcessorM.RequestUpdate -> SensorMeterC;
  QueryProcessorM.SensorIf -> SensorMeterC.LinkProviderIf;

  //ProcessQuery = QueryProcessorM;
  

  
}
