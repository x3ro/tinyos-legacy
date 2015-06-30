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
 *          February 2005
 */

configuration TestIMAPLite {
}
implementation {
  components Main, 
    TestIMAPLiteM,
    HTTPServerM,
    TelnetM,
    IPCLIENT as IPClientC,
    TimerC,
    LedsC,
    ParamViewM,
    IMAPLiteM;

  Main.StdControl->TestIMAPLiteM;
  Main.StdControl->TimerC;

  TestIMAPLiteM.IPStdControl -> IPClientC;
  TestIMAPLiteM.UIP          -> IPClientC;
  TestIMAPLiteM.Client       -> IPClientC;

  TestIMAPLiteM.Timer        -> TimerC.Timer[unique("Timer")];
  TestIMAPLiteM.Leds         -> LedsC;

  TestIMAPLiteM.HTTPStdControl -> HTTPServerM;
  TestIMAPLiteM.HTTPServer     -> HTTPServerM;
  HTTPServerM.TCPServer      -> IPClientC.TCPServer[unique("TCPServer")];

  TestIMAPLiteM.IMAPStdControl -> IMAPLiteM;
  TestIMAPLiteM.IMAPLite       -> IMAPLiteM;
  IMAPLiteM.TCPClient        -> IPClientC.TCPClient[unique("TCPClient")];
  IMAPLiteM.Leds -> LedsC;

  TestIMAPLiteM.TelnetStdControl -> TelnetM;
  TelnetM.TCPServer -> IPClientC.TCPServer[unique("TCPServer")];

  TestIMAPLiteM.PVStdControl -> ParamViewM;
  ParamViewM.TelnetShow -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView  -> IMAPLiteM.ParamView;
  ParamViewM.ParamView  -> IPClientC.ParamView;
  ParamViewM.ParamView  -> HTTPServerM.ParamView;
}
