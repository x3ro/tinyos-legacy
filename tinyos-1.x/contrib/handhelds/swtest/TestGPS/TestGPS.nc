/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
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
 * @author Steve Ayer
 * @date   September, 2010
 */

configuration TestGPS {
}
implementation {
  components 
    Main, 
    TestGPSM,
    TimerC, 
    LedsC, 	
    GPSC,
    PressureSensorC,
    IPCLIENT as IPClientC,
    TelnetM,
    ParamViewM;

  Main.StdControl->TestGPSM;
  Main.StdControl->TimerC;

  TestGPSM.Leds        -> LedsC;
  TestGPSM.Timer       -> TimerC.Timer[unique("Timer")];

  TestGPSM.GPS            -> GPSC;
  TestGPSM.GPSStdControl  -> GPSC;

  TestGPSM.PressureSensor -> PressureSensorC;
  TestGPSM.PSStdControl   -> PressureSensorC;

  TestGPSM.IPStdControl  -> IPClientC;
  TestGPSM.UIP           -> IPClientC;
  TestGPSM.Client        -> IPClientC;
  TestGPSM.UDPClient     -> IPClientC.UDPClient[unique("UDPClient")];
  TestGPSM.TelnetRun     -> TelnetM.Telnet[unique("Telnet")];

  TestGPSM.PVStdControl      -> ParamViewM;
  TestGPSM.TelnetStdControl  -> TelnetM;

  TelnetM.TCPServer            -> IPClientC.TCPServer[unique("TCPServer")];

  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> TestGPSM.ParamView;

}
