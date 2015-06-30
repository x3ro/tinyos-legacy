/*
 * Copyright (c) 2006 Intel Corporation
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
 *     * Neither the name of the Intel Corporation nor the names of its
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
 *          July 2006
 */

configuration TestDMA_SD {
}
implementation {
  components 
    Main, 
    TestDMA_SD_M, 
    DMA_M, 
    SD_M,
    SDC,
    MMA7260_AccelM,
    TimerC, 
    LedsC, 	
    //    NTPClientM,
    TimeM,
    IPCLIENT as IPClientC,
    TelnetM,
    ParamViewM;

  Main.StdControl->TestDMA_SD_M;
  Main.StdControl->TimerC;
  Main.StdControl->TimeM;

  /* have to fix compile time channel limitation */
  TestDMA_SD_M.DMA0         -> DMA_M.DMA[0];
  TestDMA_SD_M.DMA1         -> DMA_M.DMA[1];
  TestDMA_SD_M.DMA2         -> DMA_M.DMA[2];
  TestDMA_SD_M.Leds         -> LedsC;
  TestDMA_SD_M.yTimer       -> TimerC.Timer[unique("Timer")];
  TestDMA_SD_M.Time         -> TimeM;
 
  TestDMA_SD_M.SDStdControl      -> SDC;
  TestDMA_SD_M.SD                -> SD_M;

  TestDMA_SD_M.AccelStdControl   -> MMA7260_AccelM;
  TestDMA_SD_M.Accel             -> MMA7260_AccelM;

  /* telnet stuff */
  TestDMA_SD_M.IPStdControl  -> IPClientC;
  TestDMA_SD_M.UIP           -> IPClientC;
  TestDMA_SD_M.Client        -> IPClientC;
  TestDMA_SD_M.TCPServer      -> IPClientC.TCPServer[unique("TCPServer")];

  TestDMA_SD_M.TelnetRun         -> TelnetM.Telnet[unique("Telnet")];

  TestDMA_SD_M.PVStdControl      -> ParamViewM;
  TestDMA_SD_M.TelnetStdControl  -> TelnetM;

  TimeM.LocalTime              -> TimerC;
  TimeM.Timer                  -> TimerC.Timer[unique("Timer")];
  TestDMA_SD_M.LocalTime       -> TimerC;

  TelnetM.TCPServer            -> IPClientC.TCPServer[unique("TCPServer")];

  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> TestDMA_SD_M.ParamView;
  /* end telnet stuff */
}
