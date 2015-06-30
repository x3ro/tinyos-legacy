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
 * $Id: XMEP510.nc,v 1.2 2005/02/03 09:12:07 pipeng Exp $
 */


#include "appFeatures.h"

includes sensorboardApp;



configuration XMEP510 { 

// this module does not provide any interface

}

implementation

{

    components Main, XMEP510M, SensirionHumidity,TimerC,ADCC,

    GenericCommPromiscuous as Comm,

	MULTIHOPROUTER as MultiHopM, QueuedSend,

#if FEATURE_UART_SEND

	HPLPowerManagementM,

#endif

	LEDS_COMPONENT

	DELUGE_COMPONENT 

	XEE_PARAMS_COMPONENT

	XCommandC, Bcast; 





    Main.StdControl -> XMEP510M;
    

    Main.StdControl -> QueuedSend.StdControl;

    Main.StdControl -> MultiHopM.StdControl;

    Main.StdControl -> Comm;

    Main.StdControl -> TimerC;



    DELUGE_WIRING()

    XEE_PARAMS_WIRING()

    LEDS_WIRING(XMEP510M)



    XMEP510M.Timer -> TimerC.Timer[unique("Timer")];



    XMEP510M.ADCBATT -> ADCC.ADC[BATT_PORT];

    XMEP510M.ADCControl -> ADCC;



  XMEP510M.HumControl -> SensirionHumidity;

  XMEP510M.Humidity -> SensirionHumidity.Humidity;

  XMEP510M.Temperature -> SensirionHumidity.Temperature;

  

  XMEP510M.HumidityError -> SensirionHumidity.HumidityError;

  XMEP510M.TemperatureError -> SensirionHumidity.TemperatureError;


    // Wiring for broadcast commands.

    XMEP510M.XCommand -> XCommandC;

    XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];

    Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];

    // Wiring for RF mesh networking.

    XMEP510M.RouteControl -> MultiHopM;
    XMEP510M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
    XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];  
    MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] ->Comm.ReceiveMsg[AM_XMULTIHOP_MSG];

}



