/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "UartDetectMsg.h"

/**
 * Implementation of the Uart Presence code, specified in UartPresenceC.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module UartPresenceM {
  provides {
    interface Detect as Presence;
    interface StdControl;
  }
  uses {
    interface MSP430Interrupt as Interrupt;
    interface MSP430GeneralIO as Pin;
  }
}
implementation {

  enum {
    FLAG_CONNECT = 0x01,
    FLAG_EDGE = 0x02,
    FLAG_MSG_BUSY = 0x04,
  };

  // reads and writes to m_flags is only done with bit clear and set operations
  // the only flag in m_flags that is modified in async context is FLAG_EDGE
  // which monitors the edge of the interrupt (rising or falling)
  // all other flags are accessed out of interrupt/async context
  norace bool m_flags;

  task void taskConnected();
  task void taskDisconnected();

  task void taskConnected() {
    signal Presence.connected();
  }

  task void taskDisconnected() {
    signal Presence.disconnected();
  }

  command bool Presence.isConnected() {
    return call Pin.get();
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    atomic {
      call Interrupt.disable();
      call Interrupt.clear();

      if (call Pin.get()) {
	m_flags &= ~FLAG_EDGE;
	post taskConnected();
      }
      else
	m_flags |= FLAG_EDGE;

      call Interrupt.edge(m_flags & FLAG_EDGE);
      call Interrupt.enable();
    }
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async event void Interrupt.fired() {
    call Interrupt.disable();
    call Interrupt.clear();

    // low to high -- connect
    if (m_flags & FLAG_EDGE) {
      post taskConnected();
    }
    // high to low -- disconnect
    else {
      post taskDisconnected();
    }

    m_flags ^= FLAG_EDGE;
    call Interrupt.edge(m_flags & FLAG_EDGE);
    call Interrupt.enable();
  }

  default event void Presence.connected() { }
  default event void Presence.disconnected() { }

}
