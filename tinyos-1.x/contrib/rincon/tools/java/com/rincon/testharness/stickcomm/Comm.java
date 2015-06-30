// $Id: Comm.java,v 1.1 2006/04/20 23:02:53 rincon Exp $

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
package com.rincon.testharness.stickcomm;

import java.io.IOException;

import com.rincon.testharness.messages.TestMsg;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

public class Comm implements MessageListener {
	/** Communication with the mote */
	private MoteIF mote;

	/** Reply from the MemoryStick app on the mote */
	private TestMsg reply;
	
	/**
	 * Constructor
	 *
	 */
	public Comm() {
		mote = new MoteIF((Messenger) null);
		mote.registerListener(new TestMsg(), this);
	}
	
	public void registerListener(Message m) {
		mote.registerListener(m, this);
	}

	public void start() {
		mote.start();
	}

	/**
	 * Send a message and return the reply when it arrives
	 * @param m
	 * @return
	 */
	public synchronized TestMsg send(Message m) {
		try {
			mote.send(MoteIF.TOS_BCAST_ADDR, m);
			wait();
		} catch (IOException e) {
			fail("couldn't send message");
		} catch (InterruptedException e) {
			fail("interrupted!");
		}
		return reply;
	}

    public synchronized void messageReceived(int to, Message m) {
		reply = (TestMsg) m;
		notify();
	}

	static void fail(String s) {
		System.err.println(s);
		System.exit(2);
	}

}
