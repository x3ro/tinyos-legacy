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

/* Authors:  David Gay  <dgay@intel-research.net>
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
