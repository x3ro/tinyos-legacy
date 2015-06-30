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
 * Interface for the data store module.  Inserted blocks are copied for internal storage.
 * 
 * @author Konrad Lorincz
 * @version 1.0 - April 20, 2005
 */
#include "Block.h"

interface DataStore
{   
    /**
     * Initializes the DataStore.  This MUST be called before using
     * the DataStore.  Note: The initialization process make take a
     * while.  
     *
     * @return <code>SUCCESS</code> if the initialization was
     *   scheduled succesfull; <code>FAIL</code> otherewise
     */
    command result_t init();

    /**
     * Signals that the initialization was completed.
     *
     * @param result <code>SUCCESS</code> if the initialization was
     *   completed succesfully; <code>FAIL</code> otherewise
     */
    event void initDone(result_t result);

    /**
     * Adds the new block to the DataStoreInsert new sample chunks.
     * The client MUST NOT modify the supplied block until after an
     * addDone() 

     * @param blockPtr A pointer to the block to be added 
     * @return <code>SUCCESS</code> if the insertion was scheduled succesfully;
     *   <code>FAIL</code> otherewise
     */
    command result_t add(Block *blockPtr);
        
    /**
     * Signal when the add operation completed.
     *
     * @param blockPtr pointer to the block added        
     * @param blockSqnNbr the sequence number assigned to the inserted
     *   block.  Only valid if the insertion completed successfully!
     * @param result <code>SUCCESS</code> if the insertion completed
     *   successfully; <code>FAIL</code> otherewise
     */
    event result_t addDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result);
        
    /**
     * Gets the block with blockSqnNbr and copies it to the supplied block pointer blockPtr.
     *
     * @param blockPtr  pointer to where the content of the block should be copied to
     * @param blockSqnNbr  the sequence number of the block to be retrieved
     * @return <code>SUCCESS</code> if the get was scheduled succesfully;
     *   <code>FAIL</code> otherewise
     */
    command result_t get(Block *blockPtr, blocksqnnbr_t blockSqnNbr);

    /**
     * Signal when the get operation completed.
     *
     * @param blockPtr pointer to where the block was copied to
     * @param blockSqnNbr the sequence number of the requested block. 
     *   Only valid if the insertion completed successfully!
     * @param result <code>SUCCESS</code> if the retrieval completed
     *   successfully; <code>FAIL</code> otherewise
     */
    event result_t getDone(Block *blockPtr, blocksqnnbr_t blockSqnNbr, result_t result);

    /**
     * Returns the range of blocks currently stored in the DataStore.
     *
     * @param *tailBlockSqnNbr pointer to where to copy the first available blockSqnNbr
     * @param *tailBlockSqnNbr pointer to where to copy the next available blockSqnNbr. 
     *        NOTE: this is exclusive!
     */
    command void getAvailableBlocks(blocksqnnbr_t *tailBlockSqnNbr, blocksqnnbr_t *headBlockSqnNbr);

    /**
     * Returns the number of pending operations.
     *
     * @return the number of queued operations
     */
    command uint16_t getQueueSize();

    /**
     * Writes the head and tail block sqn nbr to flash for persistance across reboots.
     *
     * @param result <code>SUCCESS</code> if it was saved;
     *   successfully; <code>FAIL</code> otherewise
     */
    command result_t saveInfo();

    /**
     * Reset the head and tail squence numbers on flash
     *
     * @param result <code>SUCCESS</code> if it was saved;
     *   successfully; <code>FAIL</code> otherewise
     */
    command result_t reset();

    /**
     * Prints the content of the DataStore to the screen using
     * PrintfUART.  IMPORTANT, make sure the Flash size is not defined
     * to be too big when using this!  It's intended for debugging only.
     * (I will probably remove this from the DataStore interface)
     */
    command result_t debugPrintDataStore();
}

