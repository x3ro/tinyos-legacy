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

 * $Id: XMDA500.nc,v 1.3 2005/01/27 07:10:43 husq Exp $

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

configuration XMDA500 { 

// this module does not provide any interface

}

implementation

{

  components Main, XMDA500M, TimerC, ADCC,

    GenericCommPromiscuous as Comm,

	MULTIHOPROUTER as MultiHopM, QueuedSend,

#if FEATURE_UART_SEND

	HPLPowerManagementM,

#endif

	LEDS_COMPONENT

	DELUGE_COMPONENT 

	XEE_PARAMS_COMPONENT

	XCommandC, Bcast; 





    Main.StdControl -> XMDA500M;
    

    Main.StdControl -> QueuedSend.StdControl;

    Main.StdControl -> MultiHopM.StdControl;

    Main.StdControl -> Comm;

    Main.StdControl -> TimerC;



    DELUGE_WIRING()

    XEE_PARAMS_WIRING()

    LEDS_WIRING(XMDA500M)



    XMDA500M.ADCControl -> ADCC;

    XMDA500M.ADCBATT -> ADCC.ADC[BATT_TEMP_PORT];

    XMDA500M.ADC2    -> ADCC.ADC[ADC2_PORT];

    XMDA500M.ADC3    -> ADCC.ADC[ADC3_PORT];

    XMDA500M.ADC4    -> ADCC.ADC[ADC4_PORT];

    XMDA500M.ADC5    -> ADCC.ADC[ADC5_PORT];

    XMDA500M.ADC6    -> ADCC.ADC[ADC6_PORT];

    XMDA500M.ADC7    -> ADCC.ADC[ADC7_PORT];

      

      

    XMDA500M.Timer -> TimerC.Timer[unique("Timer")];


    // Wiring for broadcast commands.

    XMDA500M.XCommand -> XCommandC;

    XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];

    Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];

    // Wiring for RF mesh networking.

    XMDA500M.RouteControl -> MultiHopM;

    XMDA500M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
    XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];  
    MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] ->Comm.ReceiveMsg[AM_XMULTIHOP_MSG];

}



