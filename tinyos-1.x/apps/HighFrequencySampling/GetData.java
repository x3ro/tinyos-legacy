// $Id: GetData.java,v 1.4 2003/10/07 21:44:50 idgay Exp $

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
 * Get data from a high-frequency-sampling mote and print sampled values
 * to stdout. The mote must be connected directly to the serial port
 * (see HSSRead.nc).
 */
public class GetData implements MessageListener {
    public static int groupId() {
	String gid = Env.getenv("GROUPID");

	if (gid == null)
	    return -1;
	return Integer.parseInt(gid);
    }
 
    public static void main(String[] args) throws Exception {
	new GetData().app(args);
    }

    void app(String[] args) throws Exception {
	if (args.length != 1) {
	    System.err.println("usage: java GetData.class <nsamples>");
	    System.exit(2);
	}

	PhoenixSource ps = BuildSource.makePhoenix(PrintStreamMessenger.err);
	ps.start();
	MoteIF mif = new MoteIF(ps, groupId());

	mif.registerListener(new ReadDataMsg(), this);
	ReadRequestMsg orders = new ReadRequestMsg();
	orders.set_count(Integer.parseInt(args[0]));
	mif.send(MoteIF.TOS_BCAST_ADDR, orders);
    }

    public void messageReceived(int to, Message m) {
	ReadDataMsg data = (ReadDataMsg)m;
	int count = (data.dataLength() - data.offset_samples(0)) /
	    data.elementSize_samples();

	for (int i = 0; i < count; i++)
	    System.out.println(data.getElement_samples(i));
	if (data.get_status() != HFS.DATAMSG_MORE)
	    System.exit(data.get_status());
    }
}
