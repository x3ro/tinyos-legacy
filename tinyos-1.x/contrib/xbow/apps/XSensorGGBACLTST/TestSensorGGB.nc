/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Copyright (c) 2004 Crossbow Technology, Inc.  
 *
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
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE CROSSBOW OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * $Id: TestSensorGGB.nc,v 1.1 2004/11/22 14:20:45 husq Exp $
 */
includes sensorboardApp;
includes TestSensor;
configuration TestSensorGGB
{ 
}
implementation
{
  components Main, TestSensorGGBM, GenericComm as Comm,
    Voltage, Temp, Accel,
    TimerC, LedsC;

  Main.StdControl -> TestSensorGGBM;
  Main.StdControl -> Comm;
  Main.StdControl -> Voltage;
  Main.StdControl -> Temp;
  Main.StdControl -> Accel;
  Main.StdControl -> TimerC;

  TestSensorGGBM.SendMsg -> Comm.SendMsg[AM_XBOWSENSORBOARDPACKET];

  TestSensorGGBM.ADCBATT -> Voltage;
  TestSensorGGBM.ADCTemp -> Temp;
  TestSensorGGBM.mADCAcl -> Accel;
 
  TestSensorGGBM.Timer -> TimerC.Timer[unique("Timer")];
  TestSensorGGBM.Leds -> LedsC;
}

