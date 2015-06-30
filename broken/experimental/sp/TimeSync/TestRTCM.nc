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
        interface SysTime;
	interface Timer as Timer0;
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
    bool toggle ;
    /**
     * Initialize system time
     * Initialize communication leyer
     **/
    command result_t StdControl.init() {
        sendPending = FALSE;
        toggle = TRUE;
        pmsg = &buffer;
        if (TOS_LOCAL_ADDRESS==1) master = TRUE;
        else master = FALSE;
        call TimeSync.init();
        // not call CommControl.init(); because it is called in TimeSync.init
        if (master) {
            call TimeSync.sendSync();
            call Leds.redOn();
            sendTime();
        }
        // The follwoing code is for test SysTime interface 
        //call Timer0.start(TIMER_REPEAT, 60000L);
        
        return SUCCESS;
    
    }

    command result_t StdControl.start() {
	return call CommControl.start() ;
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
	if (pmsg->type== TIMESYNC_REQUEST) {
	    call TimeSync.timeSync(msg);
            // start a timer so that we can report our time every hour 
	        // this is for testing clock drift  
            call Timer0.start(TIMER_REPEAT, 30000L);// 5 min
        }
        sendTime();
	return msg;
    } 

    void sendTime() {
	    uint16_t timeL;
            unsigned long timeH;
	    struct TimeSyncMsg * pdata = (struct TimeSyncMsg *)pmsg->data;
	    call Leds.yellowToggle();
	    call SysTime.get(&timeH, &timeL);
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
    }

    event result_t Timer0.fired() {
        sendTime();
	return SUCCESS;
    }        
       

    /*
     * task to send a time sync message of type TIME_RESPONSE
     *
    task void sendResponse() {
        uint16_t sender;
        struct TimeSyncMsg * pdata = pmsg->data;
		sender = pdata->source_addr;
        pdata->source_addr = TOS_LOCAL_ADDRESS;
        pdata->type = TIME_RESPONSE;

        // send the msg now
        sendPending = call Send.send(sender, sizeof(struct TimeSymcMsg), pmsg);        
        return SUCCESS;
    }  
    */
    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        if (msg == &buffer) sendPending = FALSE;
        
        return SUCCESS;
    } 

    event result_t  TimeSync.syncDone( ) {
        call Leds.redToggle();
	return SUCCESS;
    }


}
