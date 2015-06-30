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
 * This applications showes that when logical time are syncronized using
 * our TimeSync protocol, an application event can be synchronized 
 * using AbsoluteTimer event.
 *
 *     Test scenario: start comm stack, start TimeSync
 *     Start a fast repeat timer0 (32ms) . 
 *     start a slow absolute timer1 (10s) . 
 *     When the fast timer fires, posts a long task and restart the timer.
 *     When the slow timer fires, toggle green LED, take a time stamp.
 *     Then post a task to send the time stamp over radio (type 0x13).
 *     Yellow Leds indicates that a TimeSync msg type 0x25 is sent.
 *     GenericBase can be used to collect the msg containing the time stamp. 
 *     and ListenRaw can be used to display the collected raw data in a PC.
 *     The message type is defined in SendTime.h 
 *
 *     If the all the motes toggles their green LED at the same time,
 *     they are synchronized. 
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
    interface StdControl as TimeSyncControl;
    interface TimeSync;
    interface Time;
    interface TimeUtil;
    interface TimeSet;
    interface Leds;
    interface Timer as Timer0;
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
tos_time_t  t,  t1, t2, t3;
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

    	t1.high32 = 0x0; t1.low32 = 4096;
    	t2.high32 = 0x0; t2.low32 = 2048;
        t3 = t1; 
    	call Leds.init();
    	call CommControl.init();
	call TimeSyncControl.init();
    	return SUCCESS;
    }
 
    command result_t StdControl.start() {
	call CommControl.start() ;
   	call TimeSyncControl.start();
        call AbsoluteTimer1.set(t2);
        call Timer0.start(TIMER_REPEAT, 32);

        return SUCCESS;
  }

/** 
 *  @return Always return <code>SUCCESS</code>
 **/
    command result_t StdControl.stop() {
    	//call TimeSyncControl.stop();
    	return call CommControl.stop() ;
   
    }


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

    event result_t Timer0.fired() {
        //call Leds.yellowToggle();
        dbg(DBG_USR1, "timer0 fired\n");
        post longTask();
        return SUCCESS;
    }

    event result_t AbsoluteTimer1.fired() {
        tos_time_t temp;
        result_t retval=FALSE; 
        call Leds.greenToggle();
        t= call Time.get();
        dbg(DBG_USR1, "timer1 fired\n");
        while (!retval) {
        t2 = call TimeUtil.add(t2, t1);
        temp = call Time.get();
        if ((call TimeUtil.compare(t2, temp))==1) 
	    retval = 1;
        }
        retval = call AbsoluteTimer1.set(t2);
        if (!retval) {
            dbg(DBG_USR1, "timer1 start failed\n");
            call Leds.redToggle();
        }
        debugTime();
        return SUCCESS;
    }
}


