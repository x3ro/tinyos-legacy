/*									tab:4
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
/* Copyright (c) 2003, UC Berkeley, Intel Corp
 * Author: Fred Jiang, Kamin Whitehouse
 * Date last modified: 06/27/03
 */

module MicaCommTestM {
  provides interface StdControl;
  uses {
    interface ReceiveMsg;
    interface SendMsg;
    interface Timer;
    interface Leds;
  }
}

implementation {
  
  uint16_t destinationAddr;
  TOS_Msg msg;

  command result_t StdControl.init() {
    destinationAddr=0xFF01;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 2000);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    call Timer.stop();
  }
  
  task void timer_fire_task() {
    call SendMsg.send(destinationAddr,0, &msg);
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m){
    call Leds.redToggle();
    return m;
  }
	
  event result_t Timer.fired() {
    post timer_fire_task();
    return SUCCESS;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr m, result_t success){ 
    if(success==SUCCESS){
      call Leds.redToggle();
    }
    return SUCCESS;
  }
}

