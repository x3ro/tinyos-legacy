/*
 * Copyright (c) 2006
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
 * <pre>URL: http://www.eecs.harvard.edu/~konrad/projects/shimmer</pre>
 * @author Konrad Lorincz
 * @version 1.0, November 10, 2006
 */
#include "MultiChanSampling.h"


module MultiChanSamplingM 
{
    provides interface StdControl;
    provides interface MultiChanSampling;
 
    uses interface HPLADC12;

#ifdef MCS_USE_TIMERA
    uses interface MSP430Timer as TimerA;
    uses interface MSP430TimerControl as ControlA0;
    uses interface MSP430Compare as CompareA0;
#else
    uses interface Timer;
    uses interface LocalTime;
#endif
}
implementation 
{
    // ======================= Data ==================================
    bool isSampling = FALSE;
    sample_t samplesBuff[MCS_MAX_NBR_CHANNELS_SAMPLED];

  
    // ======================= Methods ===============================
    void resetADC12Registers(channelID_t channels[], uint8_t nbrChannels);
    void stopConversion();
    void resetTimerA();
    void startTimerA(uint8_t clockSrc, uint8_t clockDiv, uint16_t samplingPeriodJiffies);


    command result_t StdControl.init() 
    {
        atomic isSampling = FALSE;
        return SUCCESS;
    }
  
    command result_t StdControl.start() 
    {   
#ifdef MCS_USE_TIMERA
        resetTimerA();
#endif
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
#ifdef MCS_USE_TIMERA
        resetTimerA();
#else
        return call Timer.stop();
#endif
    }

    uint16_t hzToJiffies(uint16_t hz)
    {
        #define ACLK_HZ 32768UL
        uint32_t result = ACLK_HZ/hz;
        if ((double)ACLK_HZ/(double)hz - (double)result >= 0.5) // round
            result++;

        if (result > 65536) {
            //exit(1);        // abort // KLDEBUG removed exit(1) because of compiler bug
            return result;  // this line will never be reached
        }
        else
            return result;
    }

    uint32_t hzToMillisec(uint16_t hz)
    {
        uint32_t ms = 1000/hz;
        if ((double)1000.0/(double)hz - (double)ms >= 0.5) // round
            ms++;

        return ms;
    }


    command result_t MultiChanSampling.startSampling(channelID_t channelIDs[], uint8_t nbrChannels, uint16_t rateHz) 
    {
        atomic {
            if (isSampling == TRUE ||
                nbrChannels > MCS_MAX_NBR_CHANNELS_SAMPLED || rateHz < 1)
                return FAIL;
            else
                isSampling = TRUE;
        }

        resetADC12Registers(channelIDs, nbrChannels);


#ifdef MCS_USE_TIMERA
        startTimerA(MSP430TIMER_ACLK , MSP430TIMER_CLOCKDIV_1, hzToJiffies(rateHz));
#else
        call Timer.start(TIMER_REPEAT, hzToMillisec(rateHz));
#endif
        return SUCCESS;
    }

    command bool MultiChanSampling.isSampling() 
    {
        atomic return isSampling;
    }

    command result_t MultiChanSampling.stopSampling() 
    {
        atomic {
            if (isSampling == TRUE) {
                stopConversion();
                isSampling = FALSE;
#ifdef MCS_USE_TIMERA
                resetTimerA();
#else
                call Timer.stop();
#endif
                return SUCCESS;
            }
            else
                return SUCCESS;
        }            
    }


    // ----------------------- ADC12 driver code -------------------------------
    void configureAdcPin(uint8_t inputChannel)
    {
        if( inputChannel <= 7 ){
            P6SEL |= (1 << inputChannel);  //adc function (instead of general IO)
            P6DIR &= ~(1 << inputChannel); //input (instead of output)
        }
    }

    void initADC12CTL0()
    {
        adc12ctl0_t ctl0 = {
            adc12sc:0,                      // start conversion: 0 = no sample-and-conversion-start
            enc:0,                          // enable conversion: 0 = ADC12 disabled
            adc12tovie:0,                   // conversion-time-overflow-interrupt: 0 = interrupt dissabled
            adc12ovie:0,                    // ADC12MEMx overflow-interrupt: 0 = dissabled
            adc12on:1,                      // ADC12 on: 1 = on
            refon:0,                        // reference generator: 0 = off
            r2_5v:1,                        // reference generator voltage: 1 = 2.5V
            msc:1,                          // multiple sample and conversion: 1 = conversions performed ASAP
            sht0:SAMPLE_HOLD_4_CYCLES,    // sample-and-hold-time for  ADC12MEM0 to ADC12MEM7  
            sht1:SAMPLE_HOLD_4_CYCLES};   // sample-and-hold-time for  ADC12MEM8 to ADC12MEM15  

        call HPLADC12.setControl0(ctl0);
    }

    void initADC12CTL1()
    {
        adc12ctl1_t ctl1 = {
            adc12busy:0,                    // no operation is active
            conseq:1,                       // conversion mode: sequence of chans
            adc12ssel:SHT_SOURCE_ADC12OSC,  // SHT_SOURCE_ADC12OSC=0; ADC12 clocl source
            adc12div:SHT_CLOCK_DIV_1,       // SHT_CLOCK_DIV_1=0; ADC12 clock div 1
            issh:0,                         // sample-input signal not inverted
            shp:1,                          // Sample-and-hold pulse-mode select: SAMPCON signal is sourced from the sampling timer
            shs:0,                          // Sample-and-hold source select= ADC12SC bit
            cstartadd:0};                   // conversion start addres ADC12MEM0

        call HPLADC12.setControl1(ctl1);
    }

    void initADC12MEMCTLx(channelID_t channels[], uint8_t nbrChannels)
    {
        adc12memctl_t memctl = {
            inch: 0,                        // input channel: ADC0
            sref: REFERENCE_AVcc_AVss,      // reference voltage: 
            eos: 1 };                       // end of sequence flag: 1 indicates last conversion

        uint8_t i = 0;
        if (nbrChannels > 16) {
            //exit(1); // KLDEBUG removed exit(1) because of compiler bug
        }

        for (i = 0; i < nbrChannels; ++i) {
            memctl.inch = channels[i];
            configureAdcPin(memctl.inch);
            if (i < nbrChannels-1)
                memctl.eos = 0;
            else {
                memctl.eos = 1;                   // eos=1 indicates last conversion in sequence
                call HPLADC12.setIEFlags(1 << i); // Set interupt for last register in sequence
            }
            call HPLADC12.setMemControl(i, memctl);
        }
    }

    void resetADC12Registers(channelID_t channels[], uint8_t nbrChannels)
    {
        initADC12CTL0();
        initADC12CTL1();
        initADC12MEMCTLx(channels, nbrChannels);
    }

    void stopConversion()
    {
        call HPLADC12.stopConversion();
        call HPLADC12.setIEFlags(0);
        call HPLADC12.resetIFGs();
    }                                            

    async event void HPLADC12.memOverflow()  {}
    async event void HPLADC12.timeOverflow() {}

    async event void HPLADC12.converted(uint8_t adc12memRegIndex)
    {
        uint8_t i = 0;
        for (i = 0; i <= adc12memRegIndex; ++i)
            samplesBuff[i] = call HPLADC12.getMem(i);

        signal MultiChanSampling.dataReady(samplesBuff, adc12memRegIndex+1, SUCCESS);
    }


    // ----------------------- Timer code -------------------------------
#ifdef MCS_USE_TIMERA
    void resetTimerA()
    {
        MSP430CompareControl_t ccResetSHI = {
            ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
            outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };

        call TimerA.setMode(MSP430TIMER_STOP_MODE);
        call TimerA.clear();
        call TimerA.disableEvents();

        call ControlA0.setControl(ccResetSHI);
    }

    void startTimerA(uint8_t clockSrc, uint8_t clockDiv, uint16_t samplingPeriodJiffies)
    {
        // (1) - Set the sampling rate: clock, clockDivider, and samplingPeriodJiffies
        call TimerA.setClockSource(clockSrc);
        // NOTE: TimerA.setInputDivider() has a bug! So, I'm modifying the register directly.
        //call TimerA.setInputDivider(SAMPCON_CLOCK_DIV_2);
        TACTL |= (clockDiv << 6);
        
        call CompareA0.setEvent(samplingPeriodJiffies-1);
        call ControlA0.enableEvents();
        
        // (2) - Start the timer
        call TimerA.setMode(MSP430TIMER_UP_MODE); // go!
    }

    async event void TimerA.overflow() {}

    async event void CompareA0.fired()
    {
        // Trigger a sequence of conversions
        call HPLADC12.startConversion();
    }
#else
    event result_t Timer.fired()
    {
        // Trigger a sequence of conversions
        call HPLADC12.startConversion();
        return SUCCESS;
    }
#endif




}


