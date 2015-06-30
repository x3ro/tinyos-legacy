// $Id: RawReceiver.java,v 1.2 2003/10/23 23:24:15 cssharp Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:  David Gay  <dgay@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */
//package net.tinyos.message;
import net.tinyos.message.*;

import net.tinyos.util.*;
import java.util.*;
import java.io.*;

/**
 * Receiver class (receive tinyos messages).
 *
 * A receiver class provides a simple interface built on Message for
 * receiving tinyos messages from a SerialForwarder
 *
 * @version	1, 15 Jul 2002
 * @author	David Gay
 */
public class RawReceiver implements PacketListenerIF {
    public static final boolean DEBUG = false;
    public static final boolean DISPLAY_ERROR_MSGS = true;

    Vector listeners = null;
    int groupId;
    boolean drop_bad_crc;

    /**
     * Create a receiver for messages from forwarder of group id gid and
     * of active message type m.getType()
     * When such a message is received, a new instance of m's class is
     * created with the received data and send to listener.messageReceived
     * @param forwarder SerialForwarder to listen to
     * @param gid accept messages with this group id only. If set to
     *        -1, accept all group ID's.
     * @param drop_bad_crc Drop messages with a bad CRC field.
     */
    public RawReceiver(SerialStub forwarder, int gid, boolean drop_bad_crc) {
        this.listeners = new Vector();
	this.groupId = gid;
	this.drop_bad_crc = drop_bad_crc;
	forwarder.registerPacketListener(this);
    }

    /**
     * Register a particular listener for a particular message type.
     * More than one listener can be registered for each message type.
     * @param m specify message type and template we're listening for
     * @param listener destination for received messages
     */
    public void registerListener(MessageListener listener) {
      listeners.addElement(listener);
    }

    public void setGroup( int gid )
    {
      this.groupId = gid;
    }

    public int getGroup()
    {
      return this.groupId;
    }

    /**
     * Stop listening for messages of the given type with the given listener.
     * @param m specify message type and template we're listening for
     * @param listener destination for received messages
     */
    public void deregisterListener(MessageListener listener) {
      listeners.removeElement(listener);
    }

    public void packetReceived(byte[] packet) {
      final RawTOSMsg msg = new RawTOSMsg(packet);
      if (DEBUG) Dump.dump("Received message", packet);

      if (drop_bad_crc && (msg.get_crc() != 0x01)) {
	// Drop message
	if (DISPLAY_ERROR_MSGS) Dump.dump("Dropping packet with bad CRC", packet);
	return;
      }

      if ((groupId == -1) || (msg.get_group() == groupId)) {
	Enumeration en = listeners.elements();
	while (en.hasMoreElements()) {
	  MessageListener listener = (MessageListener)en.nextElement();
	  listener.messageReceived( msg.get_addr(), (Message)msg.clone() );
	}
      } else {
	if (DISPLAY_ERROR_MSGS) 
	  Dump.dump("Dropping packet with bad group ID", packet);
      }
    }
}

