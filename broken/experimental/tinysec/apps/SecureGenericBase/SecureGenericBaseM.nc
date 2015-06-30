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
/* History:   created 1/25/2001
 *
 *
 */
  
/* Generic.Base.c 
   - captures all the packets that it can hear and report it back to the UART
   - forward all incoming UART messages out to the radio
*/

module SecureGenericBaseM {
  provides interface StdControl;
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Leds;
  }
}
implementation
{
  TOS_Msg buffer; 
  TOS_MsgPtr ourBuffer;
  bool sendPending;
  uint8_t key[8]; 
  
  /* Generic.Base.Init:  
     initialize lower components.
     initialize component state, including constant portion of msgs.
  */
  command result_t StdControl.init() {
    result_t ok1, ok2, ok3;

    ourBuffer = &buffer;
    sendPending = TRUE;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();

    sendPending = FALSE;

    dbg(DBG_BOOT, "GenericBase initialized\n");

    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

    return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine(ok1, ok2);
  }

  TOS_MsgPtr receive(TOS_MsgPtr received, bool fromUART) {
    TOS_MsgPtr nextReceiveBuffer = received;
    
    dbg(DBG_USR1, "GenericBase received %s packet\n",
	fromUART ? "UART" : "radio");
    if (!sendPending) {
      
      result_t ok;
      
      nextReceiveBuffer = ourBuffer;
      ourBuffer = received;
      dbg(DBG_USR1, "GenericBase forwarding packet to %s\n",
	  fromUART ? "radio" : "UART");
      if (fromUART)
	{
	  call Leds.redToggle();
	  ok = call RadioSend.send(received);
	}
	else
	  {
	    call Leds.greenToggle();
	    received->addr = TOS_UART_ADDR;
	    ok = call UARTSend.send(received);
	  }
      if (ok != FAIL)
	{
	  dbg(DBG_USR1, "GenericBase send pending\n");
	  sendPending = TRUE;
	}
      else {
	call Leds.yellowToggle();
      }
      
    }
    return nextReceiveBuffer;
  }
  
  result_t sendDone(TOS_MsgPtr sent, result_t success) {
    if(ourBuffer == sent)
      {
	dbg(DBG_USR1, "GenericBase send buffer free\n");
	sendPending = FALSE;
      }
    return SUCCESS;
  }
  
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr data) {
    if (data->crc) {
      return receive(data, FALSE);
    }
    else {
      return data;
    }
  }
  
  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr data) {
    return receive(data, TRUE);
  }
  
  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return sendDone(msg, success);
  }
  
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return sendDone(msg, success);
  }
}  
