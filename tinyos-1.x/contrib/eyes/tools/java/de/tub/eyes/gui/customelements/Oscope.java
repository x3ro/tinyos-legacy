// $Id: Oscope.java,v 1.2 2005/11/02 20:43:29 twimmer Exp $

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



package de.tub.eyes.gui.customelements;

import net.tinyos.util.*;

import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

import de.tub.eyes.model.DataPoint;

public class Oscope extends JPanel implements ActionListener, ItemListener, ChangeListener {

    JButton timeout = new JButton("Control Panel");
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
    JButton debug = new JButton("Debug");
    JCheckBox showLegend = new JCheckBox("Show Legend", true);
    JCheckBox connect_points = new JCheckBox("Connect Datapoints", true);
    JCheckBox YAxisHex = new JCheckBox("hex Y Axis", false);
    JCheckBox scrolling = new JCheckBox("Scrolling", false);
    JSlider time_location = new JSlider(0, 100, 100);

    public JTextField legendEdit[];
    public JCheckBox legendActive[];

    public JLabel high_pass_val= new JLabel("5");
    public JLabel low_pass_val = new JLabel("2");
    public JLabel cutoff_val = new JLabel("65");
    public JSlider high_pass= new JSlider(0, 30, 5);
    public JSlider low_pass = new JSlider(0, 30, 2);
    public JSlider cutoff = new JSlider(0, 4000, 65);

    public EGraphPanel panel;
    public JPanel controlPanel;

    private boolean DEBUG_MODE = false;

    JTextArea textArea;

    public Oscope() {
//      init();
    }

    public void addData(DataPoint dp) {
      panel.addData(dp);

      if(DEBUG_MODE == true) {
        String s = debugInfo(dp);
        //System.out.println("!!!!!!!!!!!!!!!!!!! Oscope.addData: " + s);

        textArea.append(s + "\n");

        //Make sure the new text is visible, even if there
        //was a selection in the text area.
        textArea.setCaretPosition(textArea.getDocument().getLength());
      }
    }
    public void removeID(Integer id) {
        panel.removeID(id);
    }

    public String debugInfo(DataPoint dp) {
      String ss = "Received Messages: \n";
      try {
        ss += "  [sourceaddr = Mote "+ getSource(dp)+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        ss += "  [seqno = "+ getSeqno(dp)+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        ss += "  [data = "+ getValue(dp)+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }

 //    System.out.println("in debugInfo() +++++++++++++++++++ " + ss);

      return ss;
    }

    public String getSource(DataPoint dp) {
      return String.valueOf(dp.getDataSet());
    }

    public String getSeqno(DataPoint dp) {
      return String.valueOf(dp.getX());
    }

    public String getValue(DataPoint dp) {
      return String.valueOf(dp.getY());
    }


    public void init() {
        time_location.addChangeListener(this);

	setLayout(new BorderLayout());
	panel = new EGraphPanel(this);
	add("Center", panel);
	controlPanel = new JPanel();
	add("South", controlPanel);

	JPanel x_pan = new JPanel();
	x_pan.setLayout(new GridLayout(5,1));
	x_pan.add(zoom_in_x);
	x_pan.add(zoom_out_x);
	x_pan.add(save_data);
	x_pan.add(editLegend);
	x_pan.add(clear_data);
        x_pan.add(debug);
	zoom_out_x.addActionListener(this);
	zoom_in_x.addActionListener(this);
	save_data.addActionListener(this);
	editLegend.addActionListener(this);
	clear_data.addActionListener(this);
        debug.addActionListener(this);
	controlPanel.add(x_pan);

	JPanel y_pan = new JPanel();
	y_pan.setLayout(new GridLayout(5,1));
	y_pan.add(zoom_in_y);
	y_pan.add(zoom_out_y);
	y_pan.add(load_data);
	y_pan.add(showLegend);
	y_pan.add(connect_points);
	zoom_out_y.addActionListener(this);
	zoom_in_y.addActionListener(this);
	load_data.addActionListener(this);
	showLegend.addItemListener(this);
	connect_points.addItemListener(this);
	controlPanel.add(y_pan);

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
	controlPanel.add(scroll_pan);

	//controlPanel.add(timeout);
	timeout.addActionListener(this);
	JPanel p = new JPanel();
	p.setLayout(new GridLayout(4, 1));
	p.add(YAxisHex); YAxisHex.addItemListener(this);
	p.add(scrolling); scrolling.addItemListener(this);
	p.add(time_location);
	p.add(timeout);
	controlPanel.add(p);

	//panel.repaint();
	//repaint();

	legendEdit = new JTextField[panel.NUM_CHANNELS];
	for( int i=0;i<panel.NUM_CHANNELS;i++ )
	    legendEdit[i] = new JTextField(128);

	legendActive = new JCheckBox[panel.NUM_CHANNELS];
	for( int i=0;i<panel.NUM_CHANNELS;i++ )
	    legendActive[i] = new JCheckBox("Plot "+(i+1));
    }

