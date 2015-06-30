/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
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
    It broadcasts a msg ( type 18 ) every 10 seconds. 
    When other motes receives this message, it broadcasts its current time.
    GenericBase will collect these time messages and forward them to UART. 
    On host PC, I Use ListenRaw to capture the msgs and save them to a file. 


    Meanings of Leds: 
    when receving a trigger msg, toggle green LED
    When send a time message out, toggle red LED
    when receiving a timeSync msg toggle yellow Led
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

    TOS_Msg buffer, RxBuffer;
    TOS_MsgPtr pmsg, pRx;

    bool sendPending;
    bool state ; 
    char tsFlag;

    uint16_t receiverTimeStamp, currentTime;
    tos_time_t t0;
    uint16_t phase;

    task void debugTime() {
        struct TimeResp *pdata;
 
        if (!sendPending) {
            pdata = (struct TimeResp *)pmsg->data;
            pdata->source_addr = TOS_LOCAL_ADDRESS;
            dbg(DBG_USR1, "t=\%x, \%x\n", t0.high32, t0.low32);
            pdata->timeH = t0.high32;
            pdata->timeL = t0.low32;

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
		pRx = &RxBuffer;
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
        return call TimeSyncControl.stop();
        return call CommControl.stop() ;
    }

    /**
     * Receive a triggler message 
     * Record our current time, post debugTime task to send time out 
     * 
     **/
    event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
	    TOS_MsgPtr p = pRx;
		pRx = msg;
        call Leds.greenToggle();
        t0 = call Time.get();
        post debugTime();
        return p;
    } 


    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
        call Leds.redToggle();
        sendPending = FALSE;
        return SUCCESS;
    } 
}
