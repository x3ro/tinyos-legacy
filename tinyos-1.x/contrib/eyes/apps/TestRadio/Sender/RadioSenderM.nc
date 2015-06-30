/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * - Description ----------------------------------------------------------
 * Basic Application testing functionality of sending over the radio
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/07/20 15:58:04 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

includes AM;
module RadioSenderM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface Random;
    interface MarshallerControl;
    interface GenericMsgComm;
    interface TDA5250Modes;    
    interface TDA5250Config;  
  }
}

implementation {

  #define TIMER_RATE 250 //Milliseconds

  norace uint8_t byteStream[DATA_LENGTH + HEADER_SIZE];

  command result_t StdControl.init() {
    call Leds.init();
    call Random.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;  
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/
  event result_t TDA5250Config.ready() {
    return SUCCESS;
  }
  
  event result_t TDA5250Modes.ready() {
    int i;
    call MarshallerControl.setProperties(HEADER_SIZE, LENGTH_OFFSET, NUM_PREAMBLES, DATA_LENGTH);
    byteStream[LENGTH_OFFSET] = DATA_LENGTH;
     
    for(i=HEADER_SIZE; i<HEADER_SIZE+DATA_LENGTH; i++)
      byteStream[i] = call Random.rand();     
        
    call Timer.start(TIMER_REPEAT, TIMER_RATE);  
    return SUCCESS;
  }
  
  event result_t Timer.fired() {
    return call GenericMsgComm.sendNext(byteStream);
  }  
  
  async event result_t GenericMsgComm.sendDone(uint8_t* buf, bool success) { 
	  call Leds.redToggle();
    call TDA5250Modes.SleepMode();
    return SUCCESS;
  }
  
  async event void TDA5250Modes.interrupt() {
  }  
  
  event result_t TDA5250Modes.SleepModeDone() {
    return SUCCESS;
  }
  
  event result_t TDA5250Modes.CCAModeDone() {
    return SUCCESS;
  }
  
  event result_t TDA5250Modes.RxModeDone() {
    return SUCCESS;
  }  
  
  async event result_t GenericMsgComm.recvDone(uint8_t* buf, bool crc) {
    return SUCCESS;
  }
}


