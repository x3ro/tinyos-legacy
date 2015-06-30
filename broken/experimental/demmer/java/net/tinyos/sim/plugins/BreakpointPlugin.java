// $Id: BreakpointPlugin.java,v 1.2 2003/10/20 22:35:57 mikedemmer Exp $

/*									tab:2
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
 * Authors:	Matt Welsh
 * Date:        6 Feb 2003
 * Desc:        Pauses simulation when certain events occur
 *
 */

/**
 * @author Matt Welsh
 */


package net.tinyos.sim.plugins;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class BreakpointPlugin extends GuiPlugin implements SimConst {

  private static final String msgTypes[] = { 
    "Current breakpoints", 
    "Add debug message breakpoint", 
    "Add radio message breakpoint" };

  private static final int MSGTYPE_NONE = 0;
  private static final int MSGTYPE_DEBUG = 1;
  private static final int MSGTYPE_RADIO = 2;

  private static final int MAX_BP_DISPLAY = 8;

  private JCheckBox cbSelectedOnly;
  private boolean selectedOnly = false;
  private JComboBox typeBox;
  private JPanel typeFields;
  private JButton setBreakpointButton, clearBreakpointButton;

  // Breakpoint list
  private int breakpointNum = 0;
  private JList bpList;
  private Vector breakpoints;
  private JScrollPane bpListPane;
  private DefaultListModel bpModel;
  private MessageList bpReason;
  private JPanel bpPanel;

  // Debug message match
  private JPanel debugMatchPane;
  private JTextField debugStringMatch;

  class breakpoint {
    int num;
    int type;
    Set moteset;
    String debugMatchString;
    boolean enabled;

    breakpoint(int num) {
      this.num = num;
      this.enabled = true;
    }

    public String toString() {
      String s = num+": ";
      switch (type) {
	case MSGTYPE_DEBUG:
	  s += "DebugMsg contains "+debugMatchString;
	  break;
	case MSGTYPE_RADIO:
	  s += "RadioMsg contains";
	  break;
      }
      if (moteset != null) {
	s += " (";
	Iterator it = moteset.iterator();
	while (it.hasNext()) {
	  s += ((MoteSimObject)it.next()).toString();
	}
	s += ")";
      }
      return s;
    }

    private void fire(String reason) {
      tv.pause();
      tv.setStatus("Breakpoint "+num+" fired: "+toString());
      bpReason.addMessage("Breakpoint "+num+" fired: "+reason);
      //bpPanel.revalidate();
      //pluginPanel.revalidate();
      pluginPanel.repaint();
    }

    void match(SimEvent event) {
      if (!enabled) return;
      if (type == MSGTYPE_DEBUG && event instanceof DebugMsgEvent) {
	DebugMsgEvent dmEvent = (DebugMsgEvent)event;
	if (debugMatchString == null && moteset == null) return;

	if ((debugMatchString == null ||
	      dmEvent.getMessage().indexOf(debugMatchString) != -1) &&
	    (moteset == null ||
	     moteset.contains(state.getMoteSimObject(dmEvent.getMoteID())))) {
	  fire("Debug message: ["+dmEvent.getMoteID()+"] "+dmEvent.toString());
	  return;
	}
      }
    }
  }

  public void handleEvent(SimEvent event) {
    Enumeration en = breakpoints.elements();
    while (en.hasMoreElements()) {
      breakpoint bp = (breakpoint)en.nextElement();
      bp.match(event);
    }
  }

  public void register() {

    // Selected only box
    cbSelectedOnly = new JCheckBox("Selected motes only", selectedOnly);
    cbSelectedOnly.setFont(tv.labelFont);

    // Breakpoint list
    breakpoints = new Vector();
    bpModel = new DefaultListModel();
    bpList = new JList(bpModel);
    bpList.setVisibleRowCount(MAX_BP_DISPLAY);
    bpList.setFixedCellHeight(15);
    bpList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    bpList.setFont(tv.defaultFont);
    bpList.setCellRenderer(new bpCellRenderer());
    bpList.setBackground(Color.white);
    bpListPane = new JScrollPane(bpList);
    bpReason = new MessageList(MAX_BP_DISPLAY-1, MAX_BP_DISPLAY*2);
    bpReason.addMessage("No breakpoints fired.");
    bpPanel = new JPanel();
    bpPanel.setLayout(new GridLayout(2,1));
    bpPanel.add(bpListPane);
    bpPanel.add(bpReason);

    // Debug match fields
    // XXX MDW Save this for radio msg layout
    //JPanel labelPane = new JPanel();
    //labelPane.setLayout(new GridLayout(0,1));
    //labelPane.add(new JLabel("Message contains:  "));
    //labelPane.add(new JLabel("Mote ID:"));
    //JPanel fieldPane = new JPanel();
    //fieldPane.setLayout(new GridLayout(0,1));
    //debugStringMatch = new JTextField(20);
    //if (debugMatchString != null) debugStringMatch.setText(debugMatchString);
    //debugMoteMatch = new JTextField(5);
    //if (debugMoteID != -1) debugMoteMatch.setText(new Integer(debugMoteID).toString());
    //fieldPane.add(debugStringMatch);
    //fieldPane.add(debugMoteMatch);
    debugMatchPane = new JPanel();
    debugMatchPane.add(new JLabel("Message contains:"));
    debugStringMatch = new JTextField(20);
    debugStringMatch.setEditable(true);
    debugMatchPane.add(debugStringMatch);

    // Overall layout gridbag
    GridBagLayout gb = new GridBagLayout();
    GridBagConstraints c = new GridBagConstraints();
    c.weightx = 1;
    c.weighty = 0.1;
    c.anchor = GridBagConstraints.NORTH;
    c.gridwidth = GridBagConstraints.REMAINDER;
    c.gridheight = 1;
    c.fill = GridBagConstraints.HORIZONTAL;
    pluginPanel.setLayout(gb);

    // Combo box and listener
    typeBox = new JComboBox(msgTypes);
    typeBox.setFont(tv.labelFont);
    typeBox.addActionListener(new tbListener());
    gb.setConstraints(typeBox, c);

    // Create typefields panel
    typeFields = new JPanel();
    typeFields.setLayout(new BorderLayout());
    c.weighty = 1.0;
    c.gridheight = GridBagConstraints.RELATIVE;
    c.fill = GridBagConstraints.BOTH;
    gb.setConstraints(typeFields, c);

    // Create button panel
    JPanel buttonPanel = new JPanel();
    setBreakpointButton = new JButton("Enable breakpoint");
    setBreakpointButton.setFont(tv.defaultFont);
    setBreakpointButton.addActionListener(new sbListener());
    clearBreakpointButton = new JButton("Disable breakpoint");
    clearBreakpointButton.addActionListener(new cbListener());
    clearBreakpointButton.setFont(tv.defaultFont);
    buttonPanel.add(setBreakpointButton);
    buttonPanel.add(clearBreakpointButton);
    c.weighty = 0.1;
    gb.setConstraints(buttonPanel, c);

    clearBreakpoint();
    setType(MSGTYPE_NONE);

    pluginPanel.add(typeBox);
    pluginPanel.add(typeFields);
    pluginPanel.add(buttonPanel);
    //bpPanel.revalidate();
    //pluginPanel.revalidate();

  }

  public void deregister() {
    clearBreakpoint();
  }

  public void draw(Graphics graphics) {
  }

  private void setType(int type) {
    typeFields.removeAll();

    switch (type) {
      case MSGTYPE_NONE:
	setBreakpointButton.setEnabled(true);
	clearBreakpointButton.setEnabled(true);
	typeFields.add(bpPanel, BorderLayout.NORTH);
	pluginPanel.revalidate();
	//typeFields.revalidate();
	break;

      case MSGTYPE_DEBUG:
	setBreakpointButton.setEnabled(true);
	clearBreakpointButton.setEnabled(false);
	typeFields.add(cbSelectedOnly, BorderLayout.NORTH);
	typeFields.add(debugMatchPane, BorderLayout.CENTER);
	pluginPanel.revalidate();
	//typeFields.revalidate();
	break;

      default:
	// Do nothing
    }

    pluginPanel.repaint();
  }

  private void setBreakpoint() {
    int bptype = typeBox.getSelectedIndex();
    if (bptype == MSGTYPE_NONE) {
      int index = bpList.getSelectedIndex();
      if (index == -1) return;
      breakpoint bp = (breakpoint)breakpoints.elementAt(index);
      bp.enabled = true;
      pluginPanel.repaint();
      tv.setStatus("Breakpoint "+index+" enabled.");
      return;
    }

    breakpoint bp = new breakpoint(breakpointNum++);
    bp.type = bptype;
    bpModel.addElement(bp);
    breakpoints.addElement(bp);

    switch (bptype) {
      case MSGTYPE_DEBUG:
	bp.debugMatchString = debugStringMatch.getText();
	if (cbSelectedOnly.isSelected()) {
	  bp.moteset = state.getSelectedMoteSimObjects();
	  if (bp.moteset.isEmpty()) bp.moteset = null;
	}
	tv.setStatus("Setting breakpoint: "+bp.toString());
      default:
	// Do nothing
    }
    pluginPanel.repaint();
  }

  private void clearBreakpoint() {
    int index = bpList.getSelectedIndex();
    if (index == -1) return;
    breakpoint bp = (breakpoint)breakpoints.elementAt(index);
    bp.enabled = false;
    pluginPanel.repaint();
    tv.setStatus("Breakpoint "+index+" disabled.");
  }

  class sbListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      setBreakpoint();
    }
  }
  class cbListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      clearBreakpoint();
    }
  }
  class tbListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      setType(typeBox.getSelectedIndex());
    }
  }

  class bpCellRenderer extends JLabel implements ListCellRenderer {
    public Component getListCellRendererComponent(JList list,
	Object value,            // value to display
	int index,               // cell index
	boolean isSelected,      // is the cell selected
	boolean cellHasFocus)    // the list and the cell have the focus
    {
      breakpoint bp = (breakpoint)value;
      if (isSelected) {
	setBackground(list.getSelectionBackground());
	setForeground(list.getSelectionForeground());
      }
      else {
	setBackground(list.getBackground());
	setForeground(list.getForeground());
      }
      if (bp.enabled) {
	setText(bp.toString());
      } else {
	setText("("+bp.toString()+")");
      }
      setEnabled(bp.enabled);
      setFont(tv.defaultFont);
      setOpaque(true);
      return this;
    }
  }

  public String toString() {
    return "Set breakpoint";
  }
}


