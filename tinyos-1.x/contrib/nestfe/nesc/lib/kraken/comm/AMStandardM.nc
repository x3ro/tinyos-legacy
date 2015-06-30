// $Id: AMStandardM.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

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
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

//This is an AM messaging layer implementation that understands multiple
// output devices.  All packets addressed to TOS_UART_ADDR are sent to the UART
// instead of the radio.


/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Cory Sharp
 */

module AMStandardM
{
  provides interface StdControl as Control;
    
  // The interface are as parameterised by the active message id
  provides interface SendMsg[uint8_t id];
  provides interface ReceiveMsg[uint8_t id];

  provides command uint16_t activity();
  uses interface StdControl as TimerControl;
  uses interface Timer as ActivityTimer;

  // signaled after every send completion for components which wish to
  // retry failed sends
  uses event result_t sendDone();

  uses interface StdControl as UARTControl;
  uses interface BareSendMsg as UARTSend;
  uses interface ReceiveMsg as UARTReceive;

  uses interface StdControl as RadioControl;
  uses interface BareSendMsg as RadioSend;
  uses interface ReceiveMsg as RadioReceive;
  uses interface PowerManagement;

  uses interface MsgFilter as PreSendFilter;
  uses interface MsgFilter as PostSendFilter;
  uses interface MsgTestAll as IntegrityTest;
  uses interface MsgTestAny as GroupTest;
  uses interface MsgTestAny as AddressTest;
}
implementation
{
  bool is_sending;
  TOS_MsgPtr buffer;

  command uint16_t activity() {
    return 0;
  }

  event result_t ActivityTimer.fired() {
    return SUCCESS;
  }
  
  // Initialization of this component
  command bool Control.init() {
    result_t ok1, ok2;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();

    is_sending = FALSE;
    dbg(DBG_BOOT, "AM Module initialized\n");

    return rcombine(ok1, ok2);
  }

  // Command to be used for power managment
  command bool Control.start() {
    result_t ok1 = call UARTControl.start();
    result_t ok2 = call RadioControl.start();

    //HACK -- unset start here to work around possible lost calls to 
    // sendDone which seem to occur when using power management.  SRM 4.4.03
    is_sending = FALSE;

    call PowerManagement.adjustPower();

    return rcombine(ok1, ok2);
  }

  
  command bool Control.stop() {
    result_t ok1 = call UARTControl.stop();
    result_t ok2 = call RadioControl.stop();
    call PowerManagement.adjustPower();
    return rcombine(ok1, ok2);
  }

  void dbgPacket(TOS_MsgPtr data) {
    uint8_t i;

    for(i = 0; i < sizeof(TOS_Msg); i++)
      {
	dbg_clear(DBG_AM, "%02hhx ", ((uint8_t *)data)[i]);
      }
    dbg_clear(DBG_AM, "\n");
  }

  // Handle the event of the completion of a message transmission
  result_t reportSendDone(TOS_MsgPtr msg, result_t success) {
    is_sending = FALSE;
    signal SendMsg.sendDone[msg->type](msg, success);
    signal sendDone();

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
    TOS_MsgPtr buf;
    buf = buffer;
    if (buf->addr == TOS_UART_ADDR)
      ok = call UARTSend.send(buf);
    else
      ok = call RadioSend.send(buf);

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(buffer, FAIL);
  }

  // Command to accept transmission of an Active Message
  command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length, TOS_MsgPtr data) {
    if (!is_sending) {
      is_sending = TRUE;
      if (length > DATA_LENGTH) {
	dbg(DBG_AM, "AM: Send length too long: %i. Fail.\n", (int)length);
	is_sending = FALSE;
	return FAIL;
      }
      if (!(post sendTask())) {
	dbg(DBG_AM, "AM: post sendTask failed.\n");
	is_sending = FALSE;
	return FAIL;
      }
      else {
	buffer = data;
	data->length = length;
	data->addr = addr;
	data->type = id;
        call PreSendFilter.filter( buffer );
	dbg(DBG_AM, "Sending message: %hx, %hhx\n\t", addr, id);
	dbgPacket(data);
      }
      return SUCCESS;
    }
    
    return FAIL;
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    call PostSendFilter.filter( buffer );
    return reportSendDone(msg, success);
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    call PostSendFilter.filter( buffer );
    return reportSendDone(msg, success);
  }

  default command void PreSendFilter.filter( TOS_MsgPtr msg ) {
    msg->group = TOS_AM_GROUP;
  }

  default command void PostSendFilter.filter( TOS_MsgPtr msg ) {
  }


  // Handle the event of the reception of an incoming message
  TOS_MsgPtr received(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {

    if (call IntegrityTest.passes(packet) &&
        call GroupTest.passes(packet) &&
        call AddressTest.passes(packet))
      {
	uint8_t type = packet->type;
	TOS_MsgPtr tmp;
	// Debugging output
	dbg(DBG_AM, "Received message:\n\t");
	dbgPacket(packet);
	dbg(DBG_AM, "AM_type = %d\n", type);

	// dispatch message
	tmp = signal ReceiveMsg.receive[type](packet);
	if (tmp) 
	  packet = tmp;
      }
    return packet;
  }

  // default do-nothing message receive handler
  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
    return msg;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr packet) {
    // A serial cable is not a shared medium and does not need group-id
    // filtering
    packet->group = TOS_AM_GROUP;
    return received(packet);
  }
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr packet) {
    return received(packet);
  }
}

