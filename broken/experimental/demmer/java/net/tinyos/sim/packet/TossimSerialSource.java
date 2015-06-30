// $Id: TossimSerialSource.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

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

import java.io.*;
import net.tinyos.sim.event.*;

public class TossimSerialSource extends TossimSource {
  public TossimSerialSource(String host) {
    super("tossim-serial", host);
  }

  protected byte[] readTossimPacket() throws IOException {
    TossimEvent ev = eventProtocol.readEvent();
    if (ev.getMoteID() == 0 && ev instanceof UARTMsgSentEvent) {
      UARTMsgSentEvent mev = (UARTMsgSentEvent)ev;

      return mev.dataGet();
    }
    else {
      return null;
    }
  }

  protected TossimCommand writeTossimPacket(byte[] packet) {
    // Send to UART on mote 0
    return new UARTMsgSendCommand((short)0, 0L, packet);
  }
}
