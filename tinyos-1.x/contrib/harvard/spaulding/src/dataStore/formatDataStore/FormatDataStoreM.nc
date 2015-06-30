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
 *     The DataStore (i.e. the flash) must be formated once offline 
 *     before it can be used!  This is analagous to a disk format.  
 *     Note: the formatting may take several minutes.
 * 
 * @author Konrad Lorincz
 * @version 1.0 - May 18, 2005
 */
includes PrintfUART;
includes DataStore;

module FormatDataStoreM 
{
    provides interface StdControl;

    uses interface FormatStorage;
    uses interface Leds;
    uses interface Timer;
}

implementation 
{
    command result_t StdControl.init() 
    {
        call Leds.init();
        printfUART_init();
        return SUCCESS;
    }

    command result_t StdControl.start() 
    {
        call Timer.start(TIMER_ONE_SHOT, 5000);
        return SUCCESS;
    }

    command result_t StdControl.stop() 
    {
        return SUCCESS;
    }

    event result_t Timer.fired() 
    {
        uint16_t i = 0;
        result_t result = FAIL;
        call Leds.yellowOn();
        printfUART("Timer.fired() - called\n", "");        
        

        // (1) - Initialize storage
        result = call FormatStorage.init();
        printfUART("Timer.fired() - FormatStorage.init() called: result= %i\n", result);

        // (2.1) - Allocate for Deluge
        result = rcombine(call FormatStorage.allocateFixed(0xDF, 0xF0000, STORAGE_BLOCK_SIZE), result);
        result = rcombine(call FormatStorage.allocate(0xD0, STORAGE_BLOCK_SIZE), result);
        result = rcombine(call FormatStorage.allocate(0xD1, STORAGE_BLOCK_SIZE), result);

        // (2.2) - Allocate for DataStore
        for (i = 0; i < DS_NBR_VOLUMES && i < STM25P_NUM_SECTORS; ++i) {            
            result = rcombine(call FormatStorage.allocate(i, STORAGE_BLOCK_SIZE), result);
            printfUART("Timer.fired() - FormatStorage.allocate() called: volumeIndex= %i, volumeSize= %i,  result= %i\n", 
                       (uint16_t)i, (uint16_t)STORAGE_BLOCK_SIZE, (uint16_t)result);        
        }

        // (3) - Commit
        result = rcombine(call FormatStorage.commit(), result);
        printfUART("Timer.fired() - FormatStorage.commit() called: result= %i\n", result);


        if (result != SUCCESS) {
            call Leds.yellowOff();
            printfUART("Timer.fired() - FAILED! to allocate, and schedule commit\n", "");
        }
        else {
            printfUART("Timer.fired() - sucessfully allocated, and scheduled commits\n", "");
        }

        return SUCCESS;
    }
  
    event void FormatStorage.commitDone(storage_result_t result) 
    {
        if (result == STORAGE_OK) {
            call Leds.greenOn();
            printfUART("FormatStorage.commitDone() - success\n", "");        
        }
        else {
            call Leds.redOn();
            printfUART("FormatStorage.commitDone() - FAILED!\n", "");        
        }
    }
}
