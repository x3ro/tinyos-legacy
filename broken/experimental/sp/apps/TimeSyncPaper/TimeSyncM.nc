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
 * Date last modified:  
 *
 */
/*
 * Meaning of Leds:
 *  TimeSync msg sent --- yellow
 *  TimeSync msg received --- green
 *
 */

includes TimeSyncMsg;
includes TimeSync;
module TimeSyncM {
    provides {
        interface TimeSync;
        interface StdControl;
    }
    uses {
        interface Time;
	interface TimeSet;
        interface TimeUtil;
        interface Leds;
	interface StdControl as TimeControl;
	interface SendMsg as SendSyncMsg;
        interface ReceiveMsg as TimeSyncReceive;
	interface StdControl as CommControl;
        interface RadioTiming ;
	interface AbsoluteTimer as AbsoluteTimer0;
        interface StdControl as AtimerControl;
    }
}
implementation
{
    //bool auto_correct ;
    bool forwardFlag;
    uint8_t state; 
    uint8_t level;
    TOS_Msg RxBuffer, TxBuffer;
    TOS_MsgPtr pRx, pSend;
    bool sendPending;
    uint32_t TSinterval;
    tos_time_t next;
    task void sendSyncTask();
    void timerStart();


    inline uint32_t abs(int32_t a) {
    	if (a>0) return a;
    	else return 0-a ;
    }
    /**
     * Receive a time sync message 
     * extract the time from the message
     * adjust the lst byte of time with message time stamp (msg->time)
     * set System time to the new value if in UNSNCED state
     * or adjust local time if syned before.
     **/

    void timeSyncTask( ) {
        uint16_t now;
        int32_t  delta;
        char temp;
        //struct TimeSyncMsg  msg;
        struct TimeSyncMsg * pmsg= (struct TimeSyncMsg *)pRx->data;
        temp = TOSH_interrupt_disable();
        // receiver side delay calculation
        now = call  RadioTiming.currentTime();
        if (now >= pRx->time)  delta = now - pRx->time;
        else delta = 0x10000 - pRx->time + now  ;
        // convert delta to us
        delta >>= 2;
        delta += TX_DELAY;
        if (pmsg->timeL +delta > pmsg->timeL) {
	        pmsg->timeL += delta ;
	    } else {
  	        pmsg->timeL += delta ;
	        pmsg->timeH++;
	    }
        call TimeSet.set(call TimeUtil.create(pmsg->timeH , pmsg->timeL));            
        state = SLAVE_SYNCED;
	if (temp) TOSH_interrupt_enable();
	call Leds.greenToggle();
    }        

    event result_t SendSyncMsg.sendDone(TOS_MsgPtr msg, result_t success) {
        call Leds.yellowToggle();
        dbg(DBG_USR1, "time sync msg sent\n");
        sendPending = FALSE;
        return SUCCESS;
    } 
    /**
     * send a time sync message
     **/
    command result_t TimeSync.sendSync() {
        TOS_MsgPtr pmsg = &TxBuffer;
        struct TimeSyncMsg * pdata;
        if (!sendPending) {
        pdata = (struct TimeSyncMsg *) pmsg->data;
	dbg(DBG_USR1, "TimeSync.sendSync\n");
        pdata->source_addr = TOS_LOCAL_ADDRESS;
        pdata-> level = level;
         // send the msg now
            sendPending = call SendSyncMsg.send(TOS_BCAST_ADDR, sizeof(struct TimeSyncMsg), pmsg);      
        }
            return SUCCESS;
    }  

    task void sendSyncTask() {
        call TimeSync.sendSync();
    }

    command result_t TimeSync.setInterval(uint32_t n) {
	TSinterval = n;
       	return SUCCESS;
    }

    command result_t TimeSync.setState(uint8_t s) {
	state = s;
	return SUCCESS;
    }

    /**
     * Initialize system time
     * Initialize communication leyer
     **/
    command result_t StdControl.init() {
        sendPending = FALSE;
        TSinterval = TIME_SYNC_INTERVAL; 
        if (TOS_LOCAL_ADDRESS==0) {
            state=MASTER;
            level =0;
        } else {
            state = SLAVE_UNSYNCED;
            level = 0xFF;
        }
        forwardFlag = FALSE;
        //auto_correct = FALSE;
        call CommControl.init();
        call TimeControl.init();
        call AtimerControl.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call CommControl.start() ;
        call TimeControl.start(); 
        call AtimerControl.start();

        dbg(DBG_USR1, "TimeSyncM.start: TSinterval= \%x\n", TSinterval);
	if (state == MASTER) {
            next = call Time.get();
            dbg(DBG_USR1, "TimeSyncM.start next = \%x\n", next.low32);
	    // get UTC time from base station
  	    // set our clock
	    // send time sync msg
	    //post sendSyncTask(); 
	    dbg(DBG_USR1, "TimeSyncM.start master send a time sync msg\n");
	    timerStart();
	}
        return SUCCESS;
    }

    void timerStart() {
	result_t retval; 
	next = call TimeUtil.addUint32(next, TSinterval);
        dbg(DBG_USR1, "TimeSyncM. timerStart next = \%x\n", next.low32);
	// start a timer so that we can periodically send time sync msg
	retval = call AbsoluteTimer0.set(next);
        if (retval) { dbg(DBG_USR1, "ATimer start successfully\n");
        } else {
            dbg(DBG_USR1, "ATimer start failed\n");
            //call Leds.redToggle();
        }
    }

    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
        //call AtimerControl.stop();
        call TimeControl.stop();
        return call CommControl.stop() ;
    }

    /** 
     *  Timer expired Event Handler 
     *   
     *  @return Alway return <code>SUCCESS</code>
     **/

    event result_t AbsoluteTimer0.fired() {
        //call Leds.greenToggle();
        dbg(DBG_USR1, "TimeSyncM.Timer.expired\n");
	// send another time sync msg
        post sendSyncTask();        
        // restart timer
        timerStart();
	return SUCCESS;	
    }


    /**
     * Receive a time sync message 
     * check the type field. if type is TIMESYNC_REQUEST
     * call TimeSync.timeSync
     * else if type is TIME REQUEST, send our current time back  
     * 
     **/

    event TOS_MsgPtr TimeSyncReceive.receive(TOS_MsgPtr msg) {
        TOS_MsgPtr p = pRx;
	pRx = msg; 
	    timeSyncTask();
        return p; // keep msg and return the other buffer. 
    } 

}
