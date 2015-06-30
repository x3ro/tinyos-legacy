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
 * This module provides a generic block i/o interface to the hardware's flash
 * Read operations directly access the flash.  Write operations must first
 * call getWriteBlock to get a memory pointer to an in-core copy of the
 * flash contents.  The block can then be manipulated.  After all modifications
 * are done the block is written back to the flash with the commitBlock command.
 *
 * The number of writable blocks is limited by the in-core memory allocation,
 * currently set to <8 blocks.
 */



module HPLFlashM {

  provides {
    interface Flash;
  }

}



implementation
{
//#undef TM_FLASH_TOS
//#define TM_FLASH_TOS 0

  /*
   * Gets a memory pointer to a block for reading.  In this implementation
   * the memory is accessed directly from flash.  This pointer cannot be used
   * to modify the contents in flash.  Any writes to the pointer will result
   * in unpredicted behavior.
   */

  command void *Flash.getReadBlock(int blockIndex) {
    return TM_API_GetFlashReadPtr(blockIndex + TM_FLASH_TOS);
  }



  /*
   * Gets a memory pointer to a block for writing.  The contents of the block
   * can be read or written using this pointer.  Changes to the block are not
   * committed until the commitBlock command is called.
   */

  command void *Flash.getWriteBlock(int blockIndex) {
    return TM_API_GetFlashWritePtr(blockIndex + TM_FLASH_TOS, BLOCK_SIZE);
  }



  /*
   * Write a block from core memory back into flash memory and deallocate the
   * pointer.  Future writes to the same block must first call getWriteBlock.
   */
  command result_t Flash.commitBlock(int blockIndex) {
    TM_API_FlashWriteDone(blockIndex + TM_FLASH_TOS);
    return SUCCESS;
  }

}

