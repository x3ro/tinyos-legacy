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
 * Description - defines the sample chunk. The encoding will change when we introduce compression.
 *     For now we have a temporary encoding that is easy to debug.
 *
 * @author: Konrad Lorincz
 * @version 1.0 - 4/20/05
 */
#ifndef SAMPLECHUNK_H
#define SAMPLECHUNK_H
#include "MultiChanSampling.h"
#include "Block.h"

/* Define to pack samples into the SampleChunk */
//#define SAMPLE_CHUNK_PACKED 

/* Number of samples in a sample chunk */
#define SAMPLE_CHUNK_NUM_SAMPLES ((BLOCK_DATA_SIZE - 2*sizeof(uint32_t) - 3*sizeof(uint16_t) - sizeof(channelID_t)*MCS_MAX_NBR_CHANNELS_SAMPLED) / sizeof(sample_t))

/* Number of bytes in a sample chunk if packed */
#define SAMPLE_CHUNK_PACKED_NUM_BYTES ((BLOCK_DATA_SIZE - sizeof(uint32_t) - sizeof(uint16_t) - sizeof(channelID_t)*MCS_MAX_NBR_CHANNELS_SAMPLED))

/* DO NOT CHANGE THIS STRUCTURE without modifying definitions above
 * and the corresponding code in Block.java and Fetch.java
 */
typedef struct SampleChunk {
    uint32_t    localTime;
    uint32_t    globalTime;
    uint16_t    samplingRate;
    uint16_t    timeSynched;         // true or false 
    uint16_t    nbrMultiChanSamples; // Number of samples

    // The number of actual samples represented in 'samples' is 
    // determined by the channelIDs map. All map entries that are
    // *not* set to CHAN_INVALID represent an actual channel.
    channelID_t channelIDs[MCS_MAX_NBR_CHANNELS_SAMPLED];

#ifdef SAMPLE_CHUNK_PACKED
    /* Packed data */
    uint8_t     data[SAMPLE_CHUNK_PACKED_NUM_BYTES];
#else 
    sample_t    samples[SAMPLE_CHUNK_NUM_SAMPLES];
#endif
} SampleChunk;         

// =========================== Methods ===============================
inline void SampleChunk_init(SampleChunk *scPtr)
{   
    scPtr->localTime = 0;
    scPtr->globalTime = 0;
    scPtr->samplingRate = 0;
    scPtr->timeSynched = 0;
    scPtr->nbrMultiChanSamples = 0;
}

/**
 * Prints the content of a block.
 */
inline void SampleChunk_print(SampleChunk *scPtr)
{
  #ifdef PRINTFUART_ENABLED
    uint16_t i = 0, n = 0;
    printfUART("  --- SampleChunk_print() - for SampleChunk (0x%x) --- \n", scPtr);
    printfUART("    localTime= %lu, globalTime= %lu, samplingRate= %u, timeSynched= %u, nbrMultiChanSamples= %u, channelIDs= {", 
               scPtr->localTime,  scPtr->globalTime, scPtr->samplingRate, scPtr->nbrMultiChanSamples);  
    for (i = 0; i < MCS_MAX_NBR_CHANNELS_SAMPLED; ++i) {
        if (i < MCS_MAX_NBR_CHANNELS_SAMPLED - 1)
            {printfUART("%u, ", scPtr->channelIDs[i]);}
        else
            {printfUART("%u}>", scPtr->channelIDs[i]);}
    }                                          

#ifndef SAMPLE_CHUNK_PACKED
    printfUART("\n    --- samples ---\n", "");
    printfUART("    {", "");
    for (n = 0; n < SAMPLE_CHUNK_NUM_SAMPLES; ++n) {
        if (n % MCS_MAX_NBR_CHANNELS_SAMPLED == 0)
            {printfUART(" {", "");}
        printfUART("%u ", scPtr->samples[n]);
/*         printfUART("{", (uint16_t)scPtr->timeStamp);   */
/*         for (i = 0; i < MCS_MAX_NBR_CHANNELS_SAMPLED; ++i) { */
/*             if (i < MCS_MAX_NBR_CHANNELS_SAMPLED - 1) */
/*                 {printfUART("%u, ", scPtr->samples[n]);} */
/*             else */
/*                 {printfUART("%u},  ", scPtr->samples[n]);} */
/*         }                           */
    }
    printfUART("}\n", "");
    printfUART("  ------------------------------------------------\n", "");
#endif
  #endif
}

#endif
