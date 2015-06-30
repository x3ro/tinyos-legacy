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
 * Date:        Jul 25 2001 
 *              revised June 18 2002 
 * Desc:        Top-level class for TOSSIM networking GUI.
 *
 */
package net.tinyos.tossim;

import java.awt.*;
import java.io.*;
import java.net.*;
import javax.swing.*;

public class TossimGUI extends JFrame {

    private ButtonPanel buttons;
    private MotePanel motes;
    private PacketPanel packets;
    private CommReader reader;
    private Thread radioThread = null;
    private static int portToUsePacketReading = -1;
    
    public TossimGUI() {
	super("Keter");
	motes = new MotePanel();
	packets = new PacketPanel(motes);
	buttons = new ButtonPanel(motes, packets);
	reader = new CommReader(portToUsePacketReading);
	motes.setPacketPanel(packets);
	
	GridBagLayout bag = new GridBagLayout();
        GridBagConstraints constraints = new GridBagConstraints();
        getContentPane().setLayout(bag);

	constraints.gridwidth = GridBagConstraints.RELATIVE;
	constraints.weightx = 0.3;
	constraints.anchor = GridBagConstraints.NORTHWEST;
	bag.setConstraints(motes, constraints);

	constraints.weightx = 0.7;
	constraints.gridwidth = GridBagConstraints.REMAINDER;
	bag.setConstraints(packets, constraints);

	constraints.weightx = 1.0;
	bag.setConstraints(buttons, constraints);

	try {
	    radioThread = reader.startRadioSocket(packets);
	}
	catch (Exception exception) {
	    System.err.println(exception);
	    System.exit(-1);
	}
	
	
	    
	

	this.getContentPane().add(motes);
	this.getContentPane().add(packets);
	this.getContentPane().add(buttons);
	
	this.pack();

	System.out.println("radioThread = " + radioThread);
	if (!(radioThread.isAlive())) {
	    System.out.println("radioThread terminated abruptly, exiting...");
	    System.exit(-1);
	    
	}	
	this.setVisible(true);
    }

    public static void usage() {
	System.out.println("java TossimGUI [-r <filename>] [-p <portnumber>]");
	System.out.println("\t -r <filename>: read in file of packets to inject into simulation");
	System.out.println("\t -p <portnumber>: port number to connect to to receive packets; default uses port 10584");

    }
    
    public static void main(String[] argv) throws Exception {
	
	//TossimGUI gui = new TossimGUI();
	for (int i = 0; i < argv.length; i++) {
	    if (argv[i].equals("-h")) {
		TossimGUI.usage();
		System.exit(0);
	    }
	    
	    else if (argv[i].equals("-r")) {
		System.out.println("Reading radio packets from " + argv[i+1]);
		PacketSender sender = new PacketSender(argv[i+1]);
		sender.start();
		i++;
	    }
		
	    else if (argv[i].equals("-p")) {
		portToUsePacketReading = Integer.parseInt(argv[i+1]);
		i++;
	    }
	    
	    else {
		TossimGUI.usage();
		System.exit(1);
	    }	    
	}

	TossimGUI gui = new TossimGUI();
	Socket sock = null;
	if (argv.length == -1) {
	    System.out.println("Connecting to socket 10577");
	    try {
		sock = new Socket("127.0.0.1", 10577);
	    }
	    catch (Exception e) {
		System.out.println("Connection to socket 10577 failed");
		System.exit(-1);
	    }

	    
	    
	    DataOutputStream input = new DataOutputStream(sock.getOutputStream());
	    byte[] msg  = {
		
		(byte)0xff, (byte)0xff, (byte)0x07, (byte)0x13,
		(byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
		(byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
		(byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
		(byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
		(byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
		(byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
		(byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
		(byte)0xde, (byte)0xad, (byte)0x00, (byte)0x00,
		(byte)0x00, (byte)0x00};

	    input.writeLong(666666);
	    input.writeShort(1);
	    input.write(msg);
	}
    }
}








