/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/10/19 14:03:48 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
module TinyAllocArbiterM {
  provides interface MemAlloc as MemAllocProvided[uint8_t clientID];
  uses interface MemAlloc as MemAllocUsed;
}
implementation {
  bool m_memLock = FALSE;
  uint8_t m_clientID;

  bool getMemAllocLock(uint8_t clientID)
  {
    bool locked;
    atomic {
      locked = m_memLock;
      m_memLock = TRUE;
    }
    if (locked)
      return FALSE;
    m_clientID = clientID;
    return SUCCESS;
  }

  inline void releaseMemAllocLock()
  {
    m_memLock = FALSE;
  }
  
  command result_t MemAllocProvided.allocate[uint8_t clientID](HandlePtr handle, int16_t size)
  {
    result_t result;
    if (!getMemAllocLock(clientID))
      return FAIL;
    result = call MemAllocUsed.allocate(handle, size);
    if (result == FAIL)
      releaseMemAllocLock();
    return result;
  }
  
  event result_t MemAllocUsed.allocComplete(HandlePtr handle, result_t success)
  {
    releaseMemAllocLock();
    return signal MemAllocProvided.allocComplete[m_clientID](handle, success);
  }

  default event result_t MemAllocProvided.allocComplete[uint8_t clientID](
      HandlePtr handle, result_t success)
  {
    return FAIL;
  }


  command result_t MemAllocProvided.reallocate[uint8_t clientID](Handle handle, int16_t size)
  {
    result_t result;
    if (!getMemAllocLock(clientID))
      return FAIL;
    result = call MemAllocUsed.reallocate(handle, size);
    if (result == FAIL)
      releaseMemAllocLock();
    return result;
  }
    
  event result_t MemAllocUsed.reallocComplete(Handle handle, result_t success)
  {
    releaseMemAllocLock();
    return signal MemAllocProvided.reallocComplete[m_clientID](handle, success);
  }

  default event result_t MemAllocProvided.reallocComplete[uint8_t clientID](
      Handle handle, result_t success)
  {
    return FAIL;
  }

  

  command result_t MemAllocProvided.lock[uint8_t clientID](Handle handle)
  {
    return call MemAllocUsed.lock(handle);
  }
  
  command result_t MemAllocProvided.unlock[uint8_t clientID](Handle handle)
  {
    return call MemAllocUsed.unlock(handle);
  }

  command int16_t MemAllocProvided.free[uint8_t clientID](Handle handle)
  {
    return call MemAllocUsed.free(handle);
  }
  
  command result_t MemAllocProvided.compact[uint8_t clientID]()
  {
    result_t result;
    if (!getMemAllocLock(clientID))
      return FAIL;
    result = call MemAllocUsed.compact();
    if (result == FAIL)
      releaseMemAllocLock();
    return result;
  }

  event result_t MemAllocUsed.compactComplete()
  {
    releaseMemAllocLock();
    return signal MemAllocProvided.compactComplete[m_clientID]();
  }

  default event result_t MemAllocProvided.compactComplete[uint8_t clientID]()
  {
    return FAIL;
  }

  command int16_t MemAllocProvided.size[uint8_t clientID](Handle handle)
  {
    return call MemAllocUsed.size(handle);
  }

  command bool MemAllocProvided.isLocked[uint8_t clientID](Handle handle)
  {
    return call MemAllocUsed.isLocked(handle);
  }

  command uint16_t MemAllocProvided.freeBytes[uint8_t clientID]()
  {
    return call MemAllocUsed.freeBytes();
  }
}

