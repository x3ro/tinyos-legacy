/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "NetSync.h"
#include "GlobalTime.h"

/**
 * Implementation of Moteiv's Network-wide Synchronization protocol.
 * Synchronization messages are periodically sent to surrounding nodes
 * using a Trickle-style protocol, with the exception that the interval
 * is never changed (Tau).  Uses node 0 or a UartDetect connected node
 * as the master.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module NetSyncM {
  provides {
    interface StdControl;
    interface GlobalTime<T32khz>;
  }
  uses {
    interface Timer2<TMilli> as TimerI;   // interval
    interface Timer2<TMilli> as TimerTau; // advertisement during interval
    interface LocalTime<T32khz>;
    interface SPNeighbor;
    interface SPSend;
    interface SPUtil;
    interface SPMessage;
    interface Detect;
    interface Random;
    interface Leds;
    interface ReceiveMsg as Receive;
  }
}
implementation {

  enum {
    PERIOD = (1L << NETSYNC_PERIOD_LOG2),
    PERIOD_MASK = PERIOD-1,
    TIME_SYNC = 1024*30,   // milliseconds
    TIME_ON = 1024,    // 1/32khz
    _TIME_OFF = (uint32_t)(TIME_ON + ((1.0 * PERIOD * NETSYNC_DUTYCYCLE + 50.0) / 100.0)), // 1/32khz
    TIME_OFF = (_TIME_OFF > PERIOD) ? (PERIOD-1) : _TIME_OFF, // 1/32khz
    TIME_EXPIRE = 8,
    TIME_DELAY = 3,
    INVALID_HOPCOUNT = 0xFE,
  };

  sp_message_t spmsg;
  TOS_Msg tosmsg;
  syncmsg_t* m_smsg;

  sp_neighbor_t broadcast;

  uint8_t m_timeout;
  uint32_t m_nexton, m_nextoff;

  uint32_t m_globaltime;

  bool m_ispending;

  bool isBaseStation() {
    return (TOS_LOCAL_ADDRESS == 0) || call Detect.isConnected();
  }

  command result_t StdControl.init() {
    m_smsg = (syncmsg_t*)tosmsg.data;
    m_timeout = TIME_EXPIRE + 2;
    m_smsg->addr = TOS_BCAST_ADDR;
    m_smsg->period = PERIOD;
    m_smsg->hopcount = INVALID_HOPCOUNT;
    /* set to zero by node boot
    m_nexton = m_nextoff = 0;
    m_ispending = FALSE;
    */
    return SUCCESS;
  }

  void setSyncMaster() {
    uint32_t now;
    // if a find is in progress, disable the find
    call SPNeighbor.findDone();
    m_smsg->hopcount = 0;
    m_nexton = m_nextoff = 0;
    broadcast.addr = TOS_BCAST_ADDR;
    now = call LocalTime.get();
    broadcast.timeon = now + (TIME_ON | PERIOD);
    broadcast.timeoff = now + (TIME_OFF | PERIOD);
    m_smsg->on = TIME_ON;
    m_smsg->off = TIME_OFF;
    m_timeout = 0;
    // insert into the neighbor table
    call SPNeighbor.insert(&broadcast);
  }      
  
  void unsetSyncMaster() {
    // Over-zealous reset of state.
    // Alternative: could wait for TimerI to go off and reset neighbor
    if (!isBaseStation()) {
      m_smsg->hopcount = INVALID_HOPCOUNT;
      call SPNeighbor.remove(&broadcast); 
    }
  }

  command result_t StdControl.start() {
    if (isBaseStation()) {
	setSyncMaster();
    }
    // start trickle mechanism running
    call TimerI.startOneShot( call Random.rand() % TIME_SYNC );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void TimerTau.fired() {
    // check if we have a valid synchronization
    if (m_smsg->hopcount != INVALID_HOPCOUNT) {
      // if we're not currently waiting on a message, try to send
      if (!m_ispending) {
	global_time_t g = call GlobalTime.getBoth();
	m_smsg->global_time = g.global;
	m_smsg->local_time = g.local;
	if (call SPSend.sendAdv(&spmsg, &tosmsg, SP_I_NOT_SPECIFIED, TOS_BCAST_ADDR, sizeof(syncmsg_t), SP_FLAG_C_TIMESTAMP, 1) == SUCCESS) {
	  m_ispending = TRUE;
	  call Leds.redOn();
	}
      }
    }
  }

  event void TimerI.fired() {
    call TimerI.startOneShot( TIME_SYNC );
    // start the tau timer that computes the next potential beacon
    call TimerTau.startOneShot( (TIME_SYNC >> 1) + (call Random.rand() % (TIME_SYNC >> 1)) );

    // reset the timeout if we're the base station
    if (isBaseStation()) {
      if (!m_ispending) {
	m_smsg->seqno++;
      }
      m_timeout = 0;
    }
    else {
      // check if our time synchronization info has expired
      if (m_timeout == TIME_EXPIRE) {
	m_smsg->hopcount = INVALID_HOPCOUNT;
	// remove the neighbor from the table
	if (!(call SPNeighbor.getFlags(&broadcast) & SP_FLAG_LINK_ACTIVE)) {
	  call SPNeighbor.remove(&broadcast);
	  broadcast.timeon = broadcast.timeoff;
	}
	// if there is a message pending, cancel it
	if ((m_ispending) && 
	    (!(call SPMessage.getFlags(&spmsg) & SP_FLAG_C_BUSY))) {
	  if (call SPSend.cancel(&spmsg) == SUCCESS)
	    m_ispending = FALSE;
	}
	m_timeout++;
      }
      else if (m_timeout < TIME_EXPIRE + 2) {
	m_timeout++;
      }
      else if (m_timeout == TIME_EXPIRE + 2) {
	if (call SPNeighbor.find()) {
	  call Leds.greenOn();
	}
	m_timeout++;
      }
      else if (m_timeout < TIME_EXPIRE + 2 + TIME_DELAY) {
	m_timeout ++;
      }
      else if (m_timeout == TIME_EXPIRE + 2 + TIME_DELAY) {
	call SPNeighbor.findDone();
	call Leds.greenOff();
	m_timeout = 0;
      }
    }
  }

  event void SPSend.sendDone(sp_message_t* msg, sp_message_flags_t flags, sp_error_t success) {
    m_ispending = FALSE;
    call Leds.redOff();
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg) {
    uint32_t time_send;
    uint32_t time_receive;
    uint32_t now;
    uint16_t offset;
    syncmsg_t* smsg = (syncmsg_t*)msg->data;
    uint8_t diff = (smsg->seqno - (m_smsg->seqno + 1)) & 0xFF;

    // don't update if the receiver is invalid or we're the base station
    if ((smsg->hopcount == INVALID_HOPCOUNT) || isBaseStation())
      return msg;

    // supress if someone at my level already broadcast
    if (smsg->hopcount == m_smsg->hopcount) {
      call TimerTau.stop();
      if (m_ispending)
	if (call SPSend.cancel(&spmsg) == SUCCESS) {
	  m_ispending = FALSE;
	  call Leds.redOff();
	}
    }

    //    call Leds.greenToggle();

    // only update if the sender is within one hop of our hopcount
    // or better (ie, don't allow ourselves to fall too far back
    // from the originator of the synchronization root)
    if ((uint16_t)smsg->hopcount <= (uint16_t)m_smsg->hopcount + 1) {

      if (((m_timeout > TIME_EXPIRE + 2) || 
	   (diff < TIME_EXPIRE)) ) {
	// get sender's time stamp
	time_send = call SPUtil.getSenderTimestamp(msg, sizeof(syncmsg_t));
	
	// get my time stamp
	time_receive = call SPUtil.getReceiveTimestamp(msg);
      
	// compare stamps for offset
	offset = (time_send - time_receive) & PERIOD_MASK;
	now = call LocalTime.get();

	// update sync information
	broadcast.addr = TOS_BCAST_ADDR;
	m_nexton = ((now & ~(uint32_t)PERIOD_MASK) + PERIOD) | ((smsg->on - offset) & PERIOD_MASK);
	m_nextoff = ((now & ~(uint32_t)PERIOD_MASK) + PERIOD) | ((smsg->off - offset) & PERIOD_MASK);

	if (broadcast.timeon != broadcast.timeoff) {
	  // if the skew is more than 2milliseconds, this is out of the range
	  // of the maximum crystal drift--don't allow the new schedule to
	  // go into place and ignore it.
	  if (((uint16_t)(m_nexton & 0xffff) - (uint16_t)(broadcast.timeon & 0xffff) > (uint16_t)0x2f) &&
	      ((uint16_t)(m_nexton & 0xffff) - (uint16_t)(broadcast.timeon & 0xffff) < (uint16_t)(0xffff - 0x2f))) {
	    m_nexton = m_nextoff;
	    return msg;
	  }
	}

	// change our beacon info
	atomic {
	  m_smsg->on = m_nexton & PERIOD_MASK;
	  m_smsg->off = m_nextoff & PERIOD_MASK;
	  m_smsg->hopcount = smsg->hopcount + 1;
	  m_smsg->period = smsg->period;
	  m_smsg->seqno = smsg->seqno;
	
	  m_smsg->local_time = (time_receive - time_send) + smsg->local_time;
	  m_smsg->global_time = smsg->global_time;
	}
	
	// update the entry in the table if it isn't active
	if (!(call SPNeighbor.getFlags(&broadcast) & SP_FLAG_LINK_ACTIVE)) {
	  broadcast.timeon = m_nexton;
	  broadcast.timeoff = m_nextoff;
	  m_nexton = m_nextoff = 0;
	}
	
	// re-insert into the table
	call SPNeighbor.insert(&broadcast);
	
	// if we were looking for neighbors, we can now shut down
	if (m_timeout >= TIME_EXPIRE) {
	  call SPNeighbor.findDone();
	  call Leds.greenOff();
	}
	
	// reset the timeout counter
	m_timeout = 0;
      }
    }

    // return buffer
    return msg;
  }

  event void SPNeighbor.expired(sp_neighbor_t* neighbor) { 
    // if there isn't new schedule information, increment by the interval
    if (m_smsg->hopcount == INVALID_HOPCOUNT) {
      call SPNeighbor.remove(&broadcast);
      broadcast.timeon = broadcast.timeoff;
      return;
    }

    if (m_nexton == m_nextoff) {
      neighbor->timeon += m_smsg->period;
      neighbor->timeoff += m_smsg->period;
    }
    // otherwise use the new schedule
    else {
      neighbor->timeon = m_nexton;
      neighbor->timeoff = m_nextoff;
      m_nexton = m_nextoff = 0;
    }
    // notify the neighbor table that it has been changed
    call SPNeighbor.change(neighbor);
  }

  async command bool GlobalTime.isValid() {
    return (!(m_smsg->hopcount == INVALID_HOPCOUNT));
  }

  async command uint32_t GlobalTime.get() {
    uint32_t now;
    atomic now = (m_smsg->global_time - m_smsg->local_time) + call LocalTime.get();
    return now;
  }

  async command global_time_t GlobalTime.getBoth() {
    global_time_t g;
    g.local = call LocalTime.get();
    g.global = (m_smsg->global_time - m_smsg->local_time) + g.local;
    return g;
  }

  async command uint32_t GlobalTime.convertToGlobal(uint32_t local) {
    return (m_smsg->global_time - m_smsg->local_time) + local;
  }

  async command uint32_t GlobalTime.convertToLocal(uint32_t global) {
    return (m_smsg->local_time - m_smsg->global_time) + global;
  }
  
  event void SPNeighbor.update(sp_neighbor_t* neighbor) { }
  event result_t SPNeighbor.admit(sp_neighbor_t* neighbor) { return SUCCESS; }
  event void SPNeighbor.evicted(sp_neighbor_t* neighbor) { }

  event void Detect.connected() {
      setSyncMaster();
  }
  event void Detect.disconnected() { 
      unsetSyncMaster();
  }
}
