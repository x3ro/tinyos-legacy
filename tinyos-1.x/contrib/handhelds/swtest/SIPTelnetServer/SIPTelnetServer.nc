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

configuration SIPTelnetServer {
}
implementation {
    components Main, 
	SIPTelnetServerM, 
	IPCLIENT as IPClientC,
	TelnetM,
	ParamViewM,
	LedsC,
	SIPUA_M, SIPTransactionM, SIPMessagePoolM, SIPMessageM, 
	TimerC, NTPClientM;

    Main.StdControl->SIPTelnetServerM;
    Main.StdControl->TimerC;

    SIPTelnetServerM.NTPClient         -> NTPClientM;
    SIPTelnetServerM.SIPStdControl     -> SIPUA_M;
    SIPTelnetServerM.IPStdControl      -> IPClientC;
    SIPTelnetServerM.PVStdControl      -> ParamViewM;
    SIPTelnetServerM.TelnetStdControl  -> TelnetM;

    SIPTelnetServerM.TelnetRun         -> TelnetM.Telnet[unique("Telnet")];

    SIPTelnetServerM.UIP               -> IPClientC;
    SIPTelnetServerM.Client            -> IPClientC;

    ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
    ParamViewM.ParamView         -> IPClientC.ParamView;
    ParamViewM.ParamView         -> SIPTelnetServerM.ParamView;

    TelnetM.TCPServer            -> IPClientC.TCPServer[unique("TCPServer")];

    SIPTelnetServerM.Leds              -> LedsC;
    SIPTelnetServerM.SIPTransaction    -> SIPTransactionM;
    SIPTelnetServerM.SIPUA             -> SIPUA_M;
  
    SIPUA_M.IPStdControl             -> IPClientC;
    SIPUA_M.UIP                      -> IPClientC;
    SIPUA_M.SIPTransactionStdControl -> SIPTransactionM;
    SIPUA_M.SIPMessageStdControl     -> SIPMessageM;
    SIPUA_M.SIPMessagePool           -> SIPMessagePoolM;
    SIPUA_M.SIPTransaction           -> SIPTransactionM;
    SIPUA_M.RegistrationTimer        -> TimerC.Timer[unique("Timer")];
    SIPUA_M.Leds                     -> LedsC;
    SIPUA_M.Client                   -> IPClientC;

    SIPTransactionM.TransactionTimer -> TimerC.Timer[unique("Timer")];
    SIPTransactionM.SIPMessage       -> SIPMessageM;
    SIPTransactionM.SIPMessagePool   -> SIPMessagePoolM;
    SIPTransactionM.Leds             -> LedsC;
     
    SIPMessageM.TCPClient      -> IPClientC.TCPClient[unique("TCPClient")];
    SIPMessageM.TCPServer      -> IPClientC.TCPServer[unique("TCPServer")];
    SIPMessageM.SIPMessagePool -> SIPMessagePoolM;
    SIPMessageM.Leds -> LedsC;

    NTPClientM.UDPClient       -> IPClientC.UDPClient[unique("UDPClient")];
    NTPClientM.Timer           -> TimerC.Timer[unique("Timer")];
    NTPClientM.Client          -> IPClientC;
    //    NTPClientM.Leds            -> LedsC;

}
