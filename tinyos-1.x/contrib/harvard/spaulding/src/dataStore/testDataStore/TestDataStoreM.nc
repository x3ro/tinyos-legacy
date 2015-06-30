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
#include "Block.h"


module TestDataStoreM
{
    provides interface StdControl;

    uses interface Leds;
    uses interface Timer;
    uses interface DataStore;
}
implementation
{
    // ---------- Data ----------
    enum {TIMER_INTERVAL = 5000L};
    uint16_t cntTimerFired = 0;

    Block blockBuff;

    blocksqnnbr_t lastBlockSqnNbrAdded = 0;
    uint8_t randNbr = 0;

    // ----------------------- Methods ----------

    command result_t StdControl.init()
    {
        printfUART_init();
        printfUART("TestDateStore:StdControl.init() - called\n");

        randNbr = 0xcc;
        Block_init(&blockBuff);

        return SUCCESS;
    }

    command result_t StdControl.start()
    {
        printfUART("TestDateStore:StdControl.start() - called\n");
        return call DataStore.init();        
    }

    command result_t StdControl.stop()
    {
        return SUCCESS;
    }

    event void DataStore.initDone(result_t result)
    {
        if (result == SUCCESS) {
            printfUART("DataStore.initDone() - success\n");
            call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);    
        }
        else {
            printfUART("DataStore.initDone() - FAILED!\n");
        }
    }

    result_t addBlock(Block *blockPtr, uint16_t startValue)
    {
        uint16_t i = 0;
        
        printfUART("\n\naddBlock() - called, startValue= %u\n", startValue);

        Block_init(blockPtr);
        for (i = 0; i < BLOCK_DATA_SIZE; ++i) {
            if (i == 7)
                blockPtr->data[i] = randNbr;
            else
                blockPtr->data[i] = startValue +i;
        }

        Block_print(blockPtr);
        if ( call DataStore.add(blockPtr) == SUCCESS ) 
            { printfUART("addBlock() - successfully scheduled add(), blockPtr= %p\n", blockPtr); return SUCCESS;}
        else
            { printfUART("addBlock() - FAILED! to schedule add(), blockPtr= %p\n", blockPtr); return FAIL;}
    }

    result_t getBlock(Block *blockPtr)
    {
        printfUART("\n\ngetBlock() - called\n");
        Block_init(blockPtr);

        if ( call DataStore.get(blockPtr, lastBlockSqnNbrAdded) == SUCCESS )
            { printfUART("getBlock() - successfuly scheduled get blockPtr= %p, blockSqnNbr= %lu\n", 
                         blockPtr, lastBlockSqnNbrAdded); return SUCCESS; }
        else
            { printfUART("getBlock() - FAILED! to schedule get blockPtr= %p, blockSqnNbr= %lu\n", 
                         blockPtr, lastBlockSqnNbrAdded); return FAIL; }
    }

    event result_t Timer.fired()
    {
        ++cntTimerFired;
        call Leds.yellowToggle();
        printfUART("\n\n\n\nTimer.fired() - cntTimerFired= %u\n", cntTimerFired);

        if (cntTimerFired % 3 == 0)
            getBlock(&blockBuff);
        else if (cntTimerFired % 3 == 1)
            addBlock(&blockBuff, cntTimerFired);
        else
            call DataStore.debugPrintDataStore();

        return SUCCESS;
    }
                                              
    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if (result == SUCCESS) {
            printfUART("DataStore.addDone() - successfuly added blockPtr= %p\n", blockPtr);
            atomic lastBlockSqnNbrAdded = blockSqnNbr;            
        }
        else {
            call Leds.redToggle();
            printfUART("DataStore.addDone() - WARNING failed to add blockPtr= %p\n", blockPtr);
        }
        //Block_print(blockPtr);

        return result;
    }              

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if (result == SUCCESS) {
            printfUART("DataStore.getDone() - successfuly got blockPtr= %p, blockSqnNbr= %lu\n", 
                        blockPtr, blockSqnNbr);            
        }
        else {
            printfUART("DataStore.getDone() - FAILED! to ger blockPtr= %p, blockSqnNbr= %lu\n", 
                        blockPtr, blockSqnNbr);            
            call Leds.redToggle();
        }
        Block_print(blockPtr);

        return result;
    }

}
