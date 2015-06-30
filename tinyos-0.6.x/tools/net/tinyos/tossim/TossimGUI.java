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
 * Date:        Jul 25 2001
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
    
    public TossimGUI() {
	super("Keter");
	motes = new MotePanel();
	packets = new PacketPanel(motes);
	buttons = new ButtonPanel(motes, packets);
	reader = new CommReader();
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
	    reader.startRadioSocket(packets);
	}
	catch (Exception exception) {
	    System.err.println(exception);
	}
	
	this.getContentPane().add(motes);
	this.getContentPane().add(packets);
	this.getContentPane().add(buttons);
	
	this.pack();
	this.setVisible(true);
    }

    public static void usage() {
	System.out.println("java TossimGUI [-r <filename>]");
	System.out.println("\t -r <filename>: read in file of packets to inject into simulation");

    }
    
    static void main(String[] argv) throws Exception {
	//TossimGUI gui = new TossimGUI();
	int args = 0;

	while(argv.length - args > 0) {
	    
	    
	    if ((argv.length - args) % 2 != 0) {
		TossimGUI.usage();
		System.exit(1);
	    }

	    String flag = argv[args];
	    args++;

	    if (flag.equals("-h")) {
		TossimGUI.usage();
		System.exit(0);
	    }

	    String val = argv[args];
	    args++;

	    if (flag.equals("-r")) {
		System.out.println("Reading radio packets from " + val);
		PacketSender sender = new PacketSender(val);
		sender.start();
		//sender.join();
	    }
	    
	}

	TossimGUI gui = new TossimGUI();

    	if (argv.length == -1) {
	    
	    ServerSocket server = new ServerSocket(10576, 1);
	    System.out.println("Waiting on socket 10576.");
	    Socket sock = server.accept();
	    System.out.println("Accepted connection from " + sock);
	    
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
