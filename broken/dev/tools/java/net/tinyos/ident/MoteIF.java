/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
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
 */
package net.tinyos.ident;

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;

class MoteIF implements MessageListener {
    IdentityReceiver dispatch;

    net.tinyos.message.MoteIF intf;

    MoteIF(byte gid, IdentityReceiver d) {
	dispatch = d;
	try {
	    intf = new net.tinyos.message.MoteIF("localhost", 9000, gid);
	    intf.registerListener(new IdentMsg(), this);
	}
	catch (IOException e) {
	    fail("couldn't contact serial forwarder");
	}
    }

    void start() {
	intf.start();
    }

    void mysend(Message m) {
	try {
	    intf.send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, m);
	}
	catch (IOException e) {
	    fail("couldn't send message");
	}
    }

    static void fail(String s) {
	System.err.println(s);
	System.exit(2);
    }
    
    void sendClear() {
	mysend(new ClearIdMsg());
    }

    void sendSet(String id) {
	SetIdMsg msg = new SetIdMsg();

	int idlength = id.length();
	for (int i = 0; i < idlength; i++)
	    msg.setId_id(i, (byte)id.charAt(i));
	msg.setId_id(idlength, (byte)0);

	mysend(msg);
    }

    public void messageReceived(int to, Message m) {
	IdentMsg idmsg = (IdentMsg)m;
	StringBuffer receivedId = new StringBuffer(Ident.MAX_ID_LENGTH);
	int idlen = 0;
	byte idchar;

	try {
	    for (idlen = 0; (idchar = idmsg.getIdentity_id(idlen)) != 0; idlen++)
		receivedId.append((char)idchar);

	    dispatch.identityReceived(receivedId.toString());
	}
	catch (ArrayIndexOutOfBoundsException e) { }
    }
}
