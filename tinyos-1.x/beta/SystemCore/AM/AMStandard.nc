// $Id: AMStandard.nc,v 1.6 2004/08/24 02:29:50 gtolle Exp $

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
 */

includes AMEnhanced;

module AMStandard
{
  provides {
    interface StdControl as Control;
    
    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];

    command result_t softStart();
    command result_t softStop();
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
    interface StdControl as TimerControl;
    interface PowerManagement;

    interface MgmtAttr as MA_InPacketReceives;
    interface MgmtAttr as MA_InPacketCRCErrors;
    interface MgmtAttr as MA_InPacketInactiveDiscards;
    interface MgmtAttr as MA_InPacketGroupDiscards; 
    interface MgmtAttr as MA_InPacketAddrDiscards;
    interface MgmtAttr as MA_InPacketDelivers;

    interface MgmtAttr as MA_OutPacketRequests;
    interface MgmtAttr as MA_OutPacketInactiveDiscards;
    interface MgmtAttr as MA_OutPacketLengthDiscards;
    interface MgmtAttr as MA_OutPacketBusyDiscards;
    interface MgmtAttr as MA_OutPacketDelivers;

    interface MgmtAttr as MA_RolloverDetection;
  }
}
implementation
{
  bool active = FALSE;
  bool state;
  TOS_MsgPtr buffer;
  uint16_t receives = 0;
  uint16_t crcErrors = 0;
  uint16_t inactiveInDiscards = 0;
  uint16_t groupDiscards = 0;
  uint16_t addrDiscards = 0;
  uint16_t inDelivers = 0;
  
  uint16_t requests = 0;
  uint16_t inactiveOutDiscards = 0;
  uint16_t lengthDiscards = 0;
  uint16_t busyDiscards = 0;
  uint16_t outDelivers = 0;

  uint16_t rolloverFlags = 0;

  enum {
    IN_PACKET_RECEIVES = 1 << 0,
    IN_PACKET_CRC_ERRORS = 1 << 1,
    IN_PACKET_GROUP_DISCARDS = 1 << 2,
    IN_PACKET_ADDR_DISCARDS = 1 << 3,
    IN_PACKET_DELIVERS = 1 << 4,

    OUT_PACKET_REQUESTS = 1 << 5,
    OUT_PACKET_LENGTH_DISCARDS = 1 << 6,
    OUT_PACKET_BUSY_DISCARDS = 1 << 7,
    OUT_PACKET_DELIVERS = 1 << 8,
    
    IN_PACKET_INACTIVE_DISCARDS = 1 << 9,
    OUT_PACKET_INACTIVE_DISCARDS = 1 << 10,
  };

  void inc(uint16_t *ctr, uint16_t rolloverFlag) {
    if (*ctr == 0xffff)
      rolloverFlags |= rolloverFlag;
    (*ctr)++;
  }

  // Initialization of this component
  command bool Control.init() {
    result_t ok1, ok2;

    call TimerControl.init();
    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();

    state = FALSE;
    dbg(DBG_BOOT, "AM Module initialized\n");

    call MA_InPacketReceives.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_InPacketCRCErrors.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_InPacketInactiveDiscards.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_InPacketGroupDiscards.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_InPacketAddrDiscards.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_InPacketDelivers.init(sizeof(uint16_t), MA_TYPE_UINT);

    call MA_OutPacketRequests.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_OutPacketInactiveDiscards.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_OutPacketLengthDiscards.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_OutPacketBusyDiscards.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_OutPacketDelivers.init(sizeof(uint16_t), MA_TYPE_UINT);

    call MA_RolloverDetection.init(sizeof(uint16_t), MA_TYPE_BITSTRING);

    return rcombine(ok1, ok2);
  }

  // Command to be used for power managment
  command bool Control.start() {
    result_t ok0 = call TimerControl.start();
    result_t ok1 = call UARTControl.start();
    result_t ok2 = call RadioControl.start();

    //HACK -- unset start here to work around possible lost calls to 
    // sendDone which seem to occur when using power management.  SRM 4.4.03
    active = TRUE;
    state = FALSE;
    
    call PowerManagement.adjustPower();

    return rcombine3(ok0, ok1, ok2);
  }

  
  command bool Control.stop() {
    result_t ok1 = call UARTControl.stop();
    result_t ok2 = call RadioControl.stop();

    active = FALSE;

    call PowerManagement.adjustPower();
    return rcombine(ok1, ok2);
  }

  command result_t softStart() {
    active = TRUE;
    return SUCCESS;
  }

  command result_t softStop() {
    active = FALSE;
    return SUCCESS;
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

    if (ok == FAIL) { // failed, signal completion immediately
      inc(&busyDiscards, OUT_PACKET_BUSY_DISCARDS);
      reportSendDone(buffer, FAIL);
    } else {
      inc(&outDelivers, OUT_PACKET_DELIVERS);
    }
  }

  // Command to accept transmission of an Active Message
  command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length, TOS_MsgPtr data) {

    inc(&requests, OUT_PACKET_REQUESTS);

    if (!active && id != TOS_AM_WAKEUPID) {
      inc(&inactiveOutDiscards, OUT_PACKET_INACTIVE_DISCARDS);
      return FAIL;
    }

    if (!state) {
      state = TRUE;
      if (length > DATA_LENGTH) {
	dbg(DBG_AM, "AM: Send length too long: %i. Fail.\n", (int)length);
	inc(&lengthDiscards, OUT_PACKET_LENGTH_DISCARDS);
	state = FALSE;
	return FAIL;
      }
      if (!(post sendTask())) {
	dbg(DBG_AM, "AM: post sendTask failed.\n");
	inc(&busyDiscards, OUT_PACKET_BUSY_DISCARDS);
	state = FALSE;
	return FAIL;
      }
      else {
	buffer = data;
	data->length = length;
	data->addr = addr;
	data->type = id;
	if (buffer->group != TOS_BCAST_GROUP)
	  buffer->group = TOS_AM_GROUP;
	dbg(DBG_AM, "Sending message: %hx, %hhx\n\t", addr, id);
	dbgPacket(data);
      }
      return SUCCESS;
    }

    inc(&busyDiscards, OUT_PACKET_BUSY_DISCARDS);
    return FAIL;
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    msg->group = TOS_AM_GROUP;
    return reportSendDone(msg, success);
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    msg->group = TOS_AM_GROUP;
    return reportSendDone(msg, success);
  }

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr received(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {
//    dbg(DBG_AM, "AM_address = %hx, %hhx; \n", packet->addr, packet->type);

    inc(&receives, IN_PACKET_RECEIVES);

    if (packet->crc != 1) {
      inc(&crcErrors, IN_PACKET_CRC_ERRORS);
      return packet;
    }

    if (!active && packet->type != TOS_AM_WAKEUPID) {
      inc(&inactiveInDiscards, IN_PACKET_INACTIVE_DISCARDS);
      return packet;
    }      

    if (packet->group != TOS_AM_GROUP &&
	packet->group != TOS_BCAST_GROUP) {
      inc(&groupDiscards, IN_PACKET_GROUP_DISCARDS);
      return packet;
    }

    if (packet->addr != TOS_BCAST_ADDR &&
	packet->addr != TOS_LOCAL_ADDRESS) {
      inc(&addrDiscards, IN_PACKET_ADDR_DISCARDS);
      return packet;
    }

    {
      uint8_t type = packet->type;
      TOS_MsgPtr tmp;
      // Debugging output
      dbg(DBG_AM, "Received message:\n\t");
      dbgPacket(packet);
      dbg(DBG_AM, "AM_type = %d\n", type);

      inc(&inDelivers, IN_PACKET_DELIVERS);
      
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

  result_t copyCtr(uint8_t *buf, uint16_t ctr, uint16_t rolloverFlag) {
    memcpy(buf, &ctr, sizeof(uint16_t));
    rolloverFlags &= ~(rolloverFlag);
    return SUCCESS;
  }

  event result_t MA_InPacketReceives.getAttr(uint8_t *buf) {
    return copyCtr(buf, receives, IN_PACKET_RECEIVES);
  }

  event result_t MA_InPacketCRCErrors.getAttr(uint8_t *buf) {
    return copyCtr(buf, crcErrors, IN_PACKET_CRC_ERRORS);
  }

  event result_t MA_InPacketGroupDiscards.getAttr(uint8_t *buf) {
    return copyCtr(buf, groupDiscards, IN_PACKET_GROUP_DISCARDS);
  }

  event result_t MA_InPacketInactiveDiscards.getAttr(uint8_t *buf) {
    return copyCtr(buf, inactiveInDiscards, IN_PACKET_INACTIVE_DISCARDS);
  }

  event result_t MA_InPacketAddrDiscards.getAttr(uint8_t *buf) {
    return copyCtr(buf, addrDiscards, IN_PACKET_ADDR_DISCARDS);
  }

  event result_t MA_InPacketDelivers.getAttr(uint8_t *buf) {
    return copyCtr(buf, inDelivers, IN_PACKET_DELIVERS);
  }

  event result_t MA_OutPacketRequests.getAttr(uint8_t *buf) {
    return copyCtr(buf, requests, OUT_PACKET_REQUESTS);
  }

  event result_t MA_OutPacketInactiveDiscards.getAttr(uint8_t *buf) {
    return copyCtr(buf, inactiveOutDiscards, OUT_PACKET_INACTIVE_DISCARDS);
  }

  event result_t MA_OutPacketLengthDiscards.getAttr(uint8_t *buf) {
    return copyCtr(buf, lengthDiscards, OUT_PACKET_LENGTH_DISCARDS);
  }

  event result_t MA_OutPacketBusyDiscards.getAttr(uint8_t *buf) {
    return copyCtr(buf, busyDiscards, OUT_PACKET_BUSY_DISCARDS);
  }

  event result_t MA_OutPacketDelivers.getAttr(uint8_t *buf) {
    return copyCtr(buf, outDelivers, OUT_PACKET_DELIVERS);
  }

  event result_t MA_RolloverDetection.getAttr(uint8_t *buf) {
    return copyCtr(buf, rolloverFlags, 0);
  }
}

