/*
 * Copyright (c) 2005 Hewlett-Packard Company
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
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
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
 * Authors: Andrew Christian
 *          Jamey Hicks
 *          March 2005
 * re-spin to test receiving and setting current time during runtime
 * from pc host via python script
 *          Steve Ayer
 *          March, 2010
 */

configuration testSerialSetTime {
}
implementation {
  components Main, 
    testSerialSetTimeM,
    TelnetM,
    IPCLIENT as IPClientC,
    ParamViewM,
    LedsC,
    TimerC,
    //    NTPClientM,
    TimeM,
    HPLUSART0M;

  Main.StdControl->testSerialSetTimeM;
  Main.StdControl->TimerC;
  Main.StdControl->TimeM;

  testSerialSetTimeM.IPStdControl      -> IPClientC;
  testSerialSetTimeM.TelnetStdControl  -> TelnetM;
  testSerialSetTimeM.PVStdControl      -> ParamViewM;
  testSerialSetTimeM.Time              -> TimeM;

  testSerialSetTimeM.UARTData     -> HPLUSART0M;
  testSerialSetTimeM.UARTControl  -> HPLUSART0M;

  testSerialSetTimeM.UIP               -> IPClientC;
  testSerialSetTimeM.Client            -> IPClientC;
  testSerialSetTimeM.Leds              -> LedsC;

  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> testSerialSetTimeM.ParamView;
  ParamViewM.ParamView          -> TimeM.ParamView;

  TelnetM.TCPServer             -> IPClientC.TCPServer[unique("TCPServer")];

  TimeM.Timer                -> TimerC.Timer[unique("Timer")];
  //  TimeM.NTPClient            -> NTPClientM;
  TimeM.LocalTime            -> TimerC;
}
