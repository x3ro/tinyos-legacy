// $Id: ADCPlugin.java,v 1.3 2003/11/20 17:46:52 mikedemmer Exp $

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
 * Date:        December 11 2002
 * Desc:        Default Mote Plugin
 *              Implements functionality for viewing packets received
 *              by motes
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class ADCPlugin extends GuiPlugin implements SimConst {
  JTextField portTextField;
  JTextField valueTextField;
  private static final boolean DEBUG = false;
  
  protected static final String ADC_ATTR_NAME = "ADCPlugin.ADCAttribute";
  int count = 0;
  int count2 = 0;
  public void handleEvent(SimEvent event) {
    if (DEBUG) System.out.println("ADCPlugin handleEvent: "+event);
    if (event instanceof ADCDataReadyEvent) {
      if (DEBUG) System.out.println("\tADCPlugin processing ADCDataReadyEvent");
      ADCDataReadyEvent dev = (ADCDataReadyEvent)event;
      MoteSimObject mote = state.getMoteSimObject(dev.getMoteID());
      if (mote == null) return; // Shouldn't happen!
      ADCAttribute attr = (ADCAttribute)mote.getAttribute(ADC_ATTR_NAME);
	if (attr != null) {
	  if (DEBUG) System.out.println("\t\tSetting value to " + Integer.toHexString(dev.get_data()));
	  attr.ht.put(new Integer(dev.get_port()), new Integer(dev.get_data()));
	} else {
	  attr = new ADCAttribute();
	  if (DEBUG) System.out.println("\t\tSetting value to " + Integer.toHexString(dev.get_data()));
	  attr.ht.put(new Integer(dev.get_port()), new Integer(dev.get_data()));
	  mote.addAttribute(ADC_ATTR_NAME, attr);
	}
	
	motePanel.refresh();
    }
  }
  
  public void register() {
    JPanel parameterPane = new JPanel();
    parameterPane.setLayout(new GridLayout(2,2));

    JTextArea ta = new JTextArea(3,40);
    ta.setFont(tv.defaultFont);
    ta.setEditable(false);
    ta.setBackground(Color.lightGray);
    ta.setLineWrap(true);
    ta.setText("Magic ADC Values:\n\t65535 - random values generated for each call to read");

    // Create the port label and text field
    JLabel portLabel = new JLabel("Port (0-255)");
    portLabel.setFont(tv.defaultFont);
    portTextField = new JTextField(5);
    portTextField.setFont(tv.smallFont);
    portTextField.setEditable(true);
    parameterPane.add(portLabel);
    parameterPane.add(portTextField);

    // Create the value label and text field
    JLabel valueLabel = new JLabel("Value (0-65535)");
    valueLabel.setFont(tv.defaultFont);
    valueTextField = new JTextField(5);
    valueTextField.setFont(tv.smallFont);
    valueTextField.setEditable(true);
    parameterPane.add(valueLabel);
    parameterPane.add(valueTextField);

    // Create the set button
    JButton setButton = new JButton("Set ADC");
    setButton.addActionListener(new sbListener());
    setButton.setFont(tv.defaultFont);    

    pluginPanel.add(ta);
    pluginPanel.add(parameterPane);
    pluginPanel.add(setButton);
    pluginPanel.revalidate();
  }
  public void deregister() {}

  class ADCAttribute implements Attribute {    
    Hashtable ht = new Hashtable();
    public String toString() {
      String s = "";
      Enumeration e = ht.keys();
      while (e.hasMoreElements()) {
	Integer port = (Integer)e.nextElement();
	Integer value = (Integer)ht.get(port);
	s += "port "+port.toString()+":"+"0x"+Integer.toHexString(value.intValue())+" ";
      }
      return s;
    }
    void draw(Graphics graphics, int x, int y) {
      Enumeration e = ht.keys();
      while (e.hasMoreElements()) {
	Integer port = (Integer)e.nextElement();
	Integer value = (Integer)ht.get(port);
	String s = "port "+port.toString()+":"+"0x"+Integer.toHexString(value.intValue());
	graphics.drawString(s, x, y);
	y += 10;
      }
    }
  }

  public void draw(Graphics graphics) {
    Iterator it = state.getMoteSimObjects().iterator();
    graphics.setFont(tv.smallFont);
    graphics.setColor(Color.blue);
    while (it.hasNext()) {
      MoteSimObject mote = (MoteSimObject)it.next();
      if (!mote.isVisible()) {
	continue;
      }
      ADCAttribute attr = (ADCAttribute)mote.getAttribute(ADC_ATTR_NAME);
      if (attr != null) {
	MoteCoordinateAttribute coordinate = mote.getCoordinate();
	int x = (int)cT.simXToGUIX(coordinate.getX());
        x += (int)(cT.simXToGUIX(mote.getObjectSize()));
        int y = (int)cT.simYToGUIY(coordinate.getY());
	attr.draw(graphics, x, y);
      }
    }
  }

  public String toString() {
    return "ADC Readings";
  }
    
  class sbListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      int port;
      int value;
      try {
	port = Integer.parseInt(portTextField.getText());
	value = Integer.parseInt(valueTextField.getText());
      } catch (NumberFormatException exception) {
	tv.setStatus("Invalid paramters entered");
	return;
      }
      if ((port < 0) || (port > 255)) {
	tv.setStatus("Port " + port + " out of range");
	return;
      }
      if ((value < 0) || (value > 65535)) {
	tv.setStatus("Value " + value + " out of range");
	return;
      }
      tv.setStatus("Setting ADC values for selected mote(s)");
      Iterator it = state.getSelectedSimObjects().iterator();
      try {
	while (it.hasNext()) {
	  SimObject so = (SimObject)it.next();
	  if (so instanceof MoteSimObject) {
	    MoteSimObject m = (MoteSimObject) so;
	    simComm.sendCommand(new SetADCPortValueCommand((short)m.getID(), 0L, (byte)port, (short)value));
	  }
	} 
      } catch (java.io.IOException ioe) {
	System.err.println("Cannot send command: "+ioe);
      }
    }
  }
}


