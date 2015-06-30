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


includes TimeSyncMsg;
includes TimeSync;
includes TosTime;
includes SendTime;

module InitialSyncM {
    provides {
        interface StdControl;
        interface PassingTime;
    }
    uses {
        interface Time;
	interface TimeSet;
        interface TimeUtil;
        interface Leds;
	interface StdControl as TimeControl;
	interface SendMsg as SendSyncMsg;
        interface SendMsg as SendTime;
        interface ReceiveMsg as TimeSyncReceive;
	interface StdControl as CommControl;
        interface RadioTiming ;
	interface AbsoluteTimer as AbsoluteTimer0;
        interface StdControl as AtimerControl;
    }
}
implementation
{
    bool auto_correct ;
    bool state; 
    TOS_Msg RxBuffer, TxBuffer;
    TOS_MsgPtr pRx, pSend;
    bool sendPending;
    void sendSyncTask();
    tos_time_t t0, t1;

    task void debugTime() {
        int i=0, delay;
        bool temp;
        struct TimeResp *pdata;

        if (!sendPending) {
            pdata = (struct TimeResp *)pSend->data;
            pdata->source_addr = TOS_LOCAL_ADDRESS;
            dbg(DBG_USR1, "t=\%x, \%x\n", t0.high32, t0.low32);
            temp = TOSH_interrupt_disable();
            pdata->timeH = t0.high32;
            pdata->timeL = t0.low32;
            if (temp) TOSH_interrupt_enable();
            delay = TOS_LOCAL_ADDRESS<<8;
            while (i<delay) {
                i++;
            }
            // send the msg now
            sendPending = call SendTime.send(TOS_BCAST_ADDR, sizeof(struct TimeResp), pSend);
        }
    }


    inline uint32_t abd(uint32_t a, uint32_t b) {
    	if (a>b) return a-b;
    	else return b-a ;
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
        bool temp;

        struct TimeSyncMsg * pmsg= (struct TimeSyncMsg *)pRx->data;
	call Leds.greenToggle();
        // receiver side delay calculation
        now = call  RadioTiming.currentTime(); // currenTime is from 4 MHz timer1
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
        // test code 
        temp = TOSH_interrupt_disable();
        t0.low32 = pmsg->timeL;
        t0.high32 = pmsg->timeH;
        if (temp) TOSH_interrupt_enable();
        post debugTime();
    }        

    event result_t SendSyncMsg.sendDone(TOS_MsgPtr msg, result_t success) {
        call Leds.greenToggle();
        dbg(DBG_USR1, "time sync msg sent\n");
        sendPending = FALSE;
        // read time and send it out
        t0 = call Time.get();
        post debugTime();
        return SUCCESS;
    } 

    command void PassingTime.pass(tos_time_t t) {
        bool temp;
        temp = TOSH_interrupt_disable();
        t0 = t;
        if (temp) TOSH_interrupt_enable();
        //post debugTime();
    }

    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
        call Leds.redToggle();
        sendPending = FALSE;
        if( ! success && TOS_LOCAL_ADDRESS) {
            // resend time         
            post debugTime();
	}
        return SUCCESS;
    } 
    /**
     * send a time sync message
     **/
    void sendSyncTask() {
        TOS_MsgPtr pmsg = &TxBuffer;
        tos_time_t tt;
        struct TimeSyncMsg * pdata = (struct TimeSyncMsg *) pmsg->data;
	dbg(DBG_USR1, "InitalSync.sendSync\n");
        pdata->source_addr = TOS_LOCAL_ADDRESS;
        if ( state == MASTER)
        tt = call Time.get();
        pdata->timeH = tt.high32;
	pdata->timeL = tt.low32 ;
        pdata->phase = call Time.getUs();
        call Leds.yellowToggle();
         // send the msg now
        if (!sendPending) {
            sendPending = call SendSyncMsg.send(TOS_BCAST_ADDR, sizeof(struct TimeSyncMsg), pmsg);      
        }
       
    }  

    command result_t StdControl.init() {
        sendPending = FALSE;
	pSend = &TxBuffer; 
	t1.high32 =0; t1.low32=0;
        if (TOS_LOCAL_ADDRESS==0) state= MASTER;
        else state = SLAVE_UNSYNCED;
        call CommControl.init();
        call TimeControl.init();
	call AtimerControl.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call CommControl.start() ;
        call TimeControl.start(); 
	call AtimerControl.start();

	if (state == MASTER) {
            call TimeSet.set(t1);
            t1 = call TimeUtil.addUint32(t1, 0x400000);
	    call AbsoluteTimer0.set(t1);
            sendSyncTask();
	}
        return SUCCESS;
    }

 
    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
        call TimeControl.stop();
        return call CommControl.stop() ;
    }

    void timerStart() {
	result_t retval; 
	t1 = call TimeUtil.addUint32(t1, 0x400000);// 2 seconds interval 
        
	// start a timer so that we can periodically send time sync msg
	retval = call AbsoluteTimer0.set(t1);
        if (retval) dbg(DBG_USR1, "ATimer start successfully\n");
        else {
            dbg(DBG_USR1, "ATimer start failed\n");
            call Leds.redToggle();
        }
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
        sendSyncTask();        
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
	pRx = msg; 
	timeSyncTask();
        return &RxBuffer; // keep msg and return the other buffer. 
    } 

}
