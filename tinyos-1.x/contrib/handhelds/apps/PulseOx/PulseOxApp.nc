/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
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

configuration PulseOxApp {
}
implementation {
  components Main, 
    PulseOxAppM,
    PulseOxM, 
#ifndef LITE
    TelnetM,
    HTTPServerM,
    ParamViewM,
    ServiceViewM,
#endif
    SIPLiteServerM,
    IPCLIENT as IPClientC,
    LedsC,
    TimerC,
    HPLUARTC,
    HPLUSART0M;

  Main.StdControl->PulseOxAppM;
  Main.StdControl->TimerC;

  PulseOxAppM.IPStdControl      -> IPClientC;
  PulseOxAppM.SIPLiteStdControl -> SIPLiteServerM;
#ifndef LITE
  PulseOxAppM.TelnetStdControl  -> TelnetM;
  PulseOxAppM.PVStdControl      -> ParamViewM;
  PulseOxAppM.HTTPStdControl    -> HTTPServerM;

  PulseOxAppM.HTTPServer        -> HTTPServerM;
  PulseOxAppM.SVStdControl      -> ServiceViewM;
#endif
  PulseOxAppM.SIPLiteServer     -> SIPLiteServerM;

  PulseOxAppM.UIP               -> IPClientC;
  PulseOxAppM.Client            -> IPClientC;
  PulseOxAppM.Leds              -> LedsC;
  PulseOxAppM.PulseOx           -> PulseOxM;

  PulseOxM.USARTControl         -> HPLUSART0M;
  PulseOxM.HPLUART              -> HPLUARTC;

#ifndef LITE
  PulseOxM.TelnetPulse          -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> PulseOxM.ParamView;
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> HTTPServerM.ParamView;
  ParamViewM.ParamView          -> SIPLiteServerM.ParamView;
  TelnetM.TCPServer             -> IPClientC.TCPServer[unique("TCPServer")];
  HTTPServerM.TCPServer         -> IPClientC.TCPServer[unique("TCPServer")];
  ParamViewM.ParamView          -> ServiceViewM.ParamView;
#endif

#ifndef LITE
  ServiceViewM.TelnetShow   -> TelnetM.Telnet[unique("Telnet")];
  ServiceViewM.UDPClient    -> IPClientC.UDPClient[unique("UDPClient")];
  ServiceViewM.Client       -> IPClientC;
  ServiceViewM.UIP          -> IPClientC;
  ServiceViewM.Timer        -> TimerC.Timer[unique("Timer")];
  ServiceViewM.Leds         -> LedsC;
  ServiceViewM.ServiceView  -> PulseOxAppM.ServiceView;
#endif

  SIPLiteServerM.UDPMaster      -> IPClientC.UDPClient[unique("UDPClient")];
  SIPLiteServerM.UDPStream      -> IPClientC.UDPClient[unique("UDPClient")];
  SIPLiteServerM.TimerMaster   -> TimerC.Timer[unique("Timer")];
}
