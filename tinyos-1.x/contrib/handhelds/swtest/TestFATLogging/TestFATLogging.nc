/*
 * Copyright (c) 2009, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Steve Ayer
 *          May, 2009
 */

includes FatFs;
//includes SD;

configuration TestFATLogging {
}
implementation {
  components 
    Main, 
    TestFATLoggingM, 
    FatFsM,
    DMA_M, 
    diskIOC,
    MMA7260_AccelM,
    TimerC, 
    LedsC, 	
    TimeM,
    NTPClientM,
    IPCLIENT as IPClientC,
    TelnetM,
    ParamViewM;

  Main.StdControl->TestFATLoggingM;
  Main.StdControl->TimerC;
  Main.StdControl->TimeM;

  /* have to fix compile time channel limitation */
  TestFATLoggingM.DMA0         -> DMA_M.DMA[0];
  TestFATLoggingM.Leds         -> LedsC;
  TestFATLoggingM.sampleTimer       -> TimerC.Timer[unique("Timer")];
 
  TestFATLoggingM.AccelStdControl   -> MMA7260_AccelM;
  TestFATLoggingM.Accel             -> MMA7260_AccelM;

  TestFATLoggingM.FatFs     -> FatFsM;
  FatFsM.diskIO             -> diskIOC;
  FatFsM.diskIOStdControl   -> diskIOC;

  TestFATLoggingM.Time          -> TimeM;
  TestFATLoggingM.NTPClient     -> NTPClientM;

  NTPClientM.UDPClient       -> IPClientC.UDPClient[unique("UDPClient")];
  NTPClientM.Timer           -> TimerC.Timer[unique("Timer")];
  NTPClientM.Client          -> IPClientC;

  TestFATLoggingM.IPStdControl  -> IPClientC;
  TestFATLoggingM.UIP           -> IPClientC;
  TestFATLoggingM.Client        -> IPClientC;

  TestFATLoggingM.TelnetRun         -> TelnetM.Telnet[unique("Telnet")];

  //  TestFATLoggingM.PVStdControl      -> ParamViewM;
  TestFATLoggingM.TelnetStdControl  -> TelnetM;

  TimeM.Timer                -> TimerC.Timer[unique("Timer")];
  TimeM.NTPClient            -> NTPClientM;
  TimeM.LocalTime            -> TimerC;

  TelnetM.TCPServer            -> IPClientC.TCPServer[unique("TCPServer")];

  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> IPClientC.ParamView;
}
