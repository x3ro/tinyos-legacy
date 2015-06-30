/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.

 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.

 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 * Authors:  David Gay  <dgay@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */
/** 
 * This module implement a 
 * simple test program which sends a message every second for testing mig
 * The interfaces used are Leds, Clock, StdControl, SendMsg and ReceiveMsg
 **/
// See tools/java/net/tinyos/tests/mig1 for the java side of things
includes Mig1Msg;

module Mig1M
{
  provides interface StdControl;
  uses {
    interface Leds;
    interface Clock;
    interface StdControl as CommControl;
    interface SendMsg as SendMig1Msg;
    interface ReceiveMsg as ReceiveMig1Msg;
  }
}
implementation
{
  uint8_t counter;
  TOS_Msg msg;			/* Message to be sent out */
  bool sendPending;		/* Variable to store counter of buffer*/

/** 
  * Moduole Initialization
  * start clock and set it to fire every second
  * initialize module variables,  
  * initialize the underlying communication stack.
  * @return SUCCESS if the comm stack is initilized without error
  *         FAIL  otherwise
 **/
  command result_t StdControl.init() {
    counter = 0;
    sendPending = FALSE;
    call Clock.setRate(TOS_I1PS, TOS_S1PS);
    dbg(DBG_BOOT, "Mig1 initialized\n");
    return call CommControl.init();
  }

/**
 * hardcode the data portion of a AM message for Mig test
 * @return Always return SUCCESS
 **/

  command result_t StdControl.start() {
    Mig1Msg *m = (Mig1Msg *)msg.data;

    m->f1 = -2;
    m->f2 = 100;
    m->f3 = 0x80000000;
    m->f4 = 12.2;
    m->f5 = -2;
    m->f6 = 7;
    m->f7 = 42;
    m->f8 = 54;

    return SUCCESS;
  }
/**
 * Do operation in this command
 * @return Alway return SUCCESS
 **/

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void sendComplete() {
    call Leds.greenOff();
    sendPending = FALSE;
  }

  /**
   *  Clock Event Handler: 
   *  Turn green Led on, send a broascasting message out
  **/
  event result_t Clock.fire() {
    if (!sendPending)
      {
	Mig1Msg *m = (Mig1Msg *)msg.data;

	sendPending = TRUE;

	m->counter = counter++;
	call Leds.greenOn(); /* Green LED while sending */
	if (call SendMig1Msg.send(TOS_BCAST_ADDR, sizeof(Mig1Msg), &msg) == FAIL)
	  sendComplete();
      }
    return SUCCESS;
  }

/** Event handler for SendMsg.sendDone event
 *  If the message sent belong to this module, 
 *  turn green LED off, clear the sendPending flag 
 *  @return Always return SUCCESS
 **/
  event result_t SendMig1Msg.sendDone(TOS_MsgPtr sent, result_t success) {
    //check to see if the message that finished was yours.
    //if so, then clear the sendPending flag.
    if (&msg == sent)
      sendComplete();

    return SUCCESS;
  }

/** Event handler for ReceiveMsg.receive event
 *  Toggle yellow Led, copy the data to a message buffer
 *  @return Return the original  data buffer  
 **/
  event TOS_MsgPtr ReceiveMig1Msg.receive(TOS_MsgPtr data) {
    call Leds.yellowToggle();
    memcpy(msg.data, data->data, sizeof msg.data);
    return data;
  }
}
