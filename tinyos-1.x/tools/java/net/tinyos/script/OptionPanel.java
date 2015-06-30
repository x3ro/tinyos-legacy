// $Id: OptionPanel.java,v 1.1 2004/03/22 02:15:48 scipio Exp $

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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Sep 26 2003
 * Desc:        Main window for VM builder
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class OptionPanel extends JPanel {
    private JLabel placeholder;
    
    public OptionPanel() {
	super();
	setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	add(lockGroup());
	add(adHocGroup());
	add(sensorGroup());
	add(propagateGroup());
	setAlignmentY((float)1.0);
    }

    public static void main(String[] args) {
	JFrame frame = new JFrame();
	OptionPanel p = new OptionPanel();
	frame.getContentPane().add(p);
	frame.pack();
	frame.setVisible(true);
    }

    public JPanel lockGroup() {
	JPanel panel = new JPanel();
	ButtonGroup g = new ButtonGroup();
	JRadioButton none = new JRadioButton("None");
	JRadioButton opt = new JRadioButton("Optimistic");
	JRadioButton pess = new JRadioButton("Pessimistic   ");
	JLabel label = new JLabel("Locks");
	
	g.add(none);
	g.add(opt);
	g.add(pess);


	panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
	panel.add(label);
	panel.add(none);
	panel.add(opt);
	panel.add(pess);
	panel.setAlignmentY((float)0.0);
	return panel;
    }

    public JPanel adHocGroup() {
	JPanel panel = new JPanel();
	ButtonGroup g = new ButtonGroup();
	JRadioButton none = new JRadioButton("Beacon");
	JRadioButton opt = new JRadioButton("Snooping");
	JRadioButton pess = new JRadioButton("Link-Estimate   ");
	JLabel label = new JLabel("Ad-hoc Routing");
	
	g.add(none);
	g.add(opt);
	g.add(pess);

	panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
	panel.add(label);
	panel.add(none);
	panel.add(opt);
	panel.add(pess);
	panel.setAlignmentY((float)0.0);
	return panel;
    }

    public JPanel sensorGroup() {
	JPanel panel = new JPanel();
	JRadioButton none = new JRadioButton("Light");
	JRadioButton opt = new JRadioButton("Temp");
	JRadioButton pess = new JRadioButton("Microphone   ");
	JRadioButton accelX = new JRadioButton("Accel");
	JRadioButton magX = new JRadioButton("Mag");
	JLabel label = new JLabel("Sensors");
	
	panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
	panel.add(label);
	panel.add(none);
	panel.add(opt);
	panel.add(pess);
	panel.add(accelX);
	panel.add(magX);
	panel.setAlignmentY((float)0.0);
	return panel;
    }

    public JPanel propagateGroup() {
	JPanel panel = new JPanel();
	ButtonGroup g = new ButtonGroup();
	JRadioButton none = new JRadioButton("Steady-Rate");
	JRadioButton opt = new JRadioButton("Density-Adaptive   ");
	JLabel label = new JLabel("Propagation");
	
	g.add(none);
	g.add(opt);

	panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
	panel.add(label);
	panel.add(none);
	panel.add(opt);
	panel.setAlignmentY((float)0.0);
	return panel;
    }
}
