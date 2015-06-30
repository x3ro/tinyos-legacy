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
 *  LIABILITY, WHETHER IN CONTRACTCOMPONENT=TestTimeSync, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  2/6/03
 *
 */

/** 
 * This applications showes that when logical time are syncronized with
 * our TimeSync protocol, an application event can be synchronized 
 * using AbsoluteTimer event.
 *
 *     Test scenario: start comm stack, start TimeSync
 *     Start a fast absolute timer (32ms) . 
 *     start a slow absolute timer (4s) . 
 *     When the fast timer fires, posts a long task and restart the timer.
 *     When the slow timer fires, toggle green LED, take a time stamp.
 *     Then post a task to send the time stamp over radio (type 0x13).
 *     Yellow Leds indicates that a TimeSync msg type 0x25 is sent.
 *     GenericBase can be used to collect the msg containing the time stamp. 
 *     and ListenRaw can be used to display the collected raw data in a PC.
 *     The message type is defined in SendTime.h 
 **/ 

/*  
*/

includes TosTime;
includes TimeSyncMsg;
includes SendTime;

module EventSyncM {
    uses {
    interface SendMsg as SendTime;
    interface StdControl as CommControl;
    interface StdControl as Control;
    interface StdControl as TimeSyncControl;
    interface TimeSync;
    interface Time;
    interface TimeUtil;
    interface TimeSet;
    interface Leds;
    interface StdControl as TimeControl;
    interface AbsoluteTimer as AbsoluteTimer1;
    }

    provides interface StdControl;
}

implementation {

TOS_Msg buffer;
TOS_MsgPtr pmsg;
bool sendPending;
bool state ; 

uint16_t receiverTimeStamp, currentTime;
tos_time_t  t, t0, t1, t2, t3;
uint16_t myRand;
void PCdebugTime();


void debugTime() {
    struct TimeResp *pdata;
    if (!sendPending) {
	pdata = (struct TimeResp *)pmsg->data;
	pdata->source_addr = TOS_LOCAL_ADDRESS;
	//t = call Time.get();
	dbg(DBG_USR1, "debugTime: t=\%x, \%x\n", t.high32, t.low32);
	pdata->timeH = t.high32;
	pdata->timeL = t.low32;
	// send the msg now
	sendPending = call SendTime.send(TOS_BCAST_ADDR, sizeof(struct TimeResp), pmsg);
    }
}


/** 
 *  module Initialization.  initlize module variables
 *  and lower level components
 **/

    command result_t StdControl.init(){
    	sendPending = FALSE;
    	pmsg = &buffer;

    	t1.high32 = 0x0; t1.low32 = 0x400000;
   	t0.high32 = 0x0; t0.low32 = 0x8000;		
    	t2.high32 = 0x0; t2.low32 = 0x200000;
        t3 = t1; 
    	call Leds.init();
    	call CommControl.init();
    	call Control.init();
	call TimeSyncControl.init();
    	return SUCCESS;
    }
 
    command result_t StdControl.start() {
	call CommControl.start() ;
        call Control.start();
        call TimeSet.set(t0);
   	call TimeSyncControl.start();
        call AbsoluteTimer1.set(t2);

        return SUCCESS;
  }

/** 
 *  @return Always return <code>SUCCESS</code>
 **/
    command result_t StdControl.stop() {
    	call Control.stop();
    	call TimeControl.stop();
    	return call CommControl.stop() ;
   
    }

    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
        sendPending = FALSE;
        return SUCCESS;
    }

    event result_t AbsoluteTimer1.fired() {
        result_t retval; 
        call Leds.redToggle();
        t= call Time.get();
        dbg(DBG_USR1, "timer1 fired\n");
        t2 = call TimeUtil.add(t2, t1);
        retval = call AbsoluteTimer1.set(t2);
        if (!retval) {
            dbg(DBG_USR1, "timer1 start failed\n");
        }
//        debugTime();
        return SUCCESS;
    }
}


