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
import java.io.*;

/**
 * MoteIf class (simple mote interface).<p>
 *
 * A simple, general mote interface built on top of SerialForwarder and
 * Message.
 * Users of MoteIF can easily send messages and register new message
 * listeners.
 *
 * @version	1, 15 Jul 2002
 * @author	David Gay
 */
public class MoteIF extends Thread {

    /** The maximum message size that can be sent. */
    public static int maxMessageSize = TOSMsg.totalSize_data();

    /** The destination address for a broadcast. */
    public static final int TOS_BCAST_ADDR = 0xffff;

    SerialForwarderStub sfw;
    Sender sender;
    Receiver receiver;
    int groupId;
    boolean check_crc;

    /**
     * Create a new mote interface to SerialForwarder at host:port for
     * group id gid. The returned MoteIF (a thread object) should be
     * started if any messages are to be received.
     * @param host host of the SerialForwarder
     * @param port port of the SerialForwarder
     * @param gid group id of messages to listen to. If set to -1,
     *   receive all group ID's, and disable sending of messages.
     * @exception IOException thrown if SerialForwarder cannot be reached */
    public MoteIF(String host, int port, int gid) throws IOException {
	this(host,port,gid,maxMessageSize,true);
    }

    /**
     * Create a new mote interface to SerialForwarder at host:port for
     * group id gid. The returned MoteIF (a thread object) should be
     * started if any messages are to be received.
     * @param host host of the SerialForwarder
     * @param port port of the SerialForwarder
     * @param gid group id of messages to listen to. If set to -1,
     *   receive all group ID's, and disable sending of messages.
     * @param msg_size The maximum message size this application will need to send
     *                 Note that the serial forwarded must have been initialized with at least 
     *                 this message size as well.
     * @exception IOException thrown if SerialForwarder cannot be reached */
    public MoteIF(String host, int port, int gid, int msg_size, boolean check_crc) throws IOException {
	groupId = gid;
	this.check_crc = check_crc;
	maxMessageSize = msg_size;
	sfw = new SerialForwarderStub(host, port, msg_size + 7);
	sfw.Open();
	receiver = new Receiver(sfw, groupId, check_crc);
	if (groupId != -1) sender = new Sender(sfw, gid);
    }


    /**
     * Body of this thread. Repeatedly reads and dispatches messages from
     * the SerialForwarder 
     */
    public void run() {
	try { sfw.Read(); }
	catch (IOException e) {
	    e.printStackTrace();
	    System.exit(2);
	}
    }

    /**
     * Send m to moteId via this mote interface
     * @param moteId message destination
     * @param m message
     * @exception IOException thrown if message could not be sent
     */
    synchronized public void send(int moteId, Message m) throws IOException {
        if (sender == null) {
	  throw new IOException("Cannot send a message: group ID initialized to "+groupId);
	}
	sender.send(moteId, m);
    }

    /**
     * Register a listener for given messages type. m should be an instance
     * of a subclass of Message (generated by mig). When a message of the
     * corresponding type is received, a new instance of m's class is 
     * created with the received message as data. This message is then 
     * passed to the given MessageListener. 
     * 
     * Note that multiple MessageListeners can be registered for the same
     * message type, and in fact each listener can use a different template
     * type if it wishes (the only requirement is that m.getType() matches
     * the received message). 
     *
     * @param m message template specifying which message to receive
     * @param l listener to which received messages are dispatched
     */
    synchronized public void registerListener(Message m, MessageListener l) {
      receiver.registerListener(m, l);
    }

    /**
     * Deregister a listener for a given message type.
     * @param m message template specifying which message to receive
     * @param l listener to which received messages are dispatched
     */
    synchronized public void deregisterListener(Message m, MessageListener l) {
      receiver.deregisterListener(m, l);
    }
}
