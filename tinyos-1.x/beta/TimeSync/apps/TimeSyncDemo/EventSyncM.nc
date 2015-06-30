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
    interface SendMsg as Send;
    interface SendMsg as SendTime;
    interface ReceiveMsg as Receive;
    interface StdControl as CommControl;
    interface StdControl as Control;
    interface StdControl as TimeSyncControl;
    interface TimeSync;
    interface Time;
    interface TimeUtil;
    interface TimeSet;
    interface Leds;
    interface StdControl as TimeControl;
    interface AbsoluteTimer as AbsoluteTimer0;
    interface AbsoluteTimer as AbsoluteTimer1;
    interface Random;
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

  //simulate some application activity on every clock event
     task void longTask() {
       uint16_t ticks = myRand >> 6;
       uint16_t loop;
       while (ticks--) {
         loop++;
       }
       //call Leds.redToggle();
     }

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
        myRand = call Random.init();
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
        PCdebugTime();

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
        tos_time_t tt;

        t3 = call TimeUtil.add(t3, t0);
        tt = call Time.get(); 
        if (call TimeUtil.compare(tt, t3) == 1) {
            call Leds.redToggle();
            return;
        } else {
        retval = call AbsoluteTimer0.set(t3);
        } 
        if (!retval)
        {
            dbg(DBG_USR1, "restart timer0 failed\n");
            call Leds.redToggle();
        }
    }

    event result_t AbsoluteTimer0.fired() {
        //call Leds.yellowToggle();
        dbg(DBG_USR1, "timer0 fired\n");
        post longTask();
        PCdebugTime(); 
        return SUCCESS;
    }

    event result_t AbsoluteTimer1.fired() {
        result_t retval; 
        call Leds.greenToggle();
        t= call Time.get();
        dbg(DBG_USR1, "timer1 fired\n");
        t2 = call TimeUtil.add(t2, t1);
        retval = call AbsoluteTimer1.set(t2);
        if (!retval) {
            dbg(DBG_USR1, "timer1 start failed\n");
            call Leds.redToggle();
        }
        debugTime();
        return SUCCESS;
    }
}


