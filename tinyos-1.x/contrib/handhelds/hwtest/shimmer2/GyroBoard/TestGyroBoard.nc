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
 *  Author:  Steve Ayer
 *           August 2009
 */

configuration TestGyroBoard { 
}
implementation {
  components 
    Main, 
    TestGyroBoardM, 
    DMA_M, 
    GyroBoardC,
    TimerC, 
    LedsC, 	
    IPCLIENT as IPClientC,
    TelnetM,
    ParamViewM;

  Main.StdControl->TestGyroBoardM;
  Main.StdControl->TimerC;

  /* have to fix compile time channel limitation */
  TestGyroBoardM.DMA0         -> DMA_M.DMA[0];
  TestGyroBoardM.Leds         -> LedsC;
  TestGyroBoardM.sampleTimer   -> TimerC.Timer[unique("Timer")];
 
  TestGyroBoardM.GyroBoard               -> GyroBoardC;
  TestGyroBoardM.GyroBoardStdControl     -> GyroBoardC;

  TestGyroBoardM.IPStdControl  -> IPClientC;
  TestGyroBoardM.UIP           -> IPClientC;
  TestGyroBoardM.Client        -> IPClientC;
  TestGyroBoardM.UDPClient     -> IPClientC.UDPClient[unique("UDPClient")];

  TestGyroBoardM.TelnetRun         -> TelnetM.Telnet[unique("Telnet")];

  TestGyroBoardM.PVStdControl      -> ParamViewM;
  TestGyroBoardM.TelnetStdControl  -> TelnetM;

  TelnetM.TCPServer            -> IPClientC.TCPServer[unique("TCPServer")];

  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> TestGyroBoardM.ParamView;

}
