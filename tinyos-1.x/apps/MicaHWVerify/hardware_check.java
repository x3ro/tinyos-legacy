// $Id: hardware_check.java,v 1.7 2003/10/07 21:44:53 idgay Exp $

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
/* 
 * Author: Jason Hill
 */

//==========================================================================
//===   hardware_check.java   ==============================================

//package ;


/**
 * @author Jason Hill
 */

import java.util.*;
import java.io.*;
import javax.comm.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class hardware_check
implements MessageListener {

    MoteIF moteif;
    int rxTestValue;

    public hardware_check() {
	try {
	    moteif = new MoteIF(PrintStreamMessenger.err);
	    if (moteif == null) {
		System.out.println("Invalid packet source - check your MOTECOM environment variable");
		System.exit(2);
	    }
	}
	catch (Exception e) {
	    System.out.println("Failed to access mote: " + e);
	    System.exit(2);
	}
    }

    public void run() {
	RxTestMsg rmsg = new RxTestMsg();
	rxTestValue = (int)(Math.random() * 65536);
	rmsg.set_value(rxTestValue);

	moteif.registerListener(new DiagMsg(), this);
	moteif.start();

	int val = 0;
	int rxTime = 10;

	for (;;) {
	    try {
		moteif.send(MoteIF.TOS_BCAST_ADDR, rmsg);

		rxTime--;
		if(rxTime == 0) {
		    System.out.println("Node transmission failure");
		    System.exit(0);
		}

		Thread.sleep(2000);
	    }
	    catch(Exception e) {
		e.printStackTrace();
	    }
	}
    }

    public void messageReceived(int to, Message m) {
	DiagMsg msg = (DiagMsg)m;

	if (msg.get_SPIFix() != 0x5) {
	    System.out.println("SPI rework failed");
	    System.exit(0);
	}

	short f0 = msg.getElement_flashCheck(0);
	short f1 = msg.getElement_flashCheck(1);
	short f2 = msg.getElement_flashCheck(2);
	if (f0 != 0x1 || f1 != 0x8f || f2 != 0x9) {
	    System.out.print("4Mbit flash check failed ");
	    System.out.print(f0 + " ");
	    System.out.print(f1 + " ");
	    System.out.println(f2 + " ");
	    System.exit(0);
	}
	
	if (msg.get_rxTest() == rxTestValue) {
	    System.out.println("Hardware verification successful.");

	    System.out.print("Node Serial ID: ");
	    for(int i = 0; i < 8; i ++){
		short idb = msg.getElement_serialId(i);
		System.out.print(Integer.toHexString(idb) + " ");
	    }
	    System.out.println();

	    System.exit(0);
	}	
    }

    public static void main(String args[]) {
	if (args.length != 0) {
	    System.err.println("Usage: java hardware_check");
	    System.exit(2);
	}
	System.out.println("\nHardware check started");
	hardware_check reader = new hardware_check();
  
	try {
	    reader.run();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }

}
