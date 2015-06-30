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
#include "PrintfUART.h"
#include "PrintfRadio.h"


module TestMultiChanSamplingM 
{
    provides interface StdControl;
 
    uses interface Leds;
    uses interface Timer;
    uses interface LocalTime;

    uses interface MultiChanSampling;
    
    uses interface PrintfRadio;   
}
implementation 
{
    // ======================= Data ==================================
    uint16_t cntTimerFired = 0;                                                          

    enum { NBR_ADC_CHANS = 2 };
    channelID_t ADC_CHANS[NBR_ADC_CHANS] = {4, 3};

    // ======================= Methods ===============================
    event void MultiChanSampling.dataReady(sample_t samples[], uint8_t nbrChannels, result_t result)
    {
        printfUART("TestMultiChanSampling::MultiChanSampling.dataReady() - ");
        call Leds.greenToggle();

        if (result == SUCCESS) {
            uint8_t i = 0;
            printfUART("samples[%u]={", nbrChannels);

            for (i = 0; i < nbrChannels; ++i) {
                printfUART("%u, ", samples[i]);
            }
            printfUART("}\n");
        }
        printfRadio("samples[%u]={%u, %u}", nbrChannels, samples[0], samples[1]);

    }

    command result_t StdControl.init() 
    {
        call Leds.init(); 
        printfUART_init();
        return SUCCESS;
    }
  
    command result_t StdControl.start() 
    {   
        call Timer.start(TIMER_REPEAT, 5000);
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        return call Timer.stop();
    }

    event result_t Timer.fired()
    {
        uint32_t localTime = call LocalTime.read();
        cntTimerFired++;
        printfUART("TestMultiChanSampling::Timer.fired() - cntTimerFired= %u, localTime= %lu, isSampling= %u\n", 
                    cntTimerFired, localTime, call MultiChanSampling.isSampling());
        printfRadio("Timer.fired() - cntTimerFired= %u, localTime= %lu, isSampling= %u\n", 
                    cntTimerFired, localTime, call MultiChanSampling.isSampling());
        call Leds.redToggle();

        if ((cntTimerFired-1) % 4 == 0) {
            call MultiChanSampling.startSampling(ADC_CHANS, NBR_ADC_CHANS, 2);
        }
        else if ((cntTimerFired-1) % 4 == 2) {
            call MultiChanSampling.stopSampling();
        }


        return SUCCESS;
    }
}


