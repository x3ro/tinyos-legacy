/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "sp.h"
#include "sp_cc2420.h"

/**
 * Implementation of a CC2420 link that is always on, regardless of the 
 * contents of the SP Message Pool and SP Neighbor Table.
 * This is the default implementation used when compiling applications.
 * To use the scheduling (duty cycling) implementation, see
 * CC2420SyncMojoM.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module CC2420AlwaysOnM {
  provides {
    interface StdControl;
    interface SPSend;
    interface SPLinkEvents;
    interface SPLinkStats;
  }
  uses {
    interface TimeStamping<T32khz, uint32_t>;
    interface CC2420BareSendMsg as LowerSend;
    interface SPNeighbor;
    interface Alarm<T32khz,uint32_t> as AlarmStart;
    interface Alarm<T32khz,uint32_t> as AlarmStop;
    interface Timer2<TMilli> as SanityTimer;
    interface SplitControl as RadioControl;
    interface MacControl;
    interface MacBackoff;
    interface ObjectPool<sp_message_t> as Pool;
    interface ObjectPoolEvents<sp_message_t> as PoolEvents;
    interface Random;
  }
}
implementation {

  enum {
    FLAG_SENDDONE = 0x01,
    FLAG_MULTIMSG = 0x02,
  };

  sp_message_t* spmsg;
  norace uint8_t m_backoffs; // only used when not sending messages
  norace uint8_t m_flags;

  command result_t StdControl.init() { 
    return call RadioControl.init();
  }

  command result_t StdControl.start() { 
    return call RadioControl.start();
  }

  command result_t StdControl.stop() { 
    return call RadioControl.stop();
  }

  command result_t SPSend.send(sp_message_t* _spmsg, TOS_Msg* _tosmsg, uint16_t _addr, uint8_t _length) {
    return call SPSend.sendAdv(_spmsg,
			       _tosmsg,
			       SP_I_RADIO,
			       _addr,
			       _length,
			       SP_FLAG_C_NONE,
			       1);
  }

  command result_t SPSend.sendAdv(sp_message_t* _spmsg, TOS_Msg* _tosmsg, sp_device_t _dev, sp_address_t _addr, uint8_t _length, sp_message_flags_t _flags, uint8_t _quantity) {
    if (spmsg != NULL) {
      return FAIL;
    }
    if (_spmsg->flags & SP_FLAG_C_TIMESTAMP) {
      // if time stamps are requested, notify the time stamping component
      if (call TimeStamping.addStamp(_spmsg->msg, _length) != SUCCESS) {
	return FAIL;
      }
      else {
	_spmsg->msg->length = _length + 4;
      }
    }

    if (call LowerSend.send(_spmsg->msg) == SUCCESS) {
      if ((_spmsg->flags & SP_FLAG_C_RELIABLE) && 
	  (_spmsg->addr != TOS_BCAST_ADDR)) {
	// request an ack
	call MacControl.requestAck(_spmsg->msg);
      }

      m_backoffs = 0; // atomic, occurs when sending is done
      spmsg = _spmsg;
      if (m_flags & FLAG_SENDDONE) {
	m_flags |= FLAG_MULTIMSG;
      }
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t SPSend.update(sp_message_t* _spmsg, TOS_Msg* _tosmsg, sp_device_t _dev, sp_address_t _addr, uint8_t _length, sp_message_flags_t _flags, uint8_t _quantity) {
    return FAIL;
  }

  command result_t SPSend.cancel(sp_message_t* msg) {
    return FAIL;
  }

  event result_t LowerSend.sendDone(TOS_MsgPtr msg, cc2420_error_t success) {
    sp_message_t* _stack = spmsg;
    sp_error_t _error = SP_SUCCESS;
    spmsg = NULL;

    if ((_stack->flags & SP_FLAG_C_RELIABLE) && 
	(_stack->addr != TOS_BCAST_ADDR)) {
      if (msg->ack) {
	_stack->flags |= SP_FLAG_F_RELIABLE;
      }
      else {
	_error = SP_E_RELIABLE;
      }
    }

    // correct the length field after sending a timestamp
    if (_stack->flags & SP_FLAG_C_TIMESTAMP) {
      _stack->msg->length = _stack->length;
    }

    if (success == CC2420_E_SHUTDOWN) {
      _error = SP_E_SHUTDOWN;
    }

    if ((_error == SP_SUCCESS) && (success != CC2420_SUCCESS))
      _error = SP_E_UNKNOWN;

    if (m_backoffs > SP_FEEDBACK_COUNT_CONGESTION)
      _stack->flags |= SP_FLAG_F_CONGESTION;

    m_flags = FLAG_SENDDONE;
    signal SPSend.sendDone(_stack, _stack->flags, _error);
    m_flags &= ~FLAG_SENDDONE;

    return SUCCESS;
  }

  command sp_linkstate_t SPLinkStats.getState() {
    return SP_RADIO_ON;
  }

  command result_t SPLinkStats.find() {
    return SUCCESS;
  }
  command result_t SPLinkStats.findDone() {
    return SUCCESS;
  }

  command uint16_t SPLinkStats.getQuality(sp_neighbor_t* n, TOS_Msg* msg) {
    return correlation(msg->lqi);
  }

  async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m) {
    if (m_flags & FLAG_MULTIMSG)
      return (call Random.rand() & 0x1F) + 1;
    else
      return (call Random.rand() & 0x7F) + 1;
  }
  async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m) {
    m_backoffs++;
    return (call Random.rand() & 0x7F) + 1;
  }

  event void SanityTimer.fired() { }

  event result_t RadioControl.initDone() { return SUCCESS; }
  event result_t RadioControl.startDone() {     
    call MacControl.enableAck();
    return SUCCESS; 
  }
  event result_t RadioControl.stopDone() { return SUCCESS; }
  async event void AlarmStart.fired() { }
  async event void AlarmStop.fired() { }
  event void SPNeighbor.update(sp_neighbor_t* neighbor) { }
  event result_t SPNeighbor.admit(sp_neighbor_t* neighbor) { return SUCCESS; }
  event void SPNeighbor.expired(sp_neighbor_t* neighbor) { } 
  event void SPNeighbor.evicted(sp_neighbor_t* neighbor) { }
  event void PoolEvents.inserted(sp_message_t* msg) { }
  event void PoolEvents.removed(sp_message_t* msg) { }

}
