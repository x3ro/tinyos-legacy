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
 * Desc:        Top-level class for TOSSIM networking GUI.
 *
 */

package net.tinyos.tossim;

import java.awt.*;
import java.io.*;
import java.net.*;
import javax.swing.*;

import net.tinyos.packet.*;

public class TossimInjector extends JFrame {
    private InjectorButtonPanel buttons;
    private InjectorPacketPanel packets;
    private NetworkInjector network;
    
    public TossimInjector() throws IOException {
	super("Binah");
	packets = new InjectorPacketPanel();
	network = new NetworkInjector();
	buttons = new InjectorButtonPanel(packets, network);
	BoxLayout layout = new BoxLayout(this.getContentPane(), BoxLayout.Y_AXIS);
        this.getContentPane().setLayout(layout);

	this.getContentPane().add(packets);
	this.getContentPane().add(buttons);
	pack();
	setVisible(true);
    }

    
    public static void main(String[] args) throws Exception {
	TossimInjector inject = new TossimInjector();
    }
    
}
