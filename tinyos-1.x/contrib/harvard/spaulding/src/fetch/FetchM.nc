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

#include "FetchMsgs.h"
//#include "DataStore.h"
#include "ErrorToLeds.h"
#include "Block.h"
#include "PrintfUART.h"

module FetchM                                      
{
    provides interface StdControl;
    //provides interface Fetch;
    
    //uses interface Send as SendToRoot;
    uses interface Leds;
    uses interface Timer;
    uses interface ErrorToLeds;
    uses interface DataStore;
    uses interface SendMsg;
    uses interface ReceiveMsg;
} 
implementation 
{    
    uint16_t sendAddr;
    TOS_Msg tosSendMsg;
    FetchReplyMsg *fetchRepMsgPtr;
    uint8_t data_buffer[sizeof(Block)];

    bool busyFetchingBlock = FALSE;
    bool blockValid = FALSE;
    uint32_t currBlockID;

    uint32_t origBitmask;
    uint32_t currBitmask;
    uint32_t segmentMask;

    bool isDataStoreInitialized = FALSE;

    // Delay between sending chunks to allow data to flow up the tree
#define SEND_DELAY 10


    // =================== Methods ====================
    event void DataStore.initDone(result_t result)
    {
        if (result == SUCCESS)
            atomic isDataStoreInitialized = TRUE;
        else
            call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_FETCH1);
    }

    command result_t StdControl.init() 
    {
        uint16_t i;
        atomic {
            isDataStoreInitialized = FALSE;

            fetchRepMsgPtr = (FetchReplyMsg*) tosSendMsg.data;        
            fetchRepMsgPtr->originaddr = TOS_LOCAL_ADDRESS;
        
            // Fill the block with fake data, for now
            for (i = 0; i < FETCH_BLOCK_SIZE; i++)
                data_buffer[i] = (uint8_t)(i & 0xff);
        }    
        printfUART_init();
        printfUART("FetchM:StdControl.init() - called\n", "");

        return SUCCESS;
    }

    command result_t StdControl.start() 
    {
        //if (call DataStore.init() == FAIL)
        //    call ErrorToLeds.errorToLeds(7, ERRORTOLEDS_FETCH2);
        return SUCCESS;
    }

    command result_t StdControl.stop() {return SUCCESS;}


    // Send the next chunk up to the base.
    task void sendNextSegment() 
    {
        atomic {
            if (currBitmask == 0) 
                return;  // we sent all segments, so return
        }
        atomic {
            fetchRepMsgPtr->block_id = currBlockID;

            // Look at current bitmask: what are we sending now?
            fetchRepMsgPtr->offset = 0;

            segmentMask = 0x01;
            while (((segmentMask & currBitmask) == 0) && 
                   (fetchRepMsgPtr->offset <= FETCH_BLOCK_SIZE - FETCH_SEGMENT_SIZE)) {
                segmentMask <<= 1;
                fetchRepMsgPtr->offset += FETCH_SEGMENT_SIZE;
            }
        }

        memcpy(fetchRepMsgPtr->data, &data_buffer[fetchRepMsgPtr->offset], FETCH_SEGMENT_SIZE);
        
        if (call SendMsg.send(sendAddr, sizeof(FetchReplyMsg), &tosSendMsg) == FAIL )
            atomic busyFetchingBlock = FALSE;
    }

    event result_t Timer.fired() 
    {
        // Still in a fetch cycle; send the next chunk
        if (!(post sendNextSegment()))
            atomic busyFetchingBlock = FALSE;

        return SUCCESS;
    }

