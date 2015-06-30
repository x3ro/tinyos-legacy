/*
* Copyright (c) 2014, Ege University, Izmir, Turkey & University of Padova, Padova, Italy
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
*   notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the
*   distribution.
* - Neither the name of the copyright holders nor the names of
*   its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
* THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* @author: K. Sinan YILDIRIM <sinanyil81@gmail.com>
*/
 
#include "TimeSyncMsg.h"
#include "PI.h"

generic module TimeSyncP(typedef precision_tag)
{
    provides
    {
        interface Init;
        interface StdControl;
        interface GlobalTime<precision_tag>;

        //interfaces for extra functionality: need not to be wired
        interface TimeSyncInfo;
        interface TimeSyncMode;
        interface TimeSyncNotify;
    }
    uses
    {
        interface Boot;
        interface SplitControl as RadioControl;
        interface TimeSyncAMSend<precision_tag,uint32_t> as Send;
        interface Receive;
        interface Timer<TMilli>;
        interface Random;
        interface Leds;
        interface TimeSyncPacket<precision_tag,uint32_t>;
        interface LocalTime<precision_tag> as LocalTime;

#ifdef LOW_POWER_LISTENING
        interface LowPowerListening;
#endif

    }
}
implementation
{
    enum {
        STATE_TIMEOUT           = 5, 
        ERROR_TIMEOUT           = 3, 
    };
   
    enum {
        STATE_IDLE = 0x00,
        STATE_PROCESSING = 0x01,
        STATE_SENDING = 0x02,
        STATE_INIT = 0x04,
        STATE_LISTEN = 0x08,
    };

    uint8_t state, mode;
           
    /* logical clock parameters */ 
    float       skew;
    uint32_t    clock;
    uint32_t	lastUpdate;
    /* --------------------------*/
      
    float currentAlpha = ALPHA_MAX; 
    int32_t lastError = 0;
    
    int32_t totalError  = 0;
    uint8_t numReceived = 0;

    message_t processedMsgBuffer;
    message_t* processedMsg;

    message_t outgoingMsgBuffer;
    TimeSyncMsg* outgoingMsg;

    uint8_t heartBeats; // the number of sucessfully sent messages
                        // since adding a new entry with lower beacon id than ours

    async command uint32_t GlobalTime.getLocalTime()
    {
        return call LocalTime.get();
    }

    async command error_t GlobalTime.getGlobalTime(uint32_t *time)
    {
        *time = call GlobalTime.getLocalTime();
        return call GlobalTime.local2Global(time);
    }
    
    async command error_t GlobalTime.local2Global(uint32_t *time)
    {
    	uint32_t timePassed = *time - lastUpdate;
        *time = clock + timePassed + (int32_t)(skew * (int32_t)(timePassed));
    
        return SUCCESS;
    }

    async command error_t GlobalTime.global2Local(uint32_t *time)
    {
        uint32_t globalTimePassed = *time - clock;
        *time = lastUpdate + (int32_t)((float)globalTimePassed/(skew+1.0f));

        return SUCCESS;
    }    

    void synchronize(int32_t error, uint32_t localTime)
    {
        float newSkew = skew;
        uint32_t newClock;                
                    
        if((lastError-error) != 0 && lastError != 0)
            currentAlpha *= (float)lastError/(float)(lastError - error);                
        
        currentAlpha = fabs(currentAlpha);
         
        if(currentAlpha > ALPHA_MAX)
            currentAlpha = ALPHA_MAX;
            
        newSkew += currentAlpha*((float)error);
        
        newClock = localTime;
        call GlobalTime.local2Global(&newClock);
        newClock += error;
         
        lastError = error;
                              
        /* update logical clock parameters */
        atomic{
          skew = newSkew;
          clock  = newClock;
          lastUpdate = localTime;
        }
    }
    
    uint8_t errorCount = 0;
    
    void setClock(TimeSyncMsg* msg){
        atomic{
            skew = 0.0f;
            clock  = msg->globalTime;
            lastUpdate = msg->localTime;
        }

        lastError = 0;
        totalError = 0;
        numReceived = 0;
        errorCount = 0;
    }

    void task processMsg()
    {
        int32_t timeError; 
        TimeSyncMsg* msg = (TimeSyncMsg*)(call Send.getPayload(processedMsg, sizeof(TimeSyncMsg)));
        
        timeError = msg->localTime;
        call GlobalTime.local2Global((uint32_t*)(&timeError));
        timeError = msg->globalTime-timeError;
        
        if((state & STATE_LISTEN) != 0 || (state & STATE_INIT) != 0){
            if(timeError > E_MAX){  // Jump to the max clock value
                setClock(msg);
            }
            else if(timeError > -E_MAX){
                totalError += timeError;
                numReceived++; 
            }
        }
        else if( (timeError < E_MAX) && (timeError > -E_MAX) ){
            totalError += timeError;
            numReceived++;            
        }
        else if(++errorCount > ERROR_TIMEOUT){
            if(timeError > E_MAX){
                state |= STATE_INIT;
                heartBeats = 0;
                setClock(msg);                
            }
            
            errorCount = 0;
        }
               
        call Leds.led0Toggle();

        signal TimeSyncNotify.msg_received();
        state &= ~STATE_PROCESSING;
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
    {    
        if( (state & STATE_PROCESSING) == 0
            && call TimeSyncPacket.isValid(msg)) {
            message_t* old = processedMsg;

            processedMsg = msg;
            ((TimeSyncMsg*)(payload))->localTime = call TimeSyncPacket.eventTime(msg);

            state |= STATE_PROCESSING;
            post processMsg();

            return old;
        }

        return msg;
    }
    
    task void sendMsg()
    {
        uint32_t localTime, globalTime;
        
        globalTime = localTime = call GlobalTime.getLocalTime();
              
        call GlobalTime.local2Global(&globalTime);
        
        outgoingMsg->globalTime = globalTime;
#ifdef LOW_POWER_LISTENING
        call LowPowerListening.setRemoteWakeupInterval(&outgoingMsgBuffer, LPL_INTERVAL);
#endif
        
        if( call Send.send(AM_BROADCAST_ADDR, &outgoingMsgBuffer, TIMESYNCMSG_LEN, localTime ) != SUCCESS ){
            state &= ~STATE_SENDING;
            signal TimeSyncNotify.msg_sent();
        }        	
    }

    event void Send.sendDone(message_t* ptr, error_t error)
    {
        if (ptr != &outgoingMsgBuffer) return;

        if(error == SUCCESS) call Leds.led1Toggle();

        state &= ~STATE_SENDING;
        signal TimeSyncNotify.msg_sent();
    }
    
    void timeSyncMsgSend()
    {
        if(++heartBeats > STATE_TIMEOUT){
            /* transition from LISTEN to INIT */
            if((state & STATE_LISTEN)!= 0){
                state &= ~STATE_LISTEN;
                state |= STATE_INIT;
                heartBeats = 0;
            }
            else if((state & STATE_INIT)!= 0){
                state &= ~STATE_INIT;
            }            
        }
        
        if( ( (state & STATE_SENDING) == 0) && ((state & STATE_LISTEN) == 0) ) {
            state |= STATE_SENDING;
            post sendMsg();
        }
    }

    event void Timer.fired()
    {                  
        /* synchronize :) */
        if(numReceived > 0)
            synchronize(totalError/numReceived,call GlobalTime.getLocalTime());
        
        numReceived = 0;
        totalError = 0;
        
        if (mode == TS_TIMER_MODE) {
            timeSyncMsgSend();
        }
        else
            call Timer.stop();
      
    }
    
    command error_t TimeSyncMode.setMode(uint8_t mode_){
        if (mode_ == TS_TIMER_MODE){
            call Timer.startPeriodic((uint32_t)(896U+(call Random.rand16()&0xFF)) * BEACON_RATE);
        }
        else
            call Timer.stop();

        mode = mode_;
        return SUCCESS;
    }

    command uint8_t TimeSyncMode.getMode(){
        return mode;
    }

    command error_t TimeSyncMode.send(){
        if (mode == TS_USER_MODE){
            timeSyncMsgSend();
            return SUCCESS;
        }
        return FAIL;
    }


    command error_t Init.init()
    {
        atomic{
            skew = 0.0;
            clock = 0;
            lastUpdate = 0;
        };

        atomic outgoingMsg = (TimeSyncMsg*)call Send.getPayload(&outgoingMsgBuffer, sizeof(TimeSyncMsg));
        outgoingMsg->rootID = 0xFFFF;

        processedMsg = &processedMsgBuffer;
        state = STATE_LISTEN;
              
        return SUCCESS;
    }

    event void Boot.booted()
    {
      call RadioControl.start();
      call StdControl.start();
    }

    command error_t StdControl.start()
    {
        heartBeats = 0;
        outgoingMsg->nodeID = TOS_NODE_ID;
        call TimeSyncMode.setMode(TS_TIMER_MODE);

        return SUCCESS;
    }

    command error_t StdControl.stop()
    {
        call Timer.stop();
        return SUCCESS;
    }
    
    async command float     TimeSyncInfo.getSkew() { return skew; }
    async command uint32_t  TimeSyncInfo.getOffset() { return clock; }
    async command uint32_t  TimeSyncInfo.getSyncPoint() { return lastUpdate; }
    async command uint16_t  TimeSyncInfo.getRootID() { return outgoingMsg->rootID; }
    async command uint8_t   TimeSyncInfo.getSeqNum() { return outgoingMsg->seqNum; }
    async command uint8_t   TimeSyncInfo.getNumEntries() { return 0; }
    async command uint8_t   TimeSyncInfo.getHeartBeats() { return heartBeats; }

    default event void TimeSyncNotify.msg_received(){}
    default event void TimeSyncNotify.msg_sent(){}

    event void RadioControl.startDone(error_t error){}
    event void RadioControl.stopDone(error_t error){}
}
