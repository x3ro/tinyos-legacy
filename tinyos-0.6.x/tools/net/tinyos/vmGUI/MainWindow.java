/*									tab:2
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Feb 19 2002
 * Desc:        Main window for TinyOS VM code injector.
 *
 */

package net.tinyos.vmGUI;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;

import net.tinyos.asm.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class MainWindow extends JFrame {

    private PacketPanel packets;
    private JButton     createButton;
    private JButton     injectButton;
    private JButton     quitButton;
    private JTextArea   programArea;
    private SerialStub  stub;
    
    public MainWindow(String serialPort) throws Exception {
	super("TinyOS VM Code Injector");
	stub = new SerialPortStub(serialPort);
	stub.Open();
	
	Font font = new Font("Courier", Font.PLAIN, 12);
	TOSPacket[] packet = new TOSPacket[1];
	packet[0] = new AMPacket((short)0xffff, (byte)0x7d, (byte)0x1e);
	
	packets = new PacketPanel(packet);
	packets.setFont(font);
	programArea = new JTextArea(24, 16);
	programArea.setFont(font);
	createButton = new CreateButton(programArea, packets);
	createButton.setFont(font);
	injectButton = new InjectButton(packets, stub);
	injectButton.setFont(font);
	quitButton = new QuitButton();
	quitButton.setFont(font);
	
	getContentPane().add(packets);
	getContentPane().add(programArea);
	getContentPane().add(createButton);
	getContentPane().add(injectButton);
	getContentPane().add(quitButton);

	FlowLayout layout = new FlowLayout();
	getContentPane().setLayout(layout);

	setVisible(true);
	pack();
    }

    public MainWindow(String host, short port) throws Exception {
	super("TinyOS VM Code Injector");
 
	stub = new SerialForwarderStub(host, (int)port);
	stub.Open();
	packets = new PacketPanel();
	programArea = new JTextArea(24, 16);
	createButton = new CreateButton(programArea, packets);
	injectButton = new InjectButton(packets, stub);
	quitButton = new QuitButton();

	
    }

    private class QuitButton extends JButton {
	public QuitButton() {
	    super("Quit");
	    addActionListener(new QuitListener());
	}
	private class QuitListener implements ActionListener {
	    public void actionPerformed(ActionEvent e) {
		System.exit(0);
	    }
	}
    }

    private class InjectButton extends JButton {
	public InjectButton(PacketPanel panel, SerialStub stub) {
	    super("Inject");
	    addActionListener(new InjectListener(panel, stub));
	}

	private class InjectListener implements ActionListener {
	    private PacketPanel panel;
	    private SerialStub stub;

	    public InjectListener(PacketPanel panel, SerialStub stub) {
		this.panel = panel;
		this.stub = stub;
	    }

	    public void actionPerformed(ActionEvent e) {
		try {
		    TOSPacket packet  = panel.getPacket();
		    byte[] data = packet.toByteArray();
		    stub.Write(data);
		}
		catch (IOException exception) {
		    System.err.println("ERROR: Couldn't inject packet.\n");
		    exception.printStackTrace();
		}
	    }
	}
	
    }

    private class CreateButton extends JButton {
	
	public CreateButton(JTextArea area, PacketPanel panel) {
	    super("Create");
	    addActionListener(new CreateListener(area, panel));
	}

	private class CreateListener implements ActionListener {
	    private JTextArea area;
	    private PacketPanel panel;
	    private AssemblerMate assembler;
	    private byte count;
	    
	    public CreateListener(JTextArea area, PacketPanel panel) {
		this.assembler = new AssemblerMate();
		this.area = area;
		this.panel = panel;
		this.count = 0;
	    }
	    
	    public void actionPerformed(ActionEvent e) {
		try {
		    String text = area.getText();
		    byte[] program = assembler.toByteCodes(new StringReader(text));
		    if (program.length != 30) {
			byte[] buffer = new byte[30];
			for (int i = 0; i < 30; i++) {
			    if (i < program.length) {
				buffer[i] = program[i];
			    }
			    else {
				buffer[i] = (byte)0x00;
			    }
			}
			program = buffer;
		    }
		    byte[] buffer = new byte[30];
		    for (int i = 2; i < 30; i++) {
			buffer[i] = program[i-2];
		    }
		    buffer[1] = this.count;
		    buffer[0] = (byte)0;
		    program = buffer;
		    count++;
		    if (count < 0) {count = 0;}
		    
		    AMPacket packet = new AMPacket((short)0xffff, (byte)0x7d, (byte)0x1e, program);
		    panel.addPacketType(packet);
		}
		catch (InvalidInstructionException exception) {
		    System.err.println(exception.getMessage());
		}
		catch (IOException exception) {
		    System.err.println("Exception thrown when trying to generate packet.");
		    exception.printStackTrace();
		}
	    }
	}
    }
    
    public static void main(String[] args) {
	try {
	    MainWindow window = new MainWindow("COM2");
	} 
	
	catch (Exception e) {
	    e.printStackTrace();
	}
    }
    
    


    
}
