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
 * $Id: XMTS310.nc,v 1.11 2005/01/27 03:22:29 husq Exp $
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

configuration XMTS310 { 
// this module does not provide any interface
}
implementation
{
    components Main, TimerC, XMTS310M, 
	GenericCommPromiscuous as Comm,
	MULTIHOPROUTER as MultiHopM, QueuedSend,
	Voltage, MicC, PhotoTemp, Accel, Mag, Sounder, 
	XCommandC, 
	 
#if FEATURE_UART_SEND
	HPLPowerManagementM,
#endif

	LEDS_COMPONENT
	DELUGE_COMPONENT 
	XEE_PARAMS_COMPONENT

	Bcast;

    Main.StdControl -> XMTS310M;
    Main.StdControl -> QueuedSend.StdControl;
    Main.StdControl -> MultiHopM.StdControl;
    Main.StdControl -> Comm;
    Main.StdControl -> TimerC;

    DELUGE_WIRING()
    XEE_PARAMS_WIRING()
    LEDS_WIRING(XMTS310M)

#if FEATURE_UART_SEND
    // Wiring for UART msg.
    XMTS310M.PowerMgrDisable -> HPLPowerManagementM.Disable;
    XMTS310M.PowerMgrEnable -> HPLPowerManagementM.Enable;
    XMTS310M.SendUART -> QueuedSend.SendMsg[AM_XDEBUG_MSG];
    //XMTS310M.SendUART -> Comm.SendMsg[XDEBUGMSG_ID];
#endif

    XMTS310M.Timer -> TimerC.Timer[unique("Timer")];

    // Wiring for Battery Ref
    XMTS310M.BattControl -> Voltage;  
    XMTS310M.ADCBATT -> Voltage;  
   
    XMTS310M.TempControl -> PhotoTemp.TempStdControl;
    XMTS310M.Temperature -> PhotoTemp.ExternalTempADC;

    XMTS310M.PhotoControl -> PhotoTemp.PhotoStdControl;
    XMTS310M.Light -> PhotoTemp.ExternalPhotoADC;
    
    XMTS310M.Sounder -> Sounder;
    
    XMTS310M.MicControl -> MicC;
    XMTS310M.MicADC -> MicC;
    XMTS310M.Mic -> MicC;
    
    XMTS310M.AccelControl -> Accel;
    XMTS310M.AccelX -> Accel.AccelX;
    XMTS310M.AccelY -> Accel.AccelY;
    
    XMTS310M.MagControl-> Mag;
    XMTS310M.MagX -> Mag.MagX;
    XMTS310M.MagY -> Mag.MagY;
    
    // Wiring for broadcast commands.
    XMTS310M.XCommand -> XCommandC;
    XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];
    Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];

    // Wiring for RF mesh networking.
    XMTS310M.RouteControl -> MultiHopM;
    XMTS310M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
    XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];     
    MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] ->Comm.ReceiveMsg[AM_XMULTIHOP_MSG];
#ifdef XMESHSYNC    
    XMTS310M.DownTree -> MultiHopM.Receive[0xc];
    MultiHopM.ReceiveDownstreamMsg[0xc] -> Comm.ReceiveMsg[0xc];
#endif    
}

