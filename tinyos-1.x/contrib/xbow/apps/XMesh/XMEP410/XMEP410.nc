/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All Rights Reserved.
 *
 * Permission to use, copy, modify and distribute, this software and 
 * documentation is granted, provided the following conditions are met:
 *   1. The above copyright notice and these conditions, along with the 
 *      following disclaimers, appear in all copies of the software.
 *   2. When the use, copying, modification or distribution is for COMMERCIAL 
 *      purposes (i.e., any use other than academic research), then the 
 *      software (including all modifications of the software) may be used 
 *      ONLY with hardware manufactured by and purchased from 
 *      Crossbow Technology, unless you obtain separate written permission 
 *      from, and pay appropriate fees to, Crossbow.  For example, no right 
 *      to copy and use the software on non-Crossbow hardware, if the use is 
 *      commercial in nature, is permitted under this license. 
 *   3. When the use, copying, modification or distribution is for 
 *      NON-COMMERCIAL PURPOSES (i.e., academic research use only), the 
 *      software may be used, whether or not with Crossbow hardware, 
 *      without any fee to Crossbow. 
 *
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN 
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED 
 * HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS 
 * ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
 * OR MODIFICATIONS. 
 *
 * $Id: XMEP410.nc,v 1.1 2005/02/03 10:00:32 pipeng Exp $
 */



#include "appFeatures.h"



includes sensorboardApp;

configuration XMEP410 { 

// this module does not provide any interface

}

implementation

{

  components Main, XMEP410M, Accel, Hamamatsu, SensirionHumidity,IntSensirionHumidity,IntersemaPressure,

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





    Main.StdControl -> XMEP410M;
    

    Main.StdControl -> QueuedSend.StdControl;

    Main.StdControl -> MultiHopM.StdControl;

    Main.StdControl -> Comm;

    Main.StdControl -> TimerC;



    DELUGE_WIRING()

    XEE_PARAMS_WIRING()

    LEDS_WIRING(XMEP410M)

    

  

  XMEP410M.Timer -> TimerC.Timer[unique("Timer")];



  // Wiring for Battery Ref

  XMEP410M.BattControl -> Voltage;  

  XMEP410M.ADCBATT -> Voltage;  



  XMEP410M.AccelControl -> Accel;

  XMEP410M.AccelX -> Accel.ADC[1];

  XMEP410M.AccelY -> Accel.ADC[2];

  

  XMEP410M.PhotoControl -> Hamamatsu;

  XMEP410M.Photo1 -> Hamamatsu.ADC[1];

  XMEP410M.Photo2 -> Hamamatsu.ADC[2];

  XMEP410M.Photo3 -> Hamamatsu.ADC[3];

  XMEP410M.Photo4 -> Hamamatsu.ADC[4];

  

  XMEP410M.HumControl -> SensirionHumidity;

  XMEP410M.Humidity -> SensirionHumidity.Humidity;

  XMEP410M.Temperature -> SensirionHumidity.Temperature;

  XMEP410M.HumidityError -> SensirionHumidity.HumidityError;

  XMEP410M.TemperatureError -> SensirionHumidity.TemperatureError;



  XMEP410M.IntHumControl -> IntSensirionHumidity;

  XMEP410M.IntHumidity -> IntSensirionHumidity.Humidity;

  XMEP410M.IntTemperature -> IntSensirionHumidity.Temperature;

  XMEP410M.IntHumidityError -> IntSensirionHumidity.HumidityError;

  XMEP410M.IntTemperatureError -> IntSensirionHumidity.TemperatureError;

  

  XMEP410M.IntersemaControl -> IntersemaPressure.SplitControl;

  XMEP410M.Pressure -> IntersemaPressure.Pressure;

  XMEP410M.IntersemaTemperature -> IntersemaPressure.Temperature;

  XMEP410M.PressureError -> IntersemaPressure.PressureError;

  XMEP410M.IntersemaTemperatureError -> IntersemaPressure.TemperatureError;

  XMEP410M.Calibration -> IntersemaPressure;   

  


    // Wiring for broadcast commands.

    XMEP410M.XCommand -> XCommandC;

    XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];

    Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];

    // Wiring for RF mesh networking.

    XMEP410M.RouteControl -> MultiHopM;

    XMEP410M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
    XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];  
    MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] ->Comm.ReceiveMsg[AM_XMULTIHOP_MSG];

}