    public void destroy() {
        remove(panel);
        remove(controlPanel);
    }

    public void start() {
	panel.start();
    }

    public void stop() {
	panel.stop();
    }

    public void addDebugInfo(String s) {

    }

    public void actionPerformed(ActionEvent e) {
	Object src = e.getSource();
	for( int i=0;i<panel.NUM_CHANNELS;i++ ) {
	    if( legendEdit[i] == src ) {
		panel.dataLegend[i] = legendEdit[i].getText();
		panel.repaint( 100 );
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
	    panel.load_data();
	    panel.repaint();
	} else if (src == clear_data) {
	    panel.clear_data();
	    panel.repaint();
	} else if (src == save_data) {
	    panel.save_data();
	    panel.repaint();
	} else if (src == editLegend) {
	    JFrame legend = new JFrame("Edit Legend");
	    legend.setSize(new Dimension(200,200));
	    legend.setVisible(true);
	    Panel slp = new Panel();
	    slp.setLayout(new GridLayout(10,2));
	    for( int i=0;i<panel.NUM_CHANNELS;i++ ) {
		legendActive[i].setSelected( panel.legendActive[i] );
		slp.add( legendActive[i] );
		legendActive[i].addChangeListener(this);
		legendEdit[i].setText( panel.dataLegend[i] );
		slp.add( legendEdit[i] );
		legendEdit[i].addActionListener(this);
	    }
	    legend.getContentPane().add(slp);
	    legend.pack();
	    legend.repaint();
	} else if (src == debug) { // newly added by Chen

          //Make sure we have nice window decorations.
          JFrame.setDefaultLookAndFeelDecorated(true);

          //Create and set up the window.
          JFrame frame = new JFrame("Debug Information");

          textArea = new JTextArea(50, 20);
          textArea.setEditable(false);

          JScrollPane scrollPane = new JScrollPane(textArea,
                                                   JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
                                                   JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);

          frame.getContentPane().setLayout(new java.awt.BorderLayout());
          frame.getContentPane().add(scrollPane,java.awt.BorderLayout.CENTER);

          DEBUG_MODE = true;

          //Display the window.
          frame.pack();
          frame.show();

        } else if (src == timeout) {
          JFrame sliders = new JFrame("Filter Controls");
	    sliders.setSize(new Dimension(300,30));
	    sliders.setVisible(true);
	    Panel slp = new Panel();
	    slp.setLayout(new GridLayout(3,3));
	    slp.add(new Label("high_pass:"));
	    slp.add(high_pass);
	    slp.add(high_pass_val);
	    slp.add(new Label("low_pass:"));
	    slp.add(low_pass);
	    slp.add(low_pass_val);
	    slp.add(new Label("cutoff:"));
	    slp.add(cutoff);
	    slp.add(cutoff_val);
	    high_pass.addChangeListener(this);
	    low_pass.addChangeListener(this);
	    cutoff.addChangeListener(this);
	    sliders.getContentPane().add(slp);
	    sliders.pack();
	    sliders.repaint();
	}
    }

    public void itemStateChanged(ItemEvent e) {
	Object src = e.getSource();
	boolean on = e.getStateChange() == ItemEvent.SELECTED;
	if (src == scrolling) {
	    panel.sliding = on;
	} else if (src == showLegend) {
	    panel.legend = on;
	    panel.repaint(100);
	} else if (src == connect_points) {
	    panel.connectPoints = on;
	    panel.repaint(100);
	} else if (src == YAxisHex) {
	    panel.yaxishex = on;
	    panel.repaint(100);
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
	high_pass_val.setText("" + high_pass.getValue());
	cutoff_val.setText("" + cutoff.getValue());
	low_pass_val.setText("" + low_pass.getValue());
	for( int i=0;i<panel.NUM_CHANNELS;i++ )
	    if( src == legendActive[i] )
		panel.legendActive[i] = legendActive[i].isSelected();

	panel.repaint( 100 );
    }
    // If specified as -1, then reset messages will only work properly
    // with the new TOSBase base station
    static int group_id = -1;
}
