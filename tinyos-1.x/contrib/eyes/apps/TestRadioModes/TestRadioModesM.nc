/* -*- mode:c++; indent-tabs-mode: nil -*- */
// $Id: TestRadioModesM.nc,v 1.2 2005/09/20 08:32:41 andreaskoepke Exp $

/*                                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */

module TestRadioModesM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer as ModeTimer;
    interface Timer as TxTimer;
    interface LedsNumbered as Leds;
    interface TDA5250Modes;
    interface TDA5250Config;
    interface PacketTx;
    interface PacketRx;
    interface ByteComm;
    interface Random;
  }
}

implementation {
  
  #define MODE_TIMER_RATE 200
  #define TX_TIMER_RATE   200
  #define NUM_PREAMBLES   25
  
  uint8_t mode;
  norace bool transmitting;
   
  command result_t StdControl.init() {
    call Random.init();
    call Leds.init();
    atomic mode = 0;
    atomic transmitting = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;  
  }

  command result_t StdControl.stop() {
    return call TxTimer.stop();
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/
   
  void task SendStart() {
    if(call PacketTx.start(call Random.rand() % NUM_PREAMBLES) == FAIL)
      post SendStart();
  }
  
  void task SetTxTimer() {
    if(call TxTimer.start(TIMER_ONE_SHOT, call Random.rand() % TX_TIMER_RATE) == FAIL)
      post SetTxTimer();  
  }
  
  void task SetModeTimer() {
    if(call ModeTimer.start(TIMER_ONE_SHOT, call Random.rand() % MODE_TIMER_RATE) == FAIL)
      post SetTxTimer();  
  }  
   
   
  event result_t TxTimer.fired() {
    atomic transmitting = TRUE;
    if(call PacketTx.start(call Random.rand() % NUM_PREAMBLES) == FAIL)
      post SendStart();
    return SUCCESS;
  }

  event result_t ModeTimer.fired() {
    if(transmitting == FALSE) {
      if(mode == 0) {
        call TDA5250Modes.SleepMode();
        atomic mode = call Random.rand() % 4;
        call Leds.led0On();
        call Leds.led1Off();
        call Leds.led2Off();
        call Leds.led3Off();       
      }
      else if(mode == 1) {
        call TDA5250Modes.SetTimerMode(call Random.rand() % MODE_TIMER_RATE/20, call Random.rand() % MODE_TIMER_RATE/20);    
        atomic mode = call Random.rand() % 4;
        call Leds.led0Off();
        call Leds.led1On();
        call Leds.led2Off();
        call Leds.led3Off();        
      }     
      else if(mode == 2) {
        call TDA5250Modes.SetSelfPollingMode(call Random.rand() % MODE_TIMER_RATE/20, call Random.rand() % MODE_TIMER_RATE/20);
        atomic mode = call Random.rand() % 4;
        call Leds.led0Off();
        call Leds.led1Off();
        call Leds.led2On();
        call Leds.led3Off();    
      }
      else {
        call TDA5250Modes.RxMode();
        atomic mode = call Random.rand() % 4;
        call Leds.led0Off();
        call Leds.led1Off();
        call Leds.led2Off();
        call Leds.led3On();
      }   
    }
    if(call ModeTimer.start(TIMER_ONE_SHOT, call Random.rand() % MODE_TIMER_RATE) == FAIL)
      post SetModeTimer();
    return SUCCESS;
  }
  
  async event void TDA5250Modes.interrupt() {
    //call TDA5250Modes.RxMode();
  }
  
  event result_t TDA5250Modes.ready() {
    call TxTimer.start(TIMER_ONE_SHOT, call Random.rand() % TX_TIMER_RATE);
    call ModeTimer.start(TIMER_ONE_SHOT, MODE_TIMER_RATE);
    call PacketRx.reset();
    return SUCCESS;
  }
  
  async event result_t ByteComm.txByteReady(bool success) {
    call PacketTx.stop();
    return success;
  }
  
  async event void PacketRx.detected() {
    call PacketRx.reset();
  }
  
  async event result_t PacketTx.done() {  
      result_t res;
      if(mode == 0) {
          res = call TDA5250Modes.RxMode();
      }
      else if(mode == 1) {
          res = call TDA5250Modes.SleepMode();
      }
      else if(mode == 2) {
          res = call TDA5250Modes.ResetTimerMode();
      }
      else {
          res = call TDA5250Modes.ResetSelfPollingMode();
      }
      if(res != SUCCESS) {
          atomic {
              ;
          }
      }
      atomic transmitting = FALSE;
      post SetTxTimer();
      return SUCCESS;
  } 
  
  event result_t TDA5250Config.ready() {   
    return SUCCESS;
  }  
  
  async event result_t ByteComm.txDone() {
    return SUCCESS;
  }  
   
  async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) {
    return SUCCESS;
  }
  
  event result_t TDA5250Modes.RxModeDone(){
     return SUCCESS;
  }
  event result_t TDA5250Modes.SleepModeDone(){
     return SUCCESS;
  }
  event result_t TDA5250Modes.CCAModeDone(){
     return SUCCESS;
  }  
  
}


