// $Id: MultiHopDataM.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

#include "MultiHop.h"
#include "circularQueue.h"

/**
 * MultiHop routing using LQI on Moteiv's Tmote platforms.
 * <p>
 * This module manages the data flow of messages, and uses SP to 
 * queue outgoing messages for transmission.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module MultiHopDataM {
  provides {
    interface StdControl;
    interface Send[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface RouteControl;
    interface RouteStatistics;
  }
  uses {
    interface StdControl as RadioControl;
    interface SPSend;
    interface SPSendNext;
    interface SPMessage;
    interface ReceiveMsg;
    interface RouteControl as ControlRC;
    interface RouteSelect as ControlRSel;
    interface RouteStatistics as ControlRStat;
    interface TimerMilli as Timer;
    interface Leds;
  }
}
implementation {

  /*************************** FUNCTIONS PROTOTYPES *********************/

  // queue/buffer operations
  result_t enqueue(TOS_MsgPtr msg);
  void dequeue();
  TOS_MsgPtr get_head();
  bool is_empty();
  bool is_full();

  // message processing operations
  void forward(TOS_MsgPtr msg);
  void nextSend();
  void update();
  void signalLocalSendDone(result_t _success);
  void updateTimers(uint32_t time);

  /*************************** VARIABLES ********************************/

  TOS_Msg m_fwdbufs[MHOP_QUEUE_SIZE];            // buffers for forwarding
  CircularQueue_t m_fwdqueue;

  TOS_MsgPtr m_localbufs[MHOP_QUEUE_SIZE];       // local send pointer
  CircularQueue_t m_localqueue;

  sp_message_t m_spmsg;

  bool m_sending;                                // keep track of sending state
  bool m_taskpending;

  uint8_t m_ackfail;                             // track ack failures

  uint8_t m_retransmissions;                     // track retransmissions

  /*************************** ENUMERATIONS *****************************/

  // state of the queue
  enum {
    QUEUE_EMPTY = 0xff,
  };

  /*************************** UTILITY FUNCTIONS ************************/

  task void taskUpdateTimers();

  result_t enqueue(TOS_MsgPtr _msg) {
    if (cqueue_pushBack( &m_fwdqueue )) {
      m_fwdbufs[m_fwdqueue.back] = *_msg; // copy the buffer

      if (m_sending) {
	// update the quantity field
	call SPSend.update(&m_spmsg, 
			   call SPMessage.getTosMsg(&m_spmsg), 
			   call SPMessage.getDev(&m_spmsg),
			   call SPMessage.getAddr(&m_spmsg), 
			   (call SPMessage.getTosMsg(&m_spmsg))->length, 
			   call SPMessage.getFlags(&m_spmsg), 
			   call SPMessage.getQuantity(&m_spmsg) + 1
			   );
      }

      return SUCCESS;
    }
    return FAIL;
  }

  void dequeue() {
    if (!cqueue_isEmpty( &m_fwdqueue )) {
      cqueue_popFront( &m_fwdqueue );
    }
  }

  TOS_MsgPtr get_head() {
    if (!cqueue_isEmpty( &m_fwdqueue )) {
      return &(m_fwdbufs[m_fwdqueue.front]);
    }
    return NULL;
  }

  bool is_full() {
    return cqueue_isFull( &m_fwdqueue );
  }

  bool is_empty() {
    return cqueue_isEmpty( &m_fwdqueue );
  }

  void forward(TOS_MsgPtr _msg) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;

    // add to the forwarding queue if not full
    if (call ControlRSel.isDuplicate( _msg, _mhopmsg->id ) != TRUE) {
      atomic {
	if (!is_full()) {
	  enqueue(_msg);
	}
      }
    }

    // update timers to process and send the message
    update();
  }

  task void taskUpdateTimers() {
    m_taskpending = FALSE;
    updateTimers( MHOP_RETRY_DELAY );
  }

  void updateTimers(uint32_t time) {
    if (!call Timer.isSet()) {
      call Timer.setOneShot( time );
    }
  }

  void update() {
    if ((cqueue_isEmpty( &m_localqueue ) != TRUE) || (!is_empty())) {
      updateTimers(MHOP_INIT_DELAY);
    }
  }

  void signalLocalSendDone(result_t _success) {
    TOS_Msg* _msg = m_localbufs[ m_localqueue.front ];
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;
    cqueue_popFront( &m_localqueue );
    signal Send.sendDone[_mhopmsg->id]( _msg, _success );
  }

  void nextSend() {
    bool _sending = FALSE;
    TOS_Msg* _msg = NULL;
    TOS_MHopMsg* _mhopmsg;
    uint8_t quantity = 0;
    // if not sending, get the head of the queue and send
    
    atomic {
      if (is_empty() != TRUE) {
	_msg = get_head();
      }
      else if (cqueue_isEmpty( &m_localqueue ) != TRUE ) {
	_msg = m_localbufs[m_localqueue.front];
      }

      if ((_msg != NULL) && (!m_sending)) {
	quantity = cqueue_numElements( &m_localqueue ) + 
	  call RouteControl.getOccupancy();
	_sending = TRUE;
	m_sending = TRUE;
      }
    }

    if (_msg == NULL) 
      return;

    if (!_sending) {
      if (!m_taskpending && (post taskUpdateTimers() == SUCCESS)) {
	m_taskpending = TRUE;
      }
    }

    _mhopmsg = (TOS_MHopMsg*)_msg->data;

    // check if we have a route
    if ((call ControlRSel.selectRoute( _msg, _mhopmsg->id, m_ackfail )) == SUCCESS) {
      // try to send
      if (call SPSend.sendAdv( &m_spmsg, 
		      _msg, 
		      (_msg->addr == TOS_UART_ADDR) ? SP_I_UART : SP_I_RADIO,
		      _msg->addr, 
		      _msg->length, 
		      SP_FLAG_C_RELIABLE, 
		      quantity ) == SUCCESS) {

	if (_msg != m_localbufs[m_localqueue.front]) {
	  call Leds.yellowOn();
	}
	else {
	  call Leds.greenOn();
	}
	return;
      // otherwise try again
      }else{
	if (!m_taskpending && (post taskUpdateTimers() == SUCCESS)) {
	  m_taskpending = TRUE;
	}
      }
    }
    // couldn't route this message, dequeue it or signal send done
    else {
      if (_msg == m_localbufs[m_localqueue.front]) {
	signalLocalSendDone(FAIL);
      }
      else {
	dequeue();
      }
    }
    m_sending = FALSE;
  }

  /*************************** STDCONTROL ******************************/

  command result_t StdControl.init() {
    cqueue_init( &m_fwdqueue, MHOP_QUEUE_SIZE );
    cqueue_init( &m_localqueue, MHOP_QUEUE_SIZE );
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /*************************** TIMER ***********************************/

  event result_t Timer.fired() {
    nextSend();
    return SUCCESS;
  }

  /*************************** SEND (Multihop) *************************/

  command result_t Send.send[uint8_t id](TOS_MsgPtr _msg, uint16_t _length) {
    // modify the contents of the message
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;
    uint16_t _mhlength = offsetof(TOS_MHopMsg,data) + _length;
    
    if ((_mhlength > TOSH_DATA_LENGTH) || (cqueue_isFull( &m_localqueue ))) {
      return FAIL;
    }

    call ControlRSel.initializeFields( _msg, id );
    
    if (call ControlRSel.isDuplicate( _msg, id ) == TRUE) {
      return FAIL;
    }

    if (cqueue_pushBack( &m_localqueue ) == SUCCESS) {
      m_localbufs[m_localqueue.back] = _msg;
      _mhopmsg->id= id;
      _msg->length = _mhlength;

      if (m_sending) {
	// update the quantity field
	call SPSend.update(&m_spmsg, 
			   call SPMessage.getTosMsg(&m_spmsg), 
			   call SPMessage.getDev(&m_spmsg), 
			   call SPMessage.getAddr(&m_spmsg), 
			   (call SPMessage.getTosMsg(&m_spmsg))->length, 
			   call SPMessage.getFlags(&m_spmsg), 
			   call SPMessage.getQuantity(&m_spmsg) + 1
			   );
      }
      // update timers and try to send
      update();

      return SUCCESS;
    }
    return FAIL;

  }

  command void* Send.getBuffer[uint8_t id](TOS_MsgPtr _msg, uint16_t* _length) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)(_msg->data);
    *_length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);
    return _mhopmsg->data;
  }

  /*************************** SENDMSG (Single Hop) ********************/

  event void SPSendNext.request(sp_message_t* msg, TOS_Msg* tosmsg, uint8_t remaining) { 
    TOS_Msg* _msg = NULL;
    TOS_MHopMsg* _mhopmsg;

    if (tosmsg == m_localbufs[m_localqueue.front]) { // Msg was from upper layers (local)
      signalLocalSendDone( SUCCESS );
    }
    else {
      dequeue();
    }

    if (is_empty() != TRUE) {
      _msg = get_head();
    }
    else if (cqueue_isEmpty( &m_localqueue ) != TRUE ) {
      _msg = m_localbufs[m_localqueue.front];
    }

    if (_msg != NULL) {
      _mhopmsg = (TOS_MHopMsg*)(_msg->data);
      if ((call ControlRSel.selectRoute( _msg, _mhopmsg->id, m_ackfail )) == SUCCESS) {
	call SPSendNext.response(msg, _msg, _msg->length);
      }
    }

  }

  event void SPSend.sendDone(sp_message_t* _msg, sp_message_flags_t flags, sp_error_t _success) {
    uint8_t error = 0;
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->msg->data;

    call Leds.greenOff();
    call Leds.yellowOff();

    // was there an underrun?
    if ((_success == SP_E_BUF_UNDERRUN) || (_msg->msg == NULL)) {
      // start the process of sending again
      m_ackfail = 0;
      m_sending = FALSE;
      update();
      return;
    }

    // was the ack received?  if not, try again
    if ((!(call SPMessage.getFlags(_msg) & SP_FLAG_F_RELIABLE)) && 
	(call SPMessage.getAddr(_msg) != TOS_BCAST_ADDR) && 
	(call SPMessage.getAddr(_msg) != TOS_UART_ADDR) &&
	(m_ackfail < MHOP_RETRY_MSG)) {
      m_ackfail++;
      if (call ControlRSel.selectRoute( _msg->msg, _mhopmsg->id, m_ackfail ) == SUCCESS) {
	m_retransmissions++;
	updateTimers( MHOP_RETRY_DELAY );
      }
      else {
	error = 2;
      }
    }
    else {
      error = 1;
    }

    if (error) {
      // done sending or giving up
      m_sending = FALSE;
      m_ackfail = 0;
      if (_msg->msg == m_localbufs[m_localqueue.front]) { // Msg was from upper layers (local)
	if (error > 1) {
	  signalLocalSendDone( FAIL );
	}
	else {
	  signalLocalSendDone( (_success == SP_SUCCESS) );
	}
      } else { 
	dequeue();
      } 
      // if there's more entries, get the timer running again
      update();
    }
  }

  /*************************** RECEIVEMSG (Single Hop) *****************/

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr _msg) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*) _msg->data;
    uint8_t _length = _msg->length - offsetof(TOS_MHopMsg,data);

    // Ordinary message requiring forwarding
    // Addressed to local node or broadcast (best effort)
    // if broadcast, duplicate supression will keep from flooding up tree
    if ((_msg->addr == TOS_LOCAL_ADDRESS) || (_msg->addr == TOS_BCAST_ADDR)) {
      
      // check if we should intercept
      if ((signal Intercept.intercept[_mhopmsg->id](_msg,
						    _mhopmsg->data,
						    _length)) == SUCCESS) {
	// if yes, add the message to the forwarding queue
	forward( _msg );
      }
    }

    // Snoop the packet for permiscuous applications
    signal Snoop.intercept[_mhopmsg->id]( _msg, _mhopmsg->data, _length );

    return _msg;
  }

  /*************************** ROUTECONTROL ****************************/

  command uint16_t RouteControl.getParent() {
    return call ControlRC.getParent();
  }

  command uint8_t RouteControl.getDepth() {
    return call ControlRC.getParent();
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr _msg) {
    return call ControlRC.getSender(_msg);
  }

  command uint8_t RouteControl.getOccupancy() {
    return cqueue_numElements( &m_fwdqueue );
  }

  command uint8_t RouteControl.getQuality() {
    return call ControlRC.getQuality();
  }

  command result_t RouteControl.setUpdateInterval(uint16_t _interval) {
    return call ControlRC.setUpdateInterval(_interval);
  }

  command result_t RouteControl.manualUpdate() {
    return call ControlRC.manualUpdate();
  }

  /*************************** ROUTE STATISTICS ************************/

  command uint8_t RouteStatistics.getNeighborSize() {
    return call ControlRStat.getNeighborSize();
  }
  command void RouteStatistics.getNeighbors(uint16_t* neighbors, uint8_t length) {
    call ControlRStat.getNeighbors(neighbors, length);
  }
  command void RouteStatistics.getNeighborQuality(uint16_t* quality, uint8_t length) {
    call ControlRStat.getNeighborQuality(quality, length);
  }

  command uint8_t RouteStatistics.getRetransmissions() {
    return m_retransmissions;
  }
  
  command void RouteStatistics.resetRetransmissions() {
    m_retransmissions = 0;
  }

  /*************************** DEFAULT HANDLERS ************************/
  default event result_t Send.sendDone[uint8_t id](TOS_MsgPtr _msg, result_t _success) { return SUCCESS; }

  default event result_t Intercept.intercept[uint8_t id](TOS_MsgPtr _msg, void* _payload, uint16_t _length) { return SUCCESS; }

  default event result_t Snoop.intercept[uint8_t id](TOS_MsgPtr _msg, void* _payload, uint16_t _length) { return SUCCESS; }

}
