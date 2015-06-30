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
 * Date:        Aug 2 2001
 * Desc:        Template for classes.
 *
 */

package net.tinyos.tossim;

import java.awt.*;
import java.io.*;
import java.util.Vector;
import javax.swing.*;
import javax.swing.event.*;

public class PacketPanel extends JPanel implements PacketListener {
  final static int listWidth = 600;

    private MotePanel motes;
    private Vector vector;
    private Vector filtered;
    private JScrollPane scrollList;
    private JList list;
    private JPanel labelPanel;
    
    private boolean paused;
    
    public PacketPanel(MotePanel motes) {
	super();

	paused = false;
	
	this.motes = motes;
	this.vector = new Vector();
	this.list = makePacketList(vector);

	GridBagLayout bag = new GridBagLayout();
        GridBagConstraints constraints = new GridBagConstraints();
	constraints.gridx = GridBagConstraints.REMAINDER;
        setLayout(bag);

	
	labelPanel = new PacketLabelPanel();
	bag.setConstraints(labelPanel, constraints);

	scrollList = new JScrollPane(list);
	scrollList.setPreferredSize(new Dimension(listWidth, 400));
	bag.setConstraints(scrollList, constraints);

	add(labelPanel);
	add(scrollList);
	
	setSize(getPreferredSize());
	setVisible(true);
    }

    protected Vector getFiltered() {
	return filtered;
    }

    public synchronized void togglePause() {
	paused = !paused;
	if (!paused) {
	    notify();
	}
    }

    public synchronized boolean isPaused() {
	return paused;
    }
    
    public synchronized void receivePacket(byte[] packet) {
	if (packet.length != CommReader.PACKET_LEN) {
	    System.err.println("Received packet of unexpected length. Expected length: " + CommReader.PACKET_LEN + ", received length: " + packet.length);
	    return;
	}
	try {
	    RFMPacket rfm = new RFMPacket(packet);
	    addPacket(rfm);
	}
	catch (IOException exception) {
	    System.err.println("Exception thrown when adding packet.");
	    exception.printStackTrace();
	}
    }

    private void addPacket(RFMPacket packet) {
	//System.out.println("Added packet.");
	motes.addMote((char)0x13, packet.moteID());
	vector.add(packet);
	refresh();
    }

    public synchronized void refresh() {
	filtered = motes.filterPackets(vector);
	//System.out.println("There are " + packets.size() + " packets.");
	list.setListData(filtered);
	list.repaint();
	scrollList.repaint();
	repaint();
    }

    private JList makePacketList(Vector data) {
	JList list = new JList(data);
	list.setCellRenderer(new PacketListCellRenderer());
	list.setFixedCellWidth(listWidth);
	list.setFixedCellHeight(20);
	list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
	//list.setPreferredSize(new Dimension(listWidth, 200000000));
	list.setVisible(true);
	list.addListSelectionListener(new PacketSelectionListener(this));
	return list;
    }

    private class PacketListCellRenderer implements ListCellRenderer {
	
	public Component getListCellRendererComponent(JList list,
						      Object value,
						      int index,
						      boolean isSelected,
						      boolean cellHasFocus) {
	    //	    System.out.println("Displaying packet: " + index);
	    JPanel panel = new JPanel(true);
	    Color fg = Color.black;
	    Color bg = Color.white;

	    JLabel timeLabel;
	    JLabel moteLabel;
	    JLabel dataLabel;

	    if (isSelected) {
		bg = Color.blue;
		fg = Color.red;
	    }
	    if (value != null) {
		RFMPacket packet = (RFMPacket)value;
		String timeStr = TimeConverter.convert(packet.time());

		timeLabel = new JLabel(timeStr);
		moteLabel = new JLabel("" + packet.moteID());
		
		String dataString = "";
		for (int i = 0; i < 30; i++) {
		    byte[] data = packet.data();
		    String datum = Integer.toString((int)(data[i] & 0xff), 16);
		    if (datum.length() == 1) {dataString += "0";}
		    dataString += datum;
		    dataString += " ";
		}
		dataLabel = new JLabel(dataString);
	    }
	    else {
		timeLabel = new JLabel("Time");
		moteLabel = new JLabel("Mote");
		dataLabel = new JLabel("Data");
	    }

	    timeLabel.setPreferredSize(new Dimension(140, 20));
	    moteLabel.setPreferredSize(new Dimension(40, 20));
	    dataLabel.setPreferredSize(new Dimension(listWidth - 220, 20));

	    timeLabel.setForeground(fg);
	    timeLabel.setBackground(bg);
	    moteLabel.setForeground(fg);
	    moteLabel.setBackground(bg);
	    dataLabel.setForeground(fg);
	    dataLabel.setBackground(bg);
	    dataLabel.setFont(new Font("Courier", Font.BOLD, 12));
	    
	    panel.add(timeLabel);
	    panel.add(moteLabel);
	    panel.add(dataLabel);
	    
	    return panel;
	}
    }

    protected class PacketLabelPanel extends JPanel {
	private JLabel timeLabel;
	private JLabel moteLabel;
	private JLabel dataLabel;
	
	public PacketLabelPanel() {
	    timeLabel = new JLabel("Time",SwingConstants.LEFT);
	    moteLabel = new JLabel("Mote",SwingConstants.LEFT);
	    dataLabel = new JLabel("Data",SwingConstants.LEFT);

	    timeLabel.setPreferredSize(new Dimension(75, 20));
	    moteLabel.setPreferredSize(new Dimension(175, 20));
	    dataLabel.setPreferredSize(new Dimension(200, 20));
	    
	    add(timeLabel);
	    add(moteLabel);
	    add(dataLabel);
	}
    }

}
