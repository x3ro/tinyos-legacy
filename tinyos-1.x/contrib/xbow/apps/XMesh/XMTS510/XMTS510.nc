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
 * $Id: XMTS510.nc,v 1.3 2005/01/27 06:31:55 husq Exp $ 
 */

#include "appFeatures.h"
includes sensorboardApp;

configuration XMTS510 {
}
implementation {

  components Main, XMTS510M,Photo, Accel, MicC, TimerC,
    GenericCommPromiscuous as Comm,
	MULTIHOPROUTER as MultiHopM, QueuedSend,

#if FEATURE_UART_SEND
	HPLPowerManagementM,
#endif

	LEDS_COMPONENT
	DELUGE_COMPONENT 
	XEE_PARAMS_COMPONENT
	XCommandC, Bcast; 

    Main.StdControl -> XMTS510M;
    Main.StdControl -> QueuedSend.StdControl;
    Main.StdControl -> MultiHopM.StdControl;
    Main.StdControl -> Comm;
    Main.StdControl -> TimerC;

    DELUGE_WIRING()
    XEE_PARAMS_WIRING()
    LEDS_WIRING(XMTS510M)

    XMTS510M.Timer -> TimerC.Timer[unique("Timer")];

    XMTS510M.MicControl -> MicC;
    XMTS510M.MicADC -> MicC; 
    XMTS510M.Mic -> MicC;

    XMTS510M.PhotoControl -> Photo; 
    XMTS510M.PhotoADC -> Photo; 
    
    XMTS510M.AccelControl->Accel;
    XMTS510M.AccelX -> Accel.AccelX;
    XMTS510M.AccelY -> Accel.AccelY;

    // Wiring for broadcast commands.
    XMTS510M.XCommand -> XCommandC;
    XCommandC.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];
    Bcast.ReceiveMsg[AM_XCOMMAND_MSG] -> Comm.ReceiveMsg[AM_XCOMMAND_MSG];
    
    // Wiring for RF mesh networking.
    XMTS510M.RouteControl -> MultiHopM;
    XMTS510M.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG];
    XCommandC.Send -> MultiHopM.Send[AM_XMULTIHOP_MSG]; 
    MultiHopM.ReceiveMsg[AM_XMULTIHOP_MSG] ->Comm.ReceiveMsg[AM_XMULTIHOP_MSG];



} 

