/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/**                  
 * Description
 *
 * @author Konrad Lorincz
 * @version 1.0, April 25, 2005
 */
#include "PrintfUART.h"
#include "MultiChanSampling.h"
#include "MercurySampling.h"
#include "SamplingToDataStore.h"
#include "SampleChunk.h"
//#include "DataStore.h"
#include "SamplingMsg.h"
#include "DriverMsgs.h"
#include "ErrorToLeds.h"
 
module DriverM                                        
{
    provides interface StdControl;

    uses interface Leds;
    uses interface LocalTime;
    uses interface Timer as Timer_Heartbeat;
    uses interface Timer as Timer_MoteTurnedOn;
    uses interface Timer as Timer_DataCollection;
    uses interface Timer as Timer_StopDataCollection;
    uses interface SendMsg;
    uses interface ReceiveMsg;
    uses interface MultiChanSampling as Sampling;
    uses interface DataStore;
    uses interface ErrorToLeds;
    uses interface GlobalTime;

#ifdef PLATFORM_SHIMMER
    uses interface GyroIDG300;
    uses interface MMA7260_Accel;
#endif
}
implementation
{
    // ========================= Data =========================
    uint32_t LOCAL_TIME_RATE_HZ = 32768L;
    //enum {TIMER_INTERVAL = 10000L};
    //uint16_t cntTimerFired = 0;

    TOS_Msg tosSendMsg;
    //SamplingMsg*  samplingMsgPtr;
    bool tosSendMsgBusy = FALSE;

    TOS_Msg tosRecvMsg;
    bool tosRecvMsgBusy = FALSE;

 
//     void errorToLeds(uint8_t errValue);
//     void sendMsg(TOS_Msg *sendMsgPtr, uint16_t sendAddr, uint8_t dataSize);


    // ========================= Methods =========================
    command result_t StdControl.init()
    {
        printfUART_init();

        atomic {
            tosSendMsgBusy = FALSE;
        }
#ifdef PLATFORM_SHIMMER
        // Puts the Bluetooth radio in low power mode (essentially off)
        TOSH_CLR_BT_RESET_PIN();
        call GyroIDG300.init();
#endif
        return call Leds.init();        
    }

    command result_t StdControl.start()
    {
        result_t result = call DataStore.init();
#ifdef PLATFORM_SHIMMER
        call MMA7260_Accel.setSensitivity(RANGE_4_0G);
#endif
        call Timer_Heartbeat.start(TIMER_REPEAT, HEARTBEAT_PERIOD); 
        call Timer_MoteTurnedOn.start(TIMER_REPEAT, 500);
        return result;        
    }

    command result_t StdControl.stop()
    {
        return SUCCESS;
    }

    event void DataStore.initDone(result_t result)
    {
        if (result == SUCCESS) {
            printfUART("FetchM: DataStore.initDone() - success\n", "");
            //call Sampling.startSampling(MERCURY_CHANS, MERCURY_NBR_CHANS, MERCURY_SAMPLING_RATE);
        }
        else {
            printfUART("DriverM: DataStore.initDone() - FAILED!\n", "");
        }
    }

#ifdef PLATFORM_SHIMMER
    event void GyroIDG300.initDone(result_t result)
    {
        if (result == SUCCESS)
            call GyroIDG300.enable();
    }
#endif
    
    task void sendStatusMsg()
    {
        ReplyMsg *replyMsgPtr = (ReplyMsg*) &(tosSendMsg.data);
        StatusReply *srPtr = (StatusReply*) &replyMsgPtr->data.status;
        result_t isSynced = FAIL;
        
        // (1) - Get the lock
        atomic {
            if (tosSendMsgBusy)
                return;
            else
                tosSendMsgBusy = TRUE;
        }

        // (2) - Fill in the status reply msg
        replyMsgPtr->srcAddr = TOS_LOCAL_ADDRESS;
        replyMsgPtr->type = REPLYMSG_TYPE_STATUS;

        // status part
        srPtr->systemStatus = 0;
        if (call Sampling.isSampling())
            srPtr->systemStatus |= (1 << SYSTEM_STATUS_BIT_ISSAMPLING);

        srPtr->localTime =  call GlobalTime.getLocalTime(); //call LocalTime.read();
        isSynced = call GlobalTime.getGlobalTime(&(srPtr->globalTime));  // set to 0 until we implement GlobalTime (most likely FTSP)

        if (isSynced)
            srPtr->systemStatus |= (1 << SYSTEM_STATUS_BIT_ISTIMESYNCED);

        call DataStore.getAvailableBlocks(&srPtr->tailBlockID, &srPtr->headBlockID);
        srPtr->dataStoreQueueSize = call DataStore.getQueueSize();

        // (3) - Send the ReplyMsg
        if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(ReplyMsg), &tosSendMsg) == FAIL) {
            atomic tosSendMsgBusy = FALSE;
            printfUART("DriverM:sendStatusMsg() - ERROR! Can't place msg on send buffer! msgAddr= 0x%x\n", &tosSendMsg);
        }                     
    }

    event result_t SendMsg.sendDone(TOS_MsgPtr msgPtr, result_t sendResult)
    {
        atomic tosSendMsgBusy = FALSE;
        if (sendResult == SUCCESS) { // message sent succesfully
        }
        else {
            printfUART("DriverM:SendMsg.sendDone() - ERROR! msg TX FAILED, msgAddr= 0x%x\n", msgPtr);
        }
    
        //call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DRIVER2);

        return sendResult;
    }


    event result_t Timer_Heartbeat.fired()
    {
        if (!post sendStatusMsg()) { // ignore post fail            
        }
        return SUCCESS;
    }

    event result_t Timer_MoteTurnedOn.fired()
    {
        static uint8_t cntFired = 0;

        if (++cntFired <= 5)
            call Leds.greenToggle();
        else {
            call Leds.greenOff();
            call Timer_MoteTurnedOn.stop();
            cntFired = 0;
        }

        return SUCCESS;
    }

    event result_t Timer_DataCollection.fired()
    {
        static bool isLedOff = TRUE;

        if (isLedOff == TRUE) {
            call Leds.orangeOn();
            isLedOff = FALSE;
            call Timer_DataCollection.start(TIMER_ONE_SHOT, 100); 
        }
        else {
            call Leds.orangeOff();
            isLedOff = TRUE;
            call Timer_DataCollection.start(TIMER_ONE_SHOT, 10240);
        }

        return SUCCESS;
    }

    event result_t Timer_StopDataCollection.fired()
    {
        static uint8_t cntFired = 0;

        if (++cntFired <= 5)
            call Leds.orangeToggle();
        else {
            call Leds.orangeOff();
            call Timer_StopDataCollection.stop();
            cntFired = 0;  // incase we restart data collection
        }

        return SUCCESS;
    }


    task void handleRecvMsg() 
    {
        RequestMsg *requestMsgPtr = (RequestMsg*) &(tosRecvMsg.data);
        //ReplyMsg *replyMsgPtr = (ReplyMsg*) &(tosSendMsg.data);

        printfUART("DriverM: handleRecvMsg() - type= %i\n", requestMsgPtr->type);

        // (1) - Do the type specific things
        if (requestMsgPtr->type == REQUESTMSG_TYPE_STATUS) {
            // nothing special to do, we're always sending a status msg as the reply
        }
        else if (requestMsgPtr->type == REQUESTMSG_TYPE_STARTSAMPLING) {
            if (call Sampling.isSampling() == TRUE) { // already sampling, so do nothing                
            }
            else {
                call Sampling.startSampling(MERCURY_CHANS, MERCURY_NBR_CHANS, MERCURY_SAMPLING_RATE);
                call Timer_DataCollection.start(TIMER_ONE_SHOT, 10);
            }
        }
        else if (requestMsgPtr->type == REQUESTMSG_TYPE_STOPSAMPLING) {
            if (call Sampling.isSampling() == TRUE) {
                call Sampling.stopSampling();
                call DataStore.saveInfo();
                call Timer_DataCollection.stop();
                call Leds.orangeOff();
                call Timer_StopDataCollection.start(TIMER_REPEAT, 500); 
            }
            else { // already stopped, so do nothing
            }
        }
        else if (requestMsgPtr->type == REQUESTMSG_TYPE_RESETDATASTORE) {
            call DataStore.reset();
        }
        else {
            // Ignore -- bad request ID
            atomic tosRecvMsgBusy = FALSE;
            printfUART("ProcessCmdM: handleRecvMsg() - WARNING, unknown request type= %i\n", requestMsgPtr->type);            
            call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DRIVER1);
            return;
        }


        // (2) - Always reply with a StatusMsg, for all requests.
        atomic tosRecvMsgBusy = FALSE;
        if (!post sendStatusMsg()) {  // ignore post fail
        }                
    }


    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr tosMsgPtr)
    {
        atomic {
            if (tosRecvMsgBusy == FALSE) {
            	if (post handleRecvMsg()) {
                    tosRecvMsgBusy = TRUE;
                    memcpy(&tosRecvMsg, tosMsgPtr, sizeof(TOS_Msg));
                }
                // ignore post fail
            }
        }
        return tosMsgPtr;
    }



    event void Sampling.dataReady(sample_t samples[], uint8_t nbrChannels, result_t result) 
    {
    }

    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        return result;
    }              

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        return result;
    }

    /**
     * Used for Debugging - turns on the leds corresponding to the parameter and exits the program
     * @param errValue, the value to display on the leds (in binary)
     */
    void errorToLeds(uint8_t errValue)
    {
        atomic {
            if (errValue & 1) call Leds.redOn();
            else call Leds.redOff();
            if (errValue & 2) call Leds.greenOn();
            else call Leds.greenOff();
            if (errValue & 4) call Leds.yellowOn();
            else call Leds.yellowOff();

            printfUART("errorToLeds() - FATAL ERROR! errValue= %i\n", errValue);
            exit(1);
        }
    }
}
