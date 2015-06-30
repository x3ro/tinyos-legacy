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
 * $Id: TestMTS400.nc,v 1.10 2005/03/04 10:08:49 husq Exp $
 * 
 */
#include "appFeatures.h"  
includes sensorboardApp;

configuration TestMTS400 {
// this module does not provide any interface
}
implementation {
  components Main, TestMTS400M,  SensirionHumidity,
             IntersemaPressure,MicaWbSwitch,GenericComm as Comm,
             TimerC, Voltage, LedsC, Accel, TaosPhoto,
	XEE_PARAMS_COMPONENT
#ifdef MTS420
    GpsPacketC, 
#endif             
             ADCC;

  Main.StdControl -> TestMTS400M;
  Main.StdControl -> TimerC;
  XEE_PARAMS_WIRING()
  
  
  TestMTS400M.CommControl -> Comm;
  TestMTS400M.Receive -> Comm.ReceiveMsg[AM_XSXMSG];
  TestMTS400M.Send -> Comm.SendMsg[AM_XSXMSG];

// Wiring for gps
#ifdef MTS420
  TestMTS400M.GpsControl -> GpsPacketC;
  TestMTS400M.GpsSend -> GpsPacketC;
  TestMTS400M.GpsReceive -> GpsPacketC;
  TestMTS400M.GpsCmd -> GpsPacketC.GpsCmd;                //UARTGpsPacket.GpsCmd;
#endif  
 
  // Wiring for Battery Ref
  TestMTS400M.BattControl -> Voltage;  
  TestMTS400M.ADCBATT -> Voltage;  

// Wiring for Taos light sensor
  TestMTS400M.TaosControl -> TaosPhoto;
  TestMTS400M.TaosCh0 -> TaosPhoto.ADC[0];
  TestMTS400M.TaosCh1 -> TaosPhoto.ADC[1];
  
// Wiring for Accelerometer  
  TestMTS400M.AccelControl->Accel.StdControl;
  TestMTS400M.AccelCmd -> Accel.AccelCmd;
  TestMTS400M.AccelX -> Accel.AccelX;
  TestMTS400M.AccelY -> Accel.AccelY;

// Wiring for Sensirion humidity/temperature sensor
  TestMTS400M.TempHumControl -> SensirionHumidity;
  TestMTS400M.Humidity -> SensirionHumidity.Humidity;
  TestMTS400M.Temperature -> SensirionHumidity.Temperature;
  TestMTS400M.HumidityError -> SensirionHumidity.HumidityError;
  TestMTS400M.TemperatureError -> SensirionHumidity.TemperatureError;

// Wiring for Intersema barometric pressure/temperature sensor
  TestMTS400M.IntersemaCal -> IntersemaPressure;
  TestMTS400M.PressureControl -> IntersemaPressure;
  TestMTS400M.IntersemaPressure -> IntersemaPressure.Pressure;
  TestMTS400M.IntersemaTemp -> IntersemaPressure.Temperature;

  TestMTS400M.Leds -> LedsC;    
  TestMTS400M.Timer -> TimerC.Timer[unique("Timer")];
}
