// $Id: SimpleCmdM.nc,v 1.4 2004/05/04 22:39:07 idgay Exp $

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
 * Author:  Robert Szewczyk,  Su Ping
 *
 * $\Id$
 */

/** 
 * SimpleCmdM is a tiny OS application module. 
 * This module demonstrates a simple command interpreter for the TinyOS 
 * tutorial. The module receives a command message from the radio, which
 * is passed to the ProcessCmd interface for processing. A task is posted
 * to process the command. The command packet contains a one-byte
 * 'action' field specifying which action to take; as a simple version, 
 * this module can only interpret the follwoing commands:
 * Led_on (action = 1), Led_off (2), radio_quieter (3), and radio_louder (4).
 *
 * This module also implements the ProcessCmd interface.
 * @author Robert Szewczyk
 * @author Su Ping
 **/
includes SimpleCmdMsg;

module SimpleCmdM { 
  provides 	{
    interface StdControl;
    interface ProcessCmd; 
  }

  uses {
    interface Leds;
    interface Pot;
    interface ReceiveMsg as ReceiveCmdMsg;
    interface StdControl as CommControl;
  }
}

/* 
 *  Module Implementation
 */

implementation 
{

  // module scoped variables
  TOS_MsgPtr msg;	       
  int8_t pending;
  TOS_Msg buf;


  /**
   *
   * This task evaluates a command and execute it if it is a supported
   * command.The protocol for the command interpreter is that
   * it operates on the message and returns a (potentially modified)
   * message to the calling layer, as well a status word for whether 
   * the message should be futher processed. 
   * 
   * @return Return: None
   **/

  task void cmdInterpret() {
    struct SimpleCmdMsg * cmd = (struct SimpleCmdMsg *) msg->data;
    // do local packet modifications: update the hop count and packet source
    cmd->hop_count++;
    cmd->source = TOS_LOCAL_ADDRESS;

    // Interpret the command: Display the level on red and green led
    if (cmd->hop_count & 0x1)  
      call Leds.greenOn();
    else 
      call Leds.greenOff();
    if (cmd->hop_count & 0x2) 
      call Leds.redOn();
    else 
      call Leds.redOff();

    // Execute the command
    switch (cmd->action) {
      case LED_ON:
	call Leds.yellowOn();
	break;
      case LED_OFF:
	call Leds.yellowOff();
	break;
      case RADIO_QUIETER:
	call Pot.increase();
	break;
      case RADIO_LOUDER:
	call Pot.decrease();
	break;
    }
    pending =0;
    signal ProcessCmd.done(msg, SUCCESS);
  }

  /** 
   * Initialization for the application:
   *  1. Initialize module static variables
   *  2. Initialize communication layer
   *  @return Returns <code>SUCCESS</code> or <code>FAILED</code>
   **/

  command result_t StdControl.init() {
    msg = &buf;
    pending = 0;
    return rcombine(call CommControl.init(), call Leds.init());
  }

/** start communication layer **/
  command result_t StdControl.start(){
    return (call CommControl.start());
  }
/** stop communication layer **/
  command result_t StdControl.stop(){
    return (call CommControl.stop());
  } 

  /**
   * Posts the cmdInterpret() task to handle the recieved command.
   * @return Always returns <code>SUCCESS</code> 
   **/
  command result_t ProcessCmd.execute(TOS_MsgPtr pmsg) {
    pending =1;
    msg = pmsg;
    post cmdInterpret();
    return SUCCESS;
  }

  /** 
   * Called upon message reception and invokes the ProcessCmd.execute()
   * command.
   * @return Returns a pointer to a TOS_Msg buffer 
   **/
  event TOS_MsgPtr ReceiveCmdMsg.receive(TOS_MsgPtr pmsg){
    TOS_MsgPtr ret = msg;
    result_t retval;
    //call Leds.greenToggle();
    retval = call ProcessCmd.execute(pmsg) ;
    if (retval==SUCCESS) {
      return ret;
    } else {
      return pmsg;
    }
  }


  /** 
   * Called upon completion of command execution.
   * @return Always returns <code>SUCCESS</code>
   **/
  default event result_t ProcessCmd.done(TOS_MsgPtr pmsg, result_t status) {
    return status;
  } 

} // end of implementation
