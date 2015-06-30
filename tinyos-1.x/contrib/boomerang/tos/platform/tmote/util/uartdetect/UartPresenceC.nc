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
 * This configuration provides a library for detecting if there is an
 * active connection on the other side of a UART.
 * <p>
 * The principles of operation are as follows:
 * <p>
 * If the mote detects that USB is present, it sends a connection request
 * to the UART.  If it receives a connection response, UartDetectC.Detect
 * signals the connected() event to signal that there is an active
 * connection available.  If no response is received but the mote is
 * still connected to USB, it peroidically requests the connection to
 * try to reestablish it.
 * <p>
 * Once a connection is established, the PC provides the mote with a 
 * connection timeout.  If the node does not receive a keep alive
 * message within the timeout period, it severs the connection and 
 * returns to the request polling state.
 * <p>
 * If the USB port is disconnected, polling ceases, the mote does not
 * use the UART port, and users are notified by Detect.disconnected().
 * <pre>
 * Two interfaces are provided:
 * (1) interface Detect as Presence
 *        notification when the node is plugged in
 *        Connection is a subset of the events provided by Presence
 * (2) UartDetectC provides interface Detect as Connection 
 *        provides the full connection semantics with handshake
 * </pre>
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration UartPresenceC {
  // the PC is present but may or may not be listening
  provides interface Detect as Presence;
}
implementation {
  components MainUartPresenceC;
  components UartPresenceM;
  components MSP430InterruptC;
  components MSP430GeneralIOC;

  Presence = UartPresenceM.Presence;

  UartPresenceM.Interrupt -> MSP430InterruptC.Port12; // USB Detect
  UartPresenceM.Pin -> MSP430GeneralIOC.Port12;       // USB Detect
  
}
