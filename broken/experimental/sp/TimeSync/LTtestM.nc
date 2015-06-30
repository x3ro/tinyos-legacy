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
 * Date last modified:  9/19/02
 *
 */
includes TimeSyncMsg;
module TestAppM {
    provides interface StdControl;
    uses {
	interface SendMsg as Send;
	interface ReceiveMsg as Receive;
	interface StdControl as CommControl;
	interface TimeSync;
        interface LogicTime;
        interface AbsoluteTimer;
        //interface Clock;
//	interface Timer as Timer0;
//      interface Timer as Timer1;
        interface Leds;
    }
}
implementation
{
    void sendTime();

    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;
    bool master ;
    uint16_t myTime;
    /**
     * Initialize system time
     * Initialize communication leyer
     **/
    command result_t StdControl.init() {
        sendPending = FALSE;
        pmsg = &buffer;
        call Leds.init();
        //call AbsoluteTimer.init();  //since we call TimeSync.init
        if (TOS_LOCAL_ADDRESS==1) master = TRUE;
        else master = FALSE;
        call TimeSync.init();
        // no need to call CommControl.init(); because it is called in TimeSync.init
        if (master) {
            call LogicTime.set(100000);
            sendTime();
            //call TimeSync.sendSync();
            call Leds.yellowToggle();
            call AbsoluteTimer.start(983040);
        }
        return SUCCESS;
    }

    command result_t StdControl.start() {

	call CommControl.start() ;
/***
        if (master) {
            call LogicTime.set(100000);
            sendTime();
            //call TimeSync.sendSync();
            call Leds.yellowToggle();
            call AbsoluteTimer.start(983040);
        }
***/
    }

    command result_t StdControl.stop() {
	return call CommControl.stop() ;
    }

    /**
     * Receive a time sync message 
     * check the type field. if type is TIMESYNC_REQUEST
     * call TimeSync.timeSync
     * else if type is TIME REQUEST, send our current time back  
     * 
     **/

    event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
            call Leds.redToggle();
	    call TimeSync.timeSync(msg);
            //sendTime();
            // start a timer, so that we can periodically report our time 
            if (!master) call AbsoluteTimer.start(983040);// 0.5 min
        //}
	return msg;
    } 

    void sendTime() {
	    uint16_t timeL;
            unsigned long timeH;
	    struct TimeSyncMsg * pdata = (struct TimeSyncMsg *)pmsg->data;
	    timeL = call LogicTime.get();
	    // keep this msg
            //post a task to send response back
	    //post sendResponse();
	    //return &buffer;
		// for this test, there is no other events, 
		//so I don't have to post a task
	    //sender = pdata->source_addr;
	    pdata->source_addr = TOS_LOCAL_ADDRESS;
	    pdata->type = TIME_RESPONSE;
            pdata->timeH = timeH;
            pdata->timeL = timeL;
	    // send the msg now
	    sendPending = call Send.send(TOS_UART_ADDR, sizeof(struct TimeSyncMsg), pmsg);
            call Leds.yellowToggle();
    }

    event result_t AbsoluteTimer.expired() {
        call Leds.greenToggle();
        //call Timer1.start(TIMER_REPEAT, 300000L);
        sendTime();
	return SUCCESS;
    }        
/**
    event result_t Timer1.fired() {
        call Leds.greenToggle();
	return SUCCESS ;
    }
    event result_t Clock.fire() {
	myTime+=32 ; 
 	if (myTime>=983040 ) {
		myTime = 0; 
		call Leds.greenToggle();
	}
	return SUCCESS;
    }
***/
         
    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        //if (msg == &buffer) {
            call Leds.redToggle();
            sendPending = FALSE;
        //}
        return SUCCESS;
    } 

    event result_t  TimeSync.syncDone( ) {
        //call Leds.redToggle();
	return SUCCESS;
    }


}
