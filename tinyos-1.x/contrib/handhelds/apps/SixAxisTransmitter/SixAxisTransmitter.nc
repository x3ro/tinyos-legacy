/*
 * Copyright (c) 2007 Intel Corporation
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
 *          April 2007
 */

configuration SixAxisTransmitter {
}
implementation {
  components 
    Main, 
    SixAxisTransmitterM, 
    DMA_M, 
    //    SDC,
    AccelC,
    GyroBoardC,
    TimerC, 
    LedsC, 	
    //    TimeM,
    //    NTPClientM,
    IPCLIENT as IPClientC,
    TelnetM,
    ParamViewM;

  Main.StdControl->SixAxisTransmitterM;
  Main.StdControl->TimerC;

  /* have to fix compile time channel limitation */
  SixAxisTransmitterM.DMA0         -> DMA_M.DMA[0];
  SixAxisTransmitterM.Leds         -> LedsC;
  SixAxisTransmitterM.sampleTimer       -> TimerC.Timer[unique("Timer")];
 
  SixAxisTransmitterM.AccelStdControl   -> AccelC;
  SixAxisTransmitterM.Accel             -> AccelC;

  SixAxisTransmitterM.GyroStdControl   -> GyroBoardC;
  SixAxisTransmitterM.GyroBoard        -> GyroBoardC;

  SixAxisTransmitterM.IPStdControl  -> IPClientC;
  SixAxisTransmitterM.UIP           -> IPClientC;
  SixAxisTransmitterM.Client        -> IPClientC;
  SixAxisTransmitterM.UDPClient     -> IPClientC.UDPClient[unique("UDPClient")];

  SixAxisTransmitterM.TelnetRun         -> TelnetM.Telnet[unique("Telnet")];

  SixAxisTransmitterM.PVStdControl      -> ParamViewM;
  SixAxisTransmitterM.TelnetStdControl  -> TelnetM;

  TelnetM.TCPServer            -> IPClientC.TCPServer[unique("TCPServer")];

  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> SixAxisTransmitterM.ParamView;

}
