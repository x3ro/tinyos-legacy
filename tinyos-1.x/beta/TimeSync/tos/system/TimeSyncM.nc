// $Id: TimeSyncM.nc,v 1.2 2003/10/07 21:45:29 idgay Exp $

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
/*
 * Meaning of Leds:
 *  TimeSync msg sent --- yellow
 *  Timer fired       --- green
 *  Error when restart timer --- red
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
        //interface RadioTiming ;
	interface Timer as Timer0;
    }
}
implementation
{
    uint8_t state; 
    uint8_t level;
    uint8_t staleCounter;
    bool sendPending;
    bool one_shot;
    TOS_Msg RxBuffer, TxBuffer;
    TOS_MsgPtr pRx, pSend;
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
        tos_time_t tt, localTime, diff; 
                            
        struct TimeSyncMsg * pmsg= (struct TimeSyncMsg *)pRx->data;
        atomic {
        tt.low32 = pmsg->timeL;
        tt.high32 = pmsg->timeH;
	if (level&0x1) tt.low32 +=16;
        else tt.low32 += 17 ;
        if (tt.low32 < pmsg->timeL)   tt.high32 ++;     
        if (state==SLAVE_UNSYNCED) {
            call TimeSet.set(tt);
            state = SLAVE_SYNCED;
            level = pmsg->level +1;
            // start watchdog timer
            staleCounter =0;
        } else if (state==SLAVE_SYNCED) {
            if ( pmsg->level < level)  {
                // reset staleCounter 
                staleCounter = 0;
                localTime = call Time.get();
                diff = call TimeUtil.subtract( tt, localTime);
                if ((diff.high32!=0) || (diff.low32 > TIME_MAX_ERR)) {
                    call TimeSet.set(tt);
                    level = pmsg->level +1;
                } else {
                    call TimeSet.adjustNow(diff.low32);
                    level = pmsg->level +1;
                }
            } 
        } 
        } // atomic
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
        tos_time_t tt;
        struct TimeSyncMsg * pdata = (struct TimeSyncMsg *) pmsg->data;
	dbg(DBG_USR1, "TimeSync.sendSync\n");
        if (!sendPending) {
            tt = call Time.get();
            pdata->source_addr = TOS_LOCAL_ADDRESS;
            pdata-> level = level;
            pdata->timeL = tt.low32;
            // send the msg now
            sendPending = call SendSyncMsg.send(TOS_BCAST_ADDR, sizeof(struct TimeSyncMsg), pmsg);      
            return SUCCESS;
        }
        return FAIL;
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
        if (TOS_LOCAL_ADDRESS==1) {
            state=MASTER;
            level =0;
        } else {
            state = SLAVE_UNSYNCED;
            level = 0xFF;
        }
        staleCounter = 0;
        call TimeControl.init();
        call CommControl.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {
        uint8_t retval;
        call TimeControl.start(); 
        call CommControl.start();
        dbg(DBG_USR1, "TimeSyncM.start: TSinterval= \%x\n", TSinterval);
        if (state == MASTER) {
	    // get UTC time from base station
  	    // set our clock
        }
        one_shot = TRUE;
	// start a one-shot timer to let clock stablize
        //  and to avoid collision in the following time sync cycle
        retval = call Timer0.start(TIMER_ONE_SHOT, TOS_LOCAL_ADDRESS<<5);
        if (retval != SUCCESS) {
            dbg(DBG_USR1, "TimeSyncM: failed to start one_shot Timer0\n");
            return FAIL;
        }
        return SUCCESS;
    }


    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
        //call TimeControl.stop();
        if (state!=MASTER) {
            state = SLAVE_UNSYNCED;
            level = 0xff;
        }
        return call CommControl.stop() ;
        return SUCCESS;
    }

    /** 
     *  Timer expired Event Handler 
     *   
     *  @return Alway return <code>SUCCESS</code>
     **/

    event result_t Timer0.fired() {
        uint8_t retval;
        if (one_shot) {
            one_shot=0;
	    retval = call Timer0.start(TIMER_REPEAT, TSinterval);
            if (retval != SUCCESS) {
                dbg(DBG_USR1, "TimeSyncM: failed to start Timer0\n");
                return FAIL;
            }
        } else {
            if (state == MASTER) {
                post sendSyncTask();
                return SUCCESS;
            }
            if (++staleCounter >3) { 
                // we missed 3 time sync msg, change state to unsynced.
                state = SLAVE_UNSYNCED; 
                level = 0xff;
            } else {
                post sendSyncTask();        
            }
        }
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
        call Leds.yellowToggle();
        return p; // keep msg and return the other buffer
    } 

}
