/*									tab:4
 *
 *
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
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
 */
/*
 * Author:  Robert Szewczyk,  Su Ping
 *
 * $\Id$
 */

/** 
 *
 * This module demonstrates a simple command interpreter for the TinyOS 
 * tutorial. The module receives a command message from the radio, which
 * is passed to the ProcessCmd interface for processing. A task is posted
 * to process the command. The command packet contains a one-byte
 * 'action' field specifying which action to take; as a simple version, 
 * this module can only interpret the follwoing commands:
 * Led_on (action = 1), Led_off (2), radio_quieter (3), and radio_louder (4).
 *
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

  // Command Message structure. We anticipate that many commands will find it
  // useful to know who forwarded the current packet, how deep the current node
  // is in the broadcast tree, etc. 

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
   *  2. Turn yellow Led on
   *  3. Initialize communication layer
   *  @return Returns <code>SUCCESS</code> or <code>FAILED</code>
   **/

  command result_t StdControl.init() {
    msg = &buf;
    pending = 0;
    return (call CommControl.init());
  }


  command result_t StdControl.start(){
    return (call CommControl.start());
  }

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
