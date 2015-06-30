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
module TestM {
	uses {
		interface SendMsg as Send;
		interface ReceiveMsg as Receive;
		interface StdControl as CommControl;
		interface TimeSync;
		interface Leds;
          //interface AbsoluteTimer;
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
	

/** 
 *  module Initialization.  initlize module variables
 *  and lower level components
 **/

  command result_t StdControl.init(){
    sendPending = FALSE;
    pmsg = &buffer;

//	call AbsoluteTimer.init();
 //   t0=0x60000; time_sent =0;
    call TimeSync.init() ; // we don't call LogicTime.init()  
			   // because it is called in TimeSync.init()
   
    if (TOS_LOCAL_ADDRESS==0) master = TRUE;
    else master = FALSE;
		
    return SUCCESS;
  }
 
  command result_t StdControl.start() {
	call CommControl.start() ;
    if (master) {
            call TimeSync.sendSync();
	    call Leds.yellowToggle();
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
	  struct TimeSyncMsg * pdata = (struct TimeSyncMsg *)msg->data;

            call Leds.redToggle();

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

	return SUCCESS;
    }


  
}
