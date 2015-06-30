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
 * Description - Drier for the Sampling and DataStore components
 * 
 * @author Konrad Lorincz
 * @version 1.0 - May 25, 2005
 */
#include "PrintfUART.h"
#include "MultiChanSampling.h"
#include "SampleChunk.h"
#include "DataStore.h"
#include "SamplingMsg.h" 



configuration TestFetchC 
{
} 
implementation 
{
    components Main, FetchC, LedsC, ErrorToLedsC;
    components TestFetchM, MultiChanSamplingC as SamplingC;
    components SamplingToDataStoreC, DataStoreC;

    Main.StdControl -> TestFetchM;
    Main.StdControl -> SamplingC;
    Main.StdControl -> SamplingToDataStoreC;
    Main.StdControl -> FetchC;

    TestFetchM.Leds -> LedsC;
    TestFetchM.Sampling -> SamplingC;
    TestFetchM.DataStore -> DataStoreC; 
    TestFetchM.ErrorToLeds -> ErrorToLedsC;

    SamplingToDataStoreC.Sampling -> SamplingC;
}
