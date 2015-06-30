/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Sets the data fields of SP messages and TinyOS packets.  Maintains
 * the SP Message Pool.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPDataM {
  provides {
    interface SPSend[uint8_t id];
    interface SPSendNext[uint8_t id];
  }
  uses {
    interface ObjectPool<sp_message_t> as Pool;
    interface LocalTime<T32khz>;
    interface BareSendMsg as UARTSend;
  }
}
implementation {

  sp_message_t* m_uartmsg;

  void setFields(sp_message_t* msg, TOS_Msg* tosmsg, sp_device_t dev, sp_address_t addr, uint8_t length, sp_message_flags_t flags, uint8_t quantity, uint8_t id) {
    // store the TOSMsg
    msg->msg = tosmsg;

    // store the address
    msg->msg->addr = addr;
    // store the service identifier
    msg->msg->type = id;
    // set the group
    msg->msg->group = TOS_AM_GROUP;
    // set the length of the message
    msg->msg->length = length;

    // store the address
    msg->addr = addr;
    // store the device
    msg->dev = ( dev == SP_I_NOT_SPECIFIED ) ? SP_I_RADIO : dev;
    msg->dev = ( msg->addr == TOS_UART_ADDR ) ? SP_I_UART : msg->dev;
    // store the service identifier
    msg->id = id;
    // reset feedback flags
    msg->flags = flags & ~SP_FLAG_F_ALL;
    // store the number of packets
    msg->quantity = quantity;
    // reset the retry count
    msg->retries = 0;
    // set the length
    msg->length = length;
  }

  command result_t SPSend.send[uint8_t id](sp_message_t* msg, TOS_Msg* tosmsg, sp_address_t addr, uint8_t length) {
    // never called by SPM
    return FAIL;
  }

  command result_t SPSend.sendAdv[uint8_t id](sp_message_t* msg, TOS_Msg* tosmsg, sp_device_t dev, sp_address_t addr, uint8_t length, sp_message_flags_t flags, uint8_t quantity) {
    // check the edge condtions
    if ((tosmsg == NULL) || (length > TOSH_DATA_LENGTH) || 
	(length == 0) || (quantity == 0))
      return FAIL;

    setFields(msg, tosmsg, dev, addr, length, flags, quantity, id);

    // get the time the message was submitted
    msg->time = call LocalTime.get();

    if ((msg->addr == TOS_UART_ADDR) || (msg->dev == SP_I_UART)) {
      if (m_uartmsg == NULL) {
	if (call UARTSend.send(msg->msg) == SUCCESS) {
	  m_uartmsg = msg;
	  return SUCCESS;
	}
      }
      return FAIL;
    }

    // try to insert the message in the message pool
    return call Pool.insert(msg);
  }

  command void SPSendNext.response[uint8_t id](sp_message_t* msg, TOS_Msg* tosmsg, uint8_t length) { }

  command result_t SPSend.update[uint8_t id](sp_message_t* msg, TOS_Msg* tosmsg, sp_device_t dev, sp_address_t addr, uint8_t length, sp_message_flags_t flags, uint8_t quantity) {
    if ((msg->id == id) && (!(msg->flags & SP_FLAG_C_BUSY))) {
      uint8_t i;
      for( i=call Pool.first(); call Pool.valid(i); i=call Pool.next(i) ) {
	if (call Pool.get(i) == msg) {
	  setFields(msg, tosmsg, dev, addr, length, flags, quantity, id);
	  return SUCCESS;
	}
      }
    }
    return FAIL;
  }

  command result_t SPSend.cancel[uint8_t id](sp_message_t* msg) {
    if ((!(msg->flags & SP_FLAG_C_BUSY) && (id == msg->id))) 
      return call Pool.remove(msg);
    else 
      return FAIL;
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    sp_message_t* _stack = m_uartmsg;

    if (m_uartmsg != NULL && msg == m_uartmsg->msg) {
    
      m_uartmsg->quantity--;
      if (m_uartmsg->quantity > 0) {
	m_uartmsg->msg = NULL;
	m_uartmsg->flags |= SP_FLAG_C_FUTURES;
	// request the next packet
	signal SPSendNext.request[m_uartmsg->id](m_uartmsg, 
						 msg,
						 m_uartmsg->quantity
						 );
	m_uartmsg->flags &= ~SP_FLAG_C_FUTURES;
	if (m_uartmsg->msg != NULL) {
	  if (call UARTSend.send(m_uartmsg->msg) == SUCCESS) {
	    return SUCCESS;
	  }
	}
      }

      m_uartmsg = NULL; 
      signal SPSend.sendDone[_stack->id](_stack, _stack->flags, (success != SUCCESS));
    }
    return SUCCESS;
  }

}
