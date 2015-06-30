// $Id: Sample.java,v 1.4 2006/04/28 17:55:59 idgay Exp $

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
 * Ask a high-frequency-sampling mote to collect <n> samples at <m>
 * microsecond intervals. Report success or failure.
 */
public class Sample implements MessageListener {
    public static void main(String[] args) throws Exception {
	new Sample().app(args);
    }

    void app(String[] args) throws Exception {
	if (args.length != 2) {
	    System.err.println("usage: java Sample.class <sample interval (us)> <nsamples>");
	    System.exit(2);
	}
	int interval = Integer.parseInt(args[0]);
	if (interval <= 0) {
	  System.err.println("sample interval (in microseconds) must be positive");
	  System.exit(2);
	}
	int count = Integer.parseInt(args[1]);
	if (count <= 0 || count > HFS.MAX_SAMPLES) {
	  System.err.println("sample count must be between 1 and " + HFS.MAX_SAMPLES);
	  System.exit(2);
	}

	PhoenixSource ps = BuildSource.makePhoenix(PrintStreamMessenger.err);
	ps.start();
	MoteIF mif = new MoteIF(ps);

	mif.registerListener(new SampleDoneMsg(), this);
	SampleRequestMsg orders = new SampleRequestMsg();
	orders.set_sampleInterval(interval);
	orders.set_sampleCount(count);
	mif.send(MoteIF.TOS_BCAST_ADDR, orders);
    }

    public void messageReceived(int to, Message m) {
	SampleDoneMsg data = (SampleDoneMsg)m;
	int ok = data.get_outcome();

	switch (data.get_outcome()) {
	default:
	case HFS.SAMPLE_FAILED:
	  System.err.println("sampling failed");
	  System.exit(1);
	case HFS.SAMPLE_NOTREADY:
	  System.err.println("sampling mote busy");
	  System.exit(1);
	case HFS.SAMPLE_SUCCESS:
	  System.out.println(data.get_bytesUsed() + " bytes logged");
	  System.exit(0);
	}
    }
}
