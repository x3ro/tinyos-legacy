// $Id: MoteMessageList.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

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
 * Date:        Feb 9 2003
 * Desc:        Message display list with mote tracking
 *
 */

/**
 * @author Matt Welsh
 */


package net.tinyos.sim;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

/**
 * An extension to MessageList that associates a MoteSimObject
 * with each entry. The user can specify that only messages from a
 * given selected set of motes should be displayed.
 */
public class MoteMessageList extends MessageList implements SimConst {
  private boolean selectedOnly = false;
  private Set selected = null;

  private DefaultListModel selectedModel;

  public MoteMessageList() {
    this(DEFAULT_MAX_DISPLAY, DEFAULT_MAX_MESSAGES);
  }

  public MoteMessageList(int maxDisplay, int maxMessages) {
    super(maxDisplay, maxMessages);
    selectedModel = new DefaultListModel();
    //msgList.setCellRenderer(new mmlRenderer());
  }

  public void setSelectedOnly(boolean value) {
    this.selectedOnly = value;
    if (selectedOnly) 
      msgList.setModel(selectedModel);
    else 
      msgList.setModel(msgModel);
    msgList.repaint();
  }

  public synchronized void setSelected(Set selected) {
    this.selected = selected;
    selectedModel.clear();
    if (selected == null) return;
    Enumeration e = msgModel.elements();
    while (e.hasMoreElements()) {
      mmlEntry mml = (mmlEntry)e.nextElement();
      if (selected != null && 
	  (mml.mote == null || selected.contains(mml.mote)))
	selectedModel.addElement(mml);
    }
    msgList.repaint();
  }

  public synchronized void clear() {
    msgModel.clear();
    selectedModel.clear();
    msgList.repaint();
  }

  public synchronized void addMessage(String msg) {
    addMessage(msg, null, defaultForeground, defaultBackground);
  }

  public synchronized void addMessage(String msg, Color fgColor, Color bgColor) {
    addMessage(msg, null, fgColor, bgColor);
  }

  public synchronized void addMessage(String msg, MoteSimObject mote) {
    addMessage(msg, mote, defaultForeground, defaultBackground);
  }

  public synchronized void addMessage(String msg, MoteSimObject mote,
      Color fgColor, Color bgColor) {

    mmlEntry mml = new mmlEntry(msg, mote, fgColor, bgColor);
    msgModel.addElement(mml);
    if (msgModel.size() > maxMessages) msgModel.removeElementAt(0);
    if (selected != null && 
	(mml.mote == null || selected.contains(mml.mote))) {
      selectedModel.addElement(mml);
      if (selectedModel.size() > maxMessages) selectedModel.removeElementAt(0);
    }
    msgList.repaint();
  }

  class mmlEntry extends MessageList.mlEntry {
    public MoteSimObject mote;

    mmlEntry(String msg, MoteSimObject mote, Color fgColor, Color bgColor) {
      super(msg, fgColor, bgColor);
      this.mote = mote;
      if (mote != null) this.msg = mote.toString() + " " + this.msg;
    }
  }

  // This has strange behavior - colors appear to toggle as new messages
  // arrive
  protected class mmlRenderer extends JLabel implements ListCellRenderer {
    private MoteSimObject lastMote = null;
    private Color bgColor = new Color(210,210,210);
    private Color otherColor = Color.white;

    public Component getListCellRendererComponent(JList list,
	Object value, int index, boolean isSelected, boolean cellHasFocus) {

      mmlEntry entry = (mmlEntry)value;
      if (entry.mote != lastMote) {
	Color tmp = bgColor;
	bgColor = otherColor;
	otherColor = tmp;
	lastMote = entry.mote;
      }
      this.setFont(TinyViz.constFont);
      this.setText(entry.msg);
      if (isSelected) {
	this.setForeground(entry.fgColor);
	this.setBackground(list.getSelectionBackground());
      } else {
	this.setForeground(entry.fgColor);
	this.setBackground(this.bgColor);
      }
      this.setOpaque(true);
      return this;
    }
  }



}

