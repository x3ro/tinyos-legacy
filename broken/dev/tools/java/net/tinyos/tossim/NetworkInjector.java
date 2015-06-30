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
 * Date:        Jan 29 2002
 * Desc:        Class responsible for packet injection. This application runs in 
 *              2 possible modes.  Without any command prompt arguments, this program
 *              will first attempt to connect to port 10579, Tossim's real-time 
 *              output port.  If that fails, the program will then try to connect to
 *              port 10576, Tossim's startup run-time radio out port.  
 *              
 *              For the second mode of operation, a port is specified at the command 
 *              prompt. If connection to this port fails, no attempts to other ports
 *              are made and the application exits with an error.  
 *
 */

package net.tinyos.tossim;

import net.tinyos.packet.*;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import javax.swing.*;
import javax.swing.event.*;

public class NetworkInjector extends JFrame {
    private Socket socket;
    private net.tinyos.packet.PacketPanel panel;
    private JButton button;
    private JButton quit;
    
    public NetworkInjector(int port) {
	super();

	TOSPacket[] packets = new TOSPacket[1];
	packets[0] = new AMPacket();
	//packets[1] = new BLESSPacket();
	//	packets[1] = new BLESS_NEWPacket();
	//	packets[2] = new PINGPacket();

	panel = new net.tinyos.packet.PacketPanel(packets);

	button = new JButton("Inject");
	quit = new JButton("Quit");
	
	button.addActionListener(new InjectListener(panel, this));
	quit.addActionListener(new QuitListener());
	
	getContentPane().setLayout(new FlowLayout());
	getContentPane().add(button);
	getContentPane().add(quit);
	getContentPane().add(panel);

	if (port == -1) {
	    System.out.println("Attempting to open socket on port 10579");
	    try {
		socket = new Socket("127.0.0.1", 10579);
	    }
	    catch (Exception exception) {
		System.out.println("Connection to port 10579 failed");
		exception.printStackTrace();
		
	    }
	    
	    System.out.println("socket = " + socket);
	    
	    
	    if (socket == null) {
		System.out.println("Attempting to open socket on port 10576");
		try {
		    socket = new Socket("127.0.0.1", 10576);
		}
		catch (Exception exception) {
		    System.out.println("Connection to port 10576 failed");
		    exception.printStackTrace();
		    System.exit(-1);
		}
	    }
	}
	else {
	    System.out.println("Attempting to open socket on port " + port);
	    try {
		socket = new Socket("127.0.0.1", port);
	    }
	    catch (Exception exception) {
		System.out.println("Connection to port " + port + " failed");
		exception.printStackTrace();
		System.exit(-1);
	    }
	}
		
	    
	
	
	setVisible(true);
	pack();
    }
	
    
    public void sendPacket(TOSPacket packet) {
	try {
	    DataOutputStream output = new DataOutputStream(socket.getOutputStream());
	    byte[] data = packet.toByteArray();
	    System.out.println("Packet injection called for data of length " + data.length + ".");
	    output.writeLong(0);
	    output.writeShort(0);
	    output.write(data);
	    System.out.println("data's length = " + data.length);
	}
	catch (Exception exception) {
	    exception.printStackTrace();
	}
    }


    private class InjectListener implements ActionListener {
	private net.tinyos.packet.PacketPanel panel;
	private NetworkInjector injector;
	
	public InjectListener(net.tinyos.packet.PacketPanel panel,
			      NetworkInjector injector) {
	    this.panel = panel;
	    this.injector = injector;
	}
	
	public void actionPerformed(ActionEvent e) {
	    TOSPacket packet  = panel.getPacket();
	    injector.sendPacket(packet);
	    System.out.println("Sending packet:");
	    System.out.println(TOSPacket.dataToString(packet.toByteArray()));
	    System.out.println();
	}
	
    }

    
    private class QuitListener implements ActionListener {
	
	public QuitListener() {}
	
	public void actionPerformed(ActionEvent e) {
	    System.exit(0);
	}
	
    }
    
    public static void usage() {
	System.out.println("java NetworkInjector [<portnumber>]");
	System.out.println("<portnumber>: port number to connect to to dynamically send packets, default uses port 10579 then 10576");

    }
    
    public static void main(String[] args) {
	int port = -1;
	if (args.length == 1) 
	    port = Integer.parseInt(args[0]);

	else if (args.length > 1) {
	  usage();
	  System.exit(-1);
	}
	  
	
	NetworkInjector injector = new NetworkInjector(port);
    }
}











