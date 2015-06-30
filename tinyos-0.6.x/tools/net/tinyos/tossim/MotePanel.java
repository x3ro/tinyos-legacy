/*									tab:4
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
 * Date:        Aug 2 2001
 * Desc:        The panel that displays motes info and maintains viewing state.
 *
 */

package net.tinyos.tossim;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.tree.*;


public class MotePanel extends JPanel {
    private Hashtable table;
    private JScrollPane scrollList;
    private JPanel panel;
    private PacketPanel packetPanel;
    private Vector motes;
    
    public MotePanel() {
	super();
	table = new Hashtable();
	motes = new Vector();
	
	panel = new JPanel();
	BoxLayout layout = new BoxLayout(panel, BoxLayout.Y_AXIS);
	panel.setLayout(layout);
	
	scrollList = new JScrollPane();
	scrollList.getViewport().add(panel);
	scrollList.setPreferredSize(new java.awt.Dimension(120, 360));
	
	add(scrollList);
	setSize(getPreferredSize());
	setVisible(true);
    }

    public void setPacketPanel(PacketPanel panel) {
	packetPanel = panel;
    }

    public void clearAll() {
	Enumeration enum = motes.elements();
	while (enum.hasMoreElements()) {
	    MoteFilterPanel mote = (MoteFilterPanel)enum.nextElement();
	    if (mote.isSelected()) {
		mote.click();
	    }
	}
	repaint();
    }
    
    public void selectAll() {
	Enumeration enum = motes.elements();
	while (enum.hasMoreElements()) {
	    MoteFilterPanel mote = (MoteFilterPanel)enum.nextElement();
	    if (!mote.isSelected()) {
		mote.click();
	    }
	}
	repaint();
    }

    private BitSet buildBitSet() {
	BitSet bits = new BitSet();
	Enumeration enum = table.elements();
	while (enum.hasMoreElements()) {
	    MoteHandle handle = (MoteHandle)enum.nextElement();
	    if (handle.isSelected()) {
		bits.set(handle.moteID());
	    }
	}
	return bits;
    }
    
    public synchronized Vector filterPackets(Vector vector) {
	Vector filtered = new Vector();
	
	BitSet bits = buildBitSet();
	int len = vector.size();
	for (int i = 0; i < len; i++) {
	    RFMPacket packet = (RFMPacket)vector.elementAt(i);
	    short moteID = packet.moteID();
	    if (bits.get(moteID)) {
		filtered.addElement(packet);
	    }
	}
	return filtered;
    }

    public synchronized void addMote(char groupID, short moteID) {
	MoteHandle handle = new MoteHandle(groupID, moteID);

	if (!table.contains(handle)) {
	    addNewMote(handle);
	}
    }


    private void addNewMote(MoteHandle handle) {
	MoteFilterPanel mote = new MoteFilterPanel(handle, packetPanel);
	table.put(handle, handle);
	panel.add(mote);
	motes.addElement(mote);
	scrollList.getViewport().add(panel);
	
	repaint();
    }
    
    protected class MoteHandle {
	private char groupID;
	private short moteID;
	private boolean isSelected;
	
	public MoteHandle(char groupID, short moteID) {
	    this.groupID = groupID;
	    this.moteID = moteID;
	    isSelected = true;
	}

	public char groupID() {return groupID;}
	public short moteID() {return moteID;}

	public boolean equals(Object obj) {
	    if (obj instanceof MoteHandle) {
		MoteHandle handle = (MoteHandle)obj;
		return (handle.moteID() == moteID() &&
			handle.groupID() == groupID());
	    }
	    else {
		return false;
	    }
	}

	public int hashCode() {
	    int val = ((int)moteID) + (((int)groupID) << 16);
	    Integer integer = new Integer(val);
	    return integer.hashCode();
	}

	public boolean isSelected() {return isSelected;}
	
	public void unselect() {
	    isSelected = false;
	}
	public void select() {
	    isSelected = true;
	}
	
    }

    protected class MoteFilterPanel extends JPanel {
	private JCheckBox button;
	private JLabel mote;
	private MoteHandle handle;
	
	public MoteFilterPanel(MoteHandle handle, PacketPanel panel) {
	    super();
	    this.handle = handle;

	    mote = new JLabel("" + handle.moteID());
	    
	    button = new JCheckBox();
	    button.setSelected(handle.isSelected());
	    button.addItemListener(new MoteSelectListener(handle, panel));
	    
	    add(mote);
	    add(button);
	    
	    setVisible(true);
	}

	public short moteID() {
	    return handle.moteID();
	}

	public boolean isSelected() {
	    return button.isSelected();
	}

	public void click() {
	    button.doClick();
	}
	
	public boolean include(RFMPacket packet) {
	    if (packet.moteID() == moteID() &&
		!(isSelected())) {
		return false;
	    }
	    return true;
	}
    }

    protected class MoteSelectListener implements ItemListener {
	private MoteHandle handle;
	private PacketPanel panel;
	
	public MoteSelectListener(MoteHandle handle, PacketPanel panel) {
	    this.handle = handle;
	    this.panel = panel;
	}

	public void itemStateChanged(ItemEvent e) {
	    if (e.getStateChange() == ItemEvent.SELECTED) {
		handle.select();
	    }
	    else if (e.getStateChange() == ItemEvent.DESELECTED) {
	    	handle.unselect();
	    }

	    panel.refresh();
	}
    }
    
}
