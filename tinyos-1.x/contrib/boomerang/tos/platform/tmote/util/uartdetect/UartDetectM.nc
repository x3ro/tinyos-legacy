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
 * Implementation of the Uart Detect code, specified in UartDetectC.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module UartDetectM {
  provides {
    interface Detect as Connection;
  }
  uses {
    interface Detect as Presence;
    interface SendMsg;
    interface ReceiveMsg;
    interface Timer2<TMilli> as Timer;
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
  TOS_Msg m_msg;

  // sends a request for a connection
  void sendRequest();
  // processes packets received from the uart
  void processReceive(TOS_Msg* msg);
  void signalConnected();

  void sendRequest() {
    uartdetectmsg_t* umsg = (uartdetectmsg_t*)m_msg.data;
    if (!(m_flags & FLAG_MSG_BUSY)) { // not subject to atomic race
      umsg->cmd = UARTDETECT_REQUEST;
      umsg->addr = TOS_LOCAL_ADDRESS;
      if (call SendMsg.send(TOS_UART_ADDR, sizeof(uartdetectmsg_t), &m_msg) == SUCCESS) {
	m_flags |= FLAG_MSG_BUSY; // atomic access
      }
    }
  }

  void processReceive(TOS_Msg* msg) {
    uartdetectmsg_t* umsg = (uartdetectmsg_t*)msg->data;
    if (umsg->cmd == UARTDETECT_RESPONSE) {
      call Timer.startOneShot( umsg->timeout );
      if (!(m_flags & FLAG_CONNECT)) { // not subject to atomic race
	m_flags |= FLAG_CONNECT; // atomic access
        signalConnected();
      }
    }
    if (umsg->cmd == UARTDETECT_KEEPALIVE) {
      if (m_flags & FLAG_CONNECT) { // not subject to atomic race
	call Timer.startOneShot( umsg->timeout );
      }
      else {
	sendRequest();
      }
    }
  }

  void signalConnected() {
    signal Connection.connected();
  }

  void fConnected() {
    // try to send a message
    if (!(m_flags & FLAG_CONNECT)) { // not subject to atomic race
      call Timer.startPeriodic( UARTDETECT_POLL );
      sendRequest();
    }
  }

  void fDisconnected() {
    m_flags &= ~FLAG_CONNECT; // atomic
    call Timer.stop();
    signal Connection.disconnected();
  }

  command bool Connection.isConnected() {
    return m_flags & FLAG_CONNECT; // atomic access
  }

  event void Presence.connected() {
    fConnected();
  }

  event void Presence.disconnected() {
    fDisconnected();
  }

  event void Timer.fired() {
    // if usb is in the PC but we haven't established a connection
    // ping the PC and see if we get a response
    if ((call Presence.isConnected()) && (!(m_flags & FLAG_CONNECT))) {
      sendRequest();
    }
    // if we haven't heard anything for the timeout period
    // consider the connection failed and wait for it to be 
    // re-established
    else {
      fDisconnected();
    }
  }

  event result_t SendMsg.sendDone(TOS_Msg* msg, result_t success) {
    m_flags &= ~FLAG_MSG_BUSY; //atomic
    return SUCCESS;
  }

  event TOS_Msg* ReceiveMsg.receive(TOS_Msg* msg) {
    processReceive(msg);
    return msg;
  }

  default event void Connection.connected() { }
  default event void Connection.disconnected() { }

}
