// $Id: SimObjectPopupMenu.java,v 1.4 2004/01/10 00:58:22 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Nelson Lee
 * Date:        December 05, 2002
 * Desc:        
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import net.tinyos.sim.event.*;

public class SimObjectPopupMenu extends JPopupMenu {
    SimEventBus eventBus;
    MotePanel motePanel;
    SimState state;

    SimObject selectedSimObject;
    
    public SimObjectPopupMenu(TinyViz tv) {
	this.eventBus = tv.getSimDriver().getEventBus();
	this.state = tv.getSimDriver().getSimState();
	this.motePanel = tv.getMotePanel();

	add(new DeleteFunctionalityPopupMenuItem(this));
    }
  
    public void setSimObjectSelected(SimObject s) {
	synchronized (state) {
	    selectedSimObject = s;
	}
    }

    public SimObject getSelectedSimObject() {
	synchronized (state) {
	    SimObject s = selectedSimObject;
	    selectedSimObject = null;
	    return s;
	}
    }

    private class DeleteFunctionalityPopupMenuItem extends SimObjectPopupMenuItem {
	public DeleteFunctionalityPopupMenuItem(SimObjectPopupMenu popup) {
	    super("Delete", popup);
	    addActionListener(new DeleteFunctionalityActionListener());	    
	}
	
	
	private class DeleteFunctionalityActionListener implements ActionListener {
	    public void actionPerformed(ActionEvent e) {
		synchronized (eventBus) {
		    SimObject s = popup.getSelectedSimObject();
		    state.removeSimObject(s);
		    motePanel.refresh();
		}
	    }
	}
    }
}

