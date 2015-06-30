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

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that Flex is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component

module TestDriverM {
  provides {
     interface HPLDMA;
     interface HPLUART;
  }
  uses {
     interface Timer;
  }
}

implementation
{
  uint8 *RxBuffer;
  uint16 BufferSize;

  async command result_t HPLUART.init() {
    return SUCCESS;
  }

  command result_t HPLUART.setRate(uint8 baudrate) {
    return SUCCESS;
  }

  async command result_t HPLUART.stop() {
    return SUCCESS;
  }


  async command result_t HPLUART.put(uint8_t data) {
     return SUCCESS;
  }
 
  async command result_t HPLDMA.DMAGet(uint8 *data, uint16 size) {
    call Timer.start(TIMER_REPEAT, 11);
    RxBuffer = data;
    BufferSize = size;
  }

  async command result_t HPLDMA.DMAPut(uint8 *newTxBuffer, uint16 newTxBytes) {
	  
    return SUCCESS;
  }

  event result_t Timer.fired() {
     uint8 i;
     // size should be multiple of 6
     for(i=0; i<BufferSize; i=i+6) {
        RxBuffer[i] = 0x0; 
        RxBuffer[i+1] = 0x8A;
        RxBuffer[i+2] = 0x20; 
        RxBuffer[i+3] = 0x9E;
        RxBuffer[i+4] = 0x40; 
        RxBuffer[i+5] = 0xBC;
     }
     RxBuffer = signal HPLDMA.DMAGetDone(RxBuffer, BufferSize);
  }

}
