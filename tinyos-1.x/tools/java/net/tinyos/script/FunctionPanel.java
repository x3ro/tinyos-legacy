// $Id: FunctionPanel.java,v 1.2 2004/07/15 02:54:26 scipio Exp $

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

public class FunctionPanel extends JPanel {
    private JLabel placeholder;
    
    private JPanel availablePanel;
    private JList availableList;

    private JPanel usedPanel;
    private JList usedList;    

    private JPanel buttonPanel;
    private JButton useButton;
    private JButton unuseButton;

    private Vector availableFunctions;
    private Vector usedFunctions;

    private JPanel selectionPanel;
    private FunctionInfoPanel infoPanel;
    
    public FunctionPanel() {
	super();
	placeholder = new JLabel("Functions");
	availableFunctions = new Vector();
	usedFunctions = new Vector();
	

	infoPanel = new FunctionInfoPanel();
	
	availableList = new JList();
	availableList.setListData(availableFunctions);
	availableList.addListSelectionListener(new FunctionSelectionListener(infoPanel));
	availablePanel = makeListPanel(availableList, "Available Functions");
	
	usedList = new JList();
	usedList.setListData(usedFunctions);
	usedPanel = makeListPanel(usedList, "Used Functions");
	
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

    public void loadFunction(Function primitive) {
	availableFunctions.addElement(primitive);
        selectionPanel.repaint();
    }

    public Enumeration getSelectedFunctions() {
	return usedFunctions.elements();
    }
    
    protected void useSelected() {
	Object[] objs = availableList.getSelectedValues();
	for (int i = 0; i < objs.length; i++) {
	    Function c = (Function)objs[i];
	    availableFunctions.remove(c);
	    usedFunctions.addElement(c);
	}
	availableList.setListData(availableFunctions);
    	usedList.setListData(usedFunctions);
    }

    protected void unuseSelected() {
	Object[] objs = usedList.getSelectedValues();
	for (int i = 0; i < objs.length; i++) {
	    Function c = (Function)objs[i];
	    usedFunctions.remove(c);
	    availableFunctions.addElement(c);
	}
    	availableList.setListData(availableFunctions);
    	usedList.setListData(usedFunctions);
    }

    private JPanel makeListPanel(JList list, String title) {
	list.setFixedCellHeight(12);
	list.setFixedCellWidth(180);
	list.setCellRenderer(new FunctionCellRenderer());
	
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
	public UseButton(FunctionPanel p) {
	    super(">>");
	    this.addActionListener(new UseActionListener(p));
	}
	private class UseActionListener implements ActionListener {
	    FunctionPanel p;
	    public UseActionListener(FunctionPanel p) {
		this.p = p;
	    }
	    public void actionPerformed(ActionEvent e) {
		p.useSelected();
	    }
	}
    }

    protected class UnuseButton extends JButton {
	public UnuseButton(FunctionPanel p) {
	    super("<<");
	    this.addActionListener(new UnuseActionListener(p));
	}
	private class UnuseActionListener implements ActionListener {
	    FunctionPanel p;
	    public UnuseActionListener(FunctionPanel p) {
		this.p = p;
	    }
	    public void actionPerformed(ActionEvent e) {
		p.unuseSelected();
	    }
	}
    }
}
