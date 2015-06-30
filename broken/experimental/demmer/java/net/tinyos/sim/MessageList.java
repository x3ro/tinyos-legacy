// $Id: MessageList.java,v 1.1 2003/10/17 01:53:35 mikedemmer Exp $

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
 * Desc:        Generic message display list
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

public class MessageList extends JPanel implements SimConst {
  public static final Color defaultForeground = Color.black;
  public static final Color defaultBackground = Color.white;
  public static final Color highlightForeColor = Color.blue;

  public static final int DEFAULT_MAX_DISPLAY = 15;
  public static final int DEFAULT_MAX_MESSAGES = 500;
  protected int maxDisplay, maxMessages;
  protected JList msgList;
  protected DefaultListModel msgModel;
  protected JScrollPane listPane;
  protected JCheckBox cbHighlight;
  protected JButton bClear;
  protected JTextField highlightMatch;
  protected boolean highlight = false;

  protected MessageList() {
    this(DEFAULT_MAX_DISPLAY, DEFAULT_MAX_MESSAGES);
  }

  public MessageList(int maxDisplay, int maxMessages) {
    this.maxDisplay = maxDisplay;
    this.maxMessages = maxMessages;

    msgModel = new DefaultListModel();
    msgList = new JList(msgModel);
    if (maxDisplay > 0) msgList.setVisibleRowCount(maxDisplay);
    msgList.setFont(TinyViz.constFont);
    msgList.setFixedCellHeight(15);
    msgList.setBackground(Color.white);
    msgList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    msgList.setCellRenderer(new mlRenderer());
    listPane = new JScrollPane(msgList);
    listPane.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
    JPanel selPane = new JPanel();
    cbHighlight = new JCheckBox("Highlight", highlight);
    cbHighlight.addItemListener(new cbListener());
    cbHighlight.setFont(TinyViz.labelFont);
    selPane.add(cbHighlight);
    highlightMatch = new JTextField(20);
    highlightMatch.setFont(TinyViz.smallFont);
    highlightMatch.setEditable(true);
    selPane.add(highlightMatch);
    bClear = new JButton("Clear");
    bClear.setFont(TinyViz.defaultFont);
    bClear.addActionListener(new ActionListener() {
	public void actionPerformed(ActionEvent e) {
	  MessageList.this.clear();
	}});
    selPane.add(bClear);

    this.setLayout(new BorderLayout());
    this.add(listPane, BorderLayout.CENTER);
    this.add(selPane, BorderLayout.SOUTH);
    this.revalidate();
  }

  public synchronized void clear() {
    msgModel.clear();
    msgList.repaint();
  }

  public synchronized void addMessage(String msg) {
    addMessage(msg, defaultForeground, defaultBackground);
  }

  public synchronized void addMessage(String msg, Color fgColor, Color bgColor) {
    msgModel.addElement(new mlEntry(msg, fgColor, bgColor));
    if (msgModel.size() > maxMessages) msgModel.removeElementAt(0);
    msgList.repaint();
  }

  protected class mlEntry {
    String msg;
    Color fgColor;
    Color bgColor;

    mlEntry(String msg, Color fgColor, Color bgColor) {
      this.msg = msg;
      this.fgColor = fgColor;
      this.bgColor = bgColor;
    }
  }

  protected class mlRenderer extends JLabel implements ListCellRenderer {
    public Component getListCellRendererComponent(JList list,
	Object value, int index, boolean isSelected, boolean cellHasFocus) {

      mlEntry entry = (mlEntry)value;
      this.setFont(TinyViz.constFont);
      this.setText(entry.msg);
      if (isSelected) {
	this.setForeground(entry.fgColor);
	this.setBackground(list.getSelectionBackground());
      } else {
	this.setForeground(entry.fgColor);
	this.setBackground(entry.bgColor);
      }
      if (highlight) {
	String match = highlightMatch.getText();
	if (match != null && (entry.msg.indexOf(match) != -1)) {
	  this.setForeground(highlightForeColor);
	}
      }
      this.setOpaque(true);
      return this;
    }
  }

  class cbListener implements ItemListener {
    public void itemStateChanged(ItemEvent e) {
      highlight = (e.getStateChange() == e.SELECTED);
      msgList.repaint();
    }
  }



}

