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
#include "circularQueue.h"
#include "Reset.h"

/**
 * Implementation of a duty cycled CC2420 link.  The link is turned
 * on and off based on the schedules in the SP Neighbor Table.
 * A link is only turned on if it has a schedule and either 
 * (1) messages are pending for that neighbor or (2) the listen flag
 * is set for that neighbor.
 * <p>
 * Neighbors can contain overlapping schedules, and the union of
 * all of the current schedules will be the actual active period.
 * <p>
 * <b>WARNING:</b> Do not modify neighbors while they are "on" or "busy".
 * If the <tt>SP_FLAG_LINK_ACTIVE</tt> flag is set while accessing
 * the neighbor schedule, do <b>not</b> modify it until the flag is
 * cleared.  Doing so may result in unpredicable operation.  After
 * a link is active, an <tt>SPNeighbor.expired()</tt> event will be 
 * signalled from SPC.  Please use this event to change the schedule 
 * of the neighbor.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module CC2420SyncSaneP {
  provides {
    interface StdControl;
    interface SPSend;
    interface SPLinkEvents;
    interface SPLinkStats;
    // for debugging and power management information
    interface Get<uint32_t> as GetFindCount;
    interface Get<uint32_t> as GetWakeCount;
  }
  uses {
    interface TimeStamping<T32khz, uint32_t>;
    interface CC2420BareSendMsg as LowerSend;
    interface SPNeighbor;
    interface Alarm<T32khz,uint32_t> as VirtualAlarm[uint8_t id];
    interface Timer2<TMilli> as SanityTimer;
    interface SplitControl as RadioControl;
    interface MacControl;
    interface MacBackoff;
    interface ObjectPool<sp_message_t> as Pool;
    interface ObjectPoolEvents<sp_message_t> as PoolEvents;
    interface Set<int8_t> as SetRefCount;
    interface Random;
  }
}
implementation {

  enum {
    FLAG_SENDDONE = 0x01,
    FLAG_MULTIMSG = 0x02,
  };

  // global variables
  uint32_t sp_cc2420_findcount;
  uint32_t sp_cc2420_wakecount;

  uint8_t m_on_count;
  int8_t m_find;
  norace uint8_t m_backoffs;
  norace uint8_t m_flags;
  
  // list of expired neighbors
  sp_neighbor_t* m_expired[SP_SIZE_NEIGHBOR_TABLE];
  // queue structure for those neighbors
  CircularQueue_t queue;

  sp_message_t* spmsg;

  task void taskRadioOn();
  result_t startRadio();
  task void taskRadioOff();
  result_t stopRadio();
  bool shutdownRadio();

  async command uint32_t GetFindCount.get() {
    return sp_cc2420_findcount;
  }
  async command uint32_t GetWakeCount.get() {
    return sp_cc2420_wakecount;
  }

  /************************* STD CONTROL *****************************/

  command result_t StdControl.init() { 
    m_on_count = 0;
    cqueue_init( &queue, SP_SIZE_NEIGHBOR_TABLE );
    return call RadioControl.init();
  }

  command result_t StdControl.start() { 
    call SanityTimer.startOneShot( 
       (call Random.rand() & CC2420_SANITY_TIMER_MASK)
       + CC2420_SANITY_TIMER );
    return SUCCESS; 
  }

  command result_t StdControl.stop() { 
    return SUCCESS;
  }

  /************************* SP SEND *********************************/

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

    if ((spmsg != NULL) || (call SPLinkStats.getState() != SP_RADIO_ON)) {
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
    if( _stack != NULL && _stack->msg == msg ) {
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

      // atomic, occurs when not sending
      if (m_backoffs > SP_FEEDBACK_COUNT_CONGESTION) 
        _stack->flags |= SP_FLAG_F_CONGESTION;

      m_flags = FLAG_SENDDONE;
      signal SPSend.sendDone(_stack, _stack->flags, _error);
      m_flags &= ~FLAG_SENDDONE;
    }
    return SUCCESS;
  }

  /************************* SP LINK STATS ***************************/

  command sp_linkstate_t SPLinkStats.getState() {
    if (call MacControl.getState() == CC2420_LINKSTATE_OFF)
      return SP_RADIO_OFF;
    else
      return SP_RADIO_ON;
  }

  command result_t SPLinkStats.find() {
    atomic {
      m_find++;
      sp_cc2420_findcount++;
    }
    startRadio();  
    return SUCCESS;
  }

  command result_t SPLinkStats.findDone() {
    atomic {
      m_find--;
      if (m_find <= 0) {
	m_find = 0;
        m_on_count = 0;
      }
    }
    post taskRadioOff();
    return SUCCESS;
  }

  command uint16_t SPLinkStats.getQuality(sp_neighbor_t* n, TOS_Msg* msg) {
    return correlation(msg->lqi);
  }

  /************************* TIMER ***********************************/

  task void signalSleep() {
    signal SPLinkEvents.sleep();
  }

  task void taskRadioOn() {
    startRadio();
  }

  result_t startRadio() {
    call RadioControl.start();
    return SUCCESS;
  }

  task void taskRadioOff() {
    if (shutdownRadio()) {
      stopRadio();
      post signalSleep();
    }
  }

  result_t stopRadio() {
    m_on_count = 0;
    return call RadioControl.stop();
  }

  bool msgPend(sp_neighbor_t* _n) {
    // return TRUE if a message is pending for neighbor _n
    uint8_t i;
    for (i=call Pool.first(); call Pool.valid(i); i=call Pool.next(i)) {
      if( (call Pool.get(i))->addr == _n->addr )
	return TRUE;
    }
    return FALSE;
  }

  // signal each neighbor that expired
  task void taskExpiration() {
    sp_neighbor_t* n;
    while (!cqueue_isEmpty( &queue )) {
      atomic {
	n = m_expired[queue.front];
	cqueue_popFront( &queue );
      }
      signal SPLinkEvents.expired( n );
    }
  }

  bool shutdownRadio() {
    uint32_t _time;
    bool _sane = FALSE;

    // don't affect the 'find' state or if the radio is already off
    if (m_find > 0)
      return FALSE;
    
    if (call MacControl.getState() == CC2420_LINKSTATE_ON) {
      // we know the radio is on...
      atomic {
        uint8_t i;
	// see if any neighbors are currently active
	_time = call VirtualAlarm.getNow[0]();
        for (i=call SPNeighbor.first(); call SPNeighbor.valid(i); i=call SPNeighbor.next(i)) {
	  sp_neighbor_t* n = call SPNeighbor.get(i);
          // if the entry has a valid schedule
	  if ( n->timeon != n->timeoff ) {
	    if (n->timeon < n->timeoff) {
	      if ((n->timeon <= _time) && (n->timeoff >= _time)) {
		// if a node is on, we can stop searching
		_sane = TRUE;
		break;
	      }
	    }
	    else if (n->timeon > n->timeoff) {
	      if (!((_time < n->timeon) && (_time > n->timeoff))) {
		_sane = TRUE;
		break;
	      }
	    }
	    else {
	      if ((n->flags & SP_FLAG_LINK_ACTIVE) || 
		  (n->flags & SP_FLAG_LINK_STARTED))
		n->flags &= ~(SP_FLAG_LINK_ACTIVE | SP_FLAG_LINK_STARTED);
	    }
	  }
	}
      }
    }
    return !_sane;
  }

  event void SanityTimer.fired() {
// If Moteiv LowPower compilation option is used, the system is using
// NetSync for synchronization and should never be active for more than
// 2 seconds at any single time.  This santity timer checks that the radio
// does not get wedged, and reboots the node if any such activity occurs
#ifdef MOTEIV_LOWPOWER
    if( (m_find <= 0) && (++m_on_count >= 3) ) {
      // If the radio has been on for 3 or more periods, it has entered
      // a state that prevents shutdown.  Reboot the mote to restore low
      // power operation
      // Moteiv: CS + JP 2006/06.
      resetMote();
    }
#endif
    if (shutdownRadio()) {
      // turn radio off
      stopRadio();
      post signalSleep();
    }

    call SanityTimer.startOneShot( 
	(call Random.rand() & CC2420_SANITY_TIMER_MASK)
	+ CC2420_SANITY_TIMER 
	);
  }

  async event void VirtualAlarm.fired[uint8_t i]() {
    sp_neighbor_t* _n = call SPNeighbor.get(i);
    if( _n != NULL ) {
      if (_n->timeon == call VirtualAlarm.getAlarm[i]()) {
        if ((_n->addr == TOS_BCAST_ADDR) ||
            (_n->flags & SP_FLAG_LISTEN) || 
            msgPend(_n)) {
          _n->flags |= SP_FLAG_LINK_ACTIVE;
          // set timeoff
          call VirtualAlarm.startAt[i]( call VirtualAlarm.getAlarm[i](),
                                      _n->timeoff - call VirtualAlarm.getAlarm[i]()
                                      );

          sp_cc2420_wakecount++;

          post taskRadioOn();
        }
      }
      else if (//(_n->timeoff == call VirtualAlarm.getAlarm[i]()) &&
               (_n->flags & SP_FLAG_LINK_ACTIVE)) {
        _n->flags &= ~SP_FLAG_LINK_ACTIVE;
        // signal expired
        if (cqueue_pushBack(&queue) == SUCCESS) {
          m_expired[queue.back] = _n;
          post taskExpiration();
        }
        post taskRadioOff();
      }
    }
  }

  /************************* RADIO CONTROL ***************************/

  event result_t RadioControl.initDone() { 
    return SUCCESS;
  }

  event result_t RadioControl.startDone() {
    call MacControl.enableAck();
    signal SPLinkEvents.active();
    return SUCCESS; 
  }
  event result_t RadioControl.stopDone() {
    return SUCCESS; 
  }

  /************************* SP NEIGHBOR *****************************/

  void updateTasks(sp_neighbor_t* _n) {
    uint32_t now = call VirtualAlarm.getNow[0]();
    // if not active
    if (!(_n->flags & SP_FLAG_LINK_ACTIVE)) {
      // find where _n is
      uint8_t i;
      for (i=call SPNeighbor.first(); call SPNeighbor.valid(i); i=call SPNeighbor.next(i)) {
	if (call SPNeighbor.get(i) == _n) {
          call VirtualAlarm.startAt[i]( now, _n->timeon - now );
	  break;
        }
      }
    }
  }

  event void SPNeighbor.update(sp_neighbor_t* _n){ 
    updateTasks(_n);
  }
  event result_t SPNeighbor.admit(sp_neighbor_t* _n) { 
    updateTasks(_n);
    return SUCCESS;
  }
  event void SPNeighbor.expired(sp_neighbor_t* neighbor) {
    // do nothing, wait for the entry to be updated
  }
  event void SPNeighbor.evicted(sp_neighbor_t* _n) { 
    updateTasks(_n);
  }

  event void PoolEvents.inserted(sp_message_t* msg) { 
  }
  event void PoolEvents.removed(sp_message_t* msg) { 
  }

  /************************* MAC BACKOFF *****************************/

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

}
