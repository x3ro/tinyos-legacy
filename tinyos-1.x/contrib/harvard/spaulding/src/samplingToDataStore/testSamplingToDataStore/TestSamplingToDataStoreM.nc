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
#include "DataStore.h"
#include "SamplingMsg.h"
#include "ErrorToLeds.h"

module TestSamplingToDataStoreM                                        
{
    provides interface StdControl;

    uses interface Leds;
    uses interface Timer;
    uses interface SendMsg;
    uses interface MultiChanSampling as Sampling;
    uses interface DataStore;
    uses interface ErrorToLeds;
}
implementation
{
    // ---------- Data ----------
    uint32_t LOCAL_TIME_RATE_HZ = 32768L;
    enum {TIMER_INTERVAL = 10000L};
    uint16_t cntTimerFired = 0;

    TOS_Msg tosMsg;
    SamplingMsg*  samplingMsgPtr;
    bool isSendingBlock = FALSE;    

    Block blockBuff;
    SampleChunk *scPtr;
    uint16_t nextSampleToSend = 0;


    void errorToLeds(uint8_t errValue);
    void sendMsg(TOS_Msg *sendMsgPtr, uint16_t sendAddr, uint8_t dataSize);

    void debugPrintParams()
    {
        printfUART("-------- debugPrintParams() ---------\n", "");
        printfUART("    BLOCK_DATA_SIZE= %i\n", (uint16_t) BLOCK_DATA_SIZE);
        printfUART("    sizeof(Block)= %i\n", (uint16_t) sizeof(Block));
        printfUART("    DS_NBR_BLOCKS_PER_VOLUME= %i\n", (uint16_t) DS_NBR_BLOCKS_PER_VOLUME);         
        printfUART("    DS_NBR_VOLUMES= %i\n", (uint16_t) DS_NBR_VOLUMES);         
        printfUART("    DS_NBR_BLOCKS= %i\n", (uint16_t) DS_NBR_BLOCKS);  
        
        printfUART("\n    sizeof(SampleChunk)= %i\n", (uint16_t) sizeof(SampleChunk));
        printfUART("    MCS_MAX_NBR_CHANNELS_SAMPLED= %i\n", (uint16_t) MCS_MAX_NBR_CHANNELS_SAMPLED);  
        //printfUART("    NBR_CHANS_SAMPLED= %i\n", (uint16_t) NBR_CHANS_SAMPLED);  
        //printfUART("    NBR_SAMPLES_PER_CHUNK= %i\n", (uint16_t) NBR_SAMPLES_PER_CHUNK);                         

        printfUART("\n    sizeof(uint32_t)= %i\n", (uint16_t) sizeof(uint32_t));                         
        printfUART("    sizeof(channelID_t)= %i\n", (uint16_t) sizeof(channelID_t));                         
        printfUART("    sizeof(sample_t)= %i\n", (uint16_t) sizeof(sample_t));
        printfUART("-------------------------------------\n", "");
    }


    command result_t StdControl.init()
    {
        printfUART_init();
        atomic {
            isSendingBlock = FALSE;
            nextSampleToSend = 0;
            samplingMsgPtr = (SamplingMsg*) &(tosMsg.data);
            scPtr = (SampleChunk*) blockBuff.data;                     
        }
        return call Leds.init();        
    }

    command result_t StdControl.start()
    {
        result_t result;
        debugPrintParams();

        result = call DataStore.init();
        printfUART("DriverM: StdControl.start() - result= %i, DataStore.init()\n", result);
        //call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);    
        return result;        
    }

    command result_t StdControl.stop()
    {
        return SUCCESS;
    }

    event void DataStore.initDone(result_t result)
    {
        if (result == SUCCESS) {
            printfUART("DriverM: DataStore.initDone() - success\n", "");
            call Sampling.startSampling(MERCURY_CHANS, MERCURY_NBR_CHANS, MERCURY_SAMPLING_RATE);
        }
        else {
            printfUART("DriverM: DataStore.initDone() - FAILED!\n", "");
        }
    }

    event result_t Timer.fired()
    {
        sendMsg(&tosMsg, TOS_BCAST_ADDR, sizeof(SamplingMsg));        
        return SUCCESS;
    }


    void sendMsg(TOS_Msg *sendMsgPtr, uint16_t sendAddr, uint8_t dataSize)
    {   
        call Leds.yellowOn();

        if ( call SendMsg.send(sendAddr, dataSize, sendMsgPtr) ) {
            // send SUCCESFULL
            printfUART("sendMsg() - msg placed on send buffer! msgAddr= 0x%x\n", sendMsgPtr);
        }
        else {
            // send FAILED
            atomic isSendingBlock = FALSE;
            printfUART("sendMsg() - ERROR! Can't place msg on send buffer! msgAddr= 0x%x\n", sendMsgPtr);
        }
    }

    uint16_t SamplingMsg_maxMultiChanSamples() {
        return (SAMPLINGMSG_MAX_SAMPLES/MERCURY_NBR_CHANS) * MERCURY_NBR_CHANS;
    }

    task void sendBlock()
    {
        // (1) - Sanity check
        if (nextSampleToSend >= scPtr->nbrMultiChanSamples ||
            scPtr->nbrMultiChanSamples % MERCURY_NBR_CHANS != 0) {
            errorToLeds(7);
            return;
        }
        
        // (2) - Fill in the samplingMsg         
        samplingMsgPtr->srcAddr = TOS_LOCAL_ADDRESS;                                                                                
        atomic {
            if (nextSampleToSend == 0)
                samplingMsgPtr->timeStamp = scPtr->timeStamp;
            else {
                uint32_t timeDelta =  ((uint32_t)nextSampleToSend*(uint32_t)LOCAL_TIME_RATE_HZ) / (uint32_t)MERCURY_SAMPLING_RATE;  
                samplingMsgPtr->timeStamp = scPtr->timeStamp + timeDelta;               
            }
            samplingMsgPtr->sqnNbr = nextSampleToSend;
        }

        // the number of samples to send
        if ( scPtr->nbrMultiChanSamples - nextSampleToSend < SamplingMsg_maxMultiChanSamples()  )
            samplingMsgPtr->nbrSamples = scPtr->nbrMultiChanSamples - nextSampleToSend;
        else  // whatever is left  
            samplingMsgPtr->nbrSamples = SamplingMsg_maxMultiChanSamples();

        // sanity check        
        if (samplingMsgPtr->nbrSamples % MERCURY_NBR_CHANS != 0) {
            printfUART("SAMPLE_CHUNK_NUM_SAMPLES= %i\n", SAMPLE_CHUNK_NUM_SAMPLES);
            printfUART("SAMPLINGMSG_MAX_SAMPLES= %i\n", SAMPLINGMSG_MAX_SAMPLES);
            printfUART("SamplingMsg_maxMultiChanSamples= %i\n", SamplingMsg_maxMultiChanSamples);
            printfUART("scPtr->nbrMultiChanSamples= %i\n", scPtr->nbrMultiChanSamples);
            printfUART("nextSampleToSend= %i\n", nextSampleToSend);
            printfUART("samplingMsgPtr->nbrSamples= %i\n", samplingMsgPtr->nbrSamples);
            errorToLeds(6);
            return;
        }


        memcpy(&samplingMsgPtr->samples[0], &scPtr->samples[nextSampleToSend], (samplingMsgPtr->nbrSamples) * sizeof(sample_t));
        if (call Timer.start(TIMER_ONE_SHOT, 5) == FAIL)  // this will do the send   
            atomic isSendingBlock = FALSE;
    }


    event result_t SendMsg.sendDone(TOS_MsgPtr msgPtr, result_t sendResult)
    {
        if (sendResult == SUCCESS) { // message sent succesfully
            call Leds.yellowOff();
            // do we have more to send?
            atomic {
                nextSampleToSend += samplingMsgPtr->nbrSamples;
                if (nextSampleToSend < scPtr->nbrMultiChanSamples) {
                    if (post sendBlock() == FAIL)
                        isSendingBlock = FALSE;
                }
                else 
                    isSendingBlock = FALSE;
            }     
            //printfUART("SendMsg.sendDone() - msg TX successfully, msgAddr= 0x%x\n", msgPtr);
        }
        else {
            atomic isSendingBlock = FALSE;
            printfUART("SendMsg.sendDone() - ERROR! msg TX FAILED, msgAddr= 0x%x\n", msgPtr);
        }
    
        return sendResult;
    }


    event void Sampling.dataReady(sample_t samples[], uint8_t nbrChannels, result_t result) 
    {
        // This is handled by SamplingToDataStoreM
        //printfUART("DriverM: MultiChanSampling.dataReady() - nbrChans= %i, result= %i\n", 
        //           nbrChannels, result);
    }

    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        // This is handled by SamplingToDataStoreM
        //printfUART("DriverM: DataStore.addDone() - blockPtr= 0x%x\n", blockPtr);
//        blocksqnnbr_t tail;
//        blocksqnnbr_t head;
//        call DataStore.getAvailableBlocks(&tail, &head);
//        printfUART("--> tail= %i, head= %i, lastInserted= %i\n", 
//                   (uint16_t)tail, (uint16_t)head, (uint16_t)blockSqnNbr);
        atomic {
            if (isSendingBlock == TRUE)
                return result;
        }
        if (blockSqnNbr > 0) {
            atomic {
                isSendingBlock = TRUE;
                nextSampleToSend = 0;
            }
            if (call DataStore.get(&blockBuff, blockSqnNbr-1) == FAIL)
                atomic isSendingBlock = FALSE;
        }

        return result;
    }              

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if ( result == SUCCESS) {
//            printfUART("DriverM: DataStore.getDone() - successfuly got blockPtr= 0x%x, blockSqnNbr= %i\n", 
//                        blockPtr, (uint16_t)blockSqnNbr);
//            SampleChunk_print((SampleChunk*)(blockPtr->data));
            atomic {
                if (isSendingBlock == TRUE) {
                    if (post sendBlock() == FAIL)
                        isSendingBlock = FALSE;
                }
            }
        }
        else {
            atomic isSendingBlock = FALSE;
            printfUART("DriverM: DataStore.getDone() - FAILED! to ger blockPtr= 0x%x, blockSqnNbr= %i\n", 
                        blockPtr, (uint16_t)blockSqnNbr);            
        }
//        Block_print(blockPtr);

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
