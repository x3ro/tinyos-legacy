/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Sep 26 2003
 * Desc:        Main window for VM builder
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.script.tree.*;
import net.tinyos.util.*;

public class PrimitivePanel extends JPanel {
    private JPanel labelPanel;
    private JPanel listPanel;
    private PrimitiveInfoPanel infoPanel;
    
    public PrimitivePanel() {
	super();
	setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
	
	JLabel label = new JLabel("Primitives");
	label.setFont(TinyLook.boldFont());
	label.setAlignmentX(LEFT_ALIGNMENT);
	labelPanel = new JPanel();
	labelPanel.add(label);
	labelPanel.setBorder(new EtchedBorder());
	
	infoPanel = makeInfoPanel();
	infoPanel.setBorder(new EtchedBorder());
	listPanel = makeListPanel();
	listPanel.setBorder(new EtchedBorder());

	add(labelPanel);
	add(listPanel);
	add(infoPanel);
	
    }

    private JPanel makeListPanel() {
	Vector elements = new Vector();
	Enumeration enum = PrimitiveSet.primitiveNames();
	while (enum.hasMoreElements()) {
	    elements.add(PrimitiveSet.getPrimitive((String)enum.nextElement()));
	}
	
	JList list = new JList(elements);
	list.setFixedCellHeight(12);
	list.setFixedCellWidth(180);
	list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
	list.setCellRenderer(new PrimitiveCellRenderer());
	list.addListSelectionListener(new PrimitiveSelectionListener(infoPanel));
	
	JScrollPane pane = new JScrollPane(list);
	pane.setSize(new Dimension(200, 240));
	pane.setPreferredSize(new Dimension(200, 240));
	
	JPanel panel = new JPanel();
	panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
	panel.add(pane);
	panel.setAlignmentY((float)1.0);
	return panel;
    }

    private PrimitiveInfoPanel makeInfoPanel() {
	return new PrimitiveInfoPanel();
    }

    private class PrimitiveSelectionListener implements ListSelectionListener {
	private PrimitiveInfoPanel panel;
	
	public PrimitiveSelectionListener(PrimitiveInfoPanel p) {
	    panel = p;
	}

	public void valueChanged(ListSelectionEvent e) {
	    JList list = (JList)e.getSource();
	    Primitive primitive = (Primitive)list.getSelectedValue();
	    panel.setPrimitive(primitive);
	}
    }
    
    public static void main(String[] args) {
	JFrame frame = new JFrame();
	PrimitivePanel p = new PrimitivePanel();
	frame.getContentPane().add(p);
	frame.pack();
	frame.setVisible(true);
    }

}
