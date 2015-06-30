// $Id: AMStandardI2C.nc,v 1.3 2004/09/27 23:07:25 idgay Exp $

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
 * Authors:		kamin whitehouse,Jason Hill, David Gay, Philip Levis
 * Date last modified:  2/18/04
 *
 */

//This is an AM messaging layer implementation that understands multiple
// output devices.  All packets addressed to TOS_UART_ADDR are sent to the UART
// instead of the radio. AND ALL MESSAGES SENT TO ADDRESS BETWEEN
//0XFF01 AND 0XFFFE ARE SENT TO I2C.  0XFF00 IS RESERVED FOR I2C BROADCAST

includes I2C;

module AMStandardI2C
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

    interface StdControl as I2CControl;
    interface BareSendMsg as I2CSend;
    interface ReceiveMsg as I2CReceive;

    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;
    interface StdControl as TimerControl;
    interface Timer as ActivityTimer;
    interface PowerManagement;
    interface Leds;
  }
}
implementation
{
  bool state;
  TOS_MsgPtr buffer;
  uint16_t lastCount;
  uint16_t counter;
  
  // Initialization of this component
  command bool Control.init() {
    result_t ok1, ok2, ok3, ok4;

    call TimerControl.init();
    ok3 = call I2CControl.init();
    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();

    //set I2C address to be lower 7 bits of local address plus general
    //call address, if the node is a subprocessor.  Otherwise, set it
    //to 0x7f (the equivalent of 192.168.0.1).  Dothis after initializing the I2CSlave component
    if( (TOS_LOCAL_ADDRESS & 0xFF00) == 0xFF00){ //if I am in the subnet
      TOS_LOCAL_I2C_ADDRESS=TOS_LOCAL_ADDRESS;
    }
    else{
      TOS_LOCAL_I2C_ADDRESS=TOS_I2C_GATEWAY_ADDR; //equivalent of 192.168.0.1
    }
    
    state = FALSE;
    lastCount = 0;
    counter = 0;
    dbg(DBG_BOOT, "AM Module initialized\n");

    return rcombine4(ok1, ok2, ok3, ok4);
  }

  // Command to be used for power managment
  command bool Control.start() {
    result_t ok0 = call TimerControl.start();
    result_t ok5 = call I2CControl.start();
    result_t ok1 = call UARTControl.start();
    result_t ok2 = call RadioControl.start();
    result_t ok3 = call ActivityTimer.start(TIMER_REPEAT, 1000);

    //HACK -- unset start here to work around possible lost calls to 
    // sendDone which seem to occur when using power management.  SRM 4.4.03
    state = FALSE;

    call PowerManagement.adjustPower();

    return rcombine4(ok0, ok1, ok2, rcombine(ok3, ok5));
  }

  
  command bool Control.stop() {
    result_t ok4 = call I2CControl.stop();
    result_t ok1 = call UARTControl.stop();
    result_t ok2 = call RadioControl.stop();
    result_t ok3 = call ActivityTimer.stop();
    // call TimerControl.stop();
    call PowerManagement.adjustPower();
    return rcombine4(ok1, ok2, ok3, ok4);
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
    dbg_clear(DBG_AM, "\n");
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
    TOS_MsgPtr buf;
    buf = buffer;
    if (buf->addr == TOS_UART_ADDR)
      ok = call UARTSend.send(buf);
    else if( (buf->addr >= TOS_MIN_I2C_ADDR) && (buf->addr <= TOS_MAX_I2C_ADDR) )
      ok = call I2CSend.send(buf);
    else
      ok = call RadioSend.send(buf);

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(buffer, FAIL);
  }

  // Command to accept transmission of an Active Message
  command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length, TOS_MsgPtr data) {
    if (!state) {
      state = TRUE;
      if (length > DATA_LENGTH) {
	dbg(DBG_AM, "AM: Send length too long: %i. Fail.\n", (int)length);
	state = FALSE;
	return FAIL;
      }
      if (!(post sendTask())) {
	dbg(DBG_AM, "AM: post sendTask failed.\n");
	state = FALSE;
	return FAIL;
      }
      else {
	buffer = data;
	data->length = length;
	data->addr = addr;
	data->type = id;
	buffer->group = TOS_AM_GROUP;
	dbg(DBG_AM, "Sending message: %hx, %hhx\n\t", addr, id);
	dbgPacket(data);
      }
      return SUCCESS;
    }
    
    return FAIL;
  }

  event result_t I2CSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }
  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr receivedI2C(TOS_MsgPtr packet) {
    uint16_t addr = TOS_LOCAL_ADDRESS;
    counter++;
    dbg(DBG_AM, "AM_address = %hx, %hhx; counter:%i\n", packet->addr, packet->type, (int)counter);

    if (packet->crc == 1 && // Uncomment this line to check crcs
	packet->group == TOS_AM_GROUP &&
	(packet->addr == TOS_BCAST_ADDR ||
	 packet->addr == TOS_I2C_BCAST_ADDR ||
	 packet->addr == TOS_LOCAL_I2C_ADDRESS ||
	 packet->addr == addr))
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

  event TOS_MsgPtr I2CReceive.receive(TOS_MsgPtr packet) {
    // I2C is not a shared medium and does not need group-id
    // filtering
    packet->group = TOS_AM_GROUP;
    return receivedI2C(packet);
  }
  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr packet) {
    // A serial cable is not a shared medium and does not need group-id
    // filtering
    packet->group = TOS_AM_GROUP;
    return receivedI2C(packet);
  }
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr packet) {
    return receivedI2C(packet);
  }

}

