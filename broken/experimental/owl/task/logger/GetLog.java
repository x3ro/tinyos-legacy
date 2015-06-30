// $Id: GetLog.java,v 1.3 2004/05/27 19:12:04 idgay Exp $

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
import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.packet.*;

/**
 * Get data from a tinydb mote with logging and print data
 * to stdout. The mote must be connected directly to the serial port
 * See TinyDBLoggerM.nc
 */
public class GetLog implements MessageListener {
    public static void main(String[] args) throws Exception {
	new GetLog().app(args);
    }

    void app(String[] args) throws Exception {
	if (args.length != 2) {
	    System.err.println("usage: java GetLog.class <start> <n>");
	    System.exit(2);
	}

	PhoenixSource ps = BuildSource.makePhoenix(PrintStreamMessenger.err);
	ps.start();
	MoteIF mif = new MoteIF(ps);

	mif.registerListener(new LReadDataMsg(), this);
	LReadRequestMsg orders = new LReadRequestMsg();
	orders.set_start(Integer.parseInt(args[0]));
	orders.set_count(Integer.parseInt(args[1]));
	expected = orders.get_start();
	mif.send(MoteIF.TOS_BCAST_ADDR, orders);
    }

    long expected;

    public void messageReceived(int to, Message m) {
	LReadDataMsg data = (LReadDataMsg)m;
	long offset = data.get_offset();
	int status = data.get_status();

	if (status >= Log.DATAMSG_FAIL) {
	    System.err.println("error " + status + " at offset " + offset);
	    System.exit(1);
	}
	if (status == Log.DATAMSG_SIZE) {
	    long size = data.get_offset();
	    System.err.println("log contains " + size + " bytes");
	    if (size == 0)
		System.exit(0);
	    return;
	}
	if (offset > expected) {
	    System.err.println("lost bytes " + expected + " to " + (offset - 1));
	    for (long l = expected; l < offset; l++)
		System.out.write(0xee);
	}
	else if (offset < expected) {
	    System.err.println("expected offset " + expected +
			       ", got " + offset + " -- duplicate data, aborting");
	    System.exit(1);
	}

	int count = data.dataLength() - data.offset_data(0);
	byte[] b = new byte[count];
	for (int i = 0; i < count; i++)
	    b[i] = data.getElement_data(i);

	try {
	    System.out.write(b);
	}
	catch (java.io.IOException e) {
	    System.err.println("write error " + e);
	    System.exit(1);
	}
	expected = offset + count;

	if (data.get_status() != Log.DATAMSG_MORE)
	    System.exit(data.get_status());
    }
}
