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


includes TimeSyncMsg;
includes TimeSync;
includes TosTime;
includes SendTime;

module DriftM {
    provides {
        interface StdControl;
    }
    uses {
        interface Time;
	interface TimeSet;
        interface TimeUtil;
        interface Leds;
	interface StdControl as TimeControl;
        interface SendMsg as SendTime;
        interface ReceiveMsg as TimeSyncReceive;
		interface ReceiveMsg as Receive;
	interface StdControl as CommControl;
    }
}
implementation
{
    bool state; 
    TOS_Msg RxBuffer, TxBuffer;
    TOS_MsgPtr pRx, pSend;
    bool sendPending;
    void sendSyncTask();
    tos_time_t t0, t1;

    task void debugTime() {
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
            // send the msg now
            sendPending = call SendTime.send(TOS_UART_ADDR, sizeof(struct TimeResp), pSend);
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
        tos_time_t tt;
        bool temp;

        struct TimeSyncMsg * pmsg= (struct TimeSyncMsg *)pRx->data;
	call Leds.greenToggle();
        // receiver side delay calculation
        delta =  TX_DELAY + 0x3DB8;
        tt.low32 = pmsg->timeL;
        tt.high32 = pmsg->timeH;
        if (tt.low32 +delta > tt.low32) {
	    tt.low32 += delta ;
	} else {
  	    tt.low32 += delta ;
	    tt.high32 ++;
	}
        call TimeSet.set(tt);
        // test code 
        temp = TOSH_interrupt_disable();
        t0 = tt ;
        if (temp) TOSH_interrupt_enable();
        post debugTime();
    }        

    /**
     * Receive a triggler message 
     * Record our current time, post debugTime task to send time out 
     * 
     **/

    event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
        call Leds.greenToggle();
        t0 = call Time.get();
        post debugTime();
        return msg;
    } 
	

    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
        call Leds.redToggle();
        sendPending = FALSE;
        return SUCCESS;
    } 

    command result_t StdControl.init() {
        sendPending = FALSE;
	pSend = &TxBuffer; 
	t1.high32 =0; t1.low32=0;
        if (TOS_LOCAL_ADDRESS==0) state= MASTER;
        else state = SLAVE_UNSYNCED;
        call CommControl.init();
        call TimeControl.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call CommControl.start() ;
        call TimeControl.start(); 

        return SUCCESS;
    }

 
    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
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

    event TOS_MsgPtr TimeSyncReceive.receive(TOS_MsgPtr msg) {
	pRx = msg; 
	timeSyncTask();
        return &RxBuffer; // keep msg and return the other buffer. 
    } 

}
