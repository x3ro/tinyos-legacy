// $Id: ListenPrompt.java,v 1.1 2005/04/16 01:09:25 phoebusc Exp $

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
 *
 * @author Mike Manzo, modified by Phoebus
 * @author David Gay
 * @modified 1/18/2005 copied and modified by Phoebus
 * @modified 8/19/2004 version by David Gay
 */


package net.tinyos.tools;

import java.util.Date;
import java.sql.Timestamp;

import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class ListenPrompt {

//     static void help() {
// 	System.out.println("");
// 	System.out.println("Usage: java ListenPrompt [options] packetSource");
// 	System.out.println("  [options] are:");
// 	System.out.println("  -h, --help                  Display this message.");
// 	System.out.println("                              Required options (source). ");
// 	System.out.println("");
// 	System.out.println("  packetSource                Standard TinyOS Source");
// 	System.out.println("                              serial@COM1:platform");
// 	System.out.println("                              network@HOSTNAME:PORTNUMBER");
// 	System.out.println("                              sf@HOSTNAME:PORTNUMBER");
// 	System.out.println("");
// 	System.exit(-1);
//     }

    static void cmdHelp() {
	System.out.println("Commands are: start, stop, and quit.");
    }


    public static void main(String args[]) throws IOException {
	String command = null;
	String [] commands; 
	BufferedReader br;
	boolean recording = false;
	boolean pauseRecording = false;


	System.out.println(args[0]);

	PacketSource reader = BuildSource.makePacketSource(args[0]);
	if (reader == null) {
	    System.err.println("Invalid packet source (check your MOTECOM environment variable)");
	    System.exit(2);
	}

	try {
	    br = new BufferedReader(new InputStreamReader(System.in));
	    reader.open(PrintStreamMessenger.err);
	    for (;;) {
		if (br.ready()) {
		    command = br.readLine();
		    commands = command.split(" ");
		    if (commands[0].equalsIgnoreCase("start")) {
			recording = true;
		    } else if (commands[0].equalsIgnoreCase("stop")) {
			recording = false;
		    } else if (commands[0].equalsIgnoreCase("quit")) {
			System.exit(0);
		    } else if (commands[0].equalsIgnoreCase("help")) {
			pauseRecording = true;
			cmdHelp();
		    } else {
			pauseRecording = true;
			System.out.println("ListenPrompt.java got an unknown command: " + commands[0]);
		    }
		}
		byte[] packet = reader.readPacket();
		if (pauseRecording) {
		    pauseRecording = false;
		} else if (recording) {
		    Dump.printPacket(System.out, packet);
		    Date date = new Date();
		    Timestamp ts = new Timestamp(date.getTime());
		    System.out.println(" " + ts);
		    System.out.flush();
		}
	    }
	}
	catch (IOException e) {
	    System.err.println("Error on " + reader.getName() + ": " + e);
	}
    }
}

