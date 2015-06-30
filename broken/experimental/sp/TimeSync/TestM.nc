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

/** 
 * Implementation for TestM module. 
 **/ 
includes TimeSyncMsg;
includes SendTime;
module TestM {
	uses {
		interface SendMsg as Send;
                interface SendMsg as SendTime;
		interface ReceiveMsg as Receive;
		interface StdControl as CommControl;
		interface TimeSync;
		interface Leds;
                interface LogicTime;
                interface AbsoluteTimer;
	}

	provides interface StdControl;
}

implementation {

    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;
    bool state ; 
    bool tsFlag;

    uint16_t receiverTimeStamp, currentTime;
    unsigned long t0, now;

    void sendTime() {
        unsigned long timeH;
	    struct SendTime * pdata ;
            if (!sendPending) {
            pdata = (struct SendTime *)pmsg->data;

	    pdata->source_addr = TOS_LOCAL_ADDRESS;
	    pdata->time = call LogicTime.get();
	    // send the msg now
	    sendPending = call SendTime.send(TOS_BCAST_ADDR, sizeof(struct SendTime), pmsg);
            }
    }	

    task void debugTime() {
         struct SendTime *pdata;
            call Leds.yellowToggle();
	    pdata = (struct SendTime *)pmsg->data;
            pdata->source_addr = TOS_LOCAL_ADDRESS;
            pdata->time = t0; // master time
            pdata->receiver_timestamp = receiverTimeStamp;
            pdata->receiver_settime = now;
            pdata->currentTime = currentTime;
            // send the msg now
            sendPending = call SendTime.send(TOS_BCAST_ADDR, sizeof(struct SendTime), pmsg);
    }

/** 
 *  module Initialization.  initlize module variables
 *  and lower level components
 **/

  command result_t StdControl.init(){
    sendPending = FALSE;
    pmsg = &buffer;
//	call AbsoluteTimer.init();
 //   t0=0x60000; time_sent =0;
    t0 =0; now =0; receiverTimeStamp=0; 
    if (TOS_LOCAL_ADDRESS==1) state= MASTER;
    else state = SLAVE_UNSYNCED;
    tsFlag = FALSE;
		
    call Leds.init();
    call TimeSync.init();

    return SUCCESS;
  }
 
  command result_t StdControl.start() {
        int i;
	call CommControl.start() ;
        
	for (i=0; i< 10; i++ ) ; // create some delay

        if (state==MASTER) {
		tsFlag= TRUE; 
        }
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
        call Leds.redToggle();
		 // if (pdata->type==0) 

        // receiver side delay calculation
/* these are test code 
        now = call  LogicTime.get();
        currentTime = (uint16_t)now;
        receiverTimeStamp = msg->time;

        tt = LogicTime.currentTime();
        if (now >= msg->time)  delta = now - msg->time;
        else delta = 0x10000 + now -msg->time ;
        call LogicTime.set(pdata->timeH + delta + offset);

        t0 = pdata->timeH;
        post debugTime();
*/
        call TimeSync.timeSync(msg);

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

    event result_t AbsoluteTimer.expired() {
          if (tsFlag) { // This will allow the timer to stablize after reset.
		call TimeSync.sendSync();
	        call Leds.yellowToggle();
                tsFlag =FALSE ;
          }
          //else sendTime();
          return SUCCESS;
    }
  
}
