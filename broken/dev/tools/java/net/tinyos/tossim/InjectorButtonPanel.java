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
 * Date:        Sept 28 2001
 * Desc:        Template for classes.
 *
 */

package net.tinyos.tossim;

import net.tinyos.packet.*;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.tree.*;

public class InjectorButtonPanel extends JPanel {
    private InjectorPacketPanel packets;
    private NetworkInjector network;

    private JButton quitButton;
    private JButton injectButton;


    public InjectorButtonPanel() {super();}

    public InjectorButtonPanel(InjectorPacketPanel packets, NetworkInjector network) {
	this.packets = packets;
	this.network = network;
	quitButton = makeQuitButton();
	injectButton = makeInjectButton();

	add(quitButton);
	add(injectButton);
    }


    public void sendPacket() {
	TOSPacket packet = packets.getPacket();
	if (packet != null) {
	    network.sendPacket(packet);
	}
	else {
	    System.err.println("No packet selected.");
	}
    }

    private JButton makeQuitButton() {
	JButton button = new JButton("Quit");
	button.addActionListener(new QuitListener());
	return button;
    }

    private JButton makeInjectButton() {
	JButton button = new JButton("Inject");
	button.addActionListener(new InjectListener(this));
	return button;
    }

    protected class QuitListener implements ActionListener {
	public QuitListener() {}
	
	public void actionPerformed(ActionEvent e) {
	    System.exit(0);
	}
    }

    protected class InjectListener implements ActionListener {
	private InjectorButtonPanel panel;
	
	public InjectListener(InjectorButtonPanel panel) {
	    this.panel = panel;
	}
	
	public void actionPerformed(ActionEvent e) {
	    panel.sendPacket();
	}
    }
}

