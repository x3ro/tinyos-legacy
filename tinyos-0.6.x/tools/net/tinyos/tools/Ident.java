/* @(#)BcastInject.java
 *
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

/**
 * 
 *
 * @author <a href="mailto:szewczyk@sourceforge.net">Robert Szewczyk</a>
 */
package net.tinyos.tools;

import net.tinyos.util.*;
import java.io.*;
import java.util.Properties;

public class Ident {
    public static final int CMD_CLEAR = 10;
    public static final int CMD_SET = 11;
    public static final int MAX_ID_LENGTH = 14;

    public static final short TOS_BCAST_ADDR = (short) 0xffff;

    public static void usage() 
    {
	System.err.println("Usage: java net.tinyos.utils.Ident "+
			   " group_id command args...");
	System.err.println("\twhere command is one of the following:");
	System.err.println("\t\tclear");
	System.err.println("\t\tset <string, upto " + MAX_ID_LENGTH + " chars>");
	System.exit(2);
    }

    public static void main(String[] argv) throws IOException{
	String host = "localhost";
	int port = 9000;
	String cmd = "";
	byte group_id = 0;
	byte the_cmd = 0;
	String id = "";

	if (argv.length < 2)
	    usage();
	group_id = (byte) Integer.parseInt(argv[0]);
	cmd = argv[1];
	if (cmd.equals("clear")) {
	    if (argv.length != 2)
		usage();
	    the_cmd = CMD_CLEAR;
	}
	else if (cmd.equals("set")) {
	    if (argv.length != 3)
		usage();
	    the_cmd = CMD_SET;
	    id = argv[2];
	    if (id.length() > MAX_ID_LENGTH)
		usage();
	}
	else
	    usage();

	SerialForwarderStub rw = new SerialForwarderStub(host, port);
	byte [] packet = new byte[SerialForwarderStub.PACKET_SIZE];
	byte sequenceNo = 0;

	//Generic message header, destination, group id, and message type
	packet[0] = (byte) ((TOS_BCAST_ADDR >> 8) & 0xff);
	packet[1] = (byte) (TOS_BCAST_ADDR & 0xff);
	packet[2] = the_cmd;
	packet[3] = group_id;

	int idlength = id.length();
	for (int i = 0; i < idlength; i++)
	    packet[i + 4] = (byte)id.charAt(i);

	rw.Open();
	rw.Write(packet);
	for (int i = 0; i < SerialForwarderStub.PACKET_SIZE; i++) {
	    System.out.print(Integer.toHexString(packet[i] & 0xff)+ " ");
	}
	System.out.println();
    }
}
