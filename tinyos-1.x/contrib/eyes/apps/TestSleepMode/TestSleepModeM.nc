// $Id: TestSleepModeM.nc,v 1.3 2005/09/20 08:32:41 andreaskoepke Exp $

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

module TestSleepModeM {
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
    interface ByteComm;
  }
}

implementation {
  
  #define MODE_TIMER_RATE 2000
  #define TX_TIMER_RATE   500

  uint8_t mode;   
   
  command result_t StdControl.init() {
    call Leds.init();
    atomic mode = 0;
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
   
  event result_t TxTimer.fired() {
    call PacketTx.start(0);
    return SUCCESS;
  }

  event result_t ModeTimer.fired() {  
    if(mode == 0) {
      call TDA5250Modes.RxMode();
      atomic mode = 1;
      call Leds.led0On();
      call Leds.led1Off();
      call Leds.led2Off();
      call Leds.led3Off();       
     }
    else if(mode == 1) {
      call TDA5250Modes.SleepMode();
      atomic mode = 2;
      call Leds.led0Off();
      call Leds.led1On();
      call Leds.led2Off();
      call Leds.led3Off();        
     }     
    else {
      call TDA5250Modes.SetSelfPollingMode(MODE_TIMER_RATE/20, MODE_TIMER_RATE/20);
      atomic mode = 0;
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2On();
      call Leds.led3Off();
    } 
    return SUCCESS;
  }
  
  async event void TDA5250Modes.interrupt() {
    //call TDA5250Modes.RxMode();
    TOSH_TOGGLE_LED3_PIN();
  }
  
  event result_t TDA5250Modes.ready() {
    call TxTimer.start(TIMER_REPEAT, TX_TIMER_RATE);
    call ModeTimer.start(TIMER_REPEAT, MODE_TIMER_RATE);
    return SUCCESS;
  }
  
  event result_t TDA5250Config.ready() {   
    return SUCCESS;
  }  
  
  async event result_t ByteComm.txDone() {
    return SUCCESS;
  }
  
  async event result_t ByteComm.txByteReady(bool success) {
    call PacketTx.stop();
    return success;
  }
  
  async event result_t PacketTx.done() { 
    if(mode == 1) call TDA5250Modes.RxMode(); 
    else if(mode == 2) call TDA5250Modes.SleepMode();     
    else call TDA5250Modes.SetSelfPollingMode(MODE_TIMER_RATE/20, MODE_TIMER_RATE/20);
    //else call TDA5250Modes.ResetSelfPollingMode();
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


