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
 * Testing the ADC components.
 */
//#include "MSP430ADC12.h"
#include "MultiChanSampling.h"
#include "MercurySampling.h"
#include "SamplingMsg.h"
#include "RealTimeSamples.h"
#include "PrintfUART.h"


module RealTimeSamplesM 
{
    provides interface StdControl;
 
    uses interface Leds;
    uses interface LocalTime;
    //uses interface Timer_SendDelay;
    uses interface SendMsg;
    uses interface Pool<TOS_Msg> as TOSMsgMemPool;
    uses interface MultiChanSampling;
}
implementation 
{
    // ======================= Data ==================================
    TOS_Msg*      currTOSMsgPtr;
    SamplingMsg*  currSamplingMsgPtr;
    uint8_t       sampleIndex;                            

    bool          busySending = FALSE;

    uint16_t      sqnNbr = 0;

    norace uint16_t cntSamples;                                  
    uint32_t startTime = 0;
    uint32_t elapsedTime = 0;


    // ======================= Methods ===============================
    void errorToLeds(uint8_t errValue);
    inline void sendMsg(TOS_Msg *sendMsgPtr, uint16_t sendAddr, uint8_t dataSize);

    command result_t StdControl.init() 
    {
        call Leds.init(); 
        printfUART_init();
        
        call TOSMsgMemPool.init();
        atomic currTOSMsgPtr = call TOSMsgMemPool.alloc();

        if (currTOSMsgPtr == NULL) {
            errorToLeds(7);
            return FAIL;
        }
        else {
            atomic {
                currSamplingMsgPtr = (SamplingMsg*) &(currTOSMsgPtr->data);
                currSamplingMsgPtr->srcAddr = TOS_LOCAL_ADDRESS;
                currSamplingMsgPtr->timeStamp = 0;
                currSamplingMsgPtr->nbrSamples = 0;
                sampleIndex = 0;
                sqnNbr = 0;
                busySending = FALSE;
                return SUCCESS;
            }
        }
    }
  
    command result_t StdControl.start() 
    {
        atomic startTime = call LocalTime.read();
        return SUCCESS;
    }

    command result_t StdControl.stop()  {return SUCCESS;}


    inline void addSample(sample_t samples[], uint8_t nbrChannels) 
    {   
        printfUART("\n+++++++ New Sample +++++++++++++++++++++++\n");
        // (1) - Get the new buffer if this one is full
        if (sampleIndex + nbrChannels > SAMPLINGMSG_MAX_SAMPLES) {
            TOS_Msg *nextTOSMsgPtr;
            atomic {nextTOSMsgPtr = call TOSMsgMemPool.alloc();}
            
            if (nextTOSMsgPtr == NULL) {  // out of memory
                printfUART("addSample() - ERROR. out of memory, so dropping this sample\n", "");
                return;
            }
            else {
                // (a) Swap buffers
                TOS_Msg *sendTOSMsgPtr = currTOSMsgPtr;                
                uint16_t i = 0;
                atomic {
                    currTOSMsgPtr = nextTOSMsgPtr;
                    currSamplingMsgPtr = (SamplingMsg*) &(currTOSMsgPtr->data);
                    currSamplingMsgPtr->srcAddr = TOS_LOCAL_ADDRESS;
                    currSamplingMsgPtr->sqnNbr = sqnNbr++;
                    currSamplingMsgPtr->timeStamp = call LocalTime.read() - startTime;
                    currSamplingMsgPtr->nbrSamples = 0;
                    currSamplingMsgPtr->samplingRate = MERCURY_SAMPLING_RATE/REALTIMESAMPLES_DOWNSAMPLE_FACTOR;
                    for (i = 0; i < nbrChannels; ++i)
                        currSamplingMsgPtr->channelIDs[i] = MERCURY_CHANS[i];
                    // Set remaining channel map entries to invalid
                    for (; i < MCS_MAX_NBR_CHANNELS_SAMPLED; ++i)
                        currSamplingMsgPtr->channelIDs[i] = CHAN_INVALID;

                    sampleIndex = 0;
                }

                // (b) Send the message 
                sendMsg(sendTOSMsgPtr, TOS_BCAST_ADDR, sizeof(SamplingMsg));
            }
        }
        
        // (2) - Add the sample to the buffer
        atomic {
            currSamplingMsgPtr->nbrSamples += nbrChannels;
            memcpy(&(currSamplingMsgPtr->samples[sampleIndex]), samples, nbrChannels*sizeof(sample_t));
            sampleIndex += nbrChannels;
        }
    }   

    event void MultiChanSampling.dataReady(sample_t samples[], uint8_t nbrChannels, result_t result)
    {  
        cntSamples++;
        if (cntSamples % REALTIMESAMPLES_DOWNSAMPLE_FACTOR == 0)
            addSample(samples, nbrChannels);
    }

    inline void sendMsg(TOS_Msg *sendMsgPtr, uint16_t sendAddr, uint8_t dataSize)
    {   
        call Leds.yellowOn();
        atomic {
            if (!busySending) {
                busySending = TRUE;
                if (call SendMsg.send(sendAddr, dataSize, sendMsgPtr) == FAIL) {
                    busySending = FALSE;
                    call TOSMsgMemPool.free(sendMsgPtr);
                }
            }
        }
    }

    event result_t SendMsg.sendDone(TOS_MsgPtr msgPtr, result_t sendResult)
    {
        if (sendResult == SUCCESS) { // message sent succesfully
            call Leds.yellowOff();
            //printfUART("SendMsg.sendDone() - msg TX successfully, msgAddr= 0x%x\n", msgPtr);
        }
        else {
            printfUART("SendMsg.sendDone() - ERROR! msg TX FAILED, msgAddr= 0x%x\n", msgPtr);
        }
    
        atomic {
            busySending = FALSE;
            call TOSMsgMemPool.free(msgPtr);
        }
        return sendResult;
    }


    /**
     * Used for Debugging - turns on the leds corresponding to the parameter and exits the program
     * @param errValue, the value to display on the leds (in binary)
     */
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
            //exit(1);
        }
    }
}


