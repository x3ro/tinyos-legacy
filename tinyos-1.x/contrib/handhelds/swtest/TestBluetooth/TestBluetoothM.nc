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
 * Author: Steve Ayer
 *         February, 2007
 */

includes Message;
includes RovingNetworks;

module TestBluetoothM {
  provides{
    interface StdControl;
  }
  uses {
    interface StdControl as BTStdControl;

    interface Bluetooth;

    interface Leds;
    interface Timer;
  }
} 

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

  char msgbuf[60];
  bool ready;
  uint8_t charsReceived;

  command result_t StdControl.init() {
    call Leds.init();

    sprintf(msgbuf, "we did it abcdefghij pushing the speed envelope un");
    ready = FALSE;
    charsReceived = 0;

    call BTStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    //    call Bluetooth.setRadioMode(SLAVE_MODE);
    //    call Bluetooth.setDiscoverable(TRUE);
    //    call Bluetooth.resetDefaults();
    call Bluetooth.setName("TestMule0");
    call BTStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call BTStdControl.stop();
    return SUCCESS;
  }

  task void sendStuff() {
    call Bluetooth.write(msgbuf, strlen(msgbuf));
  }

  async event void Bluetooth.connectionMade(uint8_t status) { 
    call Leds.yellowOff();
    if(ready)
      call Timer.start(TIMER_REPEAT, 10);
  }

  async event void Bluetooth.commandModeEnded() { 
    atomic ready = TRUE;
    call Leds.greenOn();
  }
    
  async event void Bluetooth.connectionClosed(uint8_t reason){
    call Leds.yellowOn();
  }

  async event void Bluetooth.dataAvailable(uint8_t data){
  }

  event void Bluetooth.writeDone(){
  }

  event result_t Timer.fired() {
    post sendStuff();
    return SUCCESS;
  }
}

