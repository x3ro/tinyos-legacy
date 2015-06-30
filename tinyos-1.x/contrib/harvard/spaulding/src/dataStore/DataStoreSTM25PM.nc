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
#include "DataStoreSTM25PPrivate.h"
#include "Storage.h"
#include "BlockStorage.h"
#include "ErrorToLeds.h"

//#define printfUART(__format...) {}

module DataStoreSTM25PM 
{
    provides interface StdControl;
    provides interface DataStore;
    
    uses interface Leds;
    uses interface FormatStorage;
    uses interface ErrorToLeds;
    uses interface Queue<Request> as RequestQueue;

    uses interface BlockRead[volume_t parID];
    uses interface BlockWrite[volume_t parID];
    uses interface Mount[volume_t parID];
    uses interface StorageRemap[volume_t parID];    
} 
implementation 
{
    // ========================= Data =========================
    enum {REQUEST_MAX_ATTEMPTS = 5};

    BlockHandle  tail;
    BlockHandle  head;

    enum DataStoreState {
        S_UNINITIALIZED,           
        S_INITIALIZING,
        S_READY,
        S_READING,
        S_WRITING,
        S_ERASING_VOLUME,
        S_DEBUG_PRINTING,
    };      
    enum DataStoreState currState;

    volume_t nextVolumeIndexToMount = 0;
    bool triedToFromatDataStore = FALSE;

#ifdef DATASTORE_DEBUG_PRINT_ENABLED
    // Warning: Make sure this is not too big!   
    Block debugBlock;
    uint16_t debugNextBlockIndexToGet;
#endif


    // ========================= Methods =========================    
    result_t mountVolume(volume_t volIndex);
    result_t eraseVolume(volume_t volIndex);
    void formatDataStore();
    task void processNextRequest();
    void debugPrintParams();
#ifdef DATASTORE_DEBUG_PRINT_ENABLED
    void DataStore_print(Block *blockPtr, uint16_t blockIndex);
    result_t debugPrintDataStoreBlock(uint16_t blockIndex);
#endif


    command result_t StdControl.init()
    {
        NOprintfUART_init();

        atomic {
            currState = S_UNINITIALIZED;
            nextVolumeIndexToMount = 0;

            BlockHandle_init(&tail);
            BlockHandle_init(&head);
        }

        return SUCCESS;
    }

    command result_t StdControl.start()
    {       
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        return SUCCESS;
    }
    
    // Warning, these need to be implemented. They are stubbed out for now.
    command result_t DataStore.saveInfo() {return FAIL;}
    command result_t DataStore.reset()    {return FAIL;}

    command result_t DataStore.init()
    {      
        NOprintfUART_init();                        
        NOprintfUART("\n\n\n\n\nDataStore.init() - called\n");
        debugPrintParams();
        atomic {
            triedToFromatDataStore = FALSE;
            currState = S_INITIALIZING;
        }

#ifdef DS_FORMAT_ENABLED
        formatDataStore();
#else
        atomic nextVolumeIndexToMount = 0;
        mountVolume(nextVolumeIndexToMount);
#endif
        return SUCCESS;
    }

    void printCurrState()
    {
        uint16_t queueSize = 999;
        atomic {queueSize = call RequestQueue.size();}
        NOprintfUART("\n========== DataStore current state ==========\n");
        NOprintfUART("--> tail:\n"); 
            BlockHandle_print(&tail);
        NOprintfUART("--> head:\n"); 
            BlockHandle_print(&head);
        NOprintfUART("--> Request Queue.size() = %u\n", queueSize); 
        NOprintfUART("===============================================\n");
    }
                                         
    volume_t getVolumeIndex(volume_t parID)
    {
        volume_t i = 0;
        for (i = 0; i < DS_NBR_VOLUMES; ++i) {
            if ( parID == DS_VOLS[i].parID )
                return i;
        }

        call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE1);
        return 0;      // line will never be reached
    }                                    

    inline result_t haveBlock(blocksqnnbr_t blockSqnNbr)
    {           
        return tail.blockSqnNbr <= blockSqnNbr && blockSqnNbr < head.blockSqnNbr;
    }

    void debugPrintParams() 
    {
        NOprintfUART("-------- debugPrintParams() ---------\n");
        NOprintfUART("    BLOCK_DATA_SIZE= %u\n", (uint16_t) BLOCK_DATA_SIZE);
        NOprintfUART("    sizeof(Block)= %u\n", (uint16_t) sizeof(Block));
        NOprintfUART("    DS_NBR_BLOCKS_PER_VOLUME= %u\n", (uint16_t) DS_NBR_BLOCKS_PER_VOLUME);         
        NOprintfUART("    DS_NBR_VOLUMES= %u\n", (uint16_t) DS_NBR_VOLUMES);         
        NOprintfUART("    DS_NBR_BLOCKS= %u\n", (uint16_t) DS_NBR_BLOCKS);         
        NOprintfUART("-------------------------------------\n");
    } 

    inline BlockHandle getBlockHandle(blocksqnnbr_t blockSqnNbr) 
    {
        BlockHandle handle;        
        blockindex_t logicalBlockIndex = 0;
        atomic {
            logicalBlockIndex = ( ((blockindex_t)tail.volumeIndex * DS_NBR_BLOCKS_PER_VOLUME + tail.blockIndex) +
                                     (blockSqnNbr - tail.blockSqnNbr) ) % DS_NBR_BLOCKS;
        
            handle.volumeIndex = logicalBlockIndex / DS_NBR_BLOCKS_PER_VOLUME;           // we want integer division (i.e. truncation)
            handle.blockIndex  = logicalBlockIndex % DS_NBR_BLOCKS_PER_VOLUME;
            handle.blockSqnNbr = blockSqnNbr;
        }

        return handle;
    }          
    
    inline blockaddr_t getBlockIndexAddr(blockindex_t blockIndex)
    {
        return (blockaddr_t)blockIndex * (blockaddr_t)sizeof(Block);
    }

    command void DataStore.getAvailableBlocks(blocksqnnbr_t *tailBlockSqnNbr, blocksqnnbr_t *headBlockSqnNbr)
    {
        atomic {
            *tailBlockSqnNbr = tail.blockSqnNbr;
            *headBlockSqnNbr = head.blockSqnNbr;
        }
    }

    command uint16_t DataStore.getQueueSize()
    {
        uint16_t queueSize;
        atomic {queueSize = call RequestQueue.size();}
        return queueSize;
    }
    
    inline void setKnownBlockPattern(Block *blockPtr, blocksqnnbr_t sqnNbr)
    {
        uint16_t i = 0;
        blockPtr->sqnNbr = sqnNbr;
        for (i = 0; i < BLOCK_DATA_SIZE; ++i)
            //blockPtr->data[i] =  (blockPtr->sqnNbr + i) % 256;      
            blockPtr->data[i] =  i % 256;      
    }

    inline void performRequestAdd(Request *reqPtr)
    {
        volume_t parID    = DS_VOLS[head.volumeIndex].parID;
        block_addr_t addr = getBlockIndexAddr(head.blockIndex);
        uint8_t *buf      = (uint8_t*) (reqPtr->blockPtr);
        block_addr_t len  = sizeof(Block);                           

        atomic (reqPtr->blockPtr)->sqnNbr = head.blockSqnNbr;
        reqPtr->blockSqnNbr = (reqPtr->blockPtr)->sqnNbr;

#ifdef KNOWN_BLOCK_PATTERN
        setKnownBlockPattern(reqPtr->blockPtr, (reqPtr->blockPtr)->sqnNbr);
#endif
        
        if ( call BlockWrite.write[parID](addr, buf, len) ) {
            NOprintfUART("performRequestAdd() - successfully scheduled BlockWrite.write[%u](), blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                        parID, reqPtr->blockPtr, buf, addr, len);
            atomic currState = S_WRITING;                                   
        } 
        else {
            NOprintfUART("performRequestAdd() - FAILED! scheduled BlockWrite.write[%u](), blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                        parID, reqPtr->blockPtr, buf, addr, len);
            atomic currState = S_READY;
            NOprintfUART("\n\n--> tail:\n"); 
                BlockHandle_print(&tail);
            NOprintfUART("\n\n--> head:\n"); 
                BlockHandle_print(&head);
            call ErrorToLeds.errorToLeds(0, ERRORTOLEDS_DATASTORE2);  // not an actual error because we try to post again.
            
            post processNextRequest(); // try again
        }
    }

    void performRequestGet(Request *reqPtr) 
    {
        BlockHandle handle = getBlockHandle(reqPtr->blockSqnNbr); 

        volume_t parID    = DS_VOLS[handle.volumeIndex].parID;
        block_addr_t addr = getBlockIndexAddr(handle.blockIndex);
        uint8_t *buf      = (uint8_t*) reqPtr->blockPtr;
        block_addr_t len  = sizeof(Block);                           

        if ( call BlockRead.read[parID](addr, buf, len) ) {
            NOprintfUART("performRequestGet() - successfully scheduled BlockRead.read[%u](), blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                        parID, reqPtr->blockPtr, buf, addr, len);
            atomic currState = S_READING;                                   
        }
        else {
            NOprintfUART("performRequestGet() - FAILED! scheduled BlockRead.read[%u](), blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                        parID, reqPtr->blockPtr, buf, addr, len);
            atomic currState = S_READY;
            post processNextRequest(); // try again
        } 
    }

    task void processNextRequest() 
    {
        result_t processResult = FAIL;

        atomic {processResult = (currState == S_READY && call RequestQueue.size() > 0);}
        if (processResult) {
            // We do not remove the request from the queue because the request
            // may fail in which case we want to try the request again next time.  
            // The dequeu operation should be performed when we get a done() SUCCESS
            // or after a set number of failed attempts!
            Request *reqPtr = NULL;
            atomic {reqPtr = call RequestQueue.peekPtr();}

            reqPtr->nbrAttempts++;
            
            if (reqPtr->nbrAttempts > REQUEST_MAX_ATTEMPTS) {
                NOprintfUART("processNextRequest() - FAILED! nbrAttempts= %u\n", reqPtr->nbrAttempts);        
                                  
                switch(reqPtr->requestType) {
                    case R_ADD:  signal DataStore.addDone(reqPtr->blockPtr, (reqPtr->blockPtr)->sqnNbr, FAIL);  break;
                    case R_GET:  signal DataStore.getDone(reqPtr->blockPtr, (reqPtr->blockPtr)->sqnNbr, FAIL);  break;
                    default: {
                        NOprintfUART("processNextRequest() - invalid reqPtr->requestType= %u\n", reqPtr->requestType);
                        call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE3);  // this is more serious
                        break;
                    }
                }
                atomic {
                    call RequestQueue.pop();
                    currState = S_READY;
                }
                post processNextRequest();
            }
            else {
                if (reqPtr->requestType == R_ADD)
                    performRequestAdd(reqPtr);
                else if (reqPtr->requestType == R_GET)
                    performRequestGet(reqPtr);
                else {
                    NOprintfUART("processNextRequest() - invalid reqPtr->requestType= %u\n", reqPtr->requestType);
                    call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE4);
                }
            }          
        }
        else {
            NOprintfUART("processNextRequest() - busy or Queue_size is zero, currState= %u, queueSize= %u\n", 
                        currState, call RequestQueue.size());    
        }
    }                                    

    command result_t DataStore.add(Block *blockPtr)
    {
        result_t queueResult = FAIL;
        Request nextReq;
        nextReq.requestType = R_ADD;
        nextReq.blockPtr = blockPtr;
        nextReq.blockSqnNbr = 0;     // not used with R_ADD; initialize to known value
        nextReq.nbrAttempts = 0;

        // Try to place the Request on the request queue
        atomic {queueResult = call RequestQueue.push(nextReq);}

        if (queueResult == SUCCESS) {
            NOprintfUART("DataStore.add() - success, queued request for, blockPtr= %p\n", blockPtr);
            atomic {
                if (currState == S_READY)
                    post processNextRequest();
            }
            return SUCCESS;
        }
        else {
            // Handle the unique case when the queue was full and a post processNextRequest() failed 
            // because the task queue was full
            atomic {
                if (currState == S_READY)
                    post processNextRequest();
            }         
            NOprintfUART("DataStore.add() - FAILED!, queued request for, blockPtr= %p\n", blockPtr);            
            return FAIL;
        }
    }

    event void BlockWrite.writeDone[volume_t parID](storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) 
    { 
        Block *blockPtr = (Block*) buf;

        if (result != STORAGE_OK) {
            NOprintfUART("BlockWrite.writeDone[%u]() - FAILED BlockWrite.writeDone(), blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                        parID, blockPtr, buf, addr, len);
            // Note, we signal FAIL in processNextRequest() after a set number of attempts
        }
        else {        
            Request request;
            NOprintfUART("BlockWrite.writeDone[%u]() - success BlockWrite.writeDone(), blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                        parID, blockPtr, buf, addr, len);
                                                                                    
            // (1) - Dequeue the request
            atomic request = call RequestQueue.pop();

            // Sanity check
            if (blockPtr->sqnNbr != request.blockSqnNbr) {
                // something went terribly wrong
                NOprintfUART("BlockWrite.writeDone[%u]() - FAILED!, blockPtr->sqnNbr=%lu != request.blockSqnNbr=%lu\n", 
                            parID, blockPtr->sqnNbr, request.blockSqnNbr);
                printCurrState();
                call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE5);
                signal DataStore.addDone(blockPtr, blockPtr->sqnNbr, FAIL);
            }
            else {
                // (2) - Update the head and tail
                atomic head = getBlockHandle(head.blockSqnNbr + 1);
                                                  
                // Erase the tail volume if we have to, and update the tail
                if (head.blockSqnNbr - tail.blockSqnNbr == DS_NBR_BLOCKS - DS_NBR_BLOCKS_PER_VOLUME + 1) {
                    volume_t eraseParID = DS_VOLS[tail.volumeIndex].parID;

                    atomic {
                        tail.volumeIndex  = (tail.volumeIndex + 1) % DS_NBR_VOLUMES;
                        tail.blockIndex   = 0;
                        tail.blockSqnNbr += DS_NBR_BLOCKS_PER_VOLUME;
                    }

                    printCurrState();
                    atomic currState = S_ERASING_VOLUME;
                    if ( call BlockWrite.erase[eraseParID]() ) { 
                        NOprintfUART(">>>>>>>>>>>>>>>>>>>> BlockWrite.writeDone[%u]() - success BlockWrite[%u].erase()\n", parID, eraseParID);
                        signal DataStore.addDone(blockPtr, blockPtr->sqnNbr, SUCCESS);
                        return;
                    }
                    else  {
                        NOprintfUART(">>>>>>>>>>>>>>>>>>>> BlockWrite.writeDone[%u]() - FAILED! BlockWrite[%u].erase()\n", parID, eraseParID); 
                        printCurrState();
                        call ErrorToLeds.errorToLeds(1, ERRORTOLEDS_DATASTORE11);
                    }
                }

                // (4) - Signal addDone
                signal DataStore.addDone(blockPtr, blockPtr->sqnNbr, SUCCESS);
            }
        }

        // in case there are pending requests
        atomic currState = S_READY;
        post processNextRequest();
    }


    command result_t DataStore.get(Block *blockPtr, blocksqnnbr_t blockSqnNbr)
    {
        // First, make sure we have the current block in Flash
        if ( !haveBlock(blockSqnNbr) ) {                  
            NOprintfUART("DataStore.get() - FAILED! blockSqnNbr= %lu not in FLASH\n", blockSqnNbr);
            return FAIL;    
        }
        else {
            result_t queueResult = FAIL;
            Request nextReq;
            nextReq.requestType = R_GET;
            nextReq.blockPtr = blockPtr;
            nextReq.blockSqnNbr = blockSqnNbr;
            nextReq.nbrAttempts = 0;

            // Try to place the Request on the request queue
            atomic {queueResult = call RequestQueue.push(nextReq);}

            if (queueResult) {
                NOprintfUART("DataStore.get() - success, queued request for, blockPtr= %p, blockSqnNbr= %lu\n", 
                           blockPtr, blockSqnNbr);
                atomic {
                    if (currState == S_READY)
                        post processNextRequest();
                }
                return SUCCESS;
            }
            else {
                // Handle the unique case when the queue was full and a post processNextRequest() failed 
                // because the task queue was full
                atomic {
                    if (currState == S_READY)
                        post processNextRequest();
                }         

                NOprintfUART("DataStore.get() - FAILED!, queued request for, blockPtr= %p, blockSqnNbr= %lu\n", 
                           blockPtr, blockSqnNbr);
                return FAIL;
            }                   
        }
    }
         
    event void BlockRead.readDone[volume_t parID](storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) 
    { 
#ifdef DATASTORE_DEBUG_PRINT_ENABLED
        // (1) - Debug print the datastore
        if (currState == S_DEBUG_PRINTING) {  
            if (result == STORAGE_OK)
                { /*NOprintfUART("BlockRead.readDone[%u]() - success DataStore.debugPrintDataStore(), debugBlock= %p, len= %lu\n", 
                             parID, buf, len);*/ }
            else 
                { NOprintfUART("BlockRead.readDone[%u]() - FAILED! DataStore.debugPrintDataStore(), debugBlocks= %p, len= %lu\n", 
                             parID, buf, len); }

            // DEBUG, print the datastore and return
            DataStore_print(&debugBlock, debugNextBlockIndexToGet); 
            atomic debugNextBlockIndexToGet++; 

            // print and schedule the next block
            if (debugNextBlockIndexToGet < (DS_NBR_VOLUMES*DS_NBR_BLOCKS_PER_VOLUME)) { 
                debugPrintDataStoreBlock(debugNextBlockIndexToGet);
            }
            else { // we are done
                atomic currState = S_READY;
                post processNextRequest();
            }                   
            return;
        }
#endif
        // (2) - Normal mode
        {
            Block *blockPtr = (Block*) buf;

            if (result == STORAGE_OK) {
                Request request;
                NOprintfUART("BlockRead.readDone[%u]() - success(), blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                            parID, blockPtr, buf, addr, len);
                Block_print(blockPtr);

                // (1) - Dequeue the request, return the memory, and change state
                atomic {
                    request = call RequestQueue.pop();
                }   
                
                // (2) - Sanity check and signal SUCCESS or FAIL
                if (blockPtr->sqnNbr == request.blockSqnNbr) {                                   
                    signal DataStore.getDone(blockPtr, blockPtr->sqnNbr, SUCCESS);
                }
                else {
                    NOprintfUART("BlockRead.readDone[%u]() - FAILED!, blockPtr->sqnNbr=%lu != request.blockSqnNbr=%lu\n", 
                                parID, blockPtr->sqnNbr, request.blockSqnNbr);
                    signal DataStore.getDone(blockPtr, blockPtr->sqnNbr, FAIL);
                }
            }
            else {
                NOprintfUART("BlockRead.readDone[%u]() - FAILED!, blockPtr= %p, buf= %p, addr= %lu, len= %lu\n", 
                            parID, blockPtr, buf, addr, len);
                // Note, we signal FAIL in processNextRequest() after a set number of attempts
            }
            
            // in case there are pending requests
            atomic currState = S_READY;
            post processNextRequest(); 
        }
    }


#ifdef DATASTORE_DEBUG_PRINT_ENABLED
    result_t debugPrintDataStoreBlock(uint16_t blockIndex)
    {
        volume_t volID = blockIndex / DS_NBR_BLOCKS_PER_VOLUME;
        block_addr_t volAddr = (blockIndex % DS_NBR_BLOCKS_PER_VOLUME) * sizeof(debugBlock);

        if ( call BlockRead.read[volID](volAddr, &debugBlock, sizeof(debugBlock)) ) {
            //NOprintfUART("DataStore.debugPrintDataStore()) - success BlockRead.read[%u](), debugBlock= %p, len= %u\n", 
            //            volID, &debugBlock, sizeof(debugBlock));
            return SUCCESS;
        }
        else {
            NOprintfUART("!!!!!!!!!! DataStore.debugPrintDataStore()) - FAILED! BlockRead.read[%u](), debugBlock= %p, len= %lu\n", 
                        volID, &debugBlock, sizeof(debugBlock));            
            atomic currState = S_READY;
            post processNextRequest();
            return FAIL;
        }
    }

    void DataStore_print(Block *blockPtr, uint16_t blockIndex)
    {
        volume_t volumeIndex = blockIndex / DS_NBR_BLOCKS_PER_VOLUME;

        if (blockIndex == 0) {
            NOprintfUART("\n========== DataStore_print() - for debugDSBlock (%p) ==========\n", blockPtr);
            NOprintfUART("    tail= <volumeIndex= %lu, blockIndex= %lu, blockSqnNbr= %lu>\n", tail.volumeIndex, tail.blockIndex, tail.blockSqnNbr);
            NOprintfUART("    head= <volumeIndex= %lu, blockIndex= %lu, blockSqnNbr= %lu>\n", head.volumeIndex, head.blockIndex, head.blockSqnNbr);
        }                                                
        if (blockIndex % DS_NBR_BLOCKS_PER_VOLUME == 0)
            {NOprintfUART("\n+++++ volumeIndex= %lu +++++\n", volumeIndex);}

        Block_print(blockPtr);

        if (blockIndex+1 == DS_NBR_VOLUMES*DS_NBR_BLOCKS_PER_VOLUME)
            {NOprintfUART("=====================================================================\n", "");}
    }
#endif

    command result_t DataStore.debugPrintDataStore()
    {                                                                            
#ifdef DATASTORE_DEBUG_PRINT_ENABLED
        debugPrintParams();

        if (currState == S_READY) {
            atomic currState = S_DEBUG_PRINTING;
            atomic debugNextBlockIndexToGet = 0;
            return debugPrintDataStoreBlock(debugNextBlockIndexToGet);
        }
#else
        NOprintfUART("DataStore.debugPrintDataStore() - FAILED! DATASTORE_DEBUG_PRINT_ENABLED not enabled!\n", "");
        return FAIL;
#endif
    }

    // ----- BlockRead -----
    default command result_t BlockRead.read[blockstorage_t blockId](block_addr_t addr, void* buf, block_addr_t len) { return FAIL; }
    default command result_t BlockRead.verify[blockstorage_t blockId]() { return FAIL; }
    default command result_t BlockRead.computeCrc[blockstorage_t blockId](block_addr_t addr, block_addr_t len) { return FAIL; }

    event void BlockRead.verifyDone[volume_t parID](storage_result_t result) { return; }                                           
    event void BlockRead.computeCrcDone[volume_t parID](storage_result_t result, uint16_t crc, block_addr_t addr, block_addr_t len) { return; }


    // ----- BlockWrite -----
    default command result_t BlockWrite.write[blockstorage_t blockId](block_addr_t addr, void* buf, block_addr_t len) { return FAIL; }
    default command result_t BlockWrite.erase[blockstorage_t blockId]() { return FAIL; }
    default command result_t BlockWrite.commit[blockstorage_t blockId]() { return FAIL; }

    event void BlockWrite.commitDone[volume_t parID](storage_result_t result) { return; }

    result_t eraseVolume(volume_t volIndex) 
    {
        volume_t parID = DS_VOLS[volIndex].parID;

        if ( call BlockWrite.erase[parID]() ) {
            NOprintfUART(">>>>>>>>>>>>>>>>>>>> eraseVolume() - success BlockWrite.erase[%u]()\n", parID);
            return SUCCESS;
        }
        else {
            NOprintfUART(">>>>>>>>>>>>>>>>>>>> eraseVolume() - FAILED! BlockWrite.erase[%u]()\n", parID);
            if (currState == S_INITIALIZING) {
                signal DataStore.initDone(FAIL);
            }
            call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE6);
            return FAIL;            
        }           
    }

    event void BlockWrite.eraseDone[volume_t parID](storage_result_t result) 
    { 
        if (result == STORAGE_OK) { 
            NOprintfUART("<<<<<<<<<<<<<<<<<<<< BlockWrite.eraseDone[%u]() - successfully erased\n", parID); 

            // check if we are in the initialization phase
            if (currState == S_INITIALIZING) {                 
                nextVolumeIndexToMount++;
                // Check if we have more volumes to erase
                if (nextVolumeIndexToMount < DS_NBR_VOLUMES)
                    eraseVolume(nextVolumeIndexToMount);
                else {
                    atomic currState = S_READY;  // we are done
                    signal DataStore.initDone(SUCCESS);
                }
            }
            else if (currState == S_ERASING_VOLUME) {
                printCurrState();
                // in case there are pending requests
                atomic currState = S_READY;
                post processNextRequest();
            }                                   
        }
        else {      
            NOprintfUART("<<<<<<<<<<<<<<<<<<<< BlockWrite.eraseDone[%u]() - FAILED to erase\n", parID); 

            // only exit program if we are in the initialization phase
            if (currState == S_INITIALIZING) {
                call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE7);
                signal DataStore.initDone(FAIL);
            }
            call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE7);
        }           
    }

    // ----- Mount -----
    default command result_t Mount.mount[blockstorage_t blockId](volume_id_t id) { return FAIL; }

    result_t mountVolume(volume_t volIndex) 
    {
        volume_t parID = DS_VOLS[volIndex].parID;

        if ( call Mount.mount[parID](DS_VOLS[volIndex].volID) ) {
            NOprintfUART("mountVolume() - successfully scheduled Mount[%u].mount(%u)\n", parID, DS_VOLS[volIndex].volID);             
            return SUCCESS;
        }
        else {                
            NOprintfUART("mountVolume() - FAILED! to scheduled Mount[%u].mount(%u)\n", parID, DS_VOLS[volIndex].volID);
            if (currState == S_INITIALIZING) {
                call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE8);

                // if we haven't already tried to format the datastore, try to format and then mount again
                if (!triedToFromatDataStore)
                    formatDataStore();
                else
                    signal DataStore.initDone(FAIL);
            }
            return FAIL;
        }
    }

    event void Mount.mountDone[volume_t parID](storage_result_t result, volume_id_t id) 
    { 
        if (result == STORAGE_OK) {
            NOprintfUART("Mount.mountDone[%u]() - successfully mounted, parID= %u\n", parID, id);
                     
            // check if we are in the initialization phase
            if (currState == S_INITIALIZING) {                 
                nextVolumeIndexToMount++;
                // Check if we have more volumes to mount
                if (nextVolumeIndexToMount < DS_NBR_VOLUMES)
                    mountVolume(nextVolumeIndexToMount);
                else {
#ifdef DS_ERASE_VOLUMES_ENABLED
                    // If we formated, there is no need to erase because the formatting also erased.
                    if (triedToFromatDataStore) {
                        atomic currState = S_READY;  // we are done
                        signal DataStore.initDone(SUCCESS);
                    }
                    else {
                        // We are done mounting.  Now proceed with erasing.
                        nextVolumeIndexToMount = 0;
                        eraseVolume(nextVolumeIndexToMount);
                    }                      
#else
                    // We are done mounting.  No need to erase because the formatting also erased.
                    atomic currState = S_READY;  // we are done
                    signal DataStore.initDone(SUCCESS);
#endif
                }
            }
        }
        else {        
            NOprintfUART("Mount.mountDone[%u]() - WARNING! FAILED to mount, parID= %u\n", parID, id);
            // only exit program if we are in the initialization phase
            if (currState == S_INITIALIZING) {
                call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE9);
                // if we haven't already tried to format the datastore, try to format and then mount again
                if (!triedToFromatDataStore)
                    formatDataStore();
                else
                    signal DataStore.initDone(FAIL);
            }
        }
    }

    // ----- StorageRemap -----
    default command uint32_t StorageRemap.physicalAddr[blockstorage_t blockId](uint32_t id) { return STORAGE_INVALID_ADDR; }

    void formatDataStore() 
    {
        uint16_t i = 0;
        result_t result = FAIL;
        call Leds.yellowOn();
        NOprintfUART("formatDataStore() - called\n");
        triedToFromatDataStore = TRUE;


        // (1) - Initialize storage
        result = call FormatStorage.init();
        NOprintfUART("formatDataStore() - FormatStorage.init() called: result= %u\n", result);

//#ifdef USE_DELUGE
        // (2.1) - Allocate for Deluge
        result = rcombine(call FormatStorage.allocateFixed(0xDF, 0xF0000, STORAGE_BLOCK_SIZE), (uint16_t)result);
        result = rcombine(call FormatStorage.allocate(0xD0, STORAGE_BLOCK_SIZE), result);
        result = rcombine(call FormatStorage.allocate(0xD1, STORAGE_BLOCK_SIZE), result);
//#endif
        // (2.2) - Allocate for DataStore
        for (i = 0; i < DS_NBR_VOLUMES && i < STM25P_NUM_SECTORS; ++i) {            
            result = rcombine(call FormatStorage.allocate(i, STORAGE_BLOCK_SIZE), result);
            NOprintfUART("formatDataStore() - FormatStorage.allocate() called: volumeIndex= %u, volumeSize= %lu,  result= %u\n", 
                       i, STORAGE_BLOCK_SIZE, result);        
        }

        // (3) - Commit
        result = rcombine(call FormatStorage.commit(), result);
        NOprintfUART("formatDataStore() - FormatStorage.commit() called: result= %u\n", result);

        if (result != SUCCESS) {
            call Leds.yellowOff();
            NOprintfUART("formatDataStore() - FAILED! to allocate, and schedule commit\n");
            call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE10);
        }
        else {
            NOprintfUART("formatDataStore() - sucessfully allocated, and scheduled commits\n");
        }
    }
  
    event void FormatStorage.commitDone(storage_result_t result) 
    {
        if (result == STORAGE_OK) {
            call Leds.greenOn();
            NOprintfUART("FormatStorage.commitDone() - success\n");
            // proceed with mounting
            atomic nextVolumeIndexToMount = 0;
            mountVolume(nextVolumeIndexToMount);
        }
        else {
            call Leds.redOn();
            NOprintfUART("FormatStorage.commitDone() - FAILED!\n");        
            call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_DATASTORE12);
        }
    }
}

