/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Authors:  Philip Levis  <pal@cs.berkeley.edu>
 *
 */

/**
 * MessageInjector is a Java GUI for filling in and sending TinyOS
 * packets.
 */

package net.tinyos.message;


import java.awt.*;
import java.awt.event.*;
import java.io.IOException;
import java.lang.reflect.*;
import java.util.*;
import javax.swing.*;
import javax.swing.text.*;
import javax.swing.event.*;

import net.tinyos.util.*;

public class MessageInjector extends JFrame {
    private JScrollPane pane;
    private JPanel buttonPanel;
    private JPanel nestedPanel;
    private MessageSelectionPanel selection;
    private Sender sender;

    public MessageInjector() {
	super("TinyOS Message Injector");
	try {
	    selection = new MessageSelectionPanel();
	    SerialForwarderStub stub = new SerialForwarderStub("localhost", 9000);
	    stub.Open();
	    sender = new Sender(stub, 0x7d);
	    initialize();
	}
	catch (IOException exception) {
	    exception.printStackTrace();
	}
    }

    public MessageInjector(MessageSelectionPanel panel) {
	super("TinyOS Message Injector");
	try {
	    selection = panel;
	    SerialForwarderStub stub = new SerialForwarderStub("localhost", 9000);
	    stub.Open();
	    sender = new Sender(stub, 0x7d);
	    initialize();
    	}
	catch (IOException exception) {
	    exception.printStackTrace();
	}
    }


    public MessageInjector(SerialStub stub) {
	super("TinyOS Message Injector");
	selection = new MessageSelectionPanel();
	sender = new Sender(stub, 0x7d);
	initialize();
    }

    
    public MessageInjector(MessageSelectionPanel panel,
			   SerialForwarderStub stub) {
	super("TinyOS Message Injector");
	selection = panel;
	sender = new Sender(stub, 0x7d);
	initialize();
    }

    public MessageInjector(SerialStub stub, int gid) {
	super("TinyOS Message Injector");
	selection = new MessageSelectionPanel();
	sender = new Sender(stub, gid);
	initialize();
    }

    public MessageInjector(MessageSelectionPanel panel,
			   SerialForwarderStub stub,
			   int gid) {
	super("TinyOS Message Injector");
	selection = panel;
	sender = new Sender(stub, gid);
	initialize();
    }

    private void initialize() {
	nestedPanel = new JPanel();
	nestedPanel.setLayout(new BoxLayout(nestedPanel, BoxLayout.Y_AXIS));

	JScrollPane pane = new JScrollPane(selection);
	Dimension size = pane.getPreferredSize();
	if (size.getHeight() > 380) {
	    size.setSize(size.getWidth(), 400);
	}
	else {
	    size.setSize(size.getWidth(), size.getHeight() + 20);
	}
	if (size.getWidth() > 980) {
	    size.setSize(1000, size.getHeight());
	}
	else {
	    size.setSize(size.getWidth() + 20, size.getHeight());
	}
	pane.setPreferredSize(size);
	nestedPanel.add(pane);

	buttonPanel = new ButtonPanel(selection, sender);
	nestedPanel.add(buttonPanel);
	getContentPane().add(nestedPanel);
	pack();
	setVisible(true);
    }

    private class ButtonPanel extends JPanel {
	MessageSelectionPanel panel;
	Sender sender;
	
	JButton quitButton;
	JLabel label;
	JTextPane text;
	JButton sendButton;
	
	public ButtonPanel(MessageSelectionPanel panel, Sender sender) {
	    this.panel = panel;
	    this.sender = sender;
	    this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	    
	    quitButton = new JButton("Quit");
	    quitButton.addActionListener(new QuitListener());

	    label = new JLabel("Mote ID");
	    text = new JTextPane(new LimitedStyledDocument(4));

	    sendButton = new JButton("Send");
	    sendButton.addActionListener(new InjectListener(panel, sender, text));

	    add(quitButton);
	    add(label);
	    add(text);
	    add(sendButton);
	}


	

    }

    protected class QuitListener implements ActionListener {
	public QuitListener() {}
	
	public void actionPerformed(ActionEvent e) {
	    System.exit(0);
	}
    }

    protected class InjectListener implements ActionListener {
	private MessageSelectionPanel panel;
	private Sender sender;
	private JTextPane text;
	
	public InjectListener(MessageSelectionPanel panel, Sender sender, JTextPane text) {
	    this.panel = panel;
	    this.sender = sender;
	    this.text = text;
	}
	
	public void actionPerformed(ActionEvent e) {
	    try {
		int moteID = Integer.parseInt(text.getText(), 16);
		sender.send(moteID, panel.getMessage());
	    }
	    catch (Exception exception) {
		exception.printStackTrace();
	    }
	}
    }

    public static void main(String[] args) {
	SerialPortStub stub = new SerialPortStub("COM1");
	System.out.println("Opened COM1.");
	MessageInjector mi = new MessageInjector(stub);
    }

}
