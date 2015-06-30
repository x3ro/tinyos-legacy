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
 *          Jamey Hicks
 *          March 2005
 */

configuration EKGApp {
}
implementation {
  components Main, 
    EKGAppM,
    EKGM, 
    TelnetM,
    HTTPServerM,
    SIPLiteServerM,
    IPCLIENT as IPClientC,
    ParamViewM,
    PatientViewM,
    ServiceViewM,
    LedsC,
    TimerC,
    NTPClientM,
    HPLUARTC,
    ADCC,
    TimeM,
    HPLUSART0M;

  Main.StdControl->EKGAppM;
  Main.StdControl->TimerC;
  Main.StdControl->ADCC;
  Main.StdControl->TimeM;

  EKGAppM.IPStdControl      -> IPClientC;
  EKGAppM.TelnetStdControl  -> TelnetM;
  EKGAppM.PVStdControl      -> ParamViewM;
  EKGAppM.SVStdControl      -> ServiceViewM;
  EKGAppM.HTTPStdControl    -> HTTPServerM;
  EKGAppM.NTPClient         -> NTPClientM;
  EKGAppM.SIPLiteStdControl -> SIPLiteServerM;
  EKGAppM.Time              -> TimeM;

  EKGAppM.HTTPServer        -> HTTPServerM;
  EKGAppM.SIPLiteServer     -> SIPLiteServerM;

  EKGAppM.UIP               -> IPClientC;
  EKGAppM.Client            -> IPClientC;
  EKGAppM.Leds              -> LedsC;
  EKGAppM.EKG               -> EKGM;

  EKGM.TelnetEKG            -> TelnetM.Telnet[unique("Telnet")];
  EKGM.ADC0                 -> ADCC.ADC[TOS_ADC_ADC0_PORT];
  EKGM.ADC1                 -> ADCC.ADC[TOS_ADC_ADC1_PORT];
  EKGM.ADCControl           -> ADCC.ADCControl;
  EKGM.Timer                -> TimerC.Timer[unique("Timer")];
  EKGM.Leds                 -> LedsC;

  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
  ParamViewM.ParamView          -> EKGM.ParamView;
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> HTTPServerM.ParamView;
  ParamViewM.ParamView          -> EKGAppM.ParamView;
  ParamViewM.ParamView          -> SIPLiteServerM.ParamView;
  ParamViewM.ParamView          -> PatientViewM.ParamView;
  ParamViewM.ParamView          -> ServiceViewM.ParamView;

  PatientViewM.UDPClient    -> IPClientC.UDPClient[unique("UDPClient")];
  PatientViewM.Client       -> IPClientC;
  PatientViewM.UIP          -> IPClientC;
  PatientViewM.Timer        -> TimerC.Timer[unique("Timer")];
  PatientViewM.Leds         -> LedsC;

  ServiceViewM.TelnetShow   -> TelnetM.Telnet[unique("Telnet")];
  ServiceViewM.UDPClient    -> IPClientC.UDPClient[unique("UDPClient")];
  ServiceViewM.Client       -> IPClientC;
  ServiceViewM.UIP          -> IPClientC;
  ServiceViewM.Timer        -> TimerC.Timer[unique("Timer")];
  ServiceViewM.Leds         -> LedsC;
  ServiceViewM.ServiceView  -> EKGAppM.ServiceView;

  NTPClientM.UDPClient       -> IPClientC.UDPClient[unique("UDPClient")];
  NTPClientM.Timer           -> TimerC.Timer[unique("Timer")];
  NTPClientM.Leds            -> LedsC;

  TelnetM.TCPServer             -> IPClientC.TCPServer[unique("TCPServer")];
  HTTPServerM.TCPServer         -> IPClientC.TCPServer[unique("TCPServer")];
  SIPLiteServerM.UDPMaster      -> IPClientC.UDPClient[unique("UDPClient")];
  SIPLiteServerM.UDPStream      -> IPClientC.UDPClient[unique("UDPClient")];
  SIPLiteServerM.TimerMaster    -> TimerC.Timer[unique("Timer")];

  TimeM.Timer                -> TimerC.Timer[unique("Timer")];
  TimeM.NTPClient            -> NTPClientM;
  TimeM.LocalTime            -> TimerC;
}
