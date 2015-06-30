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

includes TimeSyncMsg;

module TimeSyncM {
    provides {
        interface TimeSync;
        interface TimeSyncCtrl;
    }
    uses {
	interface LogicTime;
	interface SendMsg as SendSyncMsg;
	interface StdControl as CommControl;
    }
}
implementation
{
    uint32_t interval ;
    bool auto_correct ;
    bool state; 
    TOS_Msg buffer;
    bool sendPending;

    /**
     * Receive a time sync message 
     * extract the time from the message
     * adjust the lst byte of time with message time stamp (msg->time)
     * set System time to the new value.
     **/

    command TOS_MsgPtr TimeSync.timeSync(TOS_MsgPtr msg) {
        uint16_t now, delta;
        uint16_t offset=0; //  fixed offset to tx 11.5 byte start symbel
                            
        struct TimeSyncMsg * pmsg= (struct TimeSyncMsg *)msg->data;
        // receiver side delay calculation
        now = call  LogicTime.currentTime();
        if (now >= msg->time)  delta = now - msg->time;
        else delta = 0x10000 + now - msg->time ;
        call LogicTime.set(pmsg->timeH + delta + offset);
        //call LogicTime.set(pmsg->timeH);
        return msg ;
    }        
    event result_t SendSyncMsg.sendDone(TOS_MsgPtr msg, result_t success) {
        if (msg == &buffer) sendPending = FALSE;
        return SUCCESS;
    } 
    /**
     * send a time sync message
     **/
    command result_t TimeSync.sendSync() {
        
        TOS_MsgPtr pmsg = &buffer;
        struct TimeSyncMsg * pdata = (struct TimeSyncMsg *) pmsg->data;
        pdata->source_addr = TOS_LOCAL_ADDRESS;
        pdata->sub_type = TIMESYNC_REQUEST;
        pdata->timeH = call LogicTime.get();
        pmsg->type = AM_TIMESYNCMSG; 
        // send the msg now
        if (!sendPending) {
        sendPending = call SendSyncMsg.send(TOS_BCAST_ADDR, sizeof(struct TimeSyncMsg), pmsg);        
        return SUCCESS;
        }
        return FAIL;
    }  

    /**
     * Initialize system time
     * Initialize communication leyer
     **/
    command result_t TimeSync.init() {
        sendPending = FALSE;
        interval = 0;
        if (TOS_LOCAL_ADDRESS==1) state= MASTER;
        else state = SLAVE_UNSYNCED;
        auto_correct = FALSE;
        call CommControl.init();
        call LogicTime.init();
        return SUCCESS;
    }

}
