/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

// $Id: ControlPanel.java,v 1.1.1.1 2007/11/05 19:10:44 jpolastre Exp $

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
 * File: ControlPanel.java
 *
 * Description:
 * Displays data coming from the apps/ControlPanel application.
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

public class ControlPanel extends JPanel implements ActionListener, ItemListener, ChangeListener {

    JButton move_up = new JButton("^");
    JButton move_down = new JButton("v");
    JButton move_right = new JButton(">");
    JButton move_left = new JButton("<");
    JButton zoom_out_x = new JButton("Zoom Out X");
    JButton zoom_in_x = new JButton("Zoom In X");
    JButton zoom_out_y = new JButton("Zoom Out Y");
    JButton zoom_in_y = new JButton("Zoom In Y");
    JButton reset = new JButton("Reset");
    JButton save_data = new JButton("Save Data");
    JButton load_data = new JButton("Load Data");
    JButton editLegend = new JButton("Edit Legend");
    JButton clear_data = new JButton("Clear Dataset");
    JCheckBox showLegend = new JCheckBox("Show Legend", true);
    JCheckBox connect_points = new JCheckBox("Connect Datapoints", true);
    JCheckBox YAxisHex = new JCheckBox("hex Y Axis", false);
    JCheckBox scrolling = new JCheckBox("Scrolling", false);
    JSlider time_location = new JSlider(0, 100, 100);
    
    public Hashtable legendEdit;
    public Hashtable legendActive;

    ScopeDriver scopeDriver = null;

    /**
     * Get the ScopeDriver value.
     * @return the ScopeDriver value.
     */
    public ScopeDriver getScopeDriver() {
	return scopeDriver;
    }

    /**
     * Set the ScopeDriver value.
     * @param newScopeDriver The new ScopeDriver value.
     */
    public void setScopeDriver(ScopeDriver newScopeDriver) {
	this.scopeDriver = newScopeDriver;
    }

    
    GraphPanel panel;

    public ControlPanel(GraphPanel _panel) { 
	panel = _panel; 
	legendEdit = new Hashtable();
	legendActive = new Hashtable(); 

	// Compared with the previous implementation, we are replacing the
	// heavyweight components (java.awt.Panel) with the lightweight Swing
	// equivalent.  This should hopefully allow for more flexible use of
	// this control panel 
        time_location.addChangeListener(this);
	JPanel x_pan = new JPanel();
	x_pan.setLayout(new GridLayout(5,1));
	x_pan.add(zoom_in_x);
	x_pan.add(zoom_out_x); 
	x_pan.add(save_data); 
	x_pan.add(editLegend); 
	x_pan.add(clear_data); 
	zoom_out_x.addActionListener(this);
	zoom_in_x.addActionListener(this);
	save_data.addActionListener(this);
	editLegend.addActionListener(this);
	clear_data.addActionListener(this);
	add(x_pan);

	JPanel y_pan = new JPanel();
	y_pan.setLayout(new GridLayout(5,1));
	y_pan.add(zoom_in_y);
	y_pan.add(zoom_out_y); 
	y_pan.add(load_data); 
	showLegend.setSelected(panel.isLegendEnabled());
	y_pan.add(showLegend);
	connect_points.setSelected(panel.isConnectPoints());
	y_pan.add(connect_points); 
	zoom_out_y.addActionListener(this);
	zoom_in_y.addActionListener(this);
	load_data.addActionListener(this);
	showLegend.addItemListener(this);
	connect_points.addItemListener(this);
	add(y_pan);

	JPanel scroll_pan = new JPanel();
	move_up.addActionListener(this);
	move_down.addActionListener(this);
	move_right.addActionListener(this);
	move_left.addActionListener(this);
	reset.addActionListener(this);
	GridBagLayout		g = new GridBagLayout();
	GridBagConstraints	c = new GridBagConstraints();
	scroll_pan.setLayout(g);
	c.gridx = 1;
	c.gridy = 0;
	g.setConstraints( move_up, c );
	scroll_pan.add(move_up);
	c.gridx = 0;
	c.gridy = 1;
	g.setConstraints( move_left, c );
	scroll_pan.add(move_left);
	c.gridx = 1;
	c.gridy = 1;
	g.setConstraints( reset, c );
	scroll_pan.add(reset);
	c.gridx = 2;
	c.gridy = 1;
	g.setConstraints( move_right, c );
	scroll_pan.add(move_right);
	c.gridx = 1;
	c.gridy = 2;
	g.setConstraints( move_down, c );
	scroll_pan.add(move_down);
	add(scroll_pan);
	JPanel p = new JPanel();
	p.setLayout(new GridLayout(4, 1));
	YAxisHex.setSelected(panel.isHexAxis());
	p.add(YAxisHex); YAxisHex.addItemListener(this);
	p.add(scrolling); scrolling.addItemListener(this);
	p.add(time_location);
	add(p);
    }

