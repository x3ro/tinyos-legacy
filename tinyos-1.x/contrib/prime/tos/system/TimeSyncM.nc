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
