// $Id: InstructionPanel.java,v 1.5 2004/02/17 23:06:37 scipio Exp $

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

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.script.tree.*;
import net.tinyos.util.*;

public class InstructionPanel extends JPanel {
    private JLabel placeholder;
    
    private JPanel availablePanel;
    private JList availableList;

    private JPanel usedPanel;
    private JList usedList;    

    private JPanel buttonPanel;
    private JButton useButton;
    private JButton unuseButton;

    private Vector availableInstructions;
    private Vector usedInstructions;

    private JPanel selectionPanel;
    private PrimitiveInfoPanel infoPanel;
    
    public InstructionPanel() {
	super();
	placeholder = new JLabel("Instructions");
	availableInstructions = new Vector();
	usedInstructions = new Vector();
	

	infoPanel = new PrimitiveInfoPanel();
	
	availableList = new JList();
	availableList.setListData(availableInstructions);
	availableList.addListSelectionListener(new PrimitiveSelectionListener(infoPanel));
	availablePanel = makeListPanel(availableList, "Available Instructions");
	
	usedList = new JList();
	usedList.setListData(usedInstructions);
	usedPanel = makeListPanel(usedList, "Used Instructions");
	
	useButton = new UseButton(this);
	unuseButton = new UnuseButton(this);
	buttonPanel = new JPanel();
	buttonPanel.setLayout(new BoxLayout(buttonPanel, BoxLayout.Y_AXIS));
	buttonPanel.add(useButton);
	buttonPanel.add(unuseButton);
	buttonPanel.setAlignmentY((float)1.0);


	selectionPanel = new JPanel();
	selectionPanel.setLayout(new BoxLayout(selectionPanel, BoxLayout.X_AXIS));
	selectionPanel.add(availablePanel);
	selectionPanel.add(buttonPanel);
	selectionPanel.add(usedPanel);
	
	setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
	add(selectionPanel);
	add(infoPanel);
	
	setBorder(new EtchedBorder());
    }

    public void loadInstruction(Primitive primitive) {
	availableInstructions.addElement(primitive);
        selectionPanel.repaint();
    }

    public Enumeration getSelectedInstructions() {
	return usedInstructions.elements();
    }
    
    protected void useSelected() {
	Object[] objs = availableList.getSelectedValues();
	for (int i = 0; i < objs.length; i++) {
	    Primitive c = (Primitive)objs[i];
	    availableInstructions.remove(c);
	    usedInstructions.addElement(c);
	}
	availableList.setListData(availableInstructions);
    	usedList.setListData(usedInstructions);
    }

    protected void unuseSelected() {
	Object[] objs = usedList.getSelectedValues();
	for (int i = 0; i < objs.length; i++) {
	    Primitive c = (Primitive)objs[i];
	    usedInstructions.remove(c);
	    availableInstructions.addElement(c);
	}
    	availableList.setListData(availableInstructions);
    	usedList.setListData(usedInstructions);
    }

    private JPanel makeListPanel(JList list, String title) {
	list.setFixedCellHeight(12);
	list.setFixedCellWidth(180);
	list.setCellRenderer(new PrimitiveCellRenderer());
	
	JScrollPane pane = new JScrollPane(list);
	pane.setSize(new Dimension(200, 144));
	pane.setPreferredSize(new Dimension(200, 144));

	JLabel label = new JLabel(title);
	
	JPanel panel = new JPanel();
	panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
	panel.add(label);
	panel.add(pane);
	panel.setAlignmentY((float)1.0);
	return panel;
    }
    
    protected class UseButton extends JButton {
	public UseButton(InstructionPanel p) {
	    super(">>");
	    this.addActionListener(new UseActionListener(p));
	}
	private class UseActionListener implements ActionListener {
	    InstructionPanel p;
	    public UseActionListener(InstructionPanel p) {
		this.p = p;
	    }
	    public void actionPerformed(ActionEvent e) {
		p.useSelected();
	    }
	}
    }

    protected class UnuseButton extends JButton {
	public UnuseButton(InstructionPanel p) {
	    super("<<");
	    this.addActionListener(new UnuseActionListener(p));
	}
	private class UnuseActionListener implements ActionListener {
	    InstructionPanel p;
	    public UnuseActionListener(InstructionPanel p) {
		this.p = p;
	    }
	    public void actionPerformed(ActionEvent e) {
		p.unuseSelected();
	    }
	}
    }
}
