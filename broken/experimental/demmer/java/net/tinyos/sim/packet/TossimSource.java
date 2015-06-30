// $Id: TossimSource.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

/*
 * "Copyright (c) 2001 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * $\Id$
 */
package net.tinyos.sim.packet;

import java.net.*;
import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

abstract public class TossimSource extends AbstractSource {
  private Socket eventSocket = null;
  private Socket cmdSocket = null;
  protected SimProtocol eventProtocol = null;
  protected SimProtocol cmdProtocol = null;
  String kind, host;

  public TossimSource(String kind, String host) {
    super(kind + "@" + host);
    this.kind = kind;
    this.host = host;
  }

  protected void openSource() throws IOException {
    message("Opening " + kind + " source");
    try {
      message("Connecting to Tossim event port at " + host + ":" +
	      SimProtocol.TOSSIM_EVENT_PORT);
      eventSocket = new Socket(host, SimProtocol.TOSSIM_EVENT_PORT);
      InputStream is = eventSocket.getInputStream();
      OutputStream os = eventSocket.getOutputStream();
      eventProtocol = new SimProtocol(is, os);
      message("Connection opened to TOSSIM event port");

      message("Connecting to Tossim command port at " + host + ":" +
	      SimProtocol.TOSSIM_COMMAND_PORT);
      cmdSocket = new Socket(host, SimProtocol.TOSSIM_COMMAND_PORT);
      is = cmdSocket.getInputStream();
      os = cmdSocket.getOutputStream();
      cmdProtocol = new SimProtocol(is, os);
      message("Connection opened to Tossim command port");
    }
    catch (IOException e) {
      closeSockets();
      throw e;
    }
  }

  private void closeSockets() throws IOException {
    if (eventSocket != null) {
      eventSocket.close();
    }
    if (cmdSocket != null) {
      cmdSocket.close();
    }
    eventSocket = null;
    cmdSocket = null;
  }

  public void closeSource() throws IOException {
    message("Closing " + kind + " source");
    closeSockets();
  }

  public byte[] readSourcePacket() throws IOException {
    for (;;) { // Until we get a suitable event
      byte[] received = readTossimPacket();
      if (received != null) {
	// Remove extraneous bytes
	return BrokenPacketizer.collapsePacket(received);
      }
    }
  }

  public boolean writeSourcePacket(byte[] packet) throws IOException {
    cmdProtocol.writeCommand(writeTossimPacket(packet));
    return true;
  }

  // Read one event and if:
  // it's a packet-receive event, return the data
  // otherwise return null
  abstract protected byte[] readTossimPacket() throws IOException;

  // Return the command to write a packet
  abstract protected TossimCommand writeTossimPacket(byte[] packet);
}
