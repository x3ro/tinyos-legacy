// $Id: BcastM.nc,v 1.1.1.1 2006/05/04 23:08:19 ucsbsensornet Exp $

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
/*
 * Author: Alec Woo, David Culler, Robert Szewczyk, Su Ping
 *
 * $\Id$
 */

/**
 * BcastM is a Tinyos application module. 
 * 
 * When a message with AM message type 8 is received from underlying
 * Comm layer, this module checks if it has seen the message before and
 * drops the message if so. Otherwise, it calls the local ProcessCmd
 * interface to execute the command in the message.
 * If the command is successful, it broadcasts the original message over 
 * RF link. 
 * @author Alec Woo
 * @author David Culler
 * @author Robert Szewczyk
 * @author Su Ping
 **/
includes SimpleCmdMsg;

module BcastM { 
    provides 	interface StdControl;
    uses {
      interface ProcessCmd;
      interface Leds;
      interface Pot;
      interface ReceiveMsg as ReceiveCmdMsg;
      interface SendMsg as SendCmdMsg;
      interface StdControl as CommControl;
    }
}

/* 
 *  Module Implementation
 */

implementation 
{
  TOS_MsgPtr msg;	       
  int8_t bcast_pending;
  TOS_Msg buf;
  int8_t lastSeqno; 

  /**
   * Task:  Broadcast a mwssage
   *
   * @return Always returns <code>SUCCESS</code>
   **/

  task void forwarder() {
    call SendCmdMsg.send(TOS_BCAST_ADDR, 8, msg);
  }

  /**
   * Reset the bcast_pending flag to 0 if pmsg was sent successfully
   *
   * @return Returns the value of 'status'
   **/
  event result_t SendCmdMsg.sendDone(TOS_MsgPtr pmsg, result_t status) {
    if (status == SUCCESS) bcast_pending = 0;
    return status;
  }

  /**
   * Initalize the application.
   * @return A boolean indicating success or failure of the application 
   * initialization.
   **/
  command result_t StdControl.init() {
    msg = &buf;
    bcast_pending = 0;
    lastSeqno=0;

    return (call CommControl.init());
  }
  /** start generic communication interface **/
  command result_t StdControl.start(){
    return (call CommControl.start());
  }

  /** stop generic communication interface **/
  command result_t StdControl.stop(){
    return (call CommControl.stop());
  } 

  /**
   * A module-scoped inline function.
   *
   * Decide whether a received message is new: its sequence number has to be
   * within 127 of the previous sequence number. Also drops the message 
   * if the module is still dealing with the previous broadcast. 
   **/
  inline char is_new_msg(struct SimpleCmdMsg *bmsg) {
    if (bcast_pending) return 0;
    return (((bmsg->seqno - lastSeqno)>0) ||((bmsg->seqno+127)<lastSeqno) ) ;
  }

  /**
   * A module-scoped inline function. Updates the last sequence number
   * and set the broadcast sending flag.
   **/
  inline void remember_msg(struct SimpleCmdMsg *bmsg) {
    lastSeqno = bmsg->seqno; 
    bcast_pending = 1; 
  }

  /** 
   * Handles the AM type 8 receiving event signaled from ReceiveMsg.
   * Checks if this is a new message and calls ProcessCmd.execute()
   * if so.
   * @return A TOS_MsgPtr.
   **/
  event TOS_MsgPtr ReceiveCmdMsg.receive(TOS_MsgPtr pmsg){
    TOS_MsgPtr ret = msg;
    result_t retval;
    struct SimpleCmdMsg *data= (struct SimpleCmdMsg *)pmsg->data;

    // Check if this is a new broadcast message
    //call Leds.greenToggle();
    if (is_new_msg(data)) {
      remember_msg(data);
      retval = call ProcessCmd.execute(pmsg) ;

      // Return a message buffer to the lower levels, and hold on to the
      // current buffer
      ret = msg;
      msg = pmsg;

    } 
    return ret;
  }


  /** 
   * Handles the ProcessCmd.done event signaled by ProcessCmd.
   * Once command execution has completed, forward the message.
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t ProcessCmd.done(TOS_MsgPtr pmsg, result_t status) {
    msg = pmsg;
    //call Leds.redToggle();
    if (status) {
      post forwarder();
    } else {	
      bcast_pending = 0;
    }
    return SUCCESS;
  } 


} // end of implementation
