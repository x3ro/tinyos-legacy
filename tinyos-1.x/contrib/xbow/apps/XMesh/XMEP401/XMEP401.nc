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

 * $Id: XMEP401.nc,v 1.4 2005/01/27 07:10:43 husq Exp $

 */

#include "appFeatures.h"



includes sensorboardApp;

configuration XMEP401 { 

// this module does not provide any interface

}

implementation

{

  components Main, XMEP401M, Accel, Hamamatsu, SensirionHumidity,IntSensirionHumidity,IntersemaPressure,

  			 Voltage, ADCC, TimerC,



    GenericCommPromiscuous as Comm,

    MULTIHOPROUTER as MultiHopM, QueuedSend,

#if FEATURE_UART_SEND

	HPLPowerManagementM,

#endif

	LEDS_COMPONENT

	DELUGE_COMPONENT 

	XEE_PARAMS_COMPONENT

	XCommandC, Bcast; 





    Main.StdControl -> XMEP401M;
    

    Main.StdControl -> QueuedSend.StdControl;

    Main.StdControl -> MultiHopM.StdControl;

    Main.StdControl -> Comm;

    Main.StdControl -> TimerC;



    DELUGE_WIRING()

    XEE_PARAMS_WIRING()

    LEDS_WIRING(XMEP401M)

    

  

  XMEP401M.Timer -> TimerC.Timer[unique("Timer")];



  // Wiring for Battery Ref

  XMEP401M.BattControl -> Voltage;  

  XMEP401M.ADCBATT -> Voltage;  



  XMEP401M.AccelControl -> Accel;

  XMEP401M.AccelX -> Accel.ADC[1];

  XMEP401M.AccelY -> Accel.ADC[2];

  

  XMEP401M.PhotoControl -> Hamamatsu;

  XMEP401M.Photo1 -> Hamamatsu.ADC[1];

  XMEP401M.Photo2 -> Hamamatsu.ADC[2];

  XMEP401M.Photo3 -> Hamamatsu.ADC[3];

  XMEP401M.Photo4 -> Hamamatsu.ADC[4];

  

  XMEP401M.HumControl -> SensirionHumidity;

  XMEP401M.Humidity -> SensirionHumidity.Humidity;

  XMEP401M.Temperature -> SensirionHumidity.Temperature;

  XMEP401M.HumidityError -> SensirionHumidity.HumidityError;

  XMEP401M.TemperatureError -> SensirionHumidity.TemperatureError;



  XMEP401M.IntHumControl -> IntSensirionHumidity;

  XMEP401M.IntHumidity -> IntSensirionHumidity.Humidity;

  XMEP401M.IntTemperature -> IntSensirionHumidity.Temperature;

  XMEP401M.IntHumidityError -> IntSensirionHumidity.HumidityError;

  XMEP401M.IntTemperatureError -> IntSensirionHumidity.TemperatureError;

  

  XMEP401M.IntersemaControl -> IntersemaPressure.SplitControl;

  XMEP401M.Pressure -> IntersemaPressure.Pressure;

  XMEP401M.IntersemaTemperature -> IntersemaPressure.Temperature;

  XMEP401M.PressureError -> IntersemaPressure.PressureError;

  XMEP401M.IntersemaTemperatureError -> IntersemaPressure.TemperatureError;

  XMEP401M.Calibration -> IntersemaPressure;   

  


    // Wiring for broadcast commands.

    XMEP401M.XCommand -> XCommandC;

    XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];

    Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];

    // Wiring for RF mesh networking.

    XMEP401M.RouteControl -> MultiHopM;

    XMEP401M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
    XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];  
    MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] ->Comm.ReceiveMsg[AM_XMULTIHOP_MSG];

}



