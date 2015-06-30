// $Id: Receiver.java,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $

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

/**
 * @author David Gay <dgay@intel-research.net>
 * @author Intel Research Berkeley Lab
 */

package net.tinyos.message;

import net.tinyos.util.*;
import net.tinyos.packet.*;
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
public class Receiver implements net.tinyos.util.PacketListenerIF,
				 net.tinyos.packet.PacketListenerIF {
    public static final boolean DEBUG = false;
    public static final boolean DISPLAY_ERROR_MSGS = true;

    int groupId;
    Hashtable templateTbl; // Mapping from AM type to msgTemplate
    PhoenixSource source;
	MessageFactory messageFactory;
    /**
     * Inner class representing a single MessageListener and its
     * associated Message template.
     */
    class msgTemplate {
      Message template;
      MessageListener listener;
      msgTemplate(Message template, MessageListener listener) {
	this.template = template;
	this.listener = listener;
      }

      public boolean equals(Object o) {
	try {
	  msgTemplate mt = (msgTemplate)o;
	  if (mt.template.getClass().equals(this.template.getClass()) &&
	      mt.listener.equals(this.listener)) {
	    return true;
	  }
	} catch (Exception e) {
	  return false;
	}
	return false;
      }

      public int hashCode() {
	return listener.hashCode();
      }
    }


    /**
     * Create a receiver for messages from forwarder of group id gid and
     * of active message type m.getType()
     * When such a message is received, a new instance of m's class is
     * created with the received data and send to listener.messageReceived
     * @param forwarder packet source to listen to
     * @param gid accept messages with this group id only. If set to
     *        -1, accept all group ID's.
     */
    public Receiver(PhoenixSource forwarder, int gid) {
	this.groupId = gid;
	this.templateTbl = new Hashtable();
	this.source = forwarder;
	forwarder.registerPacketListener(this);
	messageFactory = new MessageFactory(forwarder);
    }

    /**
     * Create a receiver messages from forwarder of any group id and
     * of active message type m.getType()
     * When such a message is received, a new instance of m's class is
     * created with the received data and send to listener.messageReceived
     * @param forwarder packet source to listen to
     */
    public Receiver(PhoenixSource forwarder) {
	this(forwarder, MoteIF.ANY_GROUP_ID);

    }

    /**
     * Register a particular listener for a particular message type.
     * More than one listener can be registered for each message type.
     * @param m specify message type and template we're listening for
     * @param listener destination for received messages
     */
    public void registerListener(Message template, MessageListener listener) {
      Integer amType = new Integer(template.amType());
      Vector vec = (Vector)templateTbl.get(amType);
      if (vec == null) {
	vec = new Vector();
      }
      vec.addElement(new msgTemplate(template, listener));
      templateTbl.put(amType, vec);
    }

    /**
     * Stop listening for messages of the given type with the given listener.
     * @param m specify message type and template we're listening for
     * @param listener destination for received messages
     */
    public void deregisterListener(Message template, MessageListener listener) {
      Integer amType = new Integer(template.amType());
      Vector vec = (Vector)templateTbl.get(amType);
      if (vec == null) {
	throw new IllegalArgumentException("No listeners registered for message type "+template.getClass().getName()+" (AM type "+template.amType()+")");
      }
      msgTemplate mt = new msgTemplate(template, listener);
      // Remove all occurrences
      while (vec.removeElement(mt)) ;
      if (vec.size() == 0) templateTbl.remove(amType);
    }

    private void error(msgTemplate temp, String msg) {
	System.err.println("receive error for " + temp.template.getClass().getName() +
			   " (AM type " + temp.template.amType() +
			   "): " + msg);
    }

    public void packetReceived(byte[] packet) {
	// XXX: hack: with the new packetsource format, packet does not
	// contain a crc field, so numElements_data() will be wrong. But we
	// access the data area via dataSet/dataGet, so we're ok.

	//this is where the source comes in to create the correct packet 
	
	final TOSMsg msg = messageFactory.createTOSMsg(packet);
	
	if (DEBUG) Dump.dump("Received message", packet);

	if (drop_bad_crc && msg.get_crc() != 0x01) {
	    // Drop message
	    if (DISPLAY_ERROR_MSGS) Dump.dump("Dropping packet with bad CRC", packet);
	    return;
	}

	if (groupId == MoteIF.ANY_GROUP_ID || msg.get_group() == groupId) {
	    Integer type = new Integer(msg.get_type());
	    Vector vec = (Vector)templateTbl.get(type);
	    if (vec == null) {
		if (DEBUG) Dump.dump("Received packet with type "+msg.get_type()+", but no listeners registered", packet);
		return;
	    }
	    int length = msg.get_length();

	    Enumeration en = vec.elements();
	    while (en.hasMoreElements()) {
		msgTemplate temp = (msgTemplate)en.nextElement();

		Message received;

		// Erk - end up cloning the message multiple times in case
		// different templates used for different listeners
		try {
		    received = temp.template.clone(length);
		    received.dataSet(msg.dataGet(), msg.offset_data(0), 0, length);
		} catch (ArrayIndexOutOfBoundsException e) {
		    /* Note: this will not catch messages whose length is
		       incorrect, but less than DATA_LENGTH (see AM.h) + 2 */
		    error(temp, "invalid length message received (too long)");
		    continue;
		} catch (Exception e) {
		    error(temp, "couldn't clone message!");
		    continue;
		}

		/* Messages that are longer than the template might have
		   a variable-sized array at their end */
		if (received.dataLength() > length) {
		    error(temp, "invalid length message received (too short)");
		    continue;
		}
		temp.listener.messageReceived(msg.get_addr(), received);
	    }

	} else {
	    if (DISPLAY_ERROR_MSGS) Dump.dump("Dropping packet with bad group ID", packet);
	}
    }

    ////////////////  DEPRECATED ROUTINES /////////////////

    // Note: new packet-source does not contain crc (bad packets dropped
    // early on)
    boolean drop_bad_crc = false;

    /**
     * Create a receiver for messages from forwarder of group id gid and
     * of active message type m.getType()
     * When such a message is received, a new instance of m's class is
     * created with the received data and send to listener.messageReceived
     * @param forwarder SerialForwarder to listen to
     * @param gid accept messages with this group id only. If set to
     *        -1, accept all group ID's.
     * @param drop_bad_crc Drop messages with a bad CRC field.
     * @deprecated Use the version which takes a PhoenixSource instead
     */
    public Receiver(SerialStub forwarder, int gid, boolean drop_bad_crc) {
	this.groupId = gid;
	this.drop_bad_crc = drop_bad_crc;
	this.templateTbl = new Hashtable();
	forwarder.registerPacketListener(this);
    }
}
