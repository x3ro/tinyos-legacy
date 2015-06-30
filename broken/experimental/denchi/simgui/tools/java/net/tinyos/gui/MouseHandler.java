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
 * Authors:	Phil Levis
 *              Dennis Chi (Edited after October 15)
 * Date:        October 11 2002
 * Desc:        Template for Java classes in the sim package.
 *
 */

package net.tinyos.gui;

import java.awt.*;
import java.awt.event.*;
import java.util.*;

/**
 * The mouse handler handles mouse events from the user. At the moment, it only supports
 * the selecting and dragging of motes on the panel.
 */

public class MouseHandler implements MouseListener, MouseMotionListener {

    private DoubleBufferPanel bufferPanel = null;
    private BaseGUIPlugin graphicPanel = null;
    private Mote currentMote = null;
    private Mote tempMote = null;
    private boolean active = false;
	
    public MouseHandler(DoubleBufferPanel bufferPanel,
			BaseGUIPlugin graphicPanel) {
	this.bufferPanel = bufferPanel;
	this.graphicPanel = graphicPanel;
    }

    public Mote currentMote() {
	return currentMote;
    }
    
    private void setCurrent(Mote m) {
	if (currentMote != null) {
	    currentMote.setColor(Mote.BASIC_COLOR);
	}
	currentMote = m;
	if (currentMote != null) {
	    m.setColor(Mote.SELECTED_COLOR);
	}
	graphicPanel.refresh();
    }
	
    public void mousePressed(MouseEvent e) {
	System.err.println("Mouse pressed.");
	if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	    Mote m = bufferPanel.getMote(e.getX(), e.getY());
	    setCurrent(m);
	    active = true;
	}
    }

    public void mouseReleased(MouseEvent e) {
	System.err.println("Mouse released.");
	if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	    boolean wasActive = active;
	    active = false;
	    if (wasActive) {bufferPanel.refresh();}
	}
    }
	
    public void mouseEntered(MouseEvent e) {/* do nothing */}
	
    public void mouseExited(MouseEvent e) {/* do nothing */}
	
    public void mouseClicked(MouseEvent e) {
	System.err.println("Mouse clicked.");
	Mote m = bufferPanel.getMote(e.getX(), e.getY());
	// On left mouseclock, select the node
	if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	    setCurrent(m);
	}
	// On middle mouseclick, do nothing for now
	else if ((e.getModifiers() & MouseEvent.BUTTON2_MASK) != 0) {
	    //if (m != null) {
	    //System.err.println("Removing mote.");
	    //graphicPanel.removeMote(m);
	    //}
	}
	// On right mouseclick, do nothing for now
	else if ((e.getModifiers() & MouseEvent.BUTTON3_MASK) != 0) {
	    //if (m == null) {
	    //System.err.println("Placing new mote.");
	    //double x = bufferPanel.panelXToMoteX((double)e.getX());
	    //double y = bufferPanel.panelYToMoteY((double)e.getY());
	    //graphicPanel.addMote(x, y);
	    //}
	}
	active = false;
    }
	

    public void mouseDragged(MouseEvent e) {
	System.err.println("Mouse dragged.");
	if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	    if (currentMote != null && active) {
		bufferPanel.setMoteXY(currentMote, e.getX(), e.getY());
		graphicPanel.refresh();
	    }
	}
    }
	
    public void mouseMoved(MouseEvent e) {
	    
    }
	
}

