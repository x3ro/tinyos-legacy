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
 * Date:        Sept 28 2001
 * Desc:        Class responsible for packet injection.
 *
 */

package net.tinyos.packet;

import net.tinyos.util.*;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import javax.swing.*;
import javax.swing.event.*;

public class NetworkInjector extends JFrame {
    private SerialForwarderStub stub;
    private net.tinyos.packet.PacketPanel panel;
    private JButton button;
    
    public NetworkInjector(String host, short port) {
	super();

	TOSPacket[] packets = new TOSPacket[4];
	packets[0] = new NAMINGPacket();
	packets[1] = new AMPacket();
	packets[2] = new BLESSPacket();
	packets[3] = new PINGPacket();
	panel = new net.tinyos.packet.PacketPanel(packets);

	button = new JButton("Inject");
	button.addActionListener(new InjectListener(panel, this));

	getContentPane().setLayout(new FlowLayout());
	getContentPane().add(panel);
	getContentPane().add(button);

	
	try {
	    stub = new SerialForwarderStub(host, port);
	    stub.Open();
	}
	catch (Exception exception) {
	    exception.printStackTrace();
	}
	
	setVisible(true);
	pack();
    }

    
    public void sendPacket(TOSPacket packet) {
	try {
	    byte[] data = packet.toByteArray();
	    stub.Write(data);
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

    
    public static void main(String[] args) {
	String host = "localhost";
	short port = (short)9000;
	
	if (args.length > 0) {
	    String info = args[0];
	    int index = info.lastIndexOf(':');

	    host = info.substring(0, index);

	    String portStr = info.substring(index + 1, info.length());
	    Short sval = new Short(portStr);
	    port = sval.shortValue();
	}
	System.out.println("Connecting to " + host + ":" + port);

	NetworkInjector injector = new NetworkInjector("localhost", port);
    }
}

