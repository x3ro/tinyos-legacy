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
 *  $Id: XMDA300.nc,v 1.4 2005/01/27 07:10:42 husq Exp $
 */

/*
 *
 * Description:  Sample aplication for the MDA300 sensor board 
 * 
 * 
 *
*/

// include local hardware defs for this sensor board app
includes sensorboardApp;
#include "appFeatures.h"
includes sensorboardApp;
configuration XMDA300 { 
// this module does not provide any interface
}

implementation {
    
    components Main, XMDA300M, 
    GenericCommPromiscuous as Comm,
	MULTIHOPROUTER as MultiHopM, QueuedSend,
#if FEATURE_UART_SEND
	HPLPowerManagementM,
#endif
	LEDS_COMPONENT
	DELUGE_COMPONENT 
	XEE_PARAMS_COMPONENT
	XCommandC, Bcast, 
    SamplerC,TimerC;
  
    Main.StdControl -> XMDA300M;
    
    Main.StdControl -> QueuedSend.StdControl;
    Main.StdControl -> MultiHopM.StdControl;
    Main.StdControl -> Comm;
    Main.StdControl -> TimerC;
    DELUGE_WIRING()
    XEE_PARAMS_WIRING()
    LEDS_WIRING(XMDA300M)
  
#if FEATURE_UART_SEND
    // Wiring for UART msg.
    XMDA300M.PowerMgrDisable -> HPLPowerManagementM.Disable;
    XMDA300M.PowerMgrEnable -> HPLPowerManagementM.Enable;
    XMDA300M.SendUART -> QueuedSend.SendMsg[AM_XDEBUG_MSG];
    //XMTS310M.SendUART -> Comm.SendMsg[XDEBUGMSG_ID];
#endif
   
    XMDA300M.Timer -> TimerC.Timer[unique("Timer")];
    
    //Sampler Communication
    
    XMDA300M.SamplerControl -> SamplerC.SamplerControl;
    
    XMDA300M.Sample -> SamplerC.Sample;
 
    //support for plug and play.
    
    XMDA300M.PlugPlay -> SamplerC.PlugPlay;
    
    //relays
    
    XMDA300M.relay_normally_closed -> SamplerC.relay_normally_closed;
    
    XMDA300M.relay_normally_open -> SamplerC.relay_normally_open;
    // Wiring for broadcast commands.
    XMDA300M.XCommand -> XCommandC;
    XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];
    Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];
    // Wiring for RF mesh networking.
    XMDA300M.RouteControl -> MultiHopM;
    XMDA300M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
    XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];      
    MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] ->Comm.ReceiveMsg[AM_XMULTIHOP_MSG];
#ifdef XMESHSYNC    
    XMDA300M.DownTree -> MultiHopM.Receive[0xc];
    MultiHopM.ReceiveDownstreamMsg[0xc] -> Comm.ReceiveMsg[0xc];
#endif  
    
}
