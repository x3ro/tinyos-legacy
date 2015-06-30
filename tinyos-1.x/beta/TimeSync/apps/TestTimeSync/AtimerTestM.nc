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
 * Date last modified:  9/19/02
 *
 */

/** 
 * Implementation for TestM module. 
 **/ 

/*  Absolute Timer test 
 *
 *  Red LED: a 2 second repeat timer expired
 *  Grenn LED: toggles every 1 second
 *  Yellow LED: toggles every 0.5 sec.
*/

includes TosTime;
includes TimeSyncMsg;
includes SendTime;

module AtimerTestM {
    uses {
    interface SendMsg as SendTime;
    interface ReceiveMsg as Receive;
    interface StdControl as CommControl;
    //interface StdControl as Control;
    interface Time;
    interface TimeUtil;
    interface TimeSet;
    interface Leds;
    interface AbsoluteTimer as AbsoluteTimer0;
    interface AbsoluteTimer as AbsoluteTimer1;
    interface StdControl as TimerControl;
    interface Timer as Timer0;
    }

    provides interface StdControl;
}

implementation {

TOS_Msg buffer;
TOS_MsgPtr pmsg;
bool sendPending;
bool state ; 

uint16_t receiverTimeStamp, currentTime;
tos_time_t t0, t1, t2, t3;
void PCdebugTime();

void debugTime() {
    struct TimeResp *pdata;
    tos_time_t t;
    bool retval;

    if (!sendPending) {
        call Leds.greenToggle();
	pdata = (struct TimeResp *)pmsg->data;
	pdata->source_addr = TOS_LOCAL_ADDRESS;
	t = call Time.get();
	dbg(DBG_USR1, "debugTime: t=\%x, \%x\n", t.high32, t.low32);
	pdata->timeH = t.high32;
	pdata->timeL = t.low32;
	// send the msg now
	sendPending = call SendTime.send(TOS_BCAST_ADDR, sizeof(struct TimeResp), pmsg);
    }

    t2 = call TimeUtil.add(t, t1);
    retval = call AbsoluteTimer1.set(t2);
    if (!retval) { 
        dbg(DBG_USR1, "timer1 start failed\n");
        //call Leds.redToggle();
    }
}


/** 
 *  module Initialization.  initlize module variables
 *  and lower level components
 **/

    command result_t StdControl.init(){
    	sendPending = FALSE;
    	pmsg = &buffer;

    	t1.high32 = 0x0; t1.low32 = 2000;
   	t0.high32 = 0x0; t0.low32 = 4000;		
    	t2.high32 = 0x0; t2.low32 = 1000;
        t3 = t2; 
    	call Leds.init();
    	call CommControl.init();
    	//call TimeControl.init();
    	//call Control.init();
        call TimerControl.init();
    	return SUCCESS;
    }
 
    command result_t StdControl.start() {
	call CommControl.start() ;
        //call TimeControl.start(); 
        call TimerControl.start();
        //call Control.start();
        //call TimeSet.set(t0);
        debugTime();
        PCdebugTime();
        call Timer0.start(TIMER_REPEAT, 100);
        return SUCCESS;
  }

/** 
 *  @return Always return <code>SUCCESS</code>
 **/
    command result_t StdControl.stop() {
    	//call Control.stop();
    	call TimerControl.stop();
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
        return msg;
    } 


    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
        sendPending = FALSE;
        //call Leds.yellowToggle();
        return SUCCESS;
    }
    void PCdebugTime() {
        result_t retval;
        t3 = call TimeUtil.add(t3, t0);
        retval = call AbsoluteTimer0.set(t3);
       
        if (!retval)
        {
            dbg(DBG_USR1, "restart timer0 failed\n");
            //call Leds.redToggle();
        }
    }

    event result_t AbsoluteTimer0.fired() {
        call Leds.yellowToggle();
        dbg(DBG_USR1, "timer0 fired\n");
        PCdebugTime(); 
        return SUCCESS;
    }

    event result_t AbsoluteTimer1.fired() {
        //call Leds.greenToggle();
        dbg(DBG_USR1, "timer1 fired\n");
        debugTime();
        return SUCCESS;
    }

    event result_t Timer0.fired() {
        call Leds.redToggle();
    }
}


