/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * $Id: XMTS420.nc,v 1.3 2005/01/27 07:10:44 husq Exp $
 * 
 */
#include "appFeatures.h" 
includes sensorboardApp;

configuration XMTS420 {
// this module does not provide any interface
}
implementation {
    components Main, XMTS420M,  SensirionHumidity,
    IntersemaPressure,MicaWbSwitch,
#ifdef MTS420
    UARTGpsPacket, 
#endif
    GenericCommPromiscuous as Comm,
    EWMAMultiHopRouter as MultiHopM, QueuedSend,
    ADCC, Voltage,Accel, TaosPhoto, NMEAC,
    XCommandC, Bcast, 
#if FEATURE_UART_SEND
	HPLPowerManagementM,
#endif
	LEDS_COMPONENT
	DELUGE_COMPONENT 
	XEE_PARAMS_COMPONENT

    TimerC;

  Main.StdControl -> XMTS420M;
  Main.StdControl -> QueuedSend.StdControl;
  Main.StdControl -> MultiHopM.StdControl;
  Main.StdControl -> Comm;
  Main.StdControl -> TimerC;

  XMTS420M.ADCControl -> ADCC;

#ifdef MTS420
// Wiring for gps
  XMTS420M.GpsControl -> UARTGpsPacket;
// XMTS420M.GpsSend -> UARTGpsPacket;
  XMTS420M.GpsReceive -> UARTGpsPacket;
  XMTS420M.GpsCmd -> UARTGpsPacket.GpsCmd;
  XMTS420M.nmea -> NMEAC; // GPS NMEA parsing service
#endif  

    DELUGE_WIRING()
    XEE_PARAMS_WIRING()
    LEDS_WIRING(XMTS420M)

#if FEATURE_UART_SEND
    // Wiring for UART msg.
    XMTS420M.PowerMgrDisable -> HPLPowerManagementM.Disable;
    XMTS420M.PowerMgrEnable -> HPLPowerManagementM.Enable;
    XMTS420M.SendUART -> QueuedSend.SendMsg[AM_XDEBUG_MSG];
#endif

  
  // Wiring for Battery Ref
  XMTS420M.BattControl -> Voltage;  
  XMTS420M.ADCBATT -> Voltage;  

// Wiring for Taos light sensor
  XMTS420M.TaosControl -> TaosPhoto;
  XMTS420M.TaosCh0 -> TaosPhoto.ADC[0];
  XMTS420M.TaosCh1 -> TaosPhoto.ADC[1];
  
// Wiring for Accelerometer  
  XMTS420M.AccelControl->Accel.StdControl;
  XMTS420M.AccelCmd -> Accel.AccelCmd;
  XMTS420M.AccelX -> Accel.AccelX;
  XMTS420M.AccelY -> Accel.AccelY;

// Wiring for Sensirion humidity/temperature sensor
  XMTS420M.TempHumControl -> SensirionHumidity;
  XMTS420M.Humidity -> SensirionHumidity.Humidity;
  XMTS420M.Temperature -> SensirionHumidity.Temperature;
  XMTS420M.HumidityError -> SensirionHumidity.HumidityError;
  XMTS420M.TemperatureError -> SensirionHumidity.TemperatureError;

// Wiring for Intersema barometric pressure/temperature sensor
  XMTS420M.IntersemaCal -> IntersemaPressure;
  XMTS420M.PressureControl -> IntersemaPressure;
  XMTS420M.IntersemaPressure -> IntersemaPressure.Pressure;
  XMTS420M.IntersemaTemp -> IntersemaPressure.Temperature;
  
// Wiring for broadcast commands.
  XMTS420M.XCommand -> XCommandC;
  XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];
  Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];

//  XMTS420M.SendMsg -> QueuedSend.SendMsg[XDEBUGMSG_ID];
  XMTS420M.RouteControl -> MultiHopM;
  XMTS420M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
  XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];   
  MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] -> Comm.ReceiveMsg[AM_XMULTIHOP_MSG];
#ifdef XMESHSYNC    
    XMTS420M.DownTree -> MultiHopM.Receive[0xc];
    MultiHopM.ReceiveDownstreamMsg[0xc] -> Comm.ReceiveMsg[0xc];
#endif   
  
  XMTS420M.Timer -> TimerC.Timer[unique("Timer")];
}
