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
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250, switching modes and initializing.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2005/09/20 08:32:42 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module EncoderDecoderM {
  provides {
    interface StdControl;
    interface ByteComm as MarshallerByteComm;
    interface PacketTx as MarshallerPacketTx;
  }
  uses {
    interface RadioEncoding as Codec;
    interface PacketTx as RadioPacketTx;
    interface ByteComm as RadioByteComm;
    interface PacketRx;
  }
}

implementation {
   #define TX_BUFFER_SIZE     3

   uint8_t txBuf[TX_BUFFER_SIZE];  // Buffer for holding bytes before they are sent
   uint8_t bufHead;  // Pointer to current head of Buffer
   uint8_t bufTail;  // Pointer to current tail of Buffer
   
   /**************** Radio Init  *****************/
   command result_t StdControl.init(){
     atomic {
       bufHead = 0;
       bufTail = 0;
     }     
     return SUCCESS;
   }

   /**************** Radio Start  *****************/
   command result_t StdControl.start(){
     return SUCCESS;
   }

   /**************** Radio Stop  *****************/
   command result_t StdControl.stop(){
      return SUCCESS;
   }
   
   async event void PacketRx.detected() {
     call Codec.reset();
   }   
   
   async command result_t MarshallerPacketTx.start(uint16_t numPreambles) {
     result_t res = call RadioPacketTx.start(numPreambles);
     if(res == SUCCESS) signal MarshallerByteComm.txByteReady(SUCCESS);
     return res;
   }
   
   async command result_t MarshallerByteComm.txByte(uint8_t data) {
     call Codec.encode(data);
     return SUCCESS;
   }
   
   async command result_t MarshallerPacketTx.stop() {
     return call RadioPacketTx.stop();
   }
   
   async event result_t RadioPacketTx.done() {
     return signal MarshallerPacketTx.done();
   }   
   
  async event result_t Codec.decodeDone(char data, char error) {
    return signal MarshallerByteComm.rxByteReady(data, error, 0);
  }
  
  async event result_t Codec.encodeDone(char data) {
    atomic {
      txBuf[bufTail] = data;
      bufTail = (bufTail+1) % TX_BUFFER_SIZE;
    }
    return SUCCESS;
  }
   
   /**************** USART Tx Done ****************/
   async event result_t RadioByteComm.txByteReady(bool success) {
     result_t Result = FAIL;
     atomic {
       call RadioByteComm.txByte(txBuf[bufHead]);
       bufHead = (bufHead+1) % TX_BUFFER_SIZE;
       if(bufTail == bufHead)
         Result = SUCCESS;
     }
     if(Result == SUCCESS)  
       signal MarshallerByteComm.txByteReady(success); 
     return success;
   }

   /**************** USART Rx Done ****************/
   async event result_t RadioByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) { 
     call Codec.decode(data);
     return SUCCESS;
   }
   
  async event result_t RadioByteComm.txDone() {
    return signal MarshallerByteComm.txDone();
  }
}
