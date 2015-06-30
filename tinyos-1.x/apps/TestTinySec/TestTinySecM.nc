// $Id: TestTinySecM.nc,v 1.3 2003/10/29 02:14:56 ckarlof Exp $

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

/* Authors: Chris Karlof
 * Date:    8/21/03
 */

/**
 * Module to test TinySec. Implements a simple counter that sends a
 * message over TinySec every tic. Programming two motes with the
 * apps should result in both motes flashing green and red leds
 * (green for sending and red for receiving). You can also listen in
 * on messages with SecureTOSBase and should see a counter.
 * Messages are both encrypted and authenticated over the air.
 * @author Chris Karlof
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
    interface TinySecMode;
  }
} 

implementation {
  struct TOS_Msg data;
  uint8_t value;
  
  task void sendit(){
    (data.data)[0] = value;
    memset(data.data+1,0,7);
    (data.data)[7] = 0xff;
    call Send.send(TOS_BCAST_ADDR,8,&data);
  }
 
  command result_t StdControl.init() {
    call Leds.init();
    value = 0;
    call TinySecMode.setTransmitMode(TINYSEC_ENCRYPT_AND_AUTH);
    return SUCCESS;
  }

  /**
   * Signalled when a TinySec message done sending.
   * @return Whether sending was successful or not.
   */
  event result_t Send.sendDone(TOS_MsgPtr m, result_t s) {
    call Leds.greenToggle();    
    return s;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /**
   * Signalled when a TinySec message is received.
   * @return The same TOS_MsgPtr that was passed up.
   */
  event TOS_MsgPtr ReceiveIntMsg.receive(TOS_MsgPtr m) {
    call Leds.redToggle();
    dbg(DBG_CRYPTO,"Msg received application layer.\n");
    return m;
  }

  /**
   * Called when the counter fires. Updates the value and posts a task
   * to send another message.
   * @return Always returns SUCCESS.
   */
  command result_t IntOutput.output(uint16_t v) {
    value = (uint8_t) v;
    dbg(DBG_USR1,"USR1: Clock interrupt - sending packet\n");
    post sendit();
    signal IntOutput.outputComplete(SUCCESS);
    return SUCCESS;
  }
}
