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

/* Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  9/19/02
 *
 */

/** 
 * Implementation for TestM module. 
 **/ 

/*  Absolute Timer test 
    set time to 0x00;
    start a absolute timer that expires at t1 = t0 = {0x0, 0x100000) or 1 s.
    when this time expires, post a task to send current time to UART
    then restart the timer at t1 += t0;  
    Use ListenRaw to capture the msg. The message data format is:
	byte 1-2 mote ID 
	byte 3-6 time.high32 ( higher 32 bits of mote time
	byte 7-10 time.low32
	byte 11-12 16 bits time in binary micro second
	byte 13 TCNT0 register reading
        byte 14 not used 
*/

includes TosTime;
includes TimeSyncMsg;
includes SendTime;

module AtimerTestM {
    uses {
    interface SendMsg as Send;
    interface SendMsg as SendTime;
    interface ReceiveMsg as Receive;
    interface StdControl as CommControl;
    interface StdControl as Control;
    interface Time;
    interface TimeUtil;
    interface TimeSet;
    interface Leds;
    //interface StdControl as TimeControl;
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
    call Leds.greenToggle();

    if (!sendPending) {
	pdata = (struct TimeResp *)pmsg->data;
	pdata->source_addr = TOS_LOCAL_ADDRESS;
	t = call Time.get();
	dbg(DBG_USR1, "debugTime: t=\%x, \%x\n", t.high32, t.low32);
	pdata->timeH = t.high32;
	pdata->timeL = t.low32;
	pdata->us = call Time.getUs();
	pdata->tcnt = inp(TCNT0);
	// send the msg now
	sendPending = call SendTime.send(TOS_BCAST_ADDR, sizeof(struct TimeResp), pmsg);
    }

    t2 = call TimeUtil.add(t2, t1);
    retval = call AbsoluteTimer1.set(t2);
    if (!retval) { 
        dbg(DBG_USR1, "timer1 start failed\n");
        call Leds.redToggle();
    }
}


/** 
 *  module Initialization.  initlize module variables
 *  and lower level components
 **/

    command result_t StdControl.init(){
    	sendPending = FALSE;
    	pmsg = &buffer;

    	t1.high32 = 0x0; t1.low32 = 0x100000;
   	t0.high32 = 0x0; t0.low32 = 0x8000;		
    	t2.high32 = 0x0; t2.low32 = 0x200000;
        t3 = t1; 
    	call Leds.init();
    	call CommControl.init();
    	//call TimeControl.init();
    	call Control.init();
        call TimerControl.init();
    	return SUCCESS;
    }
 
    command result_t StdControl.start() {
	call CommControl.start() ;
        //call TimeControl.start(); 
        call TimerControl.start();
        call Control.start();
        call TimeSet.set(t0);
        debugTime();
        PCdebugTime();
        call Timer0.start(TIMER_REPEAT, 2000);
        return SUCCESS;
  }

/** 
 *  @return Always return <code>SUCCESS</code>
 **/
    command result_t StdControl.stop() {
    	call Control.stop();
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


    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        //if (msg == &buffer) {
        //call Leds.yellowToggle();
        sendPending = FALSE;
        //}
        return SUCCESS;
    } 

    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
        sendPending = FALSE;
        return SUCCESS;
    }
    void PCdebugTime() {
        result_t retval;
        t3 = call TimeUtil.add(t3, t0);
        retval = call AbsoluteTimer0.set(t3);
       
        if (!retval)
        {
            dbg(DBG_USR1, "restart timer0 failed\n");
            call Leds.redToggle();
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


