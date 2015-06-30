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
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;

public class ButtonPanel extends JPanel {
    private MotePanel motes;
    private PacketPanel packets;

    private JButton clearButton;
    private JButton selectButton;
    private JButton pauseButton;
    private JButton quitButton;
    
    public ButtonPanel(MotePanel motes, PacketPanel packets) {
	super();
	this.motes = motes;
	this.packets = packets;

	clearButton = new JButton("Clear All");
	selectButton = new JButton("Select All");
	pauseButton = new JButton("Pause");
	quitButton = new JButton("Quit"); 

	quitButton.addActionListener(new QuitListener());
	selectButton.addActionListener(new SelectListener(motes));
	clearButton.addActionListener(new ClearListener(motes));
	pauseButton.addActionListener(new PauseListener(packets));
	
	this.add(clearButton);
	this.add(selectButton);
	this.add(pauseButton);
	this.add(quitButton);
    }


    protected class QuitListener implements ActionListener {
	public QuitListener() {}
	
	public void actionPerformed(ActionEvent e) {
	    System.exit(0);
	}
    }

    protected class ClearListener implements ActionListener {
	private MotePanel motes;
	
	public ClearListener(MotePanel motes) {
	    this.motes = motes;
	}
	
	public void actionPerformed(ActionEvent e) {
	    motes.clearAll();
	    motes.repaint();
	}
    }

    protected class SelectListener implements ActionListener {
	private MotePanel motes;
	
	public SelectListener(MotePanel motes) {
	    this.motes = motes;
	}
	
	public void actionPerformed(ActionEvent e) {
	    motes.selectAll();
	    motes.repaint();
	}
    }

    protected class PauseListener implements ActionListener {
	private PacketPanel packets;
	
	public PauseListener(PacketPanel packets) {
	    this.packets = packets;
	}
	
	public void actionPerformed(ActionEvent e) {
	    packets.togglePause();
	}
    }

    

    
}
