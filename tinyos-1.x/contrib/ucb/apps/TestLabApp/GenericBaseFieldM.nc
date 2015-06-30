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
/* History:   created 1/25/2001
 *
 *
 */
  
/* Generic.Base.c 
   - captures all the packets that it can hear and report it back to the UART
   - forward all incoming UART messages out to the radio
*/

module GenericBaseFieldM {
  provides interface StdControl;
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Timer as ResetTimer;
    interface Reset;

    command result_t SetTransmitMode(uint8_t mode);

    interface Leds;
  }
}
implementation
{

// reset every 10 minutes
#define RESET_THRESHOLD 10*60*2

  TOS_Msg buffer; 
  TOS_MsgPtr ourBuffer;
  bool sendPending;
  uint16_t reset;  
  
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

#ifdef LONG_PREAMBLE
    call SetTransmitMode(OFF_MODE);
#endif

    dbg(DBG_BOOT, "GenericBase initialized\n");

    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start() {
    result_t ok1, ok2;
    reset = 0;
    
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

    call ResetTimer.start(TIMER_REPEAT, 30000);

    return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine(ok1, ok2);
  }

  event result_t ResetTimer.fired() {
    reset++;
    if (reset >= RESET_THRESHOLD)
      call Reset.reset();
    return SUCCESS;
  }

  TOS_MsgPtr receive(TOS_MsgPtr received, bool fromUART) {
    TOS_MsgPtr nextReceiveBuffer = received;
    
    dbg(DBG_USR1, "GenericBase received %s packet\n",
	fromUART ? "UART" : "radio");
    if ((!sendPending) &&
	(received->group == (TOS_AM_GROUP & 0xff))) {
      
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
#ifndef REPEATER	  
	    received->addr = TOS_UART_ADDR;
#endif
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
    //call Leds.redOn();
    if(ourBuffer == sent)
      {
	dbg(DBG_USR1, "GenericBase send buffer free\n");
	if (success == FAIL)
	  call Leds.yellowToggle();
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
