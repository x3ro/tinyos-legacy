/*									tab:2
 *
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
 * Authors:		Phil Levis
 * Description:         Injects packets through a serial forwarder.
 * 
 */


package net.tinyos.packet;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import javax.swing.*;
import javax.swing.event.*;

import net.tinyos.util.SerialPortStub;


public class PacketInjector extends JFrame {
    
    SerialPortStub stub;
    private net.tinyos.packet.PacketPanel panel;
    private JButton button;
    private JButton quit;
    
    public PacketInjector(String port) {
	super();
	
	TOSPacket[] packets = new TOSPacket[2];
	packets[0] = new AMPacket();
	packets[1] = new BLESSPacket();
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


	
	try {
	    stub = new SerialPortStub(port);
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
	private PacketInjector injector;
	
	public InjectListener(net.tinyos.packet.PacketPanel panel,
			      PacketInjector injector) {
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

    
    public static void main(String[] args) {
	if (args.length > 0) {
	    PacketInjector injector = new PacketInjector(args[0]);
	}
	else {
	    PacketInjector injector = new PacketInjector("COM1");
	}
    }
}

