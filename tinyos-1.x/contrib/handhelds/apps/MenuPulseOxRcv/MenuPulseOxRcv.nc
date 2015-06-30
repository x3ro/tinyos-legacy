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
 */

/**
 * A simple RF broadcast utility to generate TOS-format data packets.
 *
 * @author Andrew Christian
 */

configuration MenuPulseOxRcv {
}
implementation {
  components Main, MenuPulseOxRcvM, LedsC,TimerC, LCD_B,MenuM,
#if defined(SERVER)
    SIPLiteClientM, 
#endif
    IPCLIENT as IPClientC,
#if defined(HAVE_TELNET)
    TelnetM, 
    InfoMemM,
#endif
#if defined(BATTERY_VOLTAGE)
    BatVoltC,
#endif
    NTPClientM,
    TimeM,
    ButtonsSimpleM,
    MSP430InterruptC,
    PatientViewM,
    IMAPLiteM,   
    ParamViewM
    ;

  
  Main.StdControl -> MenuPulseOxRcvM;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> MenuM.StdControl;
  Main.StdControl->TimeM;
#if defined(BATTERY_VOLTAGE)
  Main.StdControl -> BatVoltC.StdControl;
#endif

  
  MenuPulseOxRcvM.TimerSlow -> TimerC.Timer[unique("Timer")];
  MenuPulseOxRcvM.TimerFast -> TimerC.Timer[unique("Timer")];
  MenuPulseOxRcvM.LCD -> LCD_B;
  MenuPulseOxRcvM.Leds  -> LedsC;
  MenuPulseOxRcvM.Menu  -> MenuM;
  MenuPulseOxRcvM.NTPClient  -> NTPClientM;
  MenuPulseOxRcvM.Time  -> TimeM;

  MenuPulseOxRcvM.IMAPStdControl -> IMAPLiteM;
  MenuPulseOxRcvM.IMAPLite       -> IMAPLiteM;
  IMAPLiteM.TCPClient        -> IPClientC.TCPClient[unique("TCPClient")];
  IMAPLiteM.Leds -> LedsC;

  
  
  MenuPulseOxRcvM.MenuStdControl -> MenuM;
  MenuM.Leds -> LedsC;
  MenuM.LCD -> LCD_B;
  MenuM.Buttons -> ButtonsSimpleM;
  MenuM.ParamList -> ParamViewM;
  MenuM.IMAPLite -> IMAPLiteM;
  MenuM.Time -> TimeM;
  
  
  ButtonsSimpleM.Timer0 -> TimerC.Timer[unique("Timer")];
#if 0
  ButtonsSimpleM.Timer1 -> TimerC.Timer[unique("Timer")];
  ButtonsSimpleM.Timer2 -> TimerC.Timer[unique("Timer")];
  ButtonsSimpleM.Timer3 -> TimerC.Timer[unique("Timer")];
#endif
  ButtonsSimpleM.Button0Interrupt -> MSP430InterruptC.Port23;
  ButtonsSimpleM.Button1Interrupt -> MSP430InterruptC.Port22;
  ButtonsSimpleM.Button2Interrupt -> MSP430InterruptC.Port21;
  ButtonsSimpleM.Button3Interrupt -> MSP430InterruptC.Port20;
  ButtonsSimpleM.Leds ->LedsC;
  ButtonsSimpleM.LCD ->LCD_B;

  NTPClientM.UDPClient       -> IPClientC.UDPClient[unique("UDPClient")];
  NTPClientM.Timer           -> TimerC.Timer[unique("Timer")];
  NTPClientM.Client          -> IPClientC;

  TimeM.Timer                -> TimerC.Timer[unique("Timer")];
  TimeM.NTPClient            -> NTPClientM;
  TimeM.LocalTime            -> TimerC;

  
#if defined(BATTERY_VOLTAGE)
  MenuPulseOxRcvM.BatVolt  -> BatVoltC;
#endif

  

  MenuPulseOxRcvM.IPStdControl  -> IPClientC;
  MenuPulseOxRcvM.UIP           -> IPClientC;
  MenuPulseOxRcvM.Client        -> IPClientC;
  MenuPulseOxRcvM.PVStdControl -> ParamViewM;
  MenuPulseOxRcvM.ParamList -> ParamViewM;
  MenuPulseOxRcvM.PatientView -> PatientViewM;

#if defined(SERVER)
  MenuPulseOxRcvM.SIPLiteStdControl -> SIPLiteClientM;
  MenuPulseOxRcvM.SIPLiteClient -> SIPLiteClientM;
  SIPLiteClientM.UDPControl    -> IPClientC.UDPClient[unique("UDPClient")];
  SIPLiteClientM.UDPStream     -> IPClientC.UDPClient[unique("UDPClient")];
  SIPLiteClientM.Timer         -> TimerC.Timer[unique("Timer")];
#endif

#if defined(HAVE_TELNET)
  MenuPulseOxRcvM.TelnetStdControl  -> TelnetM;
  MenuPulseOxRcvM.Telnet            -> TelnetM.Telnet[unique("Telnet")];
  TelnetM.TCPServer                 -> IPClientC.TCPServer[unique("TCPServer")];
  InfoMemM.Telnet                   -> TelnetM.Telnet[unique("Telnet")];
#endif

#if defined(HAVE_TELNET)
  ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
#endif
  ParamViewM.ParamView          -> IPClientC.ParamView;
  ParamViewM.ParamView          -> PatientViewM.ParamView;
  ParamViewM.ParamView		-> IMAPLiteM.ParamView;


  
  PatientViewM.UDPClient    -> IPClientC.UDPClient[unique("UDPClient")];
  PatientViewM.Client       -> IPClientC;
  PatientViewM.UIP          -> IPClientC;
  PatientViewM.Timer        -> TimerC.Timer[unique("Timer")];
  PatientViewM.Leds         -> LedsC;

}
