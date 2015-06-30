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
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Date last modified: jan05
 *
 * suggestions, contributions:  Barbara Hohlt
 *                              Janos Sallai
 */
includes Timer;
includes TimeSyncMsg;
includes trace;
module TimeSyncM
{
    provides 
    {
        interface StdControl;
        interface GlobalTime;
        
        //interfaces for extra fcionality: need not to be wired 
        interface TimeSyncInfo;
        interface TimeSyncMode;
        interface TimeSyncNotify;

        interface BluSH_AppI as tbl;
    }
    uses
    {
        interface SendMsg;
        interface ReceiveMsg;
        interface Timer;
        interface Leds;
        interface TimeStamping;
        interface SysTime64;
        command result_t ComputeByteOffset(uint8_t* lo, uint8_t* hi);
    }
}
implementation
{

    enum {
        MAX_ENTRIES = 8,        // number of entries in the table
        BEACON_RATE = TIMESYNC_RATE,    // how often send the beacon msg (in seconds)
        ROOT_TIMEOUT = 10,           //time to declare itself the root if no msg was received (in sync periods)
        IGNORE_ROOT_MSG = 4,    // after becoming the root ignore other roots messages (in send period)
        ENTRY_VALID_LIMIT = 8,      // number of entries to become synchronized
        ENTRY_SEND_LIMIT = 3,       // number of entries to send sync messages
        ENTRY_THROWOUT_LIMIT = 200
    };

    typedef struct TableItem {
        uint32_t    localLow;
        uint32_t    localHigh;
        uint32_t    globalLow; 
        uint32_t    globalHigh;
    } TableItem;

    TableItem   table[MAX_ENTRIES];
    uint8_t tableEntries;

    enum {
        STATE_IDLE = 0x00,
        STATE_PROCESSING = 0x01,
        STATE_SENDING = 0x02,
        STATE_INIT = 0x04,
    };

    uint8_t state, mode;
    uint8_t lastSeqNumSent;
    float calculatedPropagationTime;
    int16_t compensationPropagationTime;
    uint16_t syncPeriod, slowSyncPeriod, fastSyncPeriod;
    uint8_t syncCounter, syncCounter2, Nburst;
#define ROOT_ID 0xbb
/*
    We do linear regression from localTime to timeOffset (globalTime - localTime). 
    This way we can keep the slope close to zero (ideally) and represent it 
    as a float with high precision.
        
        timeOffset - offsetAverage = skew * (localTime - localAverage)
        timeOffset = offsetAverage + skew * (localTime - localAverage) 
        globalTime = localTime + offsetAverage + skew * (localTime - localAverage)
*/

    double       skew;
    uint32_t    localAverage;
    int32_t     offsetAverage;
    uint8_t     numEntries; // the number of full entries in the table 
    
    TOS_Msg processedMsgBuffer;
    TOS_MsgPtr processedMsg;

    TOS_Msg outgoingMsgBuffer;
    #define outgoingMsg ((TimeSyncMsg*)outgoingMsgBuffer.data)

    uint8_t heartBeats; // the number of sucessfully sent messages
                // since adding a new entry with lower beacon id than ours

    command BluSH_result_t tbl.getName(char *buff, uint8_t len){
        const char name[] = "tb";
        strcpy(buff,name);
        return BLUSH_SUCCESS_DONE;
    }

    command BluSH_result_t tbl.callApp(char *cmdBuff, uint8_t cmdLen,
                                              char *resBuff, uint8_t resLen){
        int i;
        uint32_t timeLow0, timeHigh0, timeLow1, timeHigh1;
        for (i=0; i<numEntries; i++) {
            trace(DBG_USR1,"%u\t%u\r\n",table[i].localLow,table[i].globalLow);
        }
        trace(DBG_USR1,"ROOT_ID=%x  TOS_LOCAL_ADDRESS=%x\r\n",ROOT_ID,TOS_LOCAL_ADDRESS);
        trace(DBG_USR1,"skew=%1.20e\r\n",skew);
        atomic {
        call GlobalTime.getLocalTime(&timeLow0,&timeHigh0);
        timeLow1=timeLow0; timeHigh1=timeHigh0;
        call GlobalTime.local2Global(&timeLow1,&timeHigh1);
        call GlobalTime.global2Local(&timeLow1,&timeHigh1);
        }
        trace(DBG_USR1,"TL0=%u TH0=%u TL1=%u TH1=%u\r\n",
              timeLow0,timeHigh0,timeLow1,timeHigh1);
        timeLow0 = call SysTime64.getTime32();
        call GlobalTime.local2Global(&timeLow1,&timeHigh1);
        timeHigh0 = call SysTime64.getTime32();
        trace(DBG_USR1,"local2Global takes %d cycles\r\n",timeHigh0-timeLow0);
        timeLow0 = call SysTime64.getTime32();
        call GlobalTime.global2Local(&timeLow1,&timeHigh1);
        timeHigh0 = call SysTime64.getTime32();
        trace(DBG_USR1,"global2Local takes %d cycles\r\n",timeHigh0-timeLow0);
        timeLow0 = call SysTime64.getTime32();
        call SysTime64.setAlarm(timeLow0+10000000);
        trace(DBG_USR1,"match register set @ time %u mr=%u\r\n",timeLow0,OSMR2);
        trace(DBG_USR1,"OIER = %x OIER_E1=%x OIER_E2=%x\r\n",OIER,OIER_E1,OIER_E2);
        return BLUSH_SUCCESS_DONE;
    }

    async event result_t SysTime64.alarmFired(uint32_t val) {
        uint32_t currentTime;
        currentTime = call SysTime64.getTime32();
        //call Leds.redToggle();
        trace(DBG_USR1, "match register interrupt @ time %u, oscr0=%u \r\n",currentTime,val);
    }

    async command result_t GlobalTime.getLocalTime(uint32_t *timeLow, uint32_t *timeHigh)
    {
        return call SysTime64.getTime64(timeLow, timeHigh);
    }

    async command result_t GlobalTime.getGlobalTime(uint32_t *timeLow, uint32_t *timeHigh)
    { 
        call GlobalTime.getLocalTime(timeLow, timeHigh);
        return call GlobalTime.local2Global(timeLow, timeHigh);
    }

    result_t is_synced()
    {
        return numEntries>=ENTRY_VALID_LIMIT || outgoingMsg->rootID==TOS_LOCAL_ADDRESS;
    }
    
    void calcSkew(double *skewptr, TableItem* tb, uint8_t n) {
        uint16_t numAdd;
        int32_t temp1, temp2;
        uint8_t i, j, weight;
        double beta;
        numAdd=0; beta=0;
        for (j=0; j<n; j++)
            for (i=j+1; i<n; i++) {
                weight = (i-j)*(i-j);
                temp1 = (int32_t)tb[i].globalLow-(int32_t)tb[j].globalLow;
                temp2 = (int32_t)tb[i].localLow-(int32_t)tb[j].localLow;
                beta +=  ((double) temp1/temp2 - 1)*weight; 
                numAdd += weight;
            }
        *skewptr = beta/numAdd;
    }

    void l2g(uint32_t *timeLow, uint32_t *timeHigh, TableItem* tb, uint8_t n, double beta) {
#define WRAP_FACTOR 4294967296.0
        uint32_t count=0;
        double d, gwrap, lwrap, gt, ltd, timeOffset;
        gwrap=tb[n-1].globalHigh*WRAP_FACTOR;
        lwrap=tb[n-1].localHigh*WRAP_FACTOR;
        timeOffset = (double)tb[n-1].globalLow - (double)tb[n-1].localLow +
            gwrap - lwrap;
        d = timeOffset-((double)tb[n-1].localLow*beta+lwrap*beta);
        ltd=(double)(*timeLow) + (*timeHigh)*WRAP_FACTOR; 
        gt = (ltd + beta*ltd + d + 0.5);
        while(gt>WRAP_FACTOR) {
            gt-=WRAP_FACTOR;
            count++;
        }
        *timeLow = (uint32_t) gt;
        *timeHigh = count;
    }

    void l2g_correct(uint32_t *timeLow, uint32_t *timeHigh, TableItem* tb, uint8_t n, 
                     double beta, int32_t delay) {
        uint32_t count=0;
        double d, gwrap, lwrap, gt, ltd, timeOffset;
        gwrap=tb[n-1].globalHigh*WRAP_FACTOR;
        lwrap=tb[n-1].localHigh*WRAP_FACTOR;
        timeOffset = (double)tb[n-1].globalLow - (double)tb[n-1].localLow +
            gwrap - lwrap;
        d = timeOffset-((double)tb[n-1].localLow*beta+lwrap*beta);
        ltd=(double)(*timeLow) + (*timeHigh)*WRAP_FACTOR + (double)delay; 
        gt = (ltd + beta*ltd + d + 0.5);
        while(gt>WRAP_FACTOR) {
            gt-=WRAP_FACTOR;
            count++;
        }
        *timeLow = (uint32_t) gt;
        *timeHigh = count;
    }

    void g2l_correct(uint32_t *timeLow, uint32_t *timeHigh, TableItem* tb, uint8_t n, 
             double beta, int32_t delay) {
        uint32_t count=0;
        double d, gwrap, lwrap, lt, gtd, timeOffset;
        gwrap=tb[n-1].globalHigh*WRAP_FACTOR;
        lwrap=tb[n-1].localHigh*WRAP_FACTOR;
        timeOffset = (double)tb[n-1].globalLow - (double)tb[n-1].localLow +
            gwrap - lwrap;
        d = timeOffset-((double)tb[n-1].localLow*beta+lwrap*beta);
        gtd=(double)(*timeLow) + (*timeHigh)*WRAP_FACTOR - (double)delay; 
        lt = (gtd - d )/(1.0+beta) + 0.5;
        while(lt>WRAP_FACTOR) {
            lt-=WRAP_FACTOR;
            count++;
        }
        *timeLow = (uint32_t) lt;
        *timeHigh = count;
    }

    void local2GlobalND(uint32_t *timeLow, uint32_t *timeHigh)
    {
        if (outgoingMsg->rootID != TOS_LOCAL_ADDRESS) {
            l2g(timeLow, timeHigh, table, numEntries, skew);
        }
    }

    async command result_t GlobalTime.local2Global(uint32_t *timeLow, uint32_t *timeHigh)
    {
        if (outgoingMsg->rootID != TOS_LOCAL_ADDRESS) {
            l2g_correct(timeLow, timeHigh, table, numEntries, skew, compensationPropagationTime);
        }
        return is_synced();
    }

    async command result_t GlobalTime.global2Local(uint32_t *timeLow, uint32_t *timeHigh)
    {
        if (outgoingMsg->rootID != TOS_LOCAL_ADDRESS) {
            g2l_correct(timeLow, timeHigh, table, numEntries, skew, compensationPropagationTime);
        }
        return is_synced();
    }

    void clearTable()
    {
        atomic numEntries = 0;
        //trace(DBG_USR1,"clearTable() called\r\n");
    }

    void addNewEntry(TimeSyncMsg *msg)
    {
        int8_t i;
        //uint32_t age, oldestTime = 0;
        int32_t timeErrorLow, timeErrorHigh;

        // clear table if the received entry is inconsistent
        timeErrorLow = msg->arrivalTime;
        timeErrorHigh = msg->arrivalTimeHigh;
        local2GlobalND(&timeErrorLow, &timeErrorHigh);
        timeErrorLow -= msg->sendingTime; 
        if( is_synced() &&
            (timeErrorLow > ENTRY_THROWOUT_LIMIT || timeErrorLow < -ENTRY_THROWOUT_LIMIT))
                clearTable();

        if (numEntries<MAX_ENTRIES) {
            //atomic {
                table[numEntries].localLow = msg->arrivalTime;
                table[numEntries].globalLow = msg->sendingTime;
                table[numEntries].localHigh = msg->arrivalTimeHigh;
                table[numEntries].globalHigh = msg->sendingTimeHigh;
                numEntries++;
                //}
        } else {
            //atomic {
                for (i=0; i<MAX_ENTRIES-1; i++) {
                    table[i].localLow = table[i+1].localLow;
                    table[i].globalLow = table[i+1].globalLow;
                    table[i].localHigh = table[i+1].localHigh;
                    table[i].globalHigh = table[i+1].globalHigh;
                }
                table[MAX_ENTRIES-1].localLow = msg->arrivalTime;
                table[MAX_ENTRIES-1].globalLow = msg->sendingTime;
                table[MAX_ENTRIES-1].localHigh = msg->arrivalTimeHigh;
                table[MAX_ENTRIES-1].globalHigh = msg->sendingTimeHigh;
                //}
        }

    }

    void task processMsg()
    {
        uint32_t receiveTime, receiveTimeHigh;
        float temp, dif;
        uint8_t *ptr, i;
        TimeSyncMsg* msg = (TimeSyncMsg*)processedMsg->data;
#define ALPHA 0.2
#define THRESHOLD_PROPAGATION_ERROR 1000
        /* trace (DBG_USR1,"processMsg msg->seqNum=%d outg->seqNum=%d\r\n", 
               msg->seqNum, outgoingMsg->seqNum);
               trace (DBG_USR1,"%x %x %d %d\r\n",msg->rootID,msg->nodeID,msg->seqNum,msg->isSynced);*/

        /*trace(DBG_USR1, "seqNum=%d lastSeqNum=%d lastparent=%x TOSLA=%x\r\n",
          msg->seqNum,lastSeqNumSent,msg->lastParent,TOS_LOCAL_ADDRESS);*/
        if (msg->seqNum==lastSeqNumSent && msg->lastParent==TOS_LOCAL_ADDRESS) {
            receiveTime = msg->arrivalTime; receiveTimeHigh = msg->arrivalTimeHigh;
            call GlobalTime.local2Global(&receiveTime, &receiveTimeHigh);
            temp = (receiveTime-(msg->sendingTime-msg->propagationTimeThisPacket))/2.0;
            //trace(DBG_USR1,"receiveTime=%d sendingTime=%d propThisPac=%d temp=%f\r\n",receiveTime,
            //msg->sendingTime,msg->propagationTimeThisPacket,temp);
            dif = calculatedPropagationTime-temp;
            if (dif<0)
                dif = -dif;
            if (dif>THRESHOLD_PROPAGATION_ERROR)
                calculatedPropagationTime=temp;
            else
                calculatedPropagationTime=(calculatedPropagationTime*(1-ALPHA)+temp*ALPHA);
            outgoingMsg->propagationTime=(int16_t)calculatedPropagationTime;
            //trace(DBG_USR1,"temp=%f dif=%f calcPropTime=%f\r\n",temp,dif,calculatedPropagationTime);
        }
        if (msg->isSynced==0) {
            syncCounter++;
            if (syncPeriod==slowSyncPeriod) {
                atomic syncPeriod = fastSyncPeriod;
                call Timer.stop();
                call Timer.start(TIMER_ONE_SHOT, (uint32_t)1000 * syncPeriod);
            }
        }

        //if ((ROOT_ID == TOS_LOCAL_ADDRESS) && ((int8_t)(msg->seqNum - outgoingMsg->seqNum) > 0)) {
        //    outgoingMsg->seqNum = msg->seqNum;
        //}

        if ((ROOT_ID != TOS_LOCAL_ADDRESS)&& (int8_t)(msg->seqNum - outgoingMsg->seqNum) > 0) {
            outgoingMsg->seqNum = msg->seqNum;
            outgoingMsg->lastParent = msg->nodeID;
            if (msg->syncPeriod > 0) {
                atomic {
                    syncPeriod = msg->syncPeriod;
                    outgoingMsg->syncPeriod = syncPeriod;
                }
                compensationPropagationTime = msg->propagationTime;
                /*
                ptr=msg;
                for (i=0;i<26;i++)
                    trace(DBG_USR1,"%x ",*ptr++);
                trace(DBG_USR1,"\r\n",*ptr++);
                trace(DBG_USR1,"receive propTime=%d\r\n",msg->propagationTime);
                */
            addNewEntry(msg);
            if (numEntries>3)
                calcSkew(&skew, table, numEntries);
            signal TimeSyncNotify.msg_received(); 
            }
        } 
        state &= ~STATE_PROCESSING;
    }

    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
    {
        uint32_t rxtimeLow, rxtimeHigh;
        TimeSyncMsg* ptr;

        if( (state & STATE_PROCESSING) == 0 ) {
            TOS_MsgPtr old = processedMsg;
            //trace (DBG_USR1,"TimeSync.receive\r\n");
            call Leds.greenToggle();
            processedMsg = p;
            ptr = (TimeSyncMsg*)(processedMsg->data);
            //#define TEST_MULTIHOP 1
#ifdef TEST_MULTIHOP
            if (TOS_LOCAL_ADDRESS == 0xa6 && ptr->nodeID != 0xbb && ptr->nodeID != 0xbe)
                return p; // make 0xa6 2 hops
            if (TOS_LOCAL_ADDRESS == 0xbe && ptr->nodeID != 0xa6 && ptr->nodeID != 0xb4)
                return p; // make 0xbe 3 hops
            if (TOS_LOCAL_ADDRESS == 0xb4 && ptr->nodeID != 0xbe)
                return p; // make 0xb4 4 hops
#endif
            call TimeStamping.getStamp(&rxtimeLow, &rxtimeHigh);
            ptr->arrivalTime = rxtimeLow;
            ptr->arrivalTimeHigh = rxtimeHigh;
            state |= STATE_PROCESSING;
            post processMsg();

            return old;
        }

        return p;
    }

#define ENOUGH_FAST_SYNCS 20
    task void sendMsg()
    {
        uint32_t localTime, localTimeHigh, globalTime, globalTimeHigh;
        uint8_t this_neighborhood_synced, lo, hi;
        uint8_t *ptr, i;
        
        call GlobalTime.getLocalTime(&localTime, &localTimeHigh);
        globalTime = localTime;  globalTimeHigh = localTimeHigh;
        call GlobalTime.local2Global(&globalTime, &globalTimeHigh);
        outgoingMsg->propagationTimeThisPacket=compensationPropagationTime;
        
        if (is_synced() == 0)
            this_neighborhood_synced = 0;
        else {
            if (syncCounter==0)
                this_neighborhood_synced = 1;
            else 
                if (syncCounter2<4) {
                    this_neighborhood_synced = 0;
                    syncCounter2=0;
                }
                else
                    this_neighborhood_synced = 1;
        }
        syncCounter2++;
        if (ROOT_ID==TOS_LOCAL_ADDRESS) {
            if (syncCounter>0)
                Nburst=0;
            atomic {
                if (Nburst>=ENOUGH_FAST_SYNCS)
                    syncPeriod = slowSyncPeriod;
                else {
                    syncPeriod = fastSyncPeriod;
                    Nburst++;
                }
                outgoingMsg->syncPeriod = syncPeriod;
            }
            outgoingMsg->isSynced = 1;
        } else
            outgoingMsg->isSynced = this_neighborhood_synced;
        syncCounter=0;

        outgoingMsg->sendingTime = globalTime - localTime;
        outgoingMsg->sendingTimeHigh = globalTimeHigh - localTimeHigh;

        /*ptr=outgoingMsg;
                for (i=0;i<26;i++)
                    trace(DBG_USR1,"%x ",*ptr++);
                trace(DBG_USR1,"\r\n",*ptr++);
                trace(DBG_USR1,"send propTime=%d  st=%d  sth=%d\r\n",
                      outgoingMsg->propagationTime, outgoingMsg->sendingTime, outgoingMsg->sendingTimeHigh);
        */
        if( call SendMsg.send(TOS_BCAST_ADDR, TIMESYNCMSG_LEN, &outgoingMsgBuffer) != SUCCESS ){
            state &= ~STATE_SENDING;
            signal TimeSyncNotify.msg_sent();
        }
        else {
            call ComputeByteOffset(&lo, &hi);
            call TimeStamping.addStamp2(&outgoingMsgBuffer, lo, hi);
            //call TimeStamping.addStamp2(&outgoingMsgBuffer, offsetof(TimeSyncMsg,sendingTime)+2,
            //                            offsetof(TimeSyncMsg,sendingTimeHigh)+2);
        }
    }
    
    event result_t SendMsg.sendDone(TOS_MsgPtr ptr, result_t success)
    {

        if (ptr != &outgoingMsgBuffer)
          return SUCCESS;

        if( success )
        {
            //trace (DBG_USR1,"TimeSync.sendDone\r\n");
            //call Leds.redToggle();
            lastSeqNumSent = outgoingMsg->seqNum;  
            if( ROOT_ID == TOS_LOCAL_ADDRESS ){
                if (syncPeriod == fastSyncPeriod)
                    (outgoingMsg->seqNum) = outgoingMsg->seqNum + 20;
                else
                    ++(outgoingMsg->seqNum);
            }
        }

        state &= ~STATE_SENDING;
        signal TimeSyncNotify.msg_sent();
        
        return SUCCESS;
    }

    void timeSyncMsgSend()  
    {
        if( (state & STATE_SENDING) == 0 ) {
            state |= STATE_SENDING;
            post sendMsg();
        }
    }

    event result_t Timer.fired()
    {
      if (mode == TS_TIMER_MODE)
        timeSyncMsgSend();
      else
        call Timer.stop();

        tableEntries = 0;

      call Timer.start(TIMER_ONE_SHOT,(uint32_t)1000 * syncPeriod);
      return SUCCESS;
    }

    command result_t TimeSyncMode.setMode(uint8_t mode_){
        if (mode == mode_)
            return SUCCESS;
            
        if (mode_ == TS_USER_MODE){
            if (call Timer.start(TIMER_ONE_SHOT, (uint32_t)1000 * syncPeriod) == FAIL)
                return FAIL;
        }
        else if (call Timer.stop() == FAIL)
            return FAIL;
            
        mode = mode_;
        return SUCCESS;        
    }
    
    command uint8_t TimeSyncMode.getMode(){
        return mode;
    }
    
    command result_t TimeSyncMode.send(){
        if (mode == TS_USER_MODE){
            timeSyncMsgSend();
            return SUCCESS;
        }
        return FAIL;
    }
    
    command result_t StdControl.init() 
    { 
        atomic{
            skew = 0.0;
            localAverage = 0;
            offsetAverage = 0;
        };

        clearTable();
        call Leds.init();
        outgoingMsg->rootID = ROOT_ID;
        outgoingMsg->seqNum = 2;
        outgoingMsg->lastParent = ROOT_ID;
        lastSeqNumSent = 0;
        
        processedMsg = &processedMsgBuffer;
        state = STATE_INIT;
        calculatedPropagationTime = 0;
        compensationPropagationTime = 0;
        outgoingMsg->propagationTime = calculatedPropagationTime;
        slowSyncPeriod = 10;
        fastSyncPeriod = 1;
        syncPeriod = fastSyncPeriod;
        syncCounter = 0; syncCounter2 = 4; Nburst=0;
        return SUCCESS;
    }

    command result_t StdControl.start() 
    {
        mode = TS_TIMER_MODE;
        heartBeats = 0;
        outgoingMsg->nodeID = TOS_LOCAL_ADDRESS;
        //if (ROOT_ID!=TOS_LOCAL_ADDRESS)
        //    outgoingMsg->reset = 1;
        call Timer.start(TIMER_ONE_SHOT, (uint32_t)1000 * syncPeriod);
                            
        return SUCCESS; 
    }

    command result_t StdControl.stop() 
    {
        call Timer.stop();
        return SUCCESS; 
    }

    async command float     TimeSyncInfo.getSkew() { return ((float)skew); }
    async command uint32_t  TimeSyncInfo.getOffset() { return offsetAverage; }
    async command uint32_t  TimeSyncInfo.getSyncPoint() { return localAverage; }
    async command uint16_t  TimeSyncInfo.getRootID() { return outgoingMsg->lastParent; }
    async command uint8_t   TimeSyncInfo.getSeqNum() { return outgoingMsg->seqNum; }
    async command uint8_t   TimeSyncInfo.getNumEntries() { return numEntries; } 
    async command uint8_t   TimeSyncInfo.getHeartBeats() { return heartBeats; }
    async command uint16_t   TimeSyncInfo.getSyncPeriod() { return syncPeriod; }


    default event void TimeSyncNotify.msg_received(){};
    default event void TimeSyncNotify.msg_sent(){};
}
