// $Id: I2CAMPacket.nc,v 1.1 2004/09/27 23:07:56 idgay Exp $

/*									tab:4
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


module I2CAMPacket
{
  provides {
    interface StdControl;
    interface BareSendMsg;
    interface ReceiveMsg;
  }
  uses {
    interface I2CPacket[uint8_t id];
    interface I2CPacketSlave;
  }
}
implementation
{
  TOS_Msg msg;
  TOS_MsgPtr tosMsgPtr;
  bool sending;
  
  command result_t StdControl.init() {
    tosMsgPtr = &msg;
    sending = FALSE;
    call I2CPacketSlave.setAddress( ((uint8_t)(0x007F & TOS_LOCAL_I2C_ADDRESS)) | I2CSLAVE_GENERAL_CALL);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t BareSendMsg.send(TOS_MsgPtr msg) {
    if (call I2CPacket.writePacket[msg->addr]
	((char *)msg,
	 offsetof(TOS_Msg, data) + msg->length,
	 I2C_ADDR_8BITS_FLAG & I2C_ACK_END_FLAG))
      {
	sending = TRUE;
	return SUCCESS;
      }
    return FAIL;
  }

  event result_t I2CPacket.writePacketDone[uint8_t id]
        (char* in_data, uint8_t len, result_t result) {
    if (sending)
      signal BareSendMsg.sendDone((TOS_MsgPtr)in_data, result);
    return SUCCESS;
  }

  event char *I2CPacketSlave.write(char *data, uint8_t length) {
    TOS_MsgPtr m = (TOS_MsgPtr)data;

    // Check that it's an actual TOS message, for us.
    if (length >= offsetof(TOS_Msg, data) &&
	(m->addr == TOS_LOCAL_I2C_ADDRESS ||
	 m->addr == TOS_I2C_BCAST_ADDR) &&
	 m->length == length - offsetof(TOS_Msg, data)  && 
	 m->group == TOS_AM_GROUP)
      {
	memcpy(tosMsgPtr, m, length);
	tosMsgPtr->crc = 1;
	tosMsgPtr = signal ReceiveMsg.receive(tosMsgPtr);
      }
    return data;
  }

  default event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m){}

  event result_t I2CPacketSlave.read(char **data, uint8_t *length) {return SUCCESS;}
  event result_t I2CPacketSlave.readDone(uint8_t sentLength){return SUCCESS;}
  event result_t I2CPacket.readPacketDone[uint8_t id](char* in_data, uint8_t len, result_t result) {
    return SUCCESS;
  }

}