/*    static result_t handleSendDone(TOS_MsgPtr msg, result_t success) 
    {
        if (success) {
            atomic currBitmask &= ~segmentMask;
            
            if (currBitmask != 0) {
                // Need to send next chunk
                if (SEND_DELAY == 0) {
                    if (!(post sendNextSegment()))
                        busyFetchingBlock = FALSE;                    
                } 
                else
                    call Timer.start(TIMER_ONE_SHOT, SEND_DELAY);
            } 
            else {
                // Done with this block
                busyFetchingBlock = FALSE;
                //call Leds.yellowToggle();
                signal Fetch.fetchDone(currBlockID, origBitmask);
            }
        } 
        else 
            busyFetchingBlock = FALSE;
        
        return SUCCESS;
    }*/

    //event result_t SendToRoot.sendDone(TOS_MsgPtr msg, result_t success) 
    event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success)
    {
        if (success) {
            atomic {
                currBitmask &= ~segmentMask;            
                if (currBitmask != 0) {
                    // Need to send next chunk
                    if (SEND_DELAY == 0) {
                        if (!(post sendNextSegment()))
                            busyFetchingBlock = FALSE;                    
                    } 
                    else
                        call Timer.start(TIMER_ONE_SHOT, SEND_DELAY);
                } 
                else {
                    // Done with this block
                    busyFetchingBlock = FALSE;
                }
            }
        } 
        else 
            atomic busyFetchingBlock = FALSE;
        
        return SUCCESS;
    }

    task void readBlock() 
    {
        // Read currBlockID from the Flash
        if (isDataStoreInitialized) {
            if (call DataStore.get((Block*)data_buffer, currBlockID) == FAIL) {
                atomic busyFetchingBlock = FALSE;
                printfUART("FetchM:readBlock() - FAILED, DataStore.get()\n", "");
            }
        }
        else
            atomic busyFetchingBlock = FALSE;
    }


    /*command result_t Fetch.fetch(uint32_t block_id, uint32_t bitmask) 
    {
        call Leds.greenToggle();
        atomic {
            if (busyFetchingBlock) {
                call Leds.redToggle();
                return FAIL;
            }

            busyFetchingBlock = TRUE;
            origBitmask = currBitmask = bitmask;

            if ((block_id == currBlockID) && (blockValid == TRUE)) {
                if (!post sendNextSegment())
                    busyFetchingBlock = FALSE;
            } 
            else {
                // Need to read block from memory
                blockValid = FALSE;
                currBlockID = block_id;
                if (!post readBlock())
                    busyFetchingBlock = FALSE;     
            }

            return SUCCESS;
        }
    }*/

    //command result_t Fetch.fetch(uint32_t block_id, uint32_t bitmask) 
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr tosMsgPtr)
    {
        printfUART("FetchM:ReceiveMsg.receive() - called\n", "");
        atomic {
            if (busyFetchingBlock) {                
                return tosMsgPtr;  // just drop the request
            }
            else {
                FetchRequestMsg *fReqMsgPtr = (FetchRequestMsg*) tosMsgPtr->data;
                uint32_t block_id = fReqMsgPtr->blockID;
                uint32_t bitmask  = fReqMsgPtr->bitmask;
                sendAddr = fReqMsgPtr->srcAddr;
                
                busyFetchingBlock = TRUE;
                origBitmask = currBitmask = bitmask;

                if (block_id == currBlockID && blockValid == TRUE) {
                    if (!post sendNextSegment())
                        busyFetchingBlock = FALSE;
                } 
                else {
                    // Need to read block from memory
                    blockValid = FALSE;
                    currBlockID = block_id;
                    if (!post readBlock())
                        busyFetchingBlock = FALSE;     
                }

                return tosMsgPtr;
            }
        }    
    }

    event result_t DataStore.addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result) {return result;}              

    event result_t DataStore.getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result) 
    {
        if (result == SUCCESS) {
            printfUART("FetchM:DataStore.getDone() - successfully got blockID= %i\n", blockSqnNbr);
            Block_print(blockPtr);
            atomic blockValid = TRUE;
            if (!(post sendNextSegment()))
                atomic busyFetchingBlock = FALSE;
        } 
        else
            atomic busyFetchingBlock = FALSE;
 
        return result;
    }
}

