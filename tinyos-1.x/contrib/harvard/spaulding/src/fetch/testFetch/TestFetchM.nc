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

module TestFetchM                                        
{
    provides interface StdControl;

    uses interface Leds;
    uses interface MultiChanSampling as Sampling;
    uses interface DataStore;
    uses interface ErrorToLeds;
}
implementation
{
    // ---------- Data ----------
    uint32_t LOCAL_TIME_RATE_HZ = 32768L;

    command result_t StdControl.init()
    {
        printfUART_init();
        return call Leds.init();        
    }

    command result_t StdControl.start()
    {
        result_t result;

        result = call DataStore.init();
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
            call Sampling.startSampling(MERCURY_CHANS, MERCURY_NBR_CHANS, MERCURY_SAMPLING_RATE);
        }
        else {
            printfUART("DriverM: DataStore.initDone() - FAILED!\n", "");
        }
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
