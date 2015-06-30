/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "NetWake.h"

/**
 * Implementation of a global network wakeup system.  Nodes use Trickle-like
 * mechanism to wake up the rest of the network and give out a schedule.
 * This implementation assumes a node with address = TOS_UART_ADDR = 0x007e
 * initiates the wakeup procedure.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module NetWakeM {
  uses {
    interface SPNeighbor;
    interface GlobalTime<T32khz>;
    interface LocalTime<T32khz> as LocalTime;
    interface ReceiveMsg;
    interface SPSend;
    interface Timer2<TMilli> as TimerTau;
    interface Timer2<TMilli> as TimerI;
    interface Random;
  }
}
implementation {

  sp_neighbor_t m_netwake;

  bool m_sending;
  sp_message_t m_spmsg;
  TOS_Msg m_tosmsg;

  void tryToSend() {
    if (!m_sending) {
      if (call SPSend.send(&m_spmsg, 
			   &m_tosmsg, 
			   TOS_BCAST_ADDR, 
			   sizeof(netwakemsg_t)) == SUCCESS) {
	m_sending = TRUE;
      }
    }
  }

  event void TimerTau.fired() {
    tryToSend();
  }

  void newTimers(uint32_t interval) {
    netwakemsg_t* nwm = (netwakemsg_t*)m_tosmsg.data;
    // only continue to advertise if the event is in the future
    if ((nwm->timeon - call GlobalTime.get()) < NETWAKE_MAX_INIT) {
      uint32_t _rand = ((uint32_t)call Random.rand() << 16) | 
	               (uint32_t)call Random.rand();
      call TimerTau.startOneShot((interval >> 1) + 
				 (_rand % (interval >> 1)));
      call TimerI.startOneShot(interval);
    }
  }

  event void TimerI.fired() {
    uint32_t interval = call TimerTau.getdt();
    if (interval < 0x80000000L) {
      interval = interval << 1;
    }
    else {
      interval = 0xFFFFFFFEL;
    }
    newTimers(interval);
  }

  // if a new message, reset Trickle timers
  void processSend() {
    newTimers(NETWAKE_MIN_INTERVAL);
  }

  // check if this is a new message
  bool processMsg(TOS_Msg* _msg, uint32_t now) {
    netwakemsg_t* nwm;
    netwakemsg_t* _nwm;
    nwm = (netwakemsg_t*)m_tosmsg.data;
    _nwm = (netwakemsg_t*)_msg->data;
    if ((_nwm->seqno == nwm->seqno) && (_nwm->addr != TOS_UART_ADDR)) {
      call TimerTau.stop();
      if (m_sending) {
	if (call SPSend.cancel(&m_spmsg) == SUCCESS)
	m_sending = FALSE;
      }
      return FALSE;
    }
    // check if the new sequence number is bigger
    else if ((_nwm->seqno > nwm->seqno) ||
	     // or the message is from the uart
	     (_nwm->addr == TOS_UART_ADDR) || 
	     // or at the wrap condition
	     (_nwm->seqno == nwm->seqno + 1) ||
	     // or our sequence numbers are out of sync with the network
	     // by more than 10 units
	     (_nwm->seqno < nwm->seqno - 10)) {
      atomic {
	if (_nwm->addr == TOS_UART_ADDR) {
	  nwm->seqno++;
	  _nwm->timeon += now;
	  _nwm->timeoff += now;
	}
	else {
	  nwm->seqno = _nwm->seqno;
	}
	nwm->addr = TOS_LOCAL_ADDRESS;
	nwm->timeon = _nwm->timeon;
	nwm->timeoff = _nwm->timeoff;
      }
      processSend();
      return TRUE;
    }
    return FALSE;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    netwakemsg_t* nwm = (netwakemsg_t*)msg->data;
    bool isValid = FALSE;
    global_time_t g;

    // check if the global schedule has been loaded by this mote
    atomic {   
      if (call GlobalTime.isValid() == TRUE) {
	g = call GlobalTime.getBoth();
	isValid = TRUE;
	g.global = g.local - g.global;
      }
    }

    // if no global schedule, return because we cannot know the correct
    // wakeup schedule
    if (!isValid)
      return msg;

    if (processMsg(msg,g.local) == TRUE) {
      if (!(call SPNeighbor.getFlags(&m_netwake) & SP_FLAG_BUSY)) {
	atomic {
	  m_netwake.timeon = (nwm->timeon + g.global);
	  // if the interval is in the middle of 
	  if ((nwm->timeon + g.global < g.local + (uint32_t)100) && 
	      (g.local + (uint32_t)100 < nwm->timeoff + g.global)) {
	    m_netwake.timeon = g.local + (uint32_t)100;
	  }
	  m_netwake.timeoff = (nwm->timeoff + g.global);
	  m_netwake.addr = TOS_BCAST_ADDR;
	}
	call SPNeighbor.insert(&m_netwake); 
      }
    }
    return msg;
  }

  event void SPSend.sendDone(sp_message_t* msg, sp_message_flags_t flags, sp_error_t error) {
    if (msg == &m_spmsg)
      m_sending = FALSE;
  }
  
  event void SPNeighbor.update(sp_neighbor_t* neighbor) { }
  event result_t SPNeighbor.admit(sp_neighbor_t* neighbor) { return SUCCESS; }
  event void SPNeighbor.expired(sp_neighbor_t* neighbor) { 
    if (neighbor == &m_netwake)
      call SPNeighbor.remove(&m_netwake);
  }
  event void SPNeighbor.evicted(sp_neighbor_t* neighbor) { }
  
}
