/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.

 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.

 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 * Authors:  David Gay  <dgay@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */
package net.tinyos.message;

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
public class Receiver implements PacketListenerIF {
    private static final boolean DEBUG = false;

    MessageListener listener;
    int groupId;
    boolean drop_bad_crc;
    Hashtable templateTbl; // Mapping from AM type to msgTemplate

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
     * @param forwarder SerialForwarder to listen to
     * @param gid accept messages with this group id only. If set to
     *        -1, accept all group ID's.
     * @param drop_bad_crc Drop messages with a bad CRC field.
     */
    Receiver(SerialForwarderStub forwarder, int gid, boolean drop_bad_crc) {
	this.groupId = gid;
	this.drop_bad_crc = drop_bad_crc;
	this.templateTbl = new Hashtable();
	forwarder.registerPacketListener(this);
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
      final TOSMsg msg = new TOSMsg(packet);
      if (DEBUG) Dump.dump("Received message", packet);

      if (drop_bad_crc && (msg.get_crc() != 0x01)) {
	// Drop message
	Dump.dump("Dropping packet with bad CRC", packet);
	return;
      }

      if ((groupId == -1) || (msg.get_group() == groupId)) {
	Integer type = new Integer(msg.get_type());
	Vector vec = (Vector)templateTbl.get(type);
	if (vec == null) {
	  Dump.dump("Received packet with type "+msg.get_type()+", but no listeners registered", packet);
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
  	  if (temp.template.dataGet().length > length) {
  	    error(temp, "invalid length message received (too short)");
	    continue;
  	  }
	  temp.listener.messageReceived(msg.get_addr(), received);
	}

      } else {
	Dump.dump("Dropping packet with bad group ID", packet);
      }
    }
}
