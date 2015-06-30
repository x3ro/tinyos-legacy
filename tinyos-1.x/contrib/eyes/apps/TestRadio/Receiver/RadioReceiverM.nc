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
 * Basic Application testing functionality of receiving over the radio
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/07/20 15:58:04 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module RadioReceiverM {
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer as TimeoutTimer;
		interface Timer as ModeTimer;
    interface MarshallerControl;
    interface GenericMsgComm;
    interface TDA5250Modes;
    interface TDA5250Config;
    interface PacketRx;
  }
}

implementation {
  #define TIMER_RATE  250 //Milliseconds

  uint8_t byteStream[DATA_LENGTH + HEADER_SIZE];
	uint8_t sleeping;

  command result_t StdControl.init() {
    call Leds.init();
		sleeping = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;  
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event result_t TimeoutTimer.fired() {  
    call Leds.yellowToggle();
    call PacketRx.reset();
    return SUCCESS;
  }  
	
  event result_t ModeTimer.fired() {
		if(sleeping == FALSE)
		  call TDA5250Modes.SleepMode();
		else call TDA5250Modes.RxMode();
    return SUCCESS;
  }  	

  /***********************************************************************
   * Commands and events
   ***********************************************************************/
   
  event result_t TDA5250Config.ready() {   
    return SUCCESS;
  }
  
  event result_t TDA5250Modes.ready() {
    call MarshallerControl.setProperties(HEADER_SIZE, LENGTH_OFFSET, NUM_PREAMBLES, DATA_LENGTH);
		
    call TDA5250Modes.RxMode();
    return SUCCESS;
  } 
  
  async event result_t GenericMsgComm.recvDone(uint8_t* buf, bool crc) {
    call TimeoutTimer.stop();
    if(crc == TRUE)
      call Leds.redToggle();
    else call Leds.greenToggle();
    call PacketRx.reset();
    return SUCCESS;
  }  
  
  async event result_t PacketRx.detected() { 
    call TimeoutTimer.start(TIMER_ONE_SHOT, 120);
    call GenericMsgComm.recvNext(byteStream);    
    return SUCCESS;
  }     
  
  async event result_t GenericMsgComm.sendDone(uint8_t* buf, bool success) {
    return SUCCESS;
  }
  
  async event void TDA5250Modes.interrupt() {
  }  
  
  event result_t TDA5250Modes.SleepModeDone() {
	  sleeping = TRUE;
	  TOSH_TOGGLE_LED3_PIN();
		call ModeTimer.start(TIMER_ONE_SHOT, TIMER_RATE);
    return SUCCESS;
  }
  
  event result_t TDA5250Modes.CCAModeDone() {
    return SUCCESS;
  }
  
  event result_t TDA5250Modes.RxModeDone() {
	  sleeping = FALSE;
	  TOSH_TOGGLE_LED3_PIN();
		call ModeTimer.start(TIMER_ONE_SHOT, TIMER_RATE);
    return SUCCESS;
  }
}


