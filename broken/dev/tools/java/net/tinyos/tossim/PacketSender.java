/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:		Phil Levis
 *                      Nelson Lee
 * Date:        Aug 14 2001 
 *              revised June 18 2002
 * Desc:        Class that reads in from a file and sends radio messages
 *              the tossim simulation.
 *
 *
 * PacketSender reads in packets from a file then sends them to the
 * tossim simulation for inclusion as events. It connects to a server and
 * it reads in a file and translates the data into binary messages to
 * the simulation.
 *
 * Packets have the following format:
 * <time> <moteID> <data0> <data1> ... <data37>
 *
 * All whitespace is insignificant. Time is an ASCII base 10 long long
 * value denoting at what time the mote should receive the
 * packet. MoteID is an ASCII base 10 short denoting the mote that
 * should receive the packet. The data fields are ASCII hexidecimal byte
 * values (e.g. "a0") denoting the data in the packet. If the mote
 * expects CRC values they must be explicitly put into the packet. A
 * sample packet:
 *
 *  666666 1 ff ff 08 13 de ad be ef de ad be ef de ad be ef de ad be
 *  ef de ad be ef de ad be ef de ad be ef de ad 00 00 00 00
 *
 * With this entry, at time 666666, a packet would be sent to mote 1.
 */

package net.tinyos.tossim;

import java.io.*;
import java.net.*;

public class PacketSender extends Thread {
    private String filename;
    
    public PacketSender(String filename) {
	this.filename = filename;
    }

    public void run() {
	Socket sock = null;
	
	try {
	    int code = StreamTokenizer.TT_EOL;
	    FileReader reader = new FileReader(filename);
	    StreamTokenizer tokenizer = new StreamTokenizer(reader);
	    tokenizer.ordinaryChars('0', '9');
	    tokenizer.wordChars('0', '9');
	    tokenizer.slashSlashComments(true);
	    
	    System.out.println("Connecting to socket 10576.");
	    try {
		sock = new Socket("127.0.0.1",10576);
		System.out.println("Connection to socket 10576 established.");
	    }
	    catch (Exception e) {
		System.out.println("Inputting packets from file must be done while running Tossim with the -ri option");
		System.exit(-1);
	    }

	    DataOutputStream output = new DataOutputStream(sock.getOutputStream());
	    
	    while(true) {
		code = tokenizer.nextToken();
		if (code == tokenizer.TT_EOF) {break;}

		else if (code == StreamTokenizer.TT_EOL) {}
		else if (code == StreamTokenizer.TT_WORD) {
		    String word = tokenizer.sval;
		    long lval = Long.parseLong(word);

		    code = tokenizer.nextToken();
		    if (code != StreamTokenizer.TT_WORD) {
			break;
		    }
		    word = tokenizer.sval;
		    short sval = Short.parseShort(word);
		    
		    byte[] data = new byte[36];
		    for (int i = 0; i < 36; i++) {
			code = tokenizer.nextToken();
			if (code != StreamTokenizer.TT_WORD) {break;}
			String datum = tokenizer.sval;
			try {
			    data[i] = (byte)(Integer.parseInt(datum, 16) & 0xff);
			}
			catch (NumberFormatException e) {
			    System.out.println(e);
			    System.out.println(datum);
			}
		    }

		    output.writeLong(lval);
		    output.writeShort(sval);
		    output.write(data);
		}
		else if (code == StreamTokenizer.TT_NUMBER) {}
	    }
	}
	catch (Exception exception) {
	    System.err.println("Exception thrown.");
	    exception.printStackTrace();
	}
	finally {
	    try {
		sock.close();
	    }
	    catch (Exception e) {}
	}
	///ServerSocket server = new ServerSocket(10576, 1);
	//System.out.println("Waiting on socket 10576.");
	//Socket sock = server.accept();
	//System.out.println("Accepted connection from " + sock);
	
	//DataOutputStream input = new DataOutputStream(sock.getOutputStream());
    }
}


