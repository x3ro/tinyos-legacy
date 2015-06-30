/*
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Authors: Chris Karlof
 * Date:    9/26/02
 */

/**
 * Module to exercise the block cipher interface
 */
module TestTinySecM {
  provides {
    interface StdControl;
    interface IntOutput;
  }
  uses {
    interface SendMsg as Send;
    interface ReceiveMsg as ReceiveIntMsg;
    interface Leds;
  }
}

implementation {
  /**
   * Init method which does the work of testing the interface.
   */
  bool state;
  struct TOS_Msg data;
  uint8_t value;

  task void sendit(){
    //  if(TOS_LOCAL_ADDRESS == 0) {
      (data.data)[0] = 8;
      (data.data)[1] = 8;
      (data.data)[2] = 8;
      (data.data)[3] = 8;
      (data.data)[4] = 4;
      (data.data)[5] = 4;
      (data.data)[6] = 4;
      (data.data)[7] = 4;
      (data.data)[8] = 2;
      (data.data)[9] = 2;
      (data.data)[10] = value;
      call Send.send(TOS_BCAST_ADDR,11,&data);
      //}
  }
 
  command result_t StdControl.init() {
    state = FALSE;
    call Leds.init();
    value = 0;
    //call Leds.redOn();
    //post sendit();
  return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr m, result_t s) {
    call Leds.greenToggle();
     return s;
  }

  command result_t StdControl.start() {
    //return call Clock.setRate(TOS_I1PS, TOS_S1PS);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    //return call Clock.setRate(TOS_I0PS, TOS_S0PS);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveIntMsg.receive(TOS_MsgPtr m) {
    //IntMsg *message = (IntMsg *)m->data;

    if((m->data)[0] == 8 &&
       (m->data)[1] == 8 &&
       (m->data)[2] == 8 &&
       (m->data)[3] == 8 &&
       (m->data)[4] == 4 &&
       (m->data)[5] == 4 &&
       (m->data)[6] == 4 &&
       (m->data)[7] == 4 &&
       (m->data)[8] == 2 &&
       (m->data)[9] == 2 
       // && (m->data)[10] == value
       ) {
          dbg(DBG_USR1,"USR1: Received msg at app layer\n");

	  call Leds.yellowOn();
    } else {
      call Leds.redOn();
      dbg(DBG_USR1,"USR1: Received at app layer - NOT_VALID!\n");
    }
    return m;
  }

  command result_t IntOutput.output(uint16_t v) {
    value = (uint8_t) v;
    call Leds.yellowToggle();
    dbg(DBG_USR1,"USR1: Clock interrupt - sending packet\n");
    post sendit();
    signal IntOutput.outputComplete(SUCCESS);
    return SUCCESS;
  }
}
