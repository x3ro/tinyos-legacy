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
 *
 *
 */

package codeGUI;

import java.awt.*;
import java.io.*;
import java.util.*;

import javax.swing.*;
import javax.swing.tree.*;

public class MotePanel extends JPanel {

    private JTree motes;
    private JScrollPane moteScroll;
    
    private JTextArea text;
    private JScrollPane textScroll;

    private JList programs;
    private Vector fileVector;
    private JScrollPane programScroll;
    
    private DefaultMutableTreeNode root;

    private byte groupID;
    
    public MotePanel(byte group) {
	super();
	this.groupID = group;

	String hexGroup = Integer.toHexString((int)(group & 0xff));
	root = new DefaultMutableTreeNode("Mote Group 0x" + hexGroup);
	motes = new JTree(root);
	motes.setVisibleRowCount(10);
	moteScroll = new JScrollPane(motes);
	motes.setSize(motes.getPreferredSize());
	moteScroll.setSize(moteScroll.getPreferredSize());
	
	text = new JTextArea(8, 40);
	textScroll = new JScrollPane(text);
	
	programs = new JList();
	fileVector = new Vector();
	programScroll = new JScrollPane(programs);
	
	GridBagLayout bag = new GridBagLayout();
	GridBagConstraints constraints = new GridBagConstraints();
	
	constraints.gridwidth = GridBagConstraints.RELATIVE;
	constraints.weightx = 0.5;
	constraints.gridheight = 2;
	constraints.anchor = GridBagConstraints.NORTHWEST;
	bag.setConstraints(moteScroll, constraints);
	
	constraints.weightx = 0.5;
	constraints.gridheight = 1;
	constraints.gridwidth = GridBagConstraints.REMAINDER;
	bag.setConstraints(textScroll, constraints);
	bag.setConstraints(programScroll, constraints);
	
	this.add(moteScroll);
	this.add(textScroll);
	this.add(programScroll);
	setLayout(bag);
	
	Font f = getFont();
	motes.setFont(f.deriveFont((float)10.0));
	programs.setFont(f.deriveFont((float)10.0));
	text.setFont(f.deriveFont((float)10.0));
	
	setSize(getPreferredSize());
    }
    
    public void setMotes(MoteInfo[] data) {
	for (int i = 0; i < data.length; i++) {
	    DefaultMutableTreeNode node = new DefaultMutableTreeNode("" + data[i].id());
	    ((DefaultTreeModel)motes.getModel()).insertNodeInto(node, root, root.getChildCount());
	    
	}
	
	repaint();
    }
	
    public synchronized void clearMotes() {
	DefaultTreeModel model = (DefaultTreeModel)motes.getModel();
	int numChildren = model.getChildCount(root);
	
	for (int i = 0; i < numChildren; i++) {
	    DefaultMutableTreeNode child = (DefaultMutableTreeNode)model.getChild(root, 0);
	    model.removeNodeFromParent(child);
	}
    }
    
    public synchronized void addMote(MoteInfo info) {
	//		System.err.println("Adding " + info.id());
	
	DefaultTreeModel model = (DefaultTreeModel)motes.getModel();
	int numChildren = model.getChildCount(root);
	for (int i = 0; i < numChildren; i++) {
	    DefaultMutableTreeNode child = (DefaultMutableTreeNode)model.getChild(root, i);
	    if (child.toString().equals("" + info.id())) {
		model.removeNodeFromParent(child);
		numChildren--;
		i--;
	    }
	}
	
	DefaultMutableTreeNode node = new DefaultMutableTreeNode("" + info.id());
	((DefaultTreeModel)motes.getModel()).insertNodeInto(node, root, root.getChildCount());
    	
	repaint();
    }
    
    public void addFile(File file) {
	fileVector.addElement(file);
	programs.setListData(fileVector);
    }
	
    public void clearFiles() {
	fileVector.clear();
	programs.setListData(fileVector);
    }
    
    public short getGroupID() {
	return groupID;
    }
    
    public short getSelectedMote() {
	TreePath path = motes.getSelectionPath();
	if (path == null) {
	    System.err.println("No mote selected: using broadcast.");
	    return (short)(0xffff);
	}
	else {
	    Object obj = path.getLastPathComponent();
	    String val = obj.toString();
	    short id;
	    
	    if (obj.equals(root)) {return (short)0xffff;}
	    try {
		id = (short)(Integer.parseInt(val));
	    }
	    catch (NumberFormatException exception) {
		id = (short)(0xffff);
	    }
	    return id;
	}
    }
	
    
    public String getSelectedMoteName() {
	TreePath path = motes.getSelectionPath();
	if (path == null) {
	    System.err.println("No mote selected.");
	    return null;
	}
	else {
	    Object obj = path.getLastPathComponent();
	    String val = obj.toString();
	    if (obj.equals(root)) {val = "255";}
	    return val;
	}
    }
    
    public File getSelectedFile() {
	return (File)programs.getSelectedValue();
    }
}
