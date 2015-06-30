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
 * Sender class (send tinyos messages).<p>
 *
 * A sender class provides a simple interface built on Message for
 * sending tinyos messages to a SerialForwarder
 *
 * @version	1, 15 Jul 2002
 * @author	David Gay
 */
public class Sender {


    // If true, dump message contents that are sent
    private static final boolean VERBOSE = false;

    byte groupId;
    SerialStub sfw;
    TOSMsg packet;

    /**
     * Create a sender for group id gid talking to SerialForwarder forwarder
     * @param forwarder SerialForwarder with which we wish to send messages
     * @param gid group id to be placed in sent messages
     */
    public Sender(SerialStub forwarder, int gid) {
        if ((gid < 0) || (gid > 0xff)) {
	  throw new IllegalArgumentException("Cannot send messages to invalid group ID: "+gid);
	}
	groupId = (byte)(gid & 0xff);
	sfw = forwarder;
	packet = new TOSMsg(SerialForwarderStub.PACKET_SIZE);
    }

    /**
     * Send m to moteId via this Sender's SerialForwarder
     * @param moteId message destination
     * @param m message
     * @exception IOException thrown if message could not be sent
     */
    synchronized public void send(int moteId, Message m) throws IOException {
	int amType = m.amType();

	if (amType < 0) {
	    throw new IOException("unknown AM type for message " +
				  m.getClass().getName());
	}

	//  message header: destination, group id, and message type
	packet.set_addr(moteId);
	packet.set_group(groupId);
	packet.set_type((short)amType);
	// Set CRC to 1 in case we're going directly to a UART;
	packet.set_crc(1);
	byte[] data = m.dataGet();
	packet.set_length((short)data.length);
	if (data.length > MoteIF.maxMessageSize)
	    throw new IOException("message too big (" + data.length + " bytes)");
	packet.dataSet(data, 0, packet.offset_data(0), data.length);

	data = packet.dataGet();
	sfw.Write(data);
	if (VERBOSE) Dump.dump("sent", data);
    }
}
