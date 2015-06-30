// $Id: AdvancedPanel.java,v 1.5 2004/03/13 02:05:13 scipio Exp $

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

public class AdvancedPanel extends JPanel implements VMOptions {
  private JLabel placeholder;
  private Vector options;
  private OptionField opStack, rStack, buffer, packet, grain;
  private Vector paths;
  
  public AdvancedPanel() {
	super();
	setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	options = new Vector();
	add(basicGroup());
	add(propagateGroup());
	paths = new Vector();
	setAlignmentY((float)1.0);
  }

  private void addOption(JPanel panel, OptionField field) {
	options.add(field);
	panel.add(field);
  }
    
  public static void main(String[] args) {
	JFrame frame = new JFrame();
	AdvancedPanel p = new AdvancedPanel();
	frame.getContentPane().add(p);
	frame.pack();
	frame.setVisible(true);
  }

  public JPanel basicGroup() {
	JPanel panel = new JPanel();
	JLabel label = new JLabel("Locks");
	opStack = new OptionField("OpStack Depth");
    opStack.setText("16");
	rStack = new OptionField("RStack Depth");
    rStack.setText("8");
    buffer = new OptionField("Buffer Size");
    buffer.setText("10");
	packet = new OptionField("Program Size");
    packet.setText("24");
	grain = new OptionField("Exec Grain");
	
	panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
	panel.add(label);
	addOption(panel, opStack);
	addOption(panel, rStack);
	addOption(panel, buffer);
	addOption(panel, packet);
	addOption(panel, grain);
	
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

  public void addSearchPath(String path) {
    paths.addElement(path);
  }
  
  public String getOpDepth() {
    return opStack.getValue();
  }

  public String getCallDepth() {
    return rStack.getValue();
  }

  public String getBufLen() {
    return buffer.getValue();
  }

  public String getProgramSize() {
    return packet.getValue();
  }

  public Enumeration getSearchPaths() {
    return paths.elements();
  }
  

  private class OptionField extends JPanel {
    private JLabel label;
    private JTextField field;
    
    public OptionField(String name) {
      super();
      setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
      label = new JLabel(name);
      label.setAlignmentX((float)1.0);
      add(label);
      field = new JTextField(4);
      field.setAlignmentX((float)0.0);
      add(field);
    }
    
    public void setText(String text) {
      field.setText(text);
    }
    
    protected String getValue() {
      return field.getText();
    }
  }
}
