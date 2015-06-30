/*									tab:4
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:   Alec Woo, Shawn Schaffert
 *
 */

module TestTempM {
  provides {
    interface StdControl;  
  }
  uses {
    interface Clock;
    interface Leds;  
    interface StdControl as TempControl;
    interface StdControl as CommControl;
    interface SendMsg;
    interface ReceiveMsg;
    interface ADC as TempADC;
  }
}

implementation {

  uint8_t clockState;
  uint8_t sensorState;
  uint8_t sendPending;
  TOS_Msg message;

  command result_t StdControl.init() {
    clockState = 0;
    sensorState = 0;
    sendPending = 0;

    call Leds.init();
    call CommControl.init();
    call TempControl.init();

    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call Clock.setRate(TOS_I1PS, TOS_S1PS);
  }
  
  command result_t StdControl.stop() {
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }


  event result_t Clock.fire() {
    if (clockState == 0) {
      clockState = 1;
      call Leds.redOn();
      call TempADC.getData();
    } else {
      clockState = 0;
      call Leds.redOff();
    }
    return SUCCESS;
  }

  event result_t TempADC.dataReady(uint16_t data) {
    uint16_t* dataToSend = (uint16_t*) message.data;
    *dataToSend = data;
    if (sensorState == 0) {
      sensorState = 1;
      call Leds.greenOn();
    } else {
      sensorState = 0;
      call Leds.greenOff();
    }
    if (call SendMsg.send( TOS_UART_ADDR, sizeof(uint16_t), &message ) )
      sendPending = 1;
    return SUCCESS;
  }


  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    if ( sent == &message )
      sendPending = 0;
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    return msg;
  }

}















