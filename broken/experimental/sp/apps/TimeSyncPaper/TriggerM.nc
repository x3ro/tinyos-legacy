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
 * This is a test program. It broadcast a SEND_TIME message without 
 * any data every 10 seconds.
 *
 */
includes SendTime;
module TriggerM {
    provides interface StdControl;
    uses {
	interface SendMsg as Send;
	interface StdControl as CommControl;
	interface Timer as Timer1;
        interface Leds;
    }
}
implementation
{

    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;

    uint16_t t;
    /**
     * Initialize system time
     * Initialize communication leyer
     **/
    command result_t StdControl.init() {
        sendPending = FALSE;
 
        pmsg = &buffer;
        call Leds.init();
	call CommControl.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {

	call CommControl.start() ;
        call Timer1.start(TIMER_REPEAT, 20000);
   //     call Leds.redToggle();
    }

    command result_t StdControl.stop() {
	return call CommControl.stop() ;
    }

    void task sendTrigger() {

        struct TestTime * pdata = (struct TestTime *)pmsg->data;
        if (!sendPending) {
            pdata->source_addr = TOS_LOCAL_ADDRESS;
	    // send the msg now
	    sendPending = call Send.send(TOS_BCAST_ADDR, sizeof(struct TestTime), pmsg);
            call Leds.yellowToggle();
        }
    }


    event result_t Timer1.fired() {
        call Leds.yellowToggle();
        post sendTrigger();
	return SUCCESS ;
    }
   
    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        //if (msg == &buffer) {
            call Leds.redToggle();
            sendPending = FALSE;
        //}
        return SUCCESS;
    } 


}
