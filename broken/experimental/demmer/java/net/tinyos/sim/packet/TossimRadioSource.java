// $Id: TossimRadioSource.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

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

public class TossimRadioSource extends TossimSource {
    public TossimRadioSource(String host) {
	super("tossim-radio", host);
    }

    protected byte[] readTossimPacket() throws IOException {
	TossimEvent ev = eventProtocol.readEvent();
	if (ev instanceof RadioMsgSentEvent) {
	    RadioMsgSentEvent mev = (RadioMsgSentEvent)ev;
	    return mev.dataGet();
	}
	else {
	    return null;
	}
    }

    protected TossimCommand writeTossimPacket(byte[] packet) {
	net.tinyos.sim.msg.RadioMsgSendCommand tmp =
	    new net.tinyos.sim.msg.RadioMsgSendCommand(packet);
	
	return new net.tinyos.sim.event.RadioMsgSendCommand((short)tmp.get_message_addr(), 0L, packet);
    }
}
