/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

// $Id: oscilloscope.java,v 1.1.1.1 2007/11/05 19:10:44 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * File: oscilloscope.java
 *
 * Description:
 * Displays data coming from the apps/oscilloscope application.
 *
 * Requires that the SerialForwarder is already started.
 *
 * @author Jason Hill and Eric Heien
 */


package com.moteiv.oscope;


import net.tinyos.util.*;
import net.tinyos.message.MoteIF;

import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

public class oscilloscope {


    GraphPanel panel;
    ControlPanel controlPanel;
    ScopeDriver driver;
    JPanel contentPane;
    public oscilloscope(MoteIF m) { 
	super();
	mainFrame = new JFrame("Oscilloscope");
	contentPane = new JPanel(new BorderLayout());
	panel = new GraphPanel(); 
	controlPanel = new ControlPanel(panel);
	driver = new ScopeDriver(m, panel);
	controlPanel.setScopeDriver(driver);
	contentPane.add("Center", panel); 
	contentPane.add("South", controlPanel); 
	mainFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);	
	mainFrame.setSize( getSize() );
	mainFrame.getContentPane().add("Center", new JScrollPane(contentPane));
	mainFrame.show();
	mainFrame.repaint(1000);
	panel.repaint();
	mainFrame.addWindowListener
	    (
	     new WindowAdapter()
		 {
		     public void windowClosing    ( WindowEvent wevent )
		     {
			 System.exit(0);
		     }
		 }
	     );
    }

    public oscilloscope() { 
	this(new MoteIF(PrintStreamMessenger.err, oscilloscope.group_id));
    }

    JFrame mainFrame;

    // If specified as -1, then reset messages will only work properly
    // with the new TOSBase base station
    static int group_id = -1; 

    public static void main(String[] args) throws IOException {
	oscilloscope app;
        if (args.length == 1) {
	  group_id = (byte) Integer.parseInt(args[0]);
	  System.err.println("oscilloscope: Using group ID "+group_id);
	  System.err.println("Note: group id should not be specified if you're using a TOSBase base station");
	}
	try {
	    UIManager.setLookAndFeel("com.sun.java.swing.plaf.windows.WindowsLookAndFeel");
	} catch (InstantiationException e) {
	} catch (ClassNotFoundException e) {
	} catch (UnsupportedLookAndFeelException e) {
	} catch (IllegalAccessException e) {
	}
	
	app = new oscilloscope();
    }
    public Dimension getSize()
    {
	return new Dimension(600, 600);
    }

}