    protected void createLegendEdit(JPanel p) {
	JCheckBox act;
	JTextField leg; 
	GridBagLayout g = new GridBagLayout();  
	GridBagConstraints constraints = new GridBagConstraints();
	p.setLayout(g);
	if (panel == null) { 
	    return; 
	}
	Vector channels = panel.getChannels(); 
	legendActive.clear();
	legendEdit.clear();
	for ( int i= 0; i< channels.size(); i++) { 
	    Channel c = (Channel) channels.elementAt(i); 
	    leg = new JTextField(30); 
	    leg.setText(c.getDataLegend());
	    legendEdit.put(leg, c); 
	    leg.addActionListener(this);
	    act = new JCheckBox("Channel "+(i+1)); 
	    act.setSelected(c.isActive());
	    legendActive.put(act, c); 
	    act.addChangeListener(this);
	    constraints.gridwidth = GridBagConstraints.RELATIVE;
	    g.setConstraints(act, constraints);
	    p.add(act);
	    constraints.gridwidth = GridBagConstraints.REMAINDER;
	    g.setConstraints(leg, constraints);
	    p.add(leg); 
	}
    }
    // No longer necessary?  
    /*    public void destroy() {
	  remove(panel);
	  remove(controlPanel);
	  }
	  public void start() {
	  panel.start();
	  }
	  
	  public void stop() {
	  panel.stop();
	  }
    */
	
    public void actionPerformed(ActionEvent e) {
	Object src = e.getSource();
	Object c = legendEdit.get(src);
	if (c != null) { 
	    if (c instanceof Channel) { 
		((Channel)c).setDataLegend(((JTextField)src).getText());
		panel.repaint(100); 
	    }
	}

	if (src == zoom_out_x) {
	    panel.zoom_out_x();
	    panel.repaint();
	} else if (src == zoom_in_x) {
	    panel.zoom_in_x();
	    panel.repaint();
	} else if (src == zoom_out_y) {
	    panel.zoom_out_y();
	    panel.repaint();
	} else if (src == zoom_in_y) {
	    panel.zoom_in_y();
	    panel.repaint();
	} else if (src == move_up) {
	    panel.move_up();
	    panel.repaint();
	} else if (src == move_down) {
	    panel.move_down();
	    panel.repaint();
	} else if (src == move_right) {
	    panel.move_right();
	    panel.repaint();
	} else if (src == move_left) {
	    panel.move_left();
	    panel.repaint();
	} else if (src == reset) {
	    panel.reset();
	    panel.repaint();
	} else if (src == load_data) {
	    //	    if (scopeDriver != null) 
	    //	scopeDriver.load_data();
	    //	    panel.load_data();
	    panel.repaint();
	} else if (src == clear_data) {
	    if (scopeDriver != null) 
		scopeDriver.clear_data();
	    panel.clear_data();
	    panel.repaint();
	} else if (src == save_data) {
	    panel.save_data();
	    panel.repaint();
	} else if (src == editLegend) {
	    JFrame legend = new JFrame("Edit Legend");
	    legend.setSize(new Dimension(200,500));
	    legend.setVisible(true);
	    JPanel slp = new JPanel();
	    //	    slp.setLayout(//new GridLayout(0,2)
	    //	  new FlowLayout(FlowLayout.LEFT)
	    //);
	    createLegendEdit(slp);
	    legend.getContentPane().add(new JScrollPane(slp));
	    legend.pack();
	    legend.show();
	    legend.repaint();
	}
    }


    public void itemStateChanged(ItemEvent e) {
	Object src = e.getSource();
	boolean on = e.getStateChange() == ItemEvent.SELECTED;
	if (src == scrolling) {
	    panel.setSliding(on);
	} else if (src == showLegend) {
	    panel.setLegendEnabled(on);
	} else if (src == connect_points) {
	    panel.setConnectPoints(on);
	} else if (src == YAxisHex) {
	    panel.setHexAxis(on);
	}
    }

    public void stateChanged(ChangeEvent e){
	Object src = e.getSource();
	if(src == time_location) {
	  double percent = (time_location.getValue() / 100.0);
	  int diff = panel.end - panel.start;
	  panel.end = panel.minimum_x + (int)((panel.maximum_x - panel.minimum_x) * percent);
	  panel.start = panel.end - diff;
	}
	/*
	  for( int i=0;i<panel.NUM_CHANNELS;i++ )
	  if( src == legendActive[i] )
	  panel.legendActive[i] = legendActive[i].isSelected();
	*/
	Object c = legendActive.get(src); 
	if ((c != null) &&
	    (c instanceof Channel)) {
	    ((Channel)c).setActive(((JCheckBox)src).isSelected());
	}
	panel.repaint( 100 );
    }

}

