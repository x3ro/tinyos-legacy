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

#include "SamplingToDataStore.h"
#include "MercurySampling.h"
#include "PrintfUART.h"
#include "SampleChunk.h"
#include "ErrorToLeds.h"

//#define printfUART(__format...) {}

module SamplingToDataStoreM 
{
    provides interface StdControl;
    provides interface SamplingToDataStore;
    
    uses interface Leds; 
    //uses interface LocalTime;
    uses interface MultiChanSampling as Sampling;
    uses interface DataStore;
    uses interface GlobalTime;
    uses interface ErrorToLeds;
} 
implementation 
{
    Block blocks[NBR_BLOCKS];
    uint8_t currBlockIndex = 0;
    uint16_t sampleChunkByteIndex;


    command result_t StdControl.init() 
    {
        uint16_t i = 0;
        SampleChunk *scPtr = NULL;
        NOprintfUART_init();

        currBlockIndex = 0;

        for (i = 0; i < NBR_BLOCKS; ++i) {
            scPtr = (SampleChunk*) blocks[i].data;
            SampleChunk_init(scPtr);
        }

        return call Leds.init();
    }

    command result_t StdControl.start() 
    {
        return SUCCESS;
    }

    command result_t StdControl.stop() 
    {
        return SUCCESS;
    }

    event void DataStore.initDone(result_t result) 
    {
        if (result == SUCCESS) {
            NOprintfUART("SamplingToDataStore: SamplingToDataStoreM: DataStore.initDone() - success\n");
        } 
        else {
            NOprintfUART("SamplingToDataStore: DataStore.initDone() - FAILED!\n");
        }
        return;
    }

    inline SampleChunk* getCurrSampleChunk() 
    {
        atomic {
            return (SampleChunk*) blocks[currBlockIndex].data;
        }
    }

    inline void doneWithBlock(SampleChunk *scPtr) 
    {   
        Block *fullBlockPtr; 
        atomic {
            fullBlockPtr = &blocks[currBlockIndex];
            currBlockIndex = (currBlockIndex + 1) % NBR_BLOCKS;
            SampleChunk_init( getCurrSampleChunk() );
            sampleChunkByteIndex = 0;
        }
//        NOprintfUART("SamplingToDataStoreM: addNewSample() - about to add to DataStore\n", "");
        call DataStore.add(fullBlockPtr);
    }

    /** Used to force the current block to be written out early (ie.,
     *  before it has filled).
     */
    command result_t SamplingToDataStore.flush() 
    {
        atomic {
            doneWithBlock(getCurrSampleChunk());
        }
        return SUCCESS;
    }

    inline void addNewSample(sample_t samples[], uint8_t nbrChannels) 
    {
        uint16_t i = 0;

        // (1) - Get pointer to current block
        SampleChunk *scPtr = getCurrSampleChunk();

        // (2) - Check to see if current block is full
#ifdef SAMPLE_CHUNK_PACKED
        if (sampleChunkByteIndex > SAMPLE_CHUNK_PACKED_NUM_BYTES - (3*nbrChannels)) {
            doneWithBlock(scPtr);
            scPtr = getCurrSampleChunk();
        }
#else
        if (scPtr->nbrMultiChanSamples > SAMPLE_CHUNK_NUM_SAMPLES - nbrChannels) {
            doneWithBlock(scPtr);
            scPtr = getCurrSampleChunk();
        }
#endif

        // (3) - Initialize SampleChunk if first sample
        if (scPtr->nbrMultiChanSamples == 0) {
            scPtr->localTime =  call GlobalTime.getLocalTime(); //call LocalTime.read();
            scPtr->timeSynched = call GlobalTime.getGlobalTime(&(scPtr->globalTime));  // set to 0 until we implement GlobalTime (most likely FTSP)
            scPtr->samplingRate = MERCURY_SAMPLING_RATE;

            NOprintfUART("SamplingToDataStoreM.addNewSample() - localTime= %lu, globalTime= %lu, samplingRate= %u, timeSynched= %u\n", 
                       scPtr->localTime, scPtr->globalTime, scPtr->samplingRate, scPtr->timeSynched);

            for (i = 0; i < nbrChannels; ++i)
                scPtr->channelIDs[i] = MERCURY_CHANS[i];  // i // KLDEBUG

            // Set remaining channel map entries to invalid
            for (; i < MCS_MAX_NBR_CHANNELS_SAMPLED; ++i)
                scPtr->channelIDs[i] = CHAN_INVALID;
        }

        // Add the samples
        atomic {
#ifdef SAMPLE_CHUNK_PACKED
            for (i = 0; i < nbrChannels; ++i) {
                // Assume 24 bits per sample
                //	scPtr->data[sampleChunkByteIndex] = scPtr->nbrMultiChanSamples;
                //	scPtr->data[sampleChunkByteIndex+1] = i;
                //	scPtr->data[sampleChunkByteIndex+2] = SAMPLE_CHUNK_PACKED_NUM_BYTES;

                memcpy(&scPtr->data[sampleChunkByteIndex], &channelSamples[i].sample, 3);
                scPtr->nbrMultiChanSamples++; // Increment on *each* sample
                sampleChunkByteIndex += 3;
            }
#else 
            // Not packed
            memcpy(&scPtr->samples[scPtr->nbrMultiChanSamples], samples, nbrChannels*sizeof(sample_t));
            scPtr->nbrMultiChanSamples += nbrChannels;
#endif
        }
//        NOprintfUART("SamplingToDataStoreM: addNewSample() - called. scPtr:\n", "");
//        SampleChunk_print(scPtr);
    }

    event void Sampling.dataReady(sample_t samples[], uint8_t nbrChannels, result_t result) 
    {
        if (result == SUCCESS) {
            addNewSample(samples, nbrChannels);
        } 
    }

    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result) 
    {
        if ( result == SUCCESS) {
//            NOprintfUART("SamplingToDataStore: DataStore.addDone() - successfuly added blockPtr= 0x%x\n", blockPtr);
        } 
        else {
            NOprintfUART("SamplingToDataStore: DataStore.addDone() - WARNING failed to add blockPtr= %p\n", blockPtr);
        }

        return result;
    }              

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result) 
    {
        if ( result == SUCCESS) {
//            NOprintfUART("SamplingToDataStore: DataStore.getDone() - successfuly got blockPtr= 0x%x, blockSqnNbr= %i\n", 
//                       blockPtr, (uint16_t)blockSqnNbr);            
        } 
        else {
            NOprintfUART("SamplingToDataStore: DataStore.getDone() - FAILED! to ger blockPtr= %p, blockSqnNbr= %lu\n", 
                       blockPtr, blockSqnNbr);            
        }
        return result;
    }
}
