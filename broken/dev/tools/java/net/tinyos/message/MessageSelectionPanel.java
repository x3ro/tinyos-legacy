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
 * MessagePanel is a swing panel representing a TinyOS message type:
 * message fields can be viewed and edited.
 */

package net.tinyos.message;


import java.awt.*;
import java.lang.reflect.*;
import java.util.*;
import javax.swing.*;
import javax.swing.text.*;


public class MessageSelectionPanel extends JPanel {
    private MessageSelection selection;
    private JTabbedPane pane;

    public MessageSelectionPanel() {
	super();
	try {
	    selection = new MessageSelection();
	    pane = new JTabbedPane();
	    addPackets();
	    add(pane);
	    pane.setAlignmentX(LEFT_ALIGNMENT);
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }

    public MessageSelectionPanel(String path) {
	super();
	try {
	    selection = new MessageSelection(path);
	    pane = new JTabbedPane();
	    addPackets();
	    add(pane);
	    pane.setAlignmentX(LEFT_ALIGNMENT);
    	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }

    public MessageSelectionPanel(MessageSelection selection) {
	super();
	try {
	    this.selection = selection;
	    pane = new JTabbedPane();
	    addPackets();
	    add(pane);
	    pane.setAlignmentX(LEFT_ALIGNMENT);
    	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }

    public Message getMessage() throws Exception {
	MessagePanel p = (MessagePanel)pane.getSelectedComponent();
	return p.getMessage();
    }
    
    private void addPackets() throws Exception {
	Message[] messages = selection.messages();
	for (int i = 0; i < messages.length; i++) {
	    MessagePanel panel = new MessagePanel(messages[i]);
	    String name = messages[i].getClass().getName();
	    Font font = new Font("Courier", Font.PLAIN, 12);
	    panel.setFont(font);
	    name = name.substring(name.lastIndexOf('.') + 1);
	    pane.add(panel, name);
	}
    }

    public static void main(String[] args) {
	try {
	    MessageSelectionPanel panel = new MessageSelectionPanel();
	    JFrame frame = new JFrame();
	    JScrollPane pane = new JScrollPane(panel);
	    frame.getContentPane().add(pane);
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
	    frame.pack();
	    frame.setVisible(true);
	    
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }
}
