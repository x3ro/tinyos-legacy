/* -*- mode:c++ -*-
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
 * $Revision: 1.4 $
 * $Date: 2005/09/20 08:32:42 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module RawDumpM
{
  provides interface RawDump;
  uses interface ByteComm;
}
implementation
{
  #define BUFSIZE 50
  #define BUFSIZE_INT (BUFSIZE + 1)

  enum {
    BUF_BUSY = 0x01,
    RAW_SENDING = 0x02 ,
    USE_SEPARATOR = 0x04 ,
    IS_BLOCKING = 0x08,
  };

  norace uint8_t state = 0;
  norace char ringBuf[BUFSIZE_INT];
  norace char *pStart = ringBuf;  // char to tranmit next
  norace char *pEnd = ringBuf;    // next free slot
  norace char separator;

  uint16_t bytesLeft()
  {
    if (pEnd >= pStart)
      return BUFSIZE_INT - (pEnd - pStart) - 1;
    else
      return pStart - pEnd;
  }

  void txNextByte()
  {
    uint8_t tState;
    atomic {
      tState = state;
      state |= RAW_SENDING;
    }
    if (!(tState & RAW_SENDING)){
      call ByteComm.txByte(*pStart++);
      if (pStart == ringBuf+BUFSIZE_INT)
        pStart = ringBuf;
    }
  }

  result_t actualDumpBytes(uint8_t *s, uint16_t length)
  {
    uint8_t tState;
    uint16_t i=0;

    atomic {
      tState = state;
      state |= BUF_BUSY;
    }
    if (tState & BUF_BUSY)
      return FAIL;
    else {
      if (length+1 <= bytesLeft()){
        for (i=0; i<length; i++){
          *pEnd++ = s[i];
          if (pEnd == ringBuf+BUFSIZE_INT)
            pEnd = ringBuf;
        }
        txNextByte();
      }
      state &= ~BUF_BUSY;
    }
    if (i==0)
      return FAIL;
    return SUCCESS;
  }


  result_t dumpBytes(uint8_t *s, uint16_t length)
  {
    if (!s || !length)
      return FAIL;
    if (!(state & IS_BLOCKING))
      return actualDumpBytes(s,length);
    else {
      if (READ_SR & SR_GIE)
        while (actualDumpBytes(s,length) == FAIL)
          ;
      else
        return FAIL;
    }
    return SUCCESS;
  }

  async command result_t RawDump.init(char s, bool blocking)
  {
    if (s != 0){
      separator = s;
      state |= USE_SEPARATOR;
    } else
      state &= ~USE_SEPARATOR;
    if (blocking)
      state |= IS_BLOCKING;
    else
      state &= ~IS_BLOCKING;
    return SUCCESS;
  }


  async command result_t RawDump.dumpString(char *s)
  {
    return dumpBytes(s, strlen(s));
  }

  async command result_t RawDump.dumpByte(uint8_t x)
  {
    char tmp[2] = {x};
    if (state & USE_SEPARATOR){
      tmp[1] = separator;
      return dumpBytes(tmp, 2);
    } else
      return dumpBytes(tmp, 1);
  }

  async command result_t RawDump.dumpWord(uint16_t x)
  {
    char tmp[3] = {*((char*) &x+1), *((char*) &x)};
    if (state & USE_SEPARATOR){
      tmp[2] = separator;
      return dumpBytes(tmp, 3);
    } else
      return dumpBytes(tmp, 2);
  }

  async command result_t RawDump.dumpLong(uint32_t x)
  {
    char tmp[5] = {*((char*) &x+3), *((char*) &x+2), *((char*) &x+1), *((char*) &x)};
    if (state & USE_SEPARATOR){
      tmp[4] = separator;
      return dumpBytes(tmp, 5);
    } else
      return dumpBytes(tmp, 4);
  }

  async command result_t RawDump.dumpNumAsASCII(uint32_t n)
  {
    char tmp[12] = {0};
    uint8_t i = 10;
    if (state & USE_SEPARATOR)
      tmp[i--] = separator;
    do {
      tmp[i--] = '0' + n % 10;
      n /= 10;
    } while (n > 0);
    return call RawDump.dumpString(tmp+i+1);
  }

  async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength){ return SUCCESS;  }

  async event result_t ByteComm.txByteReady(bool success)
  {
    if (pEnd != pStart){
      call ByteComm.txByte(*pStart++);
      if (pStart == ringBuf+BUFSIZE_INT)
        pStart = ringBuf;
    } else
      state &= ~RAW_SENDING;
    return SUCCESS;
  }

  async event result_t ByteComm.txDone()
  {
    return SUCCESS;
  }
}
