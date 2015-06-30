// $Id: Comm.java,v 1.3 2003/10/07 21:45:54 idgay Exp $

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
package net.tinyos.matchbox;

import net.tinyos.message.*;
import net.tinyos.util.*;
import java.io.*;
import java.util.Date;

public class Comm implements MessageListener {
    protected MoteIF intf;

    public Comm() {
	try {
	    intf = new MoteIF((Messenger)null);
	    intf.registerListener(new FSReplyMsg(), this);
	}
	catch (Exception e) {
	    fail("couldn't contact serial forwarder");
	}
    }

    public void start() {
	intf.start();
    }

    protected FSReplyMsg reply;

    public synchronized FSReplyMsg send(FSOpMsg m) {
	try {
	    intf.send(MoteIF.TOS_BCAST_ADDR, m);
	    wait();
	}
	catch (IOException e) {
	    fail("couldn't send message");
	}
	catch (InterruptedException e) {
	    fail("interrupted!?");
	}
	return reply;
    }

    synchronized public void messageReceived(int to, Message m) {
	reply = (FSReplyMsg)m;
	notify();
    }

    static void fail(String s) {
	System.err.println(s);
	System.exit(2);
    }
    
    private static String fsErrors[] = {
	"ok",
	"no more files",
	"no space",
	"bad data",
	"file open",
	"not found",
	"bad crc",
	"hardware problem"
    };

    private static String remErrors[] = {
	"unknown command",
	"bad command arguments",
	"file system request failed"
    };

    public static String fsErrorString(FSReplyMsg m) {
	int error = m.get_result();
	String msg;

	if (error < fsErrors.length)
	    return fsErrors[error];
	else if (error >= 0x80 && error - 0x80 < remErrors.length)
	    return remErrors[error - 0x80];
	else
	    return "unknown error " + error;
    }

    public static void fsError(FSReplyMsg m) {
	System.err.println("error: " + fsErrorString(m));
    }

    public static void check(FSReplyMsg m) {
	if (m.get_result() != FS.FS_OK) {
	    fsError(m);
	    System.exit(1);
	}
    }

    public FSReplyMsg checkedSend(FSOpMsg m) {
	FSReplyMsg reply = send(m);
	check(reply);
	return reply;
    }
}
