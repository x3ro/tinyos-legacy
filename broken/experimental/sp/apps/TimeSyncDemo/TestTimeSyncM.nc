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
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  
 *
 */

/** 
 * Implementation for TestTimeSyncM module. 
 **/ 

/*  Timesync test 

    For this test  timesync interval is 32 seconds. 
    This can be changed by modify TimeSyncMsg.h file. 
    Time Sync is running in the background
    One of the test mote has to be mote id 0, which will be the time master. 

    One mote is programed with Trigger code. 
    It broadcasts a msg ( type 18 ) every 20 seconds. 
    When other motes receives this message, it broadcasts its current time.
    GenericBase will collect these time messages and forward them to UART. 
    On host PC, I Use ListenRaw to capture the msgs and save them to a file. 


    Meanings of Leds: 
    when receving a trigger msg, toggle green LED
    When send a time message out, toggle yellow LED
    when receiving a timeSync msg toggle red Led
*/

includes TosTime;
includes TimeSyncMsg;
includes SendTime;

module TestTimeSyncM {
    uses {
        interface SendMsg as SendTime;
	interface ReceiveMsg as Receive;
	interface StdControl as CommControl;
	interface StdControl as TimeSyncControl;
        interface Time;
	interface Leds;
    }
    provides interface StdControl;
}

implementation {
    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;
    bool state ; 
    char tsFlag;

    uint16_t receiverTimeStamp, currentTime;
    tos_time_t t0;
    uint16_t phase;

    task void debugTime() {
        int i;
        uint32_t delay;        
        struct TimeResp *pdata;

        if (!sendPending) {
            pdata = (struct TimeResp *)pmsg->data;
            pdata->source_addr = TOS_LOCAL_ADDRESS;
            dbg(DBG_USR1, "t=\%x, \%x\n", t0.high32, t0.low32);
            pdata->timeH = t0.high32;
            pdata->timeL = t0.low32;
/*
            if (TOS_LOCAL_ADDRESS) 
	        delay = 0x40000<<TOS_LOCAL_ADDRESS;
            else delay =0;
            // add delay to avoid collision
            for (i=0; i< delay; i++) ; 
*/
            // send the msg now
            sendPending = call SendTime.send(TOS_UART_ADDR, sizeof(struct TimeResp), pmsg);
        }
    }


    /** 
     *  module Initialization.  initlize module variables
     *  and lower level components
     **/

    command result_t StdControl.init(){
    	sendPending = FALSE;
    	pmsg = &buffer;
    	call Leds.init();
    	call CommControl.init();
    	call TimeSyncControl.init();
    	return SUCCESS;
    }
 
    command result_t StdControl.start() {
	call CommControl.start() ;
        call TimeSyncControl.start();
        return SUCCESS;
    }

    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
        call TimeSyncControl.stop();
        return call CommControl.stop() ;
    }

    /**
     * Receive a triggler message 
     * Record our current time, post debugTime task to send time out 
     * 
     **/

    event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
        call Leds.greenToggle();
        t0 = call Time.get();
        post debugTime();
        return msg;
    } 


    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
            call Leds.redToggle();
            sendPending = FALSE;
        return SUCCESS;
    } 

}
