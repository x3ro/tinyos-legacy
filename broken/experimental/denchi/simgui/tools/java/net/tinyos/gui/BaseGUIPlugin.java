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
 *              Dennis Chi (Edited after October 15 for new simgui)
 * Date:        October 11 2002
 * Desc:        Panel that graphically displays the network.
 *
 */

package net.tinyos.gui;

import java.util.*;
import javax.swing.*;

import net.tinyos.gui.event.*;

/**
 * This is the base plugin for the simluation gui. Creates a panel to display the simulation network.
 *
 */

public class BaseGUIPlugin extends JPanel implements SimEventListener{
    
    private Vector motes = new Vector();
    private DoubleBufferPanel graphic;
    
    public BaseGUIPlugin() {
	super();
        graphic = new DoubleBufferPanel(this, 100, 100);
	add(graphic);
	
	JFrame frame = new JFrame("Sim");
	frame.getContentPane().add(this);
	frame.pack();
	frame.setVisible(true);
	
	SymWindow aSymWindow = new SymWindow();
	frame.addWindowListener(aSymWindow);
	
	//TestUpdateThread th = new TestUpdateThread(this);
	//th.start();
    }
    
    public DoubleBufferPanel getPanel () {
	return graphic;
    }

    public Vector getMotes() {
	//Vector v = new Vector();
	return SimDriver.base.getMotes();
	//Enumeration e = motes.elements();
	//while (e.hasMoreElements()) {
	//  v.addElement(e.nextElement());
	//}
	//return v;
    }
    
    public void refresh() {
	graphic.refresh();
    }
    
    public void handleEvent (SimEvent event) {
	//System.err.println ("BaseGUIPlugin: received event");
	if (event instanceof SimPaintEvent) {
	    refresh();
	}
      
    }

    class SymWindow extends java.awt.event.WindowAdapter {
	public void windowClosing(java.awt.event.WindowEvent event) {
	    Object object = event.getSource();
	    //if (object == MainFrame.this)
	    BaseGUIPlugin_windowClosing(event);
	}
    }
    
    void BaseGUIPlugin_windowClosing(java.awt.event.WindowEvent event) {
	//MainClass.displayManager.stopDisplayThread();
	System.exit(0);
    }

    private class TestUpdateThread extends Thread {
	private BaseGUIPlugin panel;
	
	public TestUpdateThread(BaseGUIPlugin panel) {
	    this.panel = panel;
	}

	public void run() {
	    while (true) {
		Vector motes = panel.getMotes();
		Enumeration enum = motes.elements();
		while (enum.hasMoreElements()) {
		    Mote m = (Mote)enum.nextElement();
		    m.setX(m.getX() + 1.0);
		    m.setY(m.getY() + 1.0);
		}
		panel.refresh();
		try {
		    Thread.sleep(500);
		    System.err.print(".");
		}
		catch (InterruptedException e) {
		    // do nothing.
		}
	    }
	}
    }
}

