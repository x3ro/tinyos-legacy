/*                                                                      tab:4
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
/*
 *
 * Authors:             Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 * Author:		Lin Gu
 * Date last modified:  11/26/02
 */

//This is an AM messaging layer implementation that understands multiple
// output devices.  All packets addressed to TOS_UART_ADDR are sent to the UART
// instead of the radio.

module AMListen
{
  provides {
    interface StdControl as Control;
    
    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];

    // How many packets were received in the past second
    command uint16_t activity();
  }

  uses {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();

    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;
    interface Leds;
    interface Timer as ActivityTimer;
  }
}
implementation
{
  bool state;
  TOS_MsgPtr buffer;
  TOS_Msg msgPriority;
  TOS_MsgPtr pmsgPriority;

  uint16_t lastCount;
  uint16_t counter;
  
  // Initialization of this component
  command bool Control.init() {
    result_t ok1 = call UARTControl.init();
    result_t ok2 = call RadioControl.init();
    
    state = FALSE;
    lastCount = 0;
    counter = 0;

    msgPriority.addr = TOS_UART_ADDR;
    pmsgPriority = &msgPriority;

    dbg(DBG_BOOT, "AM Module initialized\n");

    return rcombine(ok1, ok2);
  }

  // Command to be used for power managment
  command bool Control.start() {
    result_t ok1 = call UARTControl.start();
    result_t ok2 = call RadioControl.start();
    result_t ok3 = call ActivityTimer.start(TIMER_REPEAT, 1000);
    return rcombine3(ok1, ok2, ok3);
  }

  
  command bool Control.stop() {
    result_t ok1 = call UARTControl.stop();
    result_t ok2 = call RadioControl.stop();
    result_t ok3 = call ActivityTimer.stop();
    return rcombine3(ok1, ok2, ok3);
  }

  command uint16_t activity() {
    return lastCount;
  }
  
  void dbgPacket(TOS_MsgPtr data) {
    uint8_t i;

    for(i = 0; i < sizeof(TOS_Msg); i++)
      {
	dbg_clear(DBG_AM, "%02hhx ", ((uint8_t *)data)[i]);
      }
    dbg(DBG_AM, "\n");
  }

  // Handle the event of the completion of a message transmission
  result_t reportSendDone(TOS_MsgPtr msg, result_t success) {
    state = FALSE;
    signal SendMsg.sendDone[msg->type](msg, success);
    signal sendDone();

    return SUCCESS;
  }

  event result_t ActivityTimer.fired() {
    lastCount = counter;
    counter = 0;
    return SUCCESS;
  }
  
  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  default event result_t sendDone() {
    return SUCCESS;
  }

  // This task schedules the transmission of the Active Message
  task void sendTask() {
    result_t ok;

    if (buffer->addr == TOS_UART_ADDR)
      ok = call UARTSend.send(buffer);
    else
      ok = call RadioSend.send(buffer);

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(buffer, FAIL);
  }

  // This task schedules the transmission of the Active Message
  task void sendPriorityTask() {
    result_t ok;

    if (buffer->addr == TOS_UART_ADDR)
      ok = call UARTSend.send(pmsgPriority);
    else
      ok = call RadioSend.send(pmsgPriority);

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(buffer, FAIL);
  }

  // Command to accept transmission of an Active Message
  command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length, TOS_MsgPtr data) {
    if (!state) {
      if (length > DATA_LENGTH) {
	dbg(DBG_AM, "AM: Send length too long: %i. Fail.\n", (int)length);
	return FAIL;
      }
      state = TRUE;
      post sendTask();
      buffer = data;
      data->length = length;
      data->addr = addr;
      data->type = id;
      buffer->group = TOS_AM_GROUP;
      dbg(DBG_AM, "Sending message: %hx, %hhx\n\t", addr, id);
      dbgPacket(data);
      return SUCCESS;
    }
    
    return FAIL;
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr received(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {
    counter++;
    dbg(DBG_AM, "AM_address = %hx, %hhx; counter:%i\n", packet->addr, packet->type, (int)counter);

    if (//packet->crc == 1 && // Uncomment this line to check crcs
/*	packet->group == TOS_AM_GROUP &&
	(packet->addr == TOS_BCAST_ADDR ||
	 packet->addr == TOS_LOCAL_ADDRESS)*/
	1)
      {
/*	uint8_t type = packet->type;
	TOS_MsgPtr tmp;
    
	// Debugging output
	dbg(DBG_AM, "Received message:\n\t");
	dbgPacket(packet);
	dbg(DBG_AM, "AM_type = %d\n", type);

	// dispatch message
	tmp = signal ReceiveMsg.receive[type](packet);
	if (tmp) 
	  packet = tmp;
*/
	int *pd = (int *)(&msgPriority), *ps = (int *)packet;
	int i;

	for (i=0; i<10; i++)
	{
	  *pd = *ps;
	  pd++;
	  ps++;
	}

	post sendPriorityTask();
      }

    return packet;
  }

  // default do-nothing message receive handler
  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
    return msg;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr packet) {
    return received(packet);
  }
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr packet) {
    call Leds.redToggle();

    return received(packet);
  }
}

