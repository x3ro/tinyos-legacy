/* -*- mode:c++; indent-tabs-mode: nil -*-
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
 * $Revision: 1.14 $
 * $Date: 2005/09/22 13:02:13 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module BasicLLCM {
   provides {
      interface StdControl;
      interface ReceiveMsg as Receive;
      interface BareSendMsg as Send;
   }
   uses {
      interface GenericMsgComm;
      interface MarshallerControl;
      interface TimerJiffy as RxPacketTimeout;
      interface TimerJiffy as BackOffTimer;    
      interface Random;      
      interface PacketRx;
      interface RSSImV;
   }
}
implementation
{
   #define NUM_PREAMBLES            2
   #define BYTE_DURATION            17
   #define AUX_BYTES                8
    //Max Time of one packet asuming 19200 baud rate
   #define RX_PACKET_TIMEOUT        (BYTE_DURATION*(MSG_DATA_SIZE + AUX_BYTES))
   #define CONGESTION_BACKOFF_MAX   (BYTE_DURATION*(MSG_DATA_SIZE + AUX_BYTES))
   #define INITIAL_BACKOFF_MAX      2*TRANSMITTER_SETUP_TIME   

   bool txBusy;
   bool txBackoff;
   bool rxBusy;
   TOS_Msg rxMsg;           // receive buffer
   TOS_Msg* rxBufPtr;        // receive buffer pointer
   TOS_Msg* txBufPtr;        // receive buffer pointer
      
   result_t SendNext(TOS_Msg* msg);
   
   void SetInitialBackoffTimer();
   void SetCongestionBackoffTimer();   
   
   task void PacketSentSuccess();
   task void PacketSentFail();
   task void PacketRcvd();
   task void RxPacketTimeoutTask();
   task void SetCongestionBackoffTask();
   task void SetInitialBackoffTask();   

   /**************** Init  *****************/
   command result_t StdControl.init(){
     call Random.init();
     atomic {
       txBusy = FALSE;
       rxBusy = FALSE;
       txBackoff = FALSE;
       rxBufPtr = &rxMsg;
       txBufPtr = NULL;
     }
     call MarshallerControl.setProperties(MSG_HEADER_SIZE, LENGTH_BYTE_NUMBER, 
                                          NUM_PREAMBLES, TOSH_DATA_LENGTH, BYTE_DURATION);
     return SUCCESS;
   }

   /**************** Start  *****************/
   command result_t StdControl.start(){
      return SUCCESS;
   }

   /**************** Stop  *****************/
   command result_t StdControl.stop(){
      return SUCCESS;
   } 
   
   /**************** Send ****************/
   command result_t Send.send(TOS_Msg *msg) {
     result_t Result = FAIL;
     atomic {
       if (txBusy == FALSE && rxBusy == FALSE) {
         txBusy = TRUE;
         txBufPtr = msg;
         Result = SUCCESS;
       }
     }
     if (Result) {
       atomic txBackoff = TRUE;
       SetInitialBackoffTimer();
     }
       
     return Result;   
   }
   
   task void SetInitBackoffTask() {
     SetInitialBackoffTimer();
   }   
   
   void SetInitialBackoffTimer() {
     uint16_t random = call Random.rand() % INITIAL_BACKOFF_MAX;
     if(call BackOffTimer.setOneShot(random) == FAIL)
       post SetInitBackoffTask();
   }    
   
  async event void PacketRx.detected() {
    if(txBusy == TRUE && txBackoff == FALSE) {
      call PacketRx.reset();
    } else if(rxBusy == FALSE) {
        rxBusy = TRUE;
        rxBufPtr->strength = 0xFFFF;
        post RxPacketTimeoutTask();
        call RSSImV.getData();      
        call GenericMsgComm.recvNext((uint8_t*)rxBufPtr);    
    } else {
        rxBusy = FALSE;
        call PacketRx.reset();
    }
  }   
   
  result_t SendNext(TOS_Msg* msg) {
    if(call GenericMsgComm.sendNext((uint8_t*)msg) == FAIL) {
      atomic txBusy = FALSE;
      return FAIL;
    }
    return SUCCESS;
  }
  
  task void SetCongestBackoffTask() {
    SetCongestionBackoffTimer();
  } 
  
  void SetCongestionBackoffTimer() {
    uint16_t random = call Random.rand() % CONGESTION_BACKOFF_MAX;
    if(call BackOffTimer.setOneShot(random) == FAIL)
      post SetCongestBackoffTask();
  }  
  
  async event result_t GenericMsgComm.sendDone(uint8_t* sent, result_t result) { 
    atomic txBufPtr->ack = 1;
    if(result == SUCCESS)
      post PacketSentSuccess();
    else {
      atomic txBackoff = TRUE;
      post SetCongestBackoffTask();
    }
    return SUCCESS;
  }

  /**
   * Signalled when the reset message counter AM is received.
   * @return The free TOS_MsgPtr. 
   */
  async event result_t GenericMsgComm.recvDone(uint8_t* msgPtr, bool crc) {
    atomic {
      rxBufPtr = (TOS_Msg*)msgPtr;
      rxBufPtr->crc = crc;
    }
    post PacketRcvd();
    return SUCCESS;
  }
  
   /* Posted once a message is completely sent */
   task void PacketSentSuccess() {
     TOS_MsgPtr pBuf;
     atomic {
       txBusy = FALSE;
       pBuf = txBufPtr;
     }
     signal Send.sendDone(pBuf, SUCCESS);
   }
   
   /* Posted once a message is completely sent */
   task void PacketSentFail() {
     TOS_MsgPtr pBuf;
     atomic {
       txBusy = FALSE;
       pBuf = txBufPtr;
     }
     signal Send.sendDone(pBuf, FAIL);
   }   

   /* Posted once a message is completely received */
   task void PacketRcvd() {
      TOS_MsgPtr pBuf;
      atomic {
        pBuf = rxBufPtr;
        rxBusy = FALSE;
      }
      call PacketRx.reset();
      call RxPacketTimeout.stop();
      pBuf = signal Receive.receive(pBuf);
      atomic {
        rxBufPtr = pBuf;
      }
   }
   
   event result_t RxPacketTimeout.fired() {
     atomic {
       rxBusy = FALSE;
       call PacketRx.reset();
     }
     return SUCCESS;
   }   
   
   event result_t BackOffTimer.fired() {
     bool currentRxBusy;
     atomic currentRxBusy = rxBusy;
     if(currentRxBusy == FALSE) {
       if(SendNext(txBufPtr) == FAIL)
         post PacketSentFail();
       else atomic txBackoff = FALSE;
     }
     else 
       SetCongestionBackoffTimer();       
     return SUCCESS;
   }    
  
  task void RxPacketTimeoutTask() {
    if(call RxPacketTimeout.setOneShot(RX_PACKET_TIMEOUT) == FAIL)
      post RxPacketTimeoutTask();
  }  
  
  async event result_t RSSImV.dataReady(uint16_t data) {
    atomic rxBufPtr->strength = data;
    return SUCCESS;
  }     
  
 /**
   * Signalled when the previous packet has been sent.
   * @return Always returns SUCCESS.
   */
  default event result_t Send.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }

  /**
   * Signalled when the reset message counter AM is received.
   * @return The free TOS_MsgPtr. 
   */
  default event TOS_MsgPtr Receive.receive(TOS_MsgPtr m) {
    return m;
  }     
}




#if 0
   #define INITIAL_BACKOFF_MAX          2*TRANSMITTER_SETUP_TIME




   void SetInitialBackoffTimer();
   void SetCongestionBackoffTimer();
   
   task void SetInitBackoffTask() {
     SetInitialBackoffTimer();
   }   
   
   void SetInitialBackoffTimer() {
     uint16_t random = call Random.rand() % INITIAL_BACKOFF_MAX;
     if(call BackOffTimer.setOneShot(random) == FAIL)
       post SetInitBackoffTask();
   }   
      
   task void SetCongestBackoffTask() {
     SetCongestionBackoffTimer();
   }
     
   void SetCongestionBackoffTimer() {
     uint16_t random = call Random.rand() % CONGESTION_BACKOFF_MAX;
     if(call BackOffTimer.setOneShot(random) == FAIL)
       post SetCongestBackoffTask();
   } 
#endif

