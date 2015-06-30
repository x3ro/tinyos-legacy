/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * This module manages the BRAM memory buffers.  The hardware requires that data
 * sent over the radio is allocated in BRAM memory.  This module has been
 * implemented with this application in mind.
 *
 * The lower levels of the radio stack attach packet headers in front of the 
 * higher level packets to implement the lower level protocols.  To avoid
 * copying data, enough space is allocated in front of the requested buffer to
 * accomodate the lower level headers.  The data pointer returned by the
 * allocate routine refers to the data region available for use by the calling
 * application.  This is the same pointer which should be passed to the network
 * send routine.  The allocate routine will reserve space in front of this
 * region and the send routine will prepend the appropriate headers in that same
 * space.
 */

module MemoryM
{
  provides {
    interface Memory;
  }
}

implementation
{
  typedef struct tMemoryBlock {
    struct tMemoryBlock *next;
    char *Memory; // pointer to memory block returned to higher level (not header)
    uint16 Length; // length of memory block, including space for header
    uint16 dummy; //pad to 4-byte boundary
  } tMemoryBlock;

  tMemoryBlock *FreeList, *AllocatedList;



  command result_t Memory.initialize (char *base) {

    if (base == NULL) {
      // App's space
      FreeList = (tMemoryBlock *) &(TOSBuffer->AppMemory[0]);
    } else {
      FreeList = (tMemoryBlock *) base;
    }
    FreeList->next = NULL;
    FreeList->Memory = (char *) ((uint32)FreeList + sizeof(tMemoryBlock));

    // MAX_APP_MEMORY is defined in TOSBufferVar.h
    FreeList->Length = MAX_APP_MEMORY - sizeof(tMemoryBlock);

    AllocatedList = NULL;

    return SUCCESS;
  }



  command char *Memory.alloc (uint16 BufferSize) {
    uint16 BytesNeeded;
    tMemoryBlock *MemoryPtr;
    int i;
    uint32 newMem;

    // BufferSize must be 4-byte aligned
    BufferSize = (BufferSize + 3) & ~0x3;

    BytesNeeded = BufferSize + sizeof(tMemoryBlock);
    MemoryPtr = FreeList;

    while (MemoryPtr != NULL) {
      if (BytesNeeded <= MemoryPtr->Length) {
        // take memory block from the end
        MemoryPtr->Length -= BytesNeeded; // decrease free block's length
        // move pointer to allocated block
        newMem = ((uint32) MemoryPtr + sizeof(tMemoryBlock) + MemoryPtr->Length);
        MemoryPtr = (tMemoryBlock *) newMem;
        MemoryPtr->Memory = (char *) ((uint32) MemoryPtr + sizeof(tMemoryBlock));

        MemoryPtr->Length = BytesNeeded - sizeof(tMemoryBlock);
        MemoryPtr->next = AllocatedList;
        AllocatedList = MemoryPtr;

        for (i = 0; i < BufferSize; i++) MemoryPtr->Memory[i] = 0;
        return MemoryPtr->Memory;
      } 
      MemoryPtr = MemoryPtr->next;
    }
    return NULL;
  }



  command result_t Memory.free (char *BufferPtr) {
    tMemoryBlock *FreeBlock, *ptr, **pptr;

    // find memory block in allocated list and remove it
    FreeBlock = NULL;
    pptr = &AllocatedList;

    while (*pptr != NULL) {
      if (BufferPtr == (*pptr)->Memory) { // found it
        FreeBlock = *pptr;
        *pptr= FreeBlock->next;
      } else { // keep looking
        pptr = &((*pptr)->next);
      }
    }

    if (FreeBlock == NULL) { // could not find it
      return FAIL;
    }

    // add memory block back into free list. Maintain a sorted list and merge
    // blocks as possible.
    ptr = FreeList;
    // find list element after which to insert the new free block
    while ((ptr->next != NULL) && (ptr->next < FreeBlock)) ptr = ptr->next;

    // Insert free block into FreeList
    // should we merge new free block with subsequent block?
    if ((uint32)FreeBlock + FreeBlock->Length + sizeof(tMemoryBlock) ==
       (uint32)ptr->next) {

      FreeBlock->Length += ptr->next->Length + sizeof(tMemoryBlock);
      FreeBlock->next = ptr->next->next;
    } else {
      FreeBlock->next = ptr->next;
    }

    // should we merge new free block with previous block?
    if ((uint32)ptr + ptr->Length + sizeof(tMemoryBlock) == (uint32)FreeBlock) {
      ptr->Length += FreeBlock->Length + sizeof(tMemoryBlock);
      ptr->next = FreeBlock->next;
    } else { // insert new free block into list
      ptr->next = FreeBlock;
    }
        

    return SUCCESS;
  }



  command uint16 Memory.available() {
    uint16       LargestLength;
    tMemoryBlock *MemoryPtr;

    LargestLength = 0;
    MemoryPtr = FreeList;

    while (MemoryPtr != NULL) {
      if (MemoryPtr->Length > LargestLength) LargestLength = MemoryPtr->Length;
      MemoryPtr = MemoryPtr->next;
    }
    if ( LargestLength > 0) {
      LargestLength -= sizeof(tMemoryBlock);
    }

    return LargestLength;
  }



  // returns true if the memory pointer is in the allocated list
  command result_t Memory.isAllocated (char *BufferPtr) {
    tMemoryBlock *ptr;

    // find memory block in allocated list
    ptr = AllocatedList;

    while (ptr != NULL) {
      if (BufferPtr == ptr->Memory) return SUCCESS;
      ptr = ptr->next;
    }
    return FAIL;
  }

  command char *Memory.getAllocatedBlock() {
    if (AllocatedList != NULL) return AllocatedList->Memory;

    return NULL;
  }

  command uint16 Memory.getBlockSize(char *BufferPtr) {
    tMemoryBlock *ptr;

    // find memory block in allocated list
    ptr = AllocatedList;

    while (ptr != NULL) {
      if (BufferPtr == ptr->Memory) {
        return (ptr->Length - sizeof(tMemoryBlock));
      }
      ptr = ptr->next;
    }
    return 0;
  }
}
