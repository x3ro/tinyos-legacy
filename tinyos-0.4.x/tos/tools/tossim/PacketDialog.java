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

package tossim;

import java.awt.*;
import javax.swing.*;


public class PacketDialog extends JDialog {
    private RFMPacket packet;
    private JLabel idLabel;
    private JLabel timeLabel;
    private JLabel dataLabel;
    
    private JLabel moteID;
    private JLabel time;
    private JTextArea data;
    
    public PacketDialog(RFMPacket packet) {
	super();
	this.packet = packet;
	
	GridBagLayout bag = new GridBagLayout();
	GridBagConstraints constraints = new GridBagConstraints();
	getContentPane().setLayout(bag);
	
	idLabel = new JLabel("Mote ID:");
	timeLabel = new JLabel("Time:");
	dataLabel = new JLabel("Data");
	
	moteID = new JLabel("" + packet.moteID());
	time = new JLabel("" + packet.time());
	data = new JTextArea(makeText(packet.data()), 4, 29);
	data.setFont(new Font("Courier", Font.BOLD, 12));
	
	constraints.gridwidth = GridBagConstraints.RELATIVE;
	constraints.weightx = 0.3;
	constraints.anchor = GridBagConstraints.NORTHWEST;
	bag.setConstraints(idLabel, constraints);
	
	constraints.gridwidth = GridBagConstraints.REMAINDER;
	constraints.weightx = 0.7;
	bag.setConstraints(moteID, constraints);
	
	
	constraints.gridwidth = GridBagConstraints.RELATIVE;
	constraints.weightx = 0.3;
	constraints.anchor = GridBagConstraints.NORTHWEST;
	bag.setConstraints(timeLabel, constraints);
	
	constraints.gridwidth = GridBagConstraints.REMAINDER;
	constraints.weightx = 0.7;
	bag.setConstraints(time, constraints);
	
	constraints.weightx = 1.0;
	bag.setConstraints(dataLabel, constraints);
	bag.setConstraints(data, constraints);
	
	getContentPane().add(idLabel);
	getContentPane().add(moteID);
	
	getContentPane().add(timeLabel);
	getContentPane().add(time);
	
	getContentPane().add(dataLabel);
	getContentPane().add(data);


	pack();
	setVisible(true);
    }

    private String makeText(byte[] data) {
	String dataString = "";
	for (int i = 0; i < data.length; i++) {
	    String datum = Integer.toString((int)(data[i] & 0xff), 16);
	    if (datum.length() == 1) {dataString += "0";}
	    dataString += datum;
	    if (((i + 1) % 10) == 0) {
		dataString += "\n";
	    }
	    else {
		dataString += " ";
	    }
	}
	return dataString;
    }
}

