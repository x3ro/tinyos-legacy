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
#include "DataStoreSDPrivate.h"
#include "PrintfUART.h"



module DataStoreSDM 
{
    provides interface StdControl;
    provides interface DataStore;

    uses interface SD;
#ifdef DATASTORESD_SPLITPHASE
    uses interface Queue<Request> as RequestQueue;
#endif
} 
implementation 
{
    // ========================= Data =========================
    blocksqnnbr_t tailBlockSqnNbr = 1;
    blocksqnnbr_t headBlockSqnNbr = 1;
    uint8_t sdBuff[512];
   
#ifdef DATASTORE_REMEMBER_BLOCKS_ON_FLASH
    typedef struct FlashInfo {
        uint32_t flashInfoHash;
        uint32_t nodeID;
        blocksqnnbr_t tailBlockSqnNbr;
        blocksqnnbr_t headBlockSqnNbr;
    } FlashInfo;
    uint32_t flashInfoHash = 135792100;
    enum {FLASH_INFO_WRITE_PERIOD = 1500};  // write flashInfo to flash every X blocks (6 chans @100Hz ~= every 5 mins)

#endif
    // ========================= Methods =========================    
#ifdef DATASTORE_REMEMBER_BLOCKS_ON_FLASH
    void readFlashInfo()
    {
        FlashInfo currFlashInfo;
        
        if (call SD.readSector(0, (uint8_t*)sdBuff) == 0) {// NOTE: 0 means SUCCESS!!!
            atomic {memcpy(&currFlashInfo, sdBuff, sizeof(FlashInfo));}
            
            if (currFlashInfo.flashInfoHash == flashInfoHash) {
                // we have a valid entry
                atomic {                    
                    tailBlockSqnNbr = currFlashInfo.tailBlockSqnNbr;
                    headBlockSqnNbr = currFlashInfo.headBlockSqnNbr;    
                }
            }            
        }
    }

    void writeFlashInfo()
    {
        FlashInfo currFlashInfo;

        atomic {
            currFlashInfo.flashInfoHash = flashInfoHash;
            currFlashInfo.nodeID = TOS_LOCAL_ADDRESS;
            currFlashInfo.tailBlockSqnNbr = tailBlockSqnNbr;
            currFlashInfo.headBlockSqnNbr = headBlockSqnNbr;
            memcpy(sdBuff, &currFlashInfo, sizeof(FlashInfo));
        }

        if (call SD.writeSector(0, (uint8_t*)sdBuff) == 0) { // NOTE: 0 means SUCCESS!!!
            // nothing to do
        }
    }
#endif

    command result_t DataStore.saveInfo()
    {
        writeFlashInfo();
        return SUCCESS;
    }

    command result_t DataStore.reset()
    {
        atomic {
            tailBlockSqnNbr = 1;
            headBlockSqnNbr = 1;
        }
        return call DataStore.saveInfo();
    }


    command result_t StdControl.init()
    {
        printfUART_init();

        atomic {
            tailBlockSqnNbr = 1;
            headBlockSqnNbr = 1;
        }
        return SUCCESS;
    }

    command result_t StdControl.start()
    {
#ifdef DATASTORE_REMEMBER_BLOCKS_ON_FLASH
        readFlashInfo();
#endif
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        return SUCCESS;
    }

    void task signalInitDone()
    {
        signal DataStore.initDone(SUCCESS);
    }

    command result_t DataStore.init() {
        //signal DataStore.initDone(SUCCESS);
        if (post signalInitDone() == FAIL)
            return FAIL;
        else
            return SUCCESS;
    }

    inline result_t haveBlock(blocksqnnbr_t blockSqnNbr)
    {           
        return tailBlockSqnNbr <= blockSqnNbr && blockSqnNbr < headBlockSqnNbr;
    }

    command void DataStore.getAvailableBlocks(blocksqnnbr_t *tailBlockSqnNbrPtr, blocksqnnbr_t *headBlockSqnNbrPtr)
    {
        atomic {
            *tailBlockSqnNbrPtr = tailBlockSqnNbr;
            *headBlockSqnNbrPtr = headBlockSqnNbr;
        }
    }

    command uint16_t DataStore.getQueueSize()
    {
        return 0;
    }

#ifdef DATASTORESD_SPLITPHASE
    task void processNextRequest() 
    {
        result_t processResult = FAIL;
        atomic {processResult = (call RequestQueue.size() > 0);}

        if (processResult == FAIL)
            return;
        else {
            Request req;
            Block *blockPtr = NULL;
            atomic {req = call RequestQueue.pop();}
            blockPtr = req.blockPtr;
                                                  
            if (req.requestType == R_ADD) {
                /*atomic {
                    blockPtr->sqnNbr = headBlockSqnNbr;
                    memcpy(sdBuff, blockPtr, sizeof(Block));
                }*/
                blockPtr->sqnNbr = headBlockSqnNbr;
                //if (call SD.writeSector(blockPtr->sqnNbr, (uint8_t*)blockPtr/*sdBuff*/) == 0) { // NOTE: 0 means SUCCESS!!!
                if (call SD.writeBlock(blockPtr->sqnNbr*512, 512, (uint8_t*)blockPtr/*sdBuff*/) == 0) { // NOTE: 0 means SUCCESS!!!
                    atomic headBlockSqnNbr++;
#ifdef DATASTORE_REMEMBER_BLOCKS_ON_FLASH
                    if (headBlockSqnNbr % FLASH_INFO_WRITE_PERIOD == 0)
                        writeFlashInfo();
#endif
                    signal DataStore.addDone(blockPtr, blockPtr->sqnNbr, SUCCESS);
                }
                else
                    signal DataStore.addDone(blockPtr, blockPtr->sqnNbr, FAIL);
            }
            else if (req.requestType == R_GET) {
                if (call SD.readBlock(req.blockSqnNbr*512, 256, (uint8_t*)blockPtr/*sdBuff*/) == 0) {// NOTE: 0 means SUCCESS!!!
                    //atomic {memcpy(blockPtr, sdBuff, sizeof(Block));}
                    signal DataStore.getDone(blockPtr, blockPtr->sqnNbr, SUCCESS);
                }
                else
                    signal DataStore.getDone(blockPtr, blockPtr->sqnNbr, FAIL);
            }
        }
    }

    result_t scheduleRequest(Request nextReq)
    {
        atomic {
            if (!call RequestQueue.is_full()) {
                if (post processNextRequest() == SUCCESS) {
                    call RequestQueue.push(nextReq);
                    return SUCCESS;
                }
                else
                    return FAIL;
            }
            else
                return FAIL;
        }
    }
#endif

    command result_t DataStore.add(Block *blockPtr)
    {
#ifdef DATASTORESD_SPLITPHASE
        Request nextReq;
        nextReq.requestType = R_ADD;
        nextReq.blockPtr = blockPtr;
        nextReq.blockSqnNbr = 0;     // not used with R_ADD; initialize to known value
        return scheduleRequest(nextReq); 
#else
                
        atomic {
            blockPtr->sqnNbr = headBlockSqnNbr;
            memcpy(sdBuff, blockPtr, sizeof(Block));
        }

        if (call SD.writeSector(blockPtr->sqnNbr, (uint8_t*)sdBuff) == 0) { // NOTE: 0 means SUCCESS!!!
            atomic headBlockSqnNbr++;
            signal DataStore.addDone(blockPtr, blockPtr->sqnNbr, SUCCESS);
#ifdef DATASTORE_REMEMBER_BLOCKS_ON_FLASH
            if (headBlockSqnNbr % FLASH_INFO_WRITE_PERIOD == 0)
                writeFlashInfo();
#endif
            return SUCCESS;
        }
        else
            return FAIL;
#endif
    }

    command result_t DataStore.get(Block *blockPtr, blocksqnnbr_t blockSqnNbr)
    {
#ifdef DATASTORESD_SPLITPHASE
        Request nextReq;
        nextReq.requestType = R_GET;
        nextReq.blockPtr = blockPtr;
        nextReq.blockSqnNbr = blockSqnNbr;
        return scheduleRequest(nextReq);
#else

        if (call SD.readSector(blockSqnNbr, (uint8_t*)sdBuff) == 0) {// NOTE: 0 means SUCCESS!!!
            atomic {memcpy(blockPtr, sdBuff, sizeof(Block));}
            signal DataStore.getDone(blockPtr, blockPtr->sqnNbr, SUCCESS);
            return SUCCESS;
        }
        else
            return FAIL;
#endif
    }

    command result_t DataStore.debugPrintDataStore() {return SUCCESS;}
}

