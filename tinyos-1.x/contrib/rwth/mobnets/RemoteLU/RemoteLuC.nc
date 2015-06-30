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
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
includes UQLCmdMsg;
includes UllaQuery;

configuration RemoteLuC {

}

implementation {
  components
      Main
    , RemoteLuM
    , UllaCoreC
    , QueryProcessorC
    , CommandProcessorC
    , TimerC
#ifdef MICA2_PLATFORM
    , LogicalTime
#endif
    , LedsC
    , GenericComm
    ;

  Main.StdControl -> RemoteLuM;
  Main.StdControl -> UllaCoreC;
  Main.StdControl -> TimerC;

  //RemoteLuM.UqpIf -> QueryProcessorC.UqpIf;  // local user
	//RemoteLuM.UcpIf -> CommandProcessorC.UcpIf;
	RemoteLuM.UqpIf -> UllaCoreC.UqpIf[REMOTE_LU];  // local user
  RemoteLuM.UcpIf -> UllaCoreC.UcpIf;  // local user
  RemoteLuM.Send -> UllaCoreC;
  RemoteLuM.Receive -> UllaCoreC;
  RemoteLuM.Leds -> LedsC;
  
  RemoteLuM.Timer -> TimerC.Timer[unique("Timer")];
  
#ifndef NO_LINKUSER
  #ifdef TELOS_PLATFORM
  RemoteLuM.LocalTime -> TimerC;
  #endif
  #ifdef MICA2_PLATFORM
  RemoteLuM.Time -> LogicalTime;
  RemoteLuM.TimeControl -> LogicalTime;
  RemoteLuM.TimeUtil -> LogicalTime;
  #endif
#endif
  
  RemoteLuM.CommStdControl -> GenericComm;
  RemoteLuM.SendMsg -> GenericComm.SendMsg[AM_QUERY];
  
#ifdef TEST_LINK_USER
  RemoteLuM.User1 -> TestLinkUserM.User1;
  RemoteLuM.User2 -> TestLinkUserM.User2;
#endif

}
