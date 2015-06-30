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
 * Description - Tests the performance of the DataStore, 
 *     such as reads and writes.
 * 
 * @author Konrad Lorincz
 * @version 1.0 - May 20, 2005
 */
#include "PrintfUART.h"
#include "Block.h"
#include "TestPerformanceMsg.h"

module TestPerformanceM
{
    provides interface StdControl;

    uses interface Leds;
    uses interface SendMsg;
    uses interface LocalTime;
    uses interface DataStore;
}
implementation
{
    // ---------- Data ----------
    enum {NBR_REQUESTS_PER_EXP = 256};
    enum {BLOCK_DATA_MAX_BYTES_TO_SET = 16};

    uint32_t startTimeReq = 0;

    // what we actually send back    
    TOS_Msg tosMsg;
    TestPerformanceMsg *testPerfMsgPtr = NULL;

    typedef enum RequestType { 
        R_IDLE, R_ADD, R_GET, 
    } RequestType;
    RequestType currRequest = R_IDLE;
    uint16_t nbrReqMade = 0;

    Block blockBuff;

    uint16_t lastBlockSqnNbrAdded = 0;

    // ----------------------- Methods ----------
    inline void startRequest(RequestType nextRequest);
    inline void handleNextRequest();
    inline uint32_t getCurrentTime();
    result_t addBlock(Block *blockPtr, uint16_t startValue);
    result_t getBlock(Block *blockPtr, blocksqnnbr_t blockSqnNbr);
    task void sendMsg();


    void debugPrintParams()
    {
        printfUART("-------- debugPrintParams() ---------\n", "");
        printfUART("    BLOCK_DATA_SIZE= %i\n", (uint16_t) BLOCK_DATA_SIZE);
        printfUART("    sizeof(Block)= %i\n", (uint16_t) sizeof(Block));
        printfUART("    DS_NBR_BLOCKS_PER_VOLUME= %i\n", (uint16_t) DS_NBR_BLOCKS_PER_VOLUME);         
        printfUART("    DS_NBR_VOLUMES= %i\n", (uint16_t) DS_NBR_VOLUMES);         
        printfUART("    DS_NBR_BLOCKS= %i\n", (uint16_t) DS_NBR_BLOCKS);         
        printfUART("-------------------------------------\n", "");
    }

    command result_t StdControl.init()
    {
        printfUART_init();
        atomic lastBlockSqnNbrAdded = 0;
        
        testPerfMsgPtr = (TestPerformanceMsg*) tosMsg.data;

        testPerfMsgPtr->srcAddr = TOS_LOCAL_ADDRESS;
        testPerfMsgPtr->sqnNbr = 0;
        testPerfMsgPtr->const_sizeofBlock = sizeof(Block);
        testPerfMsgPtr->const_BLOCK_DATA_SIZE = BLOCK_DATA_SIZE;
        testPerfMsgPtr->const_DS_NBR_BLOCKS_PER_VOLUME = 0; //DS_NBR_BLOCKS_PER_VOLUME;
        testPerfMsgPtr->const_DS_NBR_VOLUMES = 0; //DS_NBR_VOLUMES;

        return SUCCESS;
    }

    command result_t StdControl.start()
    {
        call Leds.redOn();         
        return call DataStore.init();        
    }

    command result_t StdControl.stop()
    {
        return SUCCESS;
    }

    event void DataStore.initDone(result_t result)
    {
        if (result == SUCCESS) {
            printfUART("DataStore.initDone() - success\n", "");
            call Leds.redOff();
            atomic currRequest = R_IDLE;
            debugPrintParams();                

            // Start the 1st performance test
            startRequest(R_ADD);
        }
        else {
            printfUART("DataStore.initDone() - FAILED!\n", "");
        }
    }

    inline uint32_t getCurrentTime()
    {
        return call LocalTime.read();
    }


    task void sendMsg()
    {
        call Leds.greenOn();
        if ( call SendMsg.send(/*TOS_UART_ADDR*/0, sizeof(TestPerformanceMsg), &tosMsg) ) {
            printfUART("sendMsg() - successfully scheduled SendMsg.send()\n", ""); 
        } 
        else {                                                          
            printfUART("sendMsg() - FAILED! to schdule SendMsg.send()\n", ""); 
        } 
    }


    inline void handleNextRequest()
    {
        printfUART("handleNextRequest() - called, currRequest= %i, nbrReqMade= %i\n", currRequest, nbrReqMade);
        switch(currRequest) {

            case R_ADD:
                if (nbrReqMade < NBR_REQUESTS_PER_EXP) {
                    atomic nbrReqMade++;
                    addBlock(&blockBuff, nbrReqMade);
                }
                else {  // we are done
                    testPerfMsgPtr->elapsedTimeAdd = getCurrentTime() - startTimeReq;
                    testPerfMsgPtr->nbrRequests = nbrReqMade;
                    atomic currRequest = R_IDLE;
                    call Leds.greenOff();
  
                    // Now, perform the Get test experiment
                    startRequest(R_GET);
                } 
                break;

            case R_GET:
                if (nbrReqMade < NBR_REQUESTS_PER_EXP) {
                    atomic nbrReqMade++;
                    getBlock(&blockBuff, lastBlockSqnNbrAdded-(NBR_REQUESTS_PER_EXP-1)+(nbrReqMade-1));
                }
                else {  // we are done
                    testPerfMsgPtr->elapsedTimeGet = getCurrentTime() - startTimeReq;
                    testPerfMsgPtr->nbrRequests = nbrReqMade;
                    atomic currRequest = R_IDLE;
                    call Leds.yellowOff();
  
                    // We are done, report the results to the java program
                    post sendMsg();
                }                                 
                break;

            default:
                printfUART("handleNextRequest() - FAILED!, invalid currRequest= %i\n", currRequest);
                break;        
        }    
    }

    inline void startRequest(RequestType nextRequest)
    {           
        // Sanity check, the current request state should be IDLE!
        printfUART("startRequest() - called, nextRequest= %i\n", nextRequest);
        if (currRequest == R_IDLE) {
            atomic currRequest = nextRequest;
            atomic nbrReqMade = 0;
            Block_init(&blockBuff);
            if (nextRequest == R_ADD)
                call Leds.greenOn();
            else if (nextRequest == R_GET)
                call Leds.yellowOn();
            startTimeReq = getCurrentTime();            
            handleNextRequest();
        }
        else {
            printfUART("startRequest() - FAILED!, currRequest is not R_IDLE, currRequest= %i, nextRequest= %i\n", 
                        currRequest, nextRequest);
        }
    }

    result_t addBlock(Block *blockPtr, uint16_t startValue)
    {
        uint16_t i = 0;         
        printfUART("\n\naddBlock() - called, startValue= %i\n", startValue);

        for (i = 0; i < BLOCK_DATA_SIZE && i < BLOCK_DATA_MAX_BYTES_TO_SET; ++i) {
            blockPtr->data[i] = startValue +i;
        }

        //Block_print(blockPtr);
        if ( call DataStore.add(blockPtr) == SUCCESS ) { 
            printfUART("addBlock() - successfully scheduled add(), blockPtr= 0x%x\n", blockPtr); 
            return SUCCESS;
        }
        else {
            printfUART("addBlock() - FAILED! to schedule add(), blockPtr= 0x%x\n", blockPtr); 
            return FAIL;
        }
    }

    result_t getBlock(Block *blockPtr, blocksqnnbr_t blockSqnNbr)
    {
        printfUART("\n\ngetBlock() - called\n", "");

        //Block_init(blockPtr);                      
        if ( call DataStore.get(blockPtr, blockSqnNbr) == SUCCESS ) { 
            printfUART("getBlock() - successfuly scheduled get blockPtr= 0x%x, blockSqnNbr= %i\n", 
                        blockPtr, (uint16_t)blockSqnNbr); 
            return SUCCESS; 
        }
        else { 
            printfUART("getBlock() - FAILED! to schedule get blockPtr= 0x%x, blockSqnNbr= %i\n", 
                       blockPtr, (uint16_t)blockSqnNbr); 
            return FAIL;
        }
    }

    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if ( result == SUCCESS) {
            printfUART("DataStore.addDone() - successfuly added blockPtr= 0x%x\n", blockPtr);
            atomic lastBlockSqnNbrAdded = blockSqnNbr;            
        }
        else {
            printfUART("DataStore.addDone() - WARNING failed to add blockPtr= 0x%x\n", blockPtr);
        }

        handleNextRequest();
        return result;
    }              

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result)
    {
        if ( result == SUCCESS) {
            printfUART("DataStore.getDone() - successfuly got blockPtr= 0x%x, blockSqnNbr= %i\n", 
                        blockPtr, (uint16_t)blockSqnNbr);
        }
        else {
            printfUART("DataStore.getDone() - FAILED! to ger blockPtr= 0x%x, blockSqnNbr= %i\n", 
                        blockPtr, (uint16_t)blockSqnNbr);            
        }        
        //Block_print(blockPtr);

        handleNextRequest();
        return result;
    }

    /**
     * Indicates whether the beacon message was send succesfully.
     */
    event result_t SendMsg.sendDone(TOS_MsgPtr msgPtr, result_t sendResult)
    {
        if (sendResult == SUCCESS) {
            // Successfully transmited msg
            printfUART("SendMsg.sendDone() - successfully sent\n","");
            call Leds.greenOff();
        }
        else {
            // Failed to transmit msg
            printfUART("SendMsg.sendDone() - FATAL ERROR, couldn't place on wire:\n","");
        }                       
        return sendResult;
    }
}
