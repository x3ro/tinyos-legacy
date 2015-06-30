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


module TestM 
{
    provides interface StdControl;
 
    uses interface Leds;
    uses interface Timer;
    uses interface LocalTime;

    uses interface SD;
#ifdef TEST_USE_PRINTFRADIO
    uses interface PrintfRadio;
#endif
}
implementation 
{
    // ======================= Data ==================================
    uint16_t cntTimerFired = 0;                                                          

    #define SD_BLOCK_SIZE_LOG2 9
    #define SD_BLOCK_SIZE      (1 << SD_BLOCK_SIZE_LOG2)
    // BUG in SD Driver setBlockLength doesn't work
    uint8_t writeBuff[512];
    uint8_t readBuff[512];


    // ======================= Methods ===============================
    command result_t StdControl.init() 
    {
        atomic cntTimerFired = 0;
        call Leds.init(); 
        printfUART_init();
        return SUCCESS;
    }
  
    command result_t StdControl.start() 
    {   
        // BUG in SD Driver SD.setBlockLength doesn't work
        // call SD.setBlockLength(SD_BLOCK_SIZE_LOG2);
        call Timer.start(TIMER_REPEAT, 10);
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        return call Timer.stop();
    }

    void doSD()
    {
        uint16_t i = 0;

        // (1) - Write to SD
        if (cntTimerFired % 2 == 1) { // write to SD card
            for (i = 0; i < SD_BLOCK_SIZE; ++i)
                writeBuff[i] = cntTimerFired + i;
                
            if (call SD.writeSector(0, (uint8_t*)writeBuff) != 0) {
                call Leds.yellowOn();  // write FAILED
                assertUART(0);
            }
            else
                call Leds.greenOn();
        }

        // (2) - Read from SD
        else { // read from SD card
            if (call SD.readSector(0, (uint8_t*)readBuff) != 0) {
                call Leds.yellowOn();  // read FAILED
                assertUART(0);
            }
            else {
                // Make sure the readBuff is equal to the writeBuff
                for (i = 0; i < SD_BLOCK_SIZE; ++i) {
                    if (readBuff[i] != writeBuff[i]) {
                        assertUART(0);
                        return;
                    }
                }

                // If we reached this line than the read and write buffers must be the same
                call Leds.greenOff();                                                        
            }
        }
    }

    event result_t Timer.fired()
    {
        //uint32_t localTime = call LocalTime.read();
        cntTimerFired++;
      #ifdef TEST_USE_PRINTFRADIO
        printfRadio("Test::Timer.fired() - cntTimerFired= %u, localTime= %lu", cntTimerFired, localTime);
      #endif
        call Leds.redToggle();

        doSD();

        return SUCCESS;
    }
}


