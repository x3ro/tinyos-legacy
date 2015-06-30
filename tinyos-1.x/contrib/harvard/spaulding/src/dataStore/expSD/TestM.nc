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
    
    #define SD_BLOCK_SIZE 256 
    #define BUFF_SIZE 512                                                         
    uint8_t writeBuff[BUFF_SIZE];
    uint8_t readBuff[BUFF_SIZE];


    // ======================= Methods ===============================
    void initBuff(uint8_t buff[], uint16_t buffSize, uint8_t isOdd)
    {
        uint16_t i = 0;
        for (i = 0; i < buffSize; ++i) {
            if (isOdd == 1)
                buff[i] = (i*2 + 1) % 256;    
            else
                buff[i] = (i*2) % 256;
        }    
    }

    void printBuff(uint8_t buff[], char *buffName)
    {
        uint16_t startIndex[]={0, 250, 501};
        uint16_t length = 10;
        uint16_t s = 0;
        uint16_t i = 0;
        char sprintfBuff[300];
        

        for (s = 0; s < 3; ++s) {
            uint16_t lastIndex = 0;
            for (i = 0; i < length; ++i) {
                lastIndex += sprintf(&sprintfBuff[lastIndex], " %u", buff[startIndex[s]+i]);        
            }
            printfRadio("%s[%i-%i]:%s", buffName, startIndex[s], (startIndex[s]+length), sprintfBuff);
        } 
    }

    command result_t StdControl.init() 
    {
        call Leds.init(); 
        printfUART_init();
        initBuff(writeBuff, BUFF_SIZE, 1);
        initBuff(readBuff, BUFF_SIZE, 0);
        return SUCCESS;
    }
  
    command result_t StdControl.start() 
    {   
        //uint8_t rval = call SD.setBlockLength(8);
        //printfRadio("SD.setBlockLength(8) - rval= %u", rval);
        printBuff(writeBuff, "writeBuff");
        printBuff(readBuff, " readBuff");

        call Timer.start(TIMER_REPEAT, 5000);
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        return call Timer.stop();
    }


    void doSD()
    {
        uint32_t sdCardSize = call SD.readCardSize();
        uint16_t i = 0;
        uint8_t rval = 0;

        printfRadio("\n===== After =====\n");
 
        if (cntTimerFired % 2 == 1) { // write to SD card
            for (i = 0; i < SD_BLOCK_SIZE; ++i)
                writeBuff[i] = cntTimerFired + i;
                    
            rval = call SD.writeBlock(cntTimerFired*512, 512, (uint8_t*)writeBuff);
            printfRadio("SD.writeSector() - rval= %u", rval);
        }
        else { // read from SD card
            rval = call SD.readBlock((cntTimerFired-1)*512, 256, (uint8_t*)readBuff);
            printfRadio("SD.readSector() - rval= %u", rval);

            for (i = 0; i < SD_BLOCK_SIZE; ++i) {
                if (readBuff[i] != writeBuff[i]) {
                    assertUART(0);
                    return;
                }
            }
        }

        printBuff(writeBuff, "writeBuff");
        printBuff(readBuff, " readBuff");

    }

    event result_t Timer.fired()
    {
        uint32_t localTime = call LocalTime.read();  
        cntTimerFired++;
      #ifdef TEST_USE_PRINTFRADIO
        printfRadio("Test::Timer.fired() - cntTimerFired= %u, localTime= %lu \n", cntTimerFired, localTime);
      #endif
        call Leds.greenToggle();

        doSD();
        return SUCCESS;
    }
}


