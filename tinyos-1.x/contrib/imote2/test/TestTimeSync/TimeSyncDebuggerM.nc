/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti, Brano Kusy
 * Date last modified: 03/17/03
 */

includes Timer;
includes TestTimeSyncPollerMsg;
includes trace;
includes TimeReportMsg;

module TimeSyncDebuggerM
{
    provides
        interface StdControl;
    uses
    {
        interface GlobalTime;
        interface TimeSyncInfo;
        interface ReceiveMsg;
#ifdef TIMESYNC_DIAG_POLLER
        interface DiagMsg;
#else
        interface SendMsg;
#endif
        interface Timer;
        interface Leds;
        interface TimeStamping;
    }
}

implementation
{
    TOS_Msg msg;
    /*struct data_t{
        uint16_t    nodeID;
        uint16_t    msgID;
        uint32_t    globalClock;
        uint32_t    localClock;
        float       skew;
        uint8_t     is_synced;
        uint8_t     dumb_padding;
        uint16_t    rootID;
        uint8_t     seqNum;
        uint8_t     numEntries;
    } data_t;

    struct data_t d;*/

    bool reporting;

    command result_t StdControl.init() {
        call Leds.init();
        reporting = FALSE;
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call Timer.start(TIMER_REPEAT, 11000);
        return call Timer.start(TIMER_REPEAT, 11000);    // every three seconds
    }

    command result_t StdControl.stop() {
        return call Timer.stop();
    }

    task void report() {
        if( reporting )
        {
#ifdef TIMESYNC_DIAG_POLLER
            if( call DiagMsg.record() == SUCCESS ){
                call DiagMsg.uint16(d.nodeID);
                call DiagMsg.uint16(d.msgID);
    
                call DiagMsg.uint32(d.globalClock);
                call DiagMsg.uint32(d.localClock);
                
                call DiagMsg.real(d.skew);
                call DiagMsg.uint8(d.is_synced);
    
                call DiagMsg.uint16(d.rootID);
                call DiagMsg.uint8(d.seqNum);
    
                call DiagMsg.uint8(d.numEntries);
    
                call DiagMsg.send();
            }
            reporting = FALSE;
#else
            //trace(DBG_USR1,"Trying to report\r\n");
            //memcpy( msg.data,&d,sizeof(data_t));
            if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(TimeReportMsg), &msg)){
                if(!post report())
                    reporting = FALSE;  
            }
#endif            
        }
    }

#ifndef TIMESYNC_DIAG_POLLER    
    event result_t SendMsg.sendDone(TOS_MsgPtr ptr, result_t success){
        //trace(DBG_USR1,"Reporting done\r\n");
        reporting = FALSE;
        return SUCCESS;
    }
#endif    
    
    event result_t Timer.fired() {
        if( reporting )
            post report();
        return SUCCESS;
    }

    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
    {
        TimeReportMsg* ptr;
        uint32_t tLow, tHigh;
        ptr = (TimeReportMsg*) (&msg.data[0]);
        call TimeStamping.getStamp(&tLow, &tHigh);
        ptr->localClock =  tLow;
        ptr->localClockHigh = (uint8_t) (tHigh & 0xff);
        //call Leds.redToggle();

        if( !reporting )
        {
            ptr->nodeID = TOS_LOCAL_ADDRESS;
            ptr->msgID = ((TimeSyncPoll*)(p->data))->msgID;

            ptr->is_synced = call GlobalTime.local2Global(&tLow, &tHigh);
            ptr->globalClock = tLow;
            ptr->globalClockHigh = (uint8_t) (tHigh & 0xff);
    
            ptr->skew = call TimeSyncInfo.getSkew();
            ptr->rootID = call TimeSyncInfo.getRootID();
            ptr->seqNum = call TimeSyncInfo.getSeqNum();
            ptr->numEntries = call TimeSyncInfo.getNumEntries();
            ptr->syncPeriod = call TimeSyncInfo.getSyncPeriod();
            //trace(DBG_USR1, "LC=%x  GC=%u  MID=%d\r\n", ptr->localClock,
            //      ptr->globalClock, ptr->msgID);
            /*            d.nodeID = TOS_LOCAL_ADDRESS;
            d.msgID = ((TimeSyncPoll*)(p->data))->msgID;

            d.localClock = call TimeStamping.getStamp();
            d.globalClock = d.localClock;
            d.is_synced = call GlobalTime.local2Global(&d.globalClock);
                
            d.skew = call TimeSyncInfo.getSkew();
            d.rootID = call TimeSyncInfo.getRootID();
            d.seqNum = call TimeSyncInfo.getSeqNum();
            d.numEntries = call TimeSyncInfo.getNumEntries();*/
            reporting = TRUE;
        }

        return p;
    }
 }
