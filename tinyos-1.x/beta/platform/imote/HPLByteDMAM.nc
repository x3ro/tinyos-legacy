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
 * This module uses the DMA mode to implement the 1 byte HPLUART interface
 * Note this should not be used if other modules intend to use the DMA
 * interface directly, as this module will always control the receive
 */

includes motelib;

module HPLByteDMAM {
    provides interface HPLUART; 
    uses interface HPLUART as UART;
    uses interface HPLDMA as DMA;
    uses interface Timer;
}

implementation
{
#define DEFAULT_BAUDRATE eTM_B115200
    
#define RETRY_DELAY 5000
#define NUM_RETRIES 100

    uint8 baudrate = DEFAULT_BAUDRATE;
    extern tTOSBufferVar *TOSBuffer __attribute__ ((C)); 
    uint8 retries;


    async command result_t HPLUART.init() {
       uint32 temp;
       
       call UART.setRate(baudrate);
       call UART.init();
       temp = TM_UartLineOfStatus(TM_MainUartReg);
       if ((temp & 0x1E) == 0) {
           call DMA.DMAGet(TOSBuffer->UARTRxBuffer,1);
           retries = 0;
           return SUCCESS;
       }
       retries = NUM_RETRIES;
       call Timer.start(TIMER_ONE_SHOT, RETRY_DELAY);
       return FAIL;
    }
    
    command result_t HPLUART.setRate(uint8 newbaudrate){
       baudrate=newbaudrate;
       return SUCCESS;
    }
    
    async command result_t HPLUART.stop() {
        return SUCCESS;
    }
    
    async command result_t HPLUART.put(uint8_t data) {
        TOSBuffer->UARTTxBuffer[0] = data;
        call DMA.DMAPut(TOSBuffer->UARTTxBuffer, 1);
        return SUCCESS;
    }

    async event uint8* DMA.DMAGetDone(uint8 *data, uint16 Bytes) {
       if (Bytes == 1) {
          signal HPLUART.get(*data);
       } 
       return TOSBuffer->UARTRxBuffer;
    }

    async event result_t DMA.DMAPutDone(uint8 *data) {
        signal HPLUART.putDone();
        return SUCCESS;
    }

    async event result_t UART.get(uint8 data) { 
       return SUCCESS;
    }

    async event result_t UART.putDone() { 
       return SUCCESS; 
    }

    event result_t Timer.fired() {
       uint32 temp;
       if (retries > 0) {
          call UART.init();
          temp = TM_UartLineOfStatus(TM_MainUartReg);
          if ((temp & 0x1E) == 0) {
              call DMA.DMAGet(TOSBuffer->UARTRxBuffer,1);
              retries = 0;
              return SUCCESS;
          }
          retries--;
          call Timer.start(TIMER_ONE_SHOT, RETRY_DELAY);
        }
    }
}
