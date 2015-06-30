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
import javax.swing.event.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.script.tree.*;
import net.tinyos.util.*;

public class VariablePanel extends JPanel {
  private JPanel labelPanel;
  private JPanel listPanel;
  private JList list;
  
  public VariablePanel() {
    super();
    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
	
    JLabel label = new JLabel("Shared Variables");
    label.setFont(TinyLook.boldFont());
    label.setAlignmentX(LEFT_ALIGNMENT);
    labelPanel = new JPanel();
    labelPanel.add(label);
    labelPanel.setBorder(new EtchedBorder());
	
    listPanel = makeListPanel();
    listPanel.setBorder(new EtchedBorder());

    add(labelPanel);
    add(listPanel);
  }

  private JPanel makeListPanel() {
    this.list = new JList();
    list.setFixedCellHeight(12);
    list.setFixedCellWidth(140);
	
    JScrollPane pane = new JScrollPane(list);
    pane.setSize(new Dimension(250, 220));
    pane.setPreferredSize(new Dimension(250, 220));
	
    JPanel panel = new JPanel();
    panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
    panel.add(pane);
    panel.setAlignmentY((float)1.0);
    return panel;
  }

  public void setVariables(Vector v) {
    list.setListData(v);
    repaint();
  }
  
  public static void main(String[] args) {
    JFrame frame = new JFrame();
    VariablePanel p = new VariablePanel();
    frame.getContentPane().add(p);
    frame.pack();
    frame.setVisible(true);

    Vector v = new Vector();
    v.addElement("A");
    v.addElement("B");
    v.addElement("C");
    p.setVariables(v);
  }


}
