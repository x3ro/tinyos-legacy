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

module BTBufferM
{
  provides interface BTBuffer;

  uses interface Memory;
}

implementation
{


  command result_t BTBuffer.Initialize () {

    return (call Memory.initialize(NULL));

  }



  command char *BTBuffer.AllocateBuffer (uint16 BufferSize) {
    uint16   bytesNeeded;
    char *   dataPtr;

    bytesNeeded = BufferSize + LOWER_LEVEL_HEADER_SIZE;
    if ((dataPtr = call Memory.alloc(bytesNeeded)) == NULL) return NULL;

    return (&(dataPtr[LOWER_LEVEL_HEADER_SIZE]));
  }


  command result_t BTBuffer.ReleaseBuffer (char *BufferPtr) {
    char *   dataPtr;

    dataPtr = (char *) ((uint32) BufferPtr - LOWER_LEVEL_HEADER_SIZE);

    return (call Memory.free(dataPtr));
  }



  command uint16 BTBuffer.GetLargestFreeBlock() {

    return (call Memory.available() - LOWER_LEVEL_HEADER_SIZE);
  }



  command result_t BTBuffer.IsAllocated (char *BufferPtr) {
    char *   dataPtr;

    dataPtr = (char *) ((uint32) BufferPtr - LOWER_LEVEL_HEADER_SIZE);

    return (call Memory.isAllocated(dataPtr));
  }

}
