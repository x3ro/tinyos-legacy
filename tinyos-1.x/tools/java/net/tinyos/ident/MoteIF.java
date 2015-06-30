// $Id: MoteIF.java,v 1.5 2003/10/07 21:45:54 idgay Exp $

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

package net.tinyos.ident;

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;

class MoteIF implements MessageListener {
    IdentityReceiver dispatch;
    net.tinyos.message.MoteIF intf;

    MoteIF(IdentityReceiver d) {
	dispatch = d;
	intf = new net.tinyos.message.MoteIF(PrintStreamMessenger.err);
	intf.registerListener(new IdentMsg(), this);
    }

    void start() {
	intf.getSource().setResurrection();
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

	msg.setString_id_id(id);
	mysend(msg);
    }

    public void messageReceived(int to, Message m) {
	dispatch.identityReceived(((IdentMsg)m).getString_identity_id());
    }
}
