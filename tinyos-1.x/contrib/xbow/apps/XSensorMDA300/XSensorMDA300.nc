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
 * 
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


configuration XSensorMDA300 { 
// this module does not provide any interface
}

implementation {
    
    components Main, XSensorMDA300M, 
    GenericComm as Comm,
    LedsC,SamplerC,TimerC;  

    Main.StdControl -> XSensorMDA300M;    
    Main.StdControl -> TimerC;
    
    XSensorMDA300M.Leds -> LedsC;    
    XSensorMDA300M.Timer -> TimerC.Timer[unique("Timer")];    

    //Sampler Communication    
    XSensorMDA300M.SamplerControl -> SamplerC.SamplerControl;    
    XSensorMDA300M.Sample -> SamplerC.Sample;
 
    XSensorMDA300M.CommControl -> Comm;
    XSensorMDA300M.Receive -> Comm.ReceiveMsg[AM_XSXMSG];
    XSensorMDA300M.Send -> Comm.SendMsg[AM_XSXMSG];
    
    //support for plug and play.    
    XSensorMDA300M.PlugPlay -> SamplerC.PlugPlay;

    //relays
    XSensorMDA300M.relay_normally_closed -> SamplerC.relay_normally_closed;
    XSensorMDA300M.relay_normally_open -> SamplerC.relay_normally_open;

}



