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
 * $Id: TestSensor.nc,v 1.3 2004/08/20 15:02:08 mturon Exp $
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
configuration TestSensor { 
// this module does not provide any interface
}
implementation
{
    components Main, TimerC, TestSensorM, 
	GenericCommPromiscuous as Comm,
	EWMAMultiHopRouter as MultiHopM, QueuedSend,
	ADCC, MicC, PhotoTemp, Accel, Mag, Sounder,
#ifdef FEATURE_LEDS
	LedsC, 
#else
	NoLeds,
#endif
	DelugeC;

    Main.StdControl -> TestSensorM;
    Main.StdControl -> DelugeC;
    Main.StdControl -> QueuedSend.StdControl;
    Main.StdControl -> MultiHopM.StdControl;
    Main.StdControl -> Comm;
    Main.StdControl -> TimerC;

    TestSensorM.Timer -> TimerC.Timer[unique("Timer")];
#ifdef FEATURE_LEDS 
    TestSensorM.Leds -> LedsC;
#else
    TestSensorM.Leds -> NoLeds;
#endif  

    // Wiring for sensorboard readings.
    TestSensorM.ADCControl -> ADCC;

    TestSensorM.ADCBATT -> ADCC.ADC[BATT_PORT];
    
    TestSensorM.TempControl -> PhotoTemp.TempStdControl;
    TestSensorM.Temperature -> PhotoTemp.ExternalTempADC;

    TestSensorM.PhotoControl -> PhotoTemp.PhotoStdControl;
    TestSensorM.Light -> PhotoTemp.ExternalPhotoADC;
    
    TestSensorM.Sounder -> Sounder;
    
    TestSensorM.MicControl -> MicC;
    TestSensorM.MicADC ->MicC;
    TestSensorM.Mic -> MicC;
    
    TestSensorM.AccelControl -> Accel;
    TestSensorM.AccelX -> Accel.AccelX;
    TestSensorM.AccelY -> Accel.AccelY;
    
    TestSensorM.MagControl-> Mag;
    TestSensorM.MagX -> Mag.MagX;
    TestSensorM.MagY -> Mag.MagY;
    
    // Wiring for RF mesh networking.
    TestSensorM.RouteControl -> MultiHopM;
    TestSensorM.Send -> MultiHopM.Send[XMULTIHOPMSG_ID];
    MultiHopM.ReceiveMsg[XMULTIHOPMSG_ID] -> Comm.ReceiveMsg[XMULTIHOPMSG_ID];
}

