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
 * Implementation for TimeTestM module. 
 **/ 

/*
    test set up: install TimeTest to one mote and keep it 
                       in programming board
                 run java net/tinyos/tools/ListenRaw COM1
    Two msgs should be captured: 
    1st msg: when time is 0x01234567890abcde, the result of getXXX() 
    data byte 1 & 2 : mote id 
              3-10  : 8 bytes time: the result of get()
              11-14 : result of getHigh32()
              15-18 : resutl of getLow32()
              19-20 : result of getMs()
              21-22 : result of getUs()

    2nd mssg is utility function test results. test data: 
	t1 = 0x0101010123456789
        t2 = 0x0100000012345678

    bytes 1-2: mote id
          3-10: t1+t2
          11-18: t1-t2
          19-20: compare(t2, t1)
          21-22: compare(t1, t2)
*/

includes TosTime;
includes TimeSyncMsg;
includes SendTime;

module TimeTestM {
	uses {
		interface SendMsg as Send;
                interface SendMsg as SendTime;
		interface ReceiveMsg as Receive;
		interface StdControl as CommControl;
                interface StdControl as TimeControl;
		//interface TimeSync;
                interface Time;
                interface TimeSet;
                interface TimeUtil;
		interface Leds;
                //interface AbsoluteTimer as AbsoluteTimer0;

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
    tos_time_t t0, t1, t2;

    void sendTime() {
        tos_time_t t;
        struct SendTime * pdata;
        call Leds.yellowToggle();
            if (!sendPending) {
            pdata = (struct SendTime *)pmsg->data;
	    pdata->source_addr = TOS_LOCAL_ADDRESS;
/* for test the get command */
            t = call Time.get();
            pdata->time = call Time.getHigh32();

            pdata->receiver_timestamp = call Time.getMs() ;
            pdata->receiver_settime = call Time.getLow32();
            pdata->currentTime = call Time.getUs();
	    pdata->timeH = t.high32;
            pdata->timeL = t.low32;
	    // send the msg now
	    sendPending = call SendTime.send(TOS_UART_ADDR, sizeof(struct SendTime), pmsg);
            }

    }	

    task void debugTime() {
         struct SendTime *pdata;
            call Leds.yellowToggle();
	    pdata = (struct SendTime *)pmsg->data;
            pdata->source_addr = TOS_LOCAL_ADDRESS;
            pdata->time = t0.high32;
            
            pdata->receiver_timestamp = call TimeUtil.compare(t2, t1);
            pdata->receiver_settime =t0.low32;
            pdata->currentTime = call TimeUtil.compare(t1, t2);;
            t0 = call TimeUtil.subtract(t1, t2);
            pdata->timeH = t0.high32;
            pdata->timeL = t0.low32;
            // send the msg now
            sendPending = call SendTime.send(TOS_UART_ADDR, sizeof(struct SendTime), pmsg);
    }

/** 
 *  module Initialization.  initlize module variables
 *  and lower level components
 **/

  command result_t StdControl.init(){
    sendPending = FALSE;
    pmsg = &buffer;
    //call AbsoluteTimer0.init();
    receiverTimeStamp=0; 
    tsFlag =1 ;
    t1.high32 = 0x01010101; t1.low32 = 0x23456789;
    t2.high32 = 0x01000000; t2.low32 = 0x12345678;
		
    call Leds.init();
    call TimeControl.init();
    call CommControl.init();
    //call TimeSync.init();

    return SUCCESS;
  }
 
  command result_t StdControl.start() {
        int i;
        tos_time_t tt;
	call CommControl.start() ;
        call TimeControl.start() ;
        for (i=0; i<100; i++); // add some delay
        tt = call TimeUtil.create(0x01234567, 0x890abcde);
        call TimeSet.set(tt);

        sendTime();
        //call TimeSync.sendSync();
        //call Leds.yellowToggle();
        //call AbsoluteTimer0.start(t0);
        return SUCCESS;
  }

/** 
 *  @return Always return <code>SUCCESS</code>
 **/
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
        uint16_t tt, delta;
        uint16_t offset=2300;//  fixed offset to tx 11.5 byte start symbel
	struct TimeSyncMsg * pdata = (struct TimeSyncMsg *)msg->data;
        //call Leds.redToggle();
		 // if (pdata->type==0) 

        return msg;
    } 


    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        //if (msg == &buffer) {
            //call Leds.yellowToggle();
            sendPending = FALSE;
            call Leds.redToggle();
        //}
        return SUCCESS;
    } 

    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
            sendPending = FALSE;
        call Leds.redToggle();
        if (tsFlag) {
        t0 = call TimeUtil.add(t1, t2);
        post debugTime();
        tsFlag = 0;
        }
        return SUCCESS;
    }
/****
    event result_t AbsoluteTimer0.expired() {
          call Leds.redToggle();
          if (++tsFlag>2 && state==MASTER) { // This will allow the timer to stablize after reset.
                tsFlag = 0;
		//call TimeSync.sendSync();
	        call Leds.yellowToggle();
          }
          t0 +=5000; 
          //call AbsoluteTimer0.start(t0);
          //else sendTime();
          return SUCCESS;
    }
*******/ 
}
