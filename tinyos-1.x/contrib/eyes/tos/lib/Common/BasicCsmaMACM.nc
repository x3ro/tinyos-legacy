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
 * $Revision: 1.6 $
 * $Date: 2005/09/22 13:02:13 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module BasicCsmaMACM {
   provides {
      interface StdControl;
      interface GenericMsgComm;
   }
   uses {
     interface GenericMsgComm as MarshallerGenericMsgComm;
     interface ChannelMonitor;
     interface ChannelMonitorControl;   
     interface TDA5250Modes as RadioModes;  
   }
}
implementation
{
   /**************** Module Global Variables  *****************/
   norace uint8_t* txBufPtr;
   
   /**************** Radio Init  *****************/
   command result_t StdControl.init(){
     atomic txBufPtr = NULL;
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
   
   task void RxModeTask() {
     if(call RadioModes.RxMode() == FAIL)
       post RxModeTask();   
   }
   
   task void ChannelMonitorStart() {
     if(call ChannelMonitor.start() == FAIL)
       post ChannelMonitorStart();
   }   
   
   /********** Radio setup complete after first power on *********/
   event result_t RadioModes.ready() {
     if(call RadioModes.RxMode() == FAIL)
       post RxModeTask();
     return SUCCESS;
   }      
   
   /**************** Radio Send ****************/
   async command result_t GenericMsgComm.sendNext(uint8_t *msg) {
     atomic txBufPtr = msg;
     return call RadioModes.CCAMode();
   }
   
   /********** Signalled once Radio assuredly set to CCA Mode *********/
   event result_t RadioModes.CCAModeDone() {
    if(call ChannelMonitor.start() == FAIL)
      call ChannelMonitorControl.updateNoiseFloor();
     return SUCCESS;
   }    
   
  event result_t ChannelMonitorControl.updateNoiseFloorDone() {
    if(call ChannelMonitor.start() == FAIL)
      post ChannelMonitorStart();   
    return SUCCESS;
  }   
   
   /**************** Radio Send ****************/
   async command result_t GenericMsgComm.recvNext(uint8_t *msg) {
     return call MarshallerGenericMsgComm.recvNext(msg);
   }  
   
 /**
   * Signalled when the previous packet has been sent.
   * @return Always returns SUCCESS.
   */
   
  async event result_t MarshallerGenericMsgComm.sendDone(uint8_t* sent, result_t result) {
    signal GenericMsgComm.sendDone(sent, result);
    if(call RadioModes.RxMode() == FAIL)
      post RxModeTask();    
    return SUCCESS;
  }
  
 /**
   * Signalled when the next packet has been recvd.
   * @return Always returns SUCCESS.
   */  
  async event result_t MarshallerGenericMsgComm.recvDone(uint8_t* recv, bool crc) {
    signal GenericMsgComm.recvDone(recv, crc);
    return SUCCESS;
  }    
  
  event result_t ChannelMonitor.channelBusy(int16_t snr) {
    signal GenericMsgComm.sendDone(txBufPtr, FAIL);  
    if(call RadioModes.RxMode() == FAIL)
       post RxModeTask();     
    return SUCCESS;
  }
  
  event result_t ChannelMonitor.channelIdle() {
    if(call MarshallerGenericMsgComm.sendNext(txBufPtr) == FAIL) {
      signal GenericMsgComm.sendDone(txBufPtr, FAIL); 
      if(call RadioModes.RxMode() == FAIL)
         post RxModeTask();
    }
    return SUCCESS;   
  }
  
   /********** Signalled once Radio assuredly set to Rx Mode *********/
   event result_t RadioModes.RxModeDone() {
     return SUCCESS;
   }   
   
   /********** Signalled once Radio assuredly set to Sleep Mode *********/
   event result_t RadioModes.SleepModeDone() {
     return SUCCESS;
   } 
   
   /********** Interrupt form radio when in sleep or self-polling mode *********/
   async event void RadioModes.interrupt() {
   }  
}

