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
import javax.swing.*;
import javax.swing.event.*;

public class PacketSelectionListener implements ListSelectionListener {
    private static JDialog dialog;
    private PacketPanel panel;
    
    public PacketSelectionListener(PacketPanel panel) {
	this.panel = panel;
    }
    
    public void valueChanged(ListSelectionEvent e) {
	int index = e.getFirstIndex();
	Point p = null;

	//System.out.println("event e = " + e);
	
	if (dialog != null) {
	    p = dialog.getLocation();
	    //System.out.println("point p = " + p);
	    dialog.dispose();
	}
	
	dialog = new PacketDialog((RFMPacket)panel.getFiltered().elementAt(index));
	if (p != null) {
	    dialog.setLocation(p);
	}
	
	dialog.show();
    }
}

