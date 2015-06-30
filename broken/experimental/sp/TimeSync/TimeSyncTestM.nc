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
 * Implementation for TimeSyncTestM module. 
 **/ 
includes TimeSyncMsg;
module TimeSyncTestM {
	uses {
		interface SendMsg as Send;
		interface ReceiveMsg as Receive;
		interface StdControl as CommControl;
		interface TimeSync;
		interface Leds;
          interface AbsoluteTimer;
          interface LogicTime;
	}

	provides interface StdControl;
}

implementation {

    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;
    bool master ; 
    unsigned long t0;
	uint16_t time_sent;
	
    void sendTime() {
	    
      struct TimeSyncMsg * pdata = (struct TimeSyncMsg *)pmsg->data;
	  if (!sendPending) {
	    //sender = pdata->source_addr;
	    pdata->source_addr = TOS_LOCAL_ADDRESS;
	    pdata->type = TIME_RESPONSE;
            pdata->timeH = call LogicTime.get();
            //pdata->timeL = call LogicTime.currentTime();
		pdata->timeL = time_sent;
	    // send the msg now
	    sendPending = call Send.send(TOS_BCAST_ADDR, sizeof(struct TimeSyncMsg), pmsg);
	  }
      call Leds.redToggle();
    }

/** 
 *  module Initialization.  initlize module variables
 *  and lower level components
 **/

  command result_t StdControl.init(){
    sendPending = FALSE;
    pmsg = &buffer;
    call Leds.init();
//	call AbsoluteTimer.init();
 //   t0=0x60000; time_sent =0;
    call TimeSync.init() ; // we don't call LogicTime.init()  
			   // because it is called in TimeSync.init()
   
    if (TOS_LOCAL_ADDRESS==1) master = TRUE;
    else master = FALSE;
		
    return SUCCESS;
  }
 
  command result_t StdControl.start() {
	call CommControl.start() ;
    if (master) {
            call LogicTime.set(0x01020304);
            call TimeSync.sendSync();
   //         call AbsoluteTimer.start(t0);
	    call Leds.yellowToggle();
    }
//    sendTime();
    return SUCCESS;
  }

/** 
 *  @return Always return <code>SUCCESS</code>
 **/
  command result_t StdControl.stop() {

    return call CommControl.stop() ;
  }

  task void myTask() {
      sendTime();
  }

/** 
 *  Timer expired Event Handler 
 *  Toggle green LED . 
 *  @return Alway return <code>SUCCESS</code>
 **/

  event result_t AbsoluteTimer.expired() {

    call Leds.greenToggle();
	post myTask();
	t0+=0x60000;
    //call LogicTime.set(800000);
    call AbsoluteTimer.start(t0);

    return SUCCESS;
	
  }

    /**
     * Receive a time sync message 
     * check the type field. if type is TIMESYNC_REQUEST
     * call TimeSync.timeSync
     * else if type is TIME REQUEST, send our current time back  
     * 
     **/

    event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
	  struct TimeSyncMsg * pdata = (struct TimeSyncMsg *)msg->data;
	  if (pdata->type==TIMESYNC_REQUEST)  {
            call Leds.redToggle();
	    call TimeSync.timeSync(msg);
            //call LogicTime.set(pdata->timeH);
            sendTime();
       // post myTask();
            // start a timer, so that we can periodically report our time 
        //if (!master) call AbsoluteTimer.start(t0);
        		
	  }
      return msg;
    } 


    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        //if (msg == &buffer) {
            //call Leds.redToggle();
            sendPending = FALSE;
        //}
        return SUCCESS;
    } 

    event result_t  TimeSync.syncDone( ) {
        call Leds.greenToggle();
	return SUCCESS;
    }


  
}
