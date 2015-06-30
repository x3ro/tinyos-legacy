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

includes Block;

module FakeDataStoreM {
  provides {
    interface StdControl;
    interface DataStore;
  } uses {
    interface ErrorToLeds;
    interface Leds;
  }
} implementation {
  
  uint32_t currentBlockSequenceNumber;

  command result_t StdControl.init() {
    currentBlockSequenceNumber = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void task signalInitDone() {
    signal DataStore.initDone(SUCCESS);
  }

  command result_t DataStore.init() {
      //signal DataStore.initDone(SUCCESS);
      if (post signalInitDone() == FAIL)
          return FAIL;
      else
          return SUCCESS;
  }

  inline void setKnownBlockPattern(Block *blockPtr, blocksqnnbr_t sqnNbr)
  {
      uint16_t i = 0;
      blockPtr->sqnNbr = sqnNbr;
      for (i = 0; i < BLOCK_DATA_SIZE; ++i)
          blockPtr->data[i] =  (blockPtr->sqnNbr + i) % 256;      
  }

  command result_t DataStore.add(Block * blockPtr) {
    signal DataStore.addDone(blockPtr,
                             currentBlockSequenceNumber++,
                             SUCCESS);
    return SUCCESS;
  }

  command result_t DataStore.get(Block * blockPtr, 
                                 blocksqnnbr_t blockSqnNbr) {
#ifdef KNOWN_BLOCK_PATTERN
      setKnownBlockPattern(blockPtr, blockSqnNbr);
#else
    Block_init(blockPtr);
    blockPtr->sqnNbr = blockSqnNbr;
#endif

    signal DataStore.getDone(blockPtr, blockSqnNbr, SUCCESS);
    return SUCCESS;
  }

  command void DataStore.getAvailableBlocks(blocksqnnbr_t *tailBlockSqnNbr, 
                                            blocksqnnbr_t *headBlockSqnNbr) {
    *tailBlockSqnNbr = 0;
    *headBlockSqnNbr = currentBlockSequenceNumber;
    return;
  }

  command uint16_t DataStore.getQueueSize() {
    return 0;
  }

  command result_t DataStore.saveInfo() {return SUCCESS;}
  command result_t DataStore.reset()    {return SUCCESS;}


  command result_t DataStore.debugPrintDataStore() {
    return SUCCESS;
  }
}
