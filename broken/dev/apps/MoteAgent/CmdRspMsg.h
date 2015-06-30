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

enum {
 AM_COMMANDMSG = 0x47,
 AM_CMDRSPMSG = 0x48,
 AM_ALARMMSG = 0x49
};

enum componentIDs {
	LEDS=1,
    RADIO,
	LIGHT,
	TEMP,
	ACCEL,
	MAGET,
	MICPHONE,
	SOUNDER,
	LOGGER,
	CLOCK
};

enum actions {
    GET=0,
    SET_ON,
    SET_OFF,
    SET_START,
    SET_STOP
};
// the following data structure is use by both AM_COMMANDMSG and AM_RSPMAG
struct CmdRspMsg{
    int16_t source;
    int8_t seqno;
    int8_t hopCnt; 
    int8_t status; // use for SET command only
    // leds display when command is executed successfully for now
    // in future. if status is set to 0 by manager, agent is requested to 
    // send a response back  
    int8_t compID;
    int8_t action;
    int8_t args[10];
};    
 
struct CommandMsg {
    int16_t source;
    int8_t seqno;
    int8_t hopCnt;
    int8_t status; // use for SET command only
    // leds display when command is executed successfully for now
    // in future. if status is set to 0 by manager, agent is requested to
    // send a response back
    int8_t compID;
    int8_t action;
    int8_t args[10];
};


struct  AlarmMsg {
    int16_t source;
    int8_t seqno;
    int8_t hopCnt;
    int8_t text[24];
};

