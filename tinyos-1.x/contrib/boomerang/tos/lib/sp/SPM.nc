/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "sp.h"

/**
 * Implementation of the primary state machine of SP for handling
 * messages, both transmitted and received.  SPM works together
 * with other components to send messages from the pool when appropriately
 * notified by the SP Neighbor Table or the link protocol.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPM {
  provides {
    interface SPSend[uint8_t id];
    interface SPSendNext[uint8_t id];
    interface SPReceive[uint8_t id];
    interface ReceiveMsg[uint8_t id];
  }
  uses {
    interface SPSend as SPDataMgr[uint8_t id];
    interface SPSendNext as SPDataMgrNext[uint8_t id];
    interface ReceiveMsg as LowerReceive;
    interface ReceiveMsg as UARTReceive;
    interface SPLinkStats;
    interface SPLinkEvents;
    interface SPNeighbor;
    interface SPSend as LowerSend;
    interface ObjectPool<sp_message_t> as Pool;
    interface ObjectPoolEvents<sp_message_t> as PoolEvents;
    interface LocalTime<T32khz>;
  }
}
implementation {

  sp_message_t* m_currentmsg;
  bool m_sending;

  void processSendComplete(sp_message_t* msg, sp_message_flags_t flags, sp_error_t success);

  bool isOkToSend(uint16_t addr) {
    uint8_t j;
    for (j=call SPNeighbor.first(); call SPNeighbor.valid(j); j=call SPNeighbor.next(j) ) {
      sp_neighbor_t* n = call SPNeighbor.get(j);
      // only allow the message to be sent if the receipient is active
      if (((n->addr == addr) || 
           (n->addr == TOS_BCAST_ADDR)) && 
          (n->flags & SP_FLAG_LINK_ACTIVE)) {
        return TRUE;
      }
    }
    return FALSE;
  }

  uint8_t neighborPopulation() {
    return call SPNeighbor.populated();
  }
  
  void nextSend() {
    bool urgent = FALSE;
    uint32_t time = call LocalTime.get();
    uint32_t min = (uint32_t)0xFFFFFFFF;

    if ((m_sending) && (m_currentmsg != NULL))
      return;

    m_sending = FALSE;
    m_currentmsg = NULL;

    // if we're idle but the radio is on, see if we can send a message
    if (call SPLinkStats.getState() == SP_RADIO_ON) {
      // find the next message to send
      uint8_t i;
      for( i=call Pool.first(); call Pool.valid(i); i=call Pool.next(i) ) {
	// get the next message
        sp_message_t* temp = call Pool.get(i);

        // cycle through the neighbor table and find the appropriate
        // destination and check if that destination is active
        // if the destination is active and it an old message, try it
        if (isOkToSend(temp->addr) || (neighborPopulation() == 0)) {
          // if there are no urgent messages, process normally
          if (!urgent) {
            // if the message is urgent, make it the next to send
            if (temp->flags & SP_FLAG_C_URGENT) {
              urgent = TRUE;
              min = time - temp->time;
              m_currentmsg = temp;
            }
            else if ((time - temp->time) <= min) {
              min = time - temp->time;
              m_currentmsg = temp;
            }
          }
          // if there is an urgent message, process them in FIFO order
          else {
            if ((temp->flags & SP_FLAG_C_URGENT) && 
                ((time - temp->time) <= min)) {
              min = time - temp->time;
              m_currentmsg = temp;
            }
          }

	}
      } // end cycling through the message pool
    } // end if

    // if we found a message, try to send it
    if (m_currentmsg != NULL) {
      // set the active message type
      m_currentmsg->msg->type = m_currentmsg->id;
      // try to send
      if (call LowerSend.sendAdv(m_currentmsg, 
				 m_currentmsg->msg, 
				 m_currentmsg->dev,
				 m_currentmsg->addr,
				 m_currentmsg->length, 
				 m_currentmsg->flags, 
				 m_currentmsg->quantity) == SUCCESS) {
	m_sending = TRUE;
	m_currentmsg->flags |= SP_FLAG_C_BUSY;
      }
      else {
	// send failed, null out the pointer
	m_currentmsg->retries++;
	// if something bad happens over and over, complete the process
	// and move on instead of getting into a wedge.
	if (m_currentmsg->retries >= SP_CONTROL_COUNT_RETRIES) {
	  processSendComplete(m_currentmsg, m_currentmsg->flags, SP_E_UNKNOWN);
	}
	else {
	  m_currentmsg = NULL;
	  m_sending = FALSE;
	}
      }
    }
  }

  event void PoolEvents.inserted(sp_message_t* msg) {
  }

  event void PoolEvents.removed(sp_message_t* msg) { 
  }
  
  command result_t SPSend.send[uint8_t id](sp_message_t* _msg, TOS_Msg* _tosmsg, sp_address_t _addr, uint8_t _length) {
    return call SPSend.sendAdv[id](_msg,
				   _tosmsg,
				   (_addr == TOS_UART_ADDR) ? SP_I_UART : SP_I_RADIO,
				   _addr,
				   _length,
				   SP_FLAG_C_NONE,
				   1);
  }

  command result_t SPSend.sendAdv[uint8_t id](sp_message_t* _msg, TOS_Msg* _tosmsg, sp_device_t _dev, sp_address_t _addr, uint8_t _length, sp_message_flags_t _flags, uint8_t _quantity) {
    if (call SPDataMgr.sendAdv[id](_msg, 
				   _tosmsg, 
				   _dev,
				   _addr, 
				   _length, 
				   _flags, 
				   _quantity) == SUCCESS) {
      nextSend();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t SPSend.update[uint8_t id](sp_message_t* _msg, TOS_Msg* _tosmsg, sp_device_t _dev, sp_address_t _addr, uint8_t _length, sp_message_flags_t _flags, uint8_t _quantity) {
    if (call SPDataMgr.update[id](_msg, 
				  _tosmsg, 
				  _dev,
				  _addr, 
				  _length, 
				  _flags, 
				  _quantity) == SUCCESS) {
      nextSend();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t SPSend.cancel[uint8_t id](sp_message_t* _msg) {
    return call SPDataMgr.cancel[id](_msg);
  }

  command void SPSendNext.response[uint8_t id](sp_message_t* msg, TOS_Msg* tosmsg, uint8_t length) {
    // protect against unauthorized access
    if ((msg->flags & SP_FLAG_C_FUTURES) && (msg->id == id)) {
      msg->msg = tosmsg;
      // store the address
      msg->msg->addr = msg->addr;
      // store the service identifier
      msg->msg->type = msg->id;
      // set the group
      msg->msg->group = TOS_AM_GROUP;
      // set the length of the message
      msg->length = length;
      msg->msg->length = length;
    }
  }

  event void SPDataMgrNext.request[uint8_t id](sp_message_t* msg, TOS_Msg* tosmsg, uint8_t quantity) {
    signal SPSendNext.request[id](msg, tosmsg, quantity);
  }

  event void SPDataMgr.sendDone[uint8_t id](sp_message_t* msg, sp_message_flags_t flags, sp_error_t success) { 
    signal SPSend.sendDone[id](msg, flags, success);
  }

  void tryNextSend() {
    // cycle through the neighbor table and find the appropriate
    // destination and check if that destination is active
    // check if destination still on
    // if so, try to send and return from function
    if (((isOkToSend(m_currentmsg->addr) || 
	  (neighborPopulation() == 0))) &&
	(call SPLinkStats.getState() == SP_RADIO_ON)) {
      // try to send the message
      if (call LowerSend.sendAdv(m_currentmsg, 
				 m_currentmsg->msg, 
				 m_currentmsg->dev,
				 m_currentmsg->addr, 
				 m_currentmsg->length, 
				 m_currentmsg->flags, 
				 m_currentmsg->quantity
				 ) == SUCCESS) {
	m_currentmsg->flags |= SP_FLAG_C_BUSY;
	return;
      }
    }
    // can't send, wait for next opportunity
    m_currentmsg = NULL;
    m_sending = FALSE;
  }

  void processSendComplete(sp_message_t* msg, sp_message_flags_t flags, sp_error_t success) {
    sp_message_t* _stack;
    TOS_Msg* _tosstack;

    // if the radio pre-maturely shut down on us, try it again
    if (success == SP_E_SHUTDOWN)
      tryNextSend();
    // otherwise check if reliability failed
    else if ((success != SP_SUCCESS) && 
	     (m_currentmsg->flags & SP_FLAG_C_RELIABLE) &&
	     (++msg->retries < SP_CONTROL_COUNT_RETRIES)) {
      // try again, reset the error flag
      m_currentmsg->flags &= ~SP_FLAG_F_RELIABLE;
      tryNextSend();
    }
    // continue process messages to send
    else {
      
      _stack = m_currentmsg;
      _tosstack = m_currentmsg->msg;
      _stack->flags &= ~SP_FLAG_C_BUSY;
      
      // decrement the quantity
      m_currentmsg->quantity--;
      
      // if there are more packets in the sequence and life is good
      if ((m_currentmsg->quantity > 0) && (success == SP_SUCCESS)) {
	m_currentmsg->msg = NULL;
	m_currentmsg->flags |= SP_FLAG_C_FUTURES;
	// request the next packet
	signal SPSendNext.request[m_currentmsg->id](m_currentmsg, 
						    _tosstack, 
						    m_currentmsg->quantity
						    );
	m_currentmsg->flags &= ~SP_FLAG_C_FUTURES;
	m_currentmsg->retries = 0;
	// if no packet is offered, abort the transaction
	if (m_currentmsg->msg == NULL) {
	  m_currentmsg = NULL;
	  m_sending = FALSE;
	  call Pool.remove(_stack);
	  // there was a buffer underrun because the next packet
	  // was not specified
	  signal SPSend.sendDone[_stack->id](_stack, 
					     _stack->flags, 
					     SP_E_BUF_UNDERRUN
					     );
	}
	// otherwise try to send the next packet if the destination
	// is still awake
	else {
	  tryNextSend();
	}
      }
      // if the quantity is expired, 
      else {
	m_currentmsg = NULL;
	m_sending = FALSE;
	call Pool.remove(_stack);
	signal SPSend.sendDone[_stack->id](_stack, 
					   _stack->flags, 
					   success
					   );
      }
    }
  }

  event void LowerSend.sendDone(sp_message_t* msg, sp_message_flags_t flags, sp_error_t success) {

    if ((m_sending) && (m_currentmsg == msg)) {
      processSendComplete(msg, flags, success);
    }

    // figure out who to send to next
    nextSend();
  }

  event void SPLinkEvents.active() {
    nextSend();
  }

  event void SPLinkEvents.sleep() {
    // stop any subsequent sends
  }

  event void SPLinkEvents.expired(sp_neighbor_t* n) {
  }

  void setRxFields(sp_message_t* msg, TOS_Msg* tosmsg, sp_device_t dev, sp_message_flags_t flags, uint8_t quantity, uint8_t id) {
    // store the TOSMsg
    msg->msg = tosmsg;

    // store the address
    msg->addr = tosmsg->addr;
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
  }

  event TOS_MsgPtr LowerReceive.receive(TOS_MsgPtr m) {
    // perform group filtering
    if (m->group == TOS_AM_GROUP) {
      sp_message_t spmsg;
      setRxFields(&spmsg, m, SP_I_RADIO, SP_FLAG_C_NONE, 1, m->type);
      signal SPReceive.receive[m->type](&spmsg, m, SP_SUCCESS);
      return signal ReceiveMsg.receive[m->type](m);
    }
    return m;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr m) {
    sp_message_t spmsg;
    setRxFields(&spmsg, m, SP_I_UART, SP_FLAG_C_NONE, 1, m->type);
    signal SPReceive.receive[m->type](&spmsg, m, SP_SUCCESS);
    return signal ReceiveMsg.receive[m->type](m);
  }

  event void SPNeighbor.update(sp_neighbor_t* neighbor) { 
  }
  event result_t SPNeighbor.admit(sp_neighbor_t* neighbor) { 
    return SUCCESS;
  }
  event void SPNeighbor.expired(sp_neighbor_t* neighbor) {
  }

  event void SPNeighbor.evicted(sp_neighbor_t* neighbor) { 
  }

  default event void SPSend.sendDone[uint8_t id](sp_message_t* msg, sp_message_flags_t flags, sp_error_t success) { }
  default event void SPSendNext.request[uint8_t id](sp_message_t* msg, TOS_Msg* tosmsg, uint8_t remaining) { }

  default event void SPReceive.receive[uint8_t id](sp_message_t* spmsg, TOS_MsgPtr m, sp_error_t result) { }
  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr m) { return m; }
  
}
