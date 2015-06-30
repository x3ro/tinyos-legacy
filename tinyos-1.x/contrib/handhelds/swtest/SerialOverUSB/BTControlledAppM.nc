/*
 * Copyright (c) 2007, Intel Corporation
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
 *
 * Author:  Steve Ayer
 *          February 2007
 */

includes msp430baudrates;
includes Message;
includes RovingNetworks;

module BTControlledAppM {
  provides{
    interface StdControl;
  }
  uses {
    interface StdControl as BTStdControl;
    interface Bluetooth;
    interface HPLUSARTControl as UARTControl;
    interface HPLUSARTFeedback as UARTFeedback;
    interface MessagePool;
    interface Leds;
    interface Timer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

  norace bool transmissionComplete, ready;
  struct Message * transMsg;
  uint8_t charsSent;

  void setupUART() {
    call UARTControl.setClockSource(SSEL_SMCLK);
    call UARTControl.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);
    call UARTControl.setModeUART();
    call UARTControl.enableTxIntr();
    call UARTControl.enableRxIntr();
  }

  command result_t StdControl.init() {
    call Leds.init();

    transmissionComplete = ready = FALSE;

    call BTStdControl.init();

    call MessagePool.init();
    transMsg = call MessagePool.alloc();

    setupUART();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Bluetooth.resetDefaults();
    call Bluetooth.setName("foo");
       
    call BTStdControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call BTStdControl.stop();
  }

  event result_t Timer.fired() {
    return SUCCESS;
  }

  task void sendOneChar() {
    if(charsSent < msg_get_length(transMsg)){
      call UARTControl.tx(msg_get_uint8(transMsg, charsSent));
      call Leds.redToggle();
      charsSent++;
    } 
    else{
      transmissionComplete = TRUE;
      msg_clear(transMsg);
    }
  }

  void sendString() {
    charsSent = 0;
    transmissionComplete = FALSE;
    post sendOneChar();
  }

  async event void Bluetooth.connectionMade(uint8_t status) { 
    call Leds.orangeOn();
    //    call Timer.start(TIMER_REPEAT, 1000);
  }

  async event void Bluetooth.commandModeEnded() { 
    call Leds.greenOn();
    atomic ready = TRUE;
  }
    
  async event void Bluetooth.connectionClosed(uint8_t reason){
    call Leds.orangeOff();

    call Timer.stop();
  }

  async event void Bluetooth.dataAvailable(uint8_t data){
    if(data != '\n')
      msg_append_uint8(transMsg, data);
    else{
      call Leds.yellowOn();
      sendString();
    }
  }

  event void Bluetooth.writeDone(){
  }

  async event result_t UARTFeedback.txDone() {
    if(!transmissionComplete) {
      post sendOneChar();
    }
    return SUCCESS;
  }
    
  async event result_t UARTFeedback.rxDone(uint8_t data) {        
    return SUCCESS;
  }

  
}
