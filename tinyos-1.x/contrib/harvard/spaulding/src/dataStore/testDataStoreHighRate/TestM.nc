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
#include "Block.h"


module TestM 
{
    provides interface StdControl;
 
    uses interface Leds;
    uses interface Timer;
    uses interface LocalTime;

    uses interface DataStore;
#ifdef TEST_USE_PRINTFRADIO
    uses interface PrintfRadio;
#endif
}
implementation 
{
    // ======================= Data ==================================
    uint16_t cntTimerFired = 0;                                                          

    Block writeBlock;
    Block readBlock;


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
        call DataStore.init();
        call Timer.start(TIMER_REPEAT, 10);
        return SUCCESS;
    }
          
    command result_t StdControl.stop()
    {
        return call Timer.stop();
    }

    // ----- Write -----
    void addBlock(uint8_t startNbr)
    {
        uint16_t i = 0;
        for (i = 0; i < BLOCK_DATA_SIZE; ++i)
            writeBlock.data[i] = startNbr + i;
                
        call Leds.greenOn();
        if (call DataStore.add(&writeBlock) == FAIL)
            {call Leds.orangeOn(); exit(1);}
    }

    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if (result == SUCCESS && blockPtr == &writeBlock)
            call Leds.greenOff();
        else
            {call Leds.orangeOn(); exit(1);}
        return SUCCESS;
    }


    // ----- Read -----
    void getBlock(blocksqnnbr_t blockID)
    {
        call Leds.yellowOn();
        if (call DataStore.get(&readBlock, blockID) == FAIL)
            {call Leds.orangeOn(); exit(1);}
    }

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if (result == SUCCESS && 
            blockPtr == &readBlock && 
            memcmp(&writeBlock, &readBlock, sizeof(Block)) == 0) {
            call Leds.yellowOff();
        }
        else
            {call Leds.orangeOn(); exit(1);}

        return SUCCESS;
    }



    event result_t Timer.fired()
    {
        //uint32_t localTime = call LocalTime.read();
        cntTimerFired++;
      #ifdef TEST_USE_PRINTFRADIO
        printfRadio("Test::Timer.fired() - cntTimerFired= %u, localTime= %lu", cntTimerFired, localTime);
      #endif
        call Leds.redToggle();


        if (cntTimerFired % 2 == 1) // write to DataStore
            addBlock((uint8_t)cntTimerFired);
        else
            getBlock(writeBlock.sqnNbr);    

        return SUCCESS;
    }

    
    event void DataStore.initDone(result_t result) {}
}


