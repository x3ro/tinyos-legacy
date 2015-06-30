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
 * $Id: XSensorMTS300.nc,v 1.4 2005/04/04 10:04:06 husq Exp $
 */

/*
 *
 * Description:
 * 
 * 
 *
*/

#include "appFeatures.h"
includes sensorboardApp;
configuration XSensorMTS300 { 
// this module does not provide any interface
}
implementation
{
  components Main, GenericComm as Comm,
			 XSensorMTS300M, LedsC,
             TimerC, Voltage, MicC, PhotoTemp, Accel, Mag, Sounder;
  
  Main.StdControl -> XSensorMTS300M;
  Main.StdControl -> TimerC;
  
  XSensorMTS300M.CommControl -> Comm;
  XSensorMTS300M.Receive -> Comm.ReceiveMsg[AM_XSXMSG];
  XSensorMTS300M.Send -> Comm.SendMsg[AM_XSXMSG];
  
  // Wiring for Battery Ref
  XSensorMTS300M.BattControl -> Voltage;  
  XSensorMTS300M.ADCBATT -> Voltage;  
  
  XSensorMTS300M.TempControl -> PhotoTemp.TempStdControl;
  XSensorMTS300M.PhotoControl -> PhotoTemp.PhotoStdControl;
  XSensorMTS300M.Temperature -> PhotoTemp.ExternalTempADC;
  XSensorMTS300M.Light -> PhotoTemp.ExternalPhotoADC;

  XSensorMTS300M.Sounder -> Sounder;
  
  XSensorMTS300M.MicControl -> MicC;
  XSensorMTS300M.Mic -> MicC;
  XSensorMTS300M.MicADC ->MicC;
  
  
  XSensorMTS300M.AccelControl->Accel;
  XSensorMTS300M.AccelX -> Accel.AccelX;
  XSensorMTS300M.AccelY -> Accel.AccelY;

  XSensorMTS300M.MagControl-> Mag;
  XSensorMTS300M.MagX -> Mag.MagX;
  XSensorMTS300M.MagY -> Mag.MagY;
  
  XSensorMTS300M.Leds -> LedsC;
  XSensorMTS300M.Timer -> TimerC.Timer[unique("Timer")];
}

