// $Id: MoteMessageTable.java,v 1.2 2003/10/07 21:46:04 idgay Exp $

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
import javax.swing.table.*;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

/**
 * An extension to MessageList that associates a MoteSimObject
 * with each entry. The user can specify that only messages from a
 * given selected set of motes should be displayed.
 */
public class MoteMessageTable extends MessageList implements SimConst {
  private boolean selectedOnly = false;
  private Set selected = null;

  protected JTable msgTable;
  protected moteTableModel msgTableModel;

  public MoteMessageTable() {
    this(DEFAULT_MAX_DISPLAY, DEFAULT_MAX_MESSAGES);
  }

  public MoteMessageTable(int maxDisplay, int maxMessages) {
    this.maxDisplay = maxDisplay;
    this.maxMessages = maxMessages;

    msgTableModel = new moteTableModel();
    msgTable = new JTable(msgTableModel);
    //if (maxDisplay > 0) msgList.setVisibleRowCount(maxDisplay);
    msgTable.setFont(TinyViz.constFont);
    //msgList.setFixedCellHeight(15);
    msgTable.setBackground(Color.white);
    msgTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    msgTable.setDefaultRenderer(mmlEntry.class, new moteTableRenderer());
    listPane = new JScrollPane(msgTable);
    listPane.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
    //listPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
    //sbHoriz = listPane.createHorizontalScrollBar();
    //sbVert = listPane.createVerticalScrollBar();
    //listPane.setHorizontalScrollBar(sbHoriz);
    //listPane.setVerticalScrollBar(sbVert);

    this.setLayout(new BorderLayout());
    this.add(listPane, BorderLayout.NORTH);
    this.revalidate();
  }

  public void setSelectedOnly(boolean value) {
    this.selectedOnly = value;
  }

  public synchronized void setSelected(Set selected) {
    this.selected = selected;
    ((moteTableModel)msgTableModel).resetSelected();
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
    msgTableModel.addElement(new mmlEntry(msg, mote, fgColor, bgColor));
    msgTable.revalidate();
    msgTable.repaint();
  }

  class mmlEntry extends MessageList.mlEntry {
    public MoteSimObject mote;

    mmlEntry(String msg, MoteSimObject mote, Color fgColor, Color bgColor) {
      super(msg, fgColor, bgColor);
      this.mote = mote;
    }
  }

  class moteTableRenderer extends JLabel implements TableCellRenderer {
    public Component getTableCellRendererComponent(JTable table,
	Object value, boolean isSelected, boolean hasFocus, int row, 
	int column) {

      mmlEntry mml = (mmlEntry)value;
      this.setFont(TinyViz.constFont);

      if (column == 0) {
	this.setText(new Integer(mml.mote.getID()).toString());
      } else {
	this.setText(mml.msg);
      }

      if (isSelected) {
	this.setForeground(mml.fgColor);
	this.setBackground(table.getSelectionBackground());
      } else {
	this.setForeground(mml.fgColor);
	this.setBackground(mml.bgColor);
      }
      this.setOpaque(true);
      return this;
    }
  }

  class moteTableModel extends AbstractTableModel {
    Vector allItems = new Vector();
    Vector selectedItems = new Vector();

    public void addElement(mmlEntry mml) {
      allItems.addElement(mml);
      if (allItems.size() > maxMessages) allItems.removeElementAt(0);
      if (selected != null && 
	  (mml.mote == null || selected.contains(mml.mote))) {
	if (selectedItems.size() > maxMessages) selectedItems.removeElementAt(0);
	selectedItems.addElement(mml);
      }
    }

    public void resetSelected() {
      selectedItems.clear();
      if (selected == null) return;
      Enumeration e = allItems.elements();
      while (e.hasMoreElements()) {
	mmlEntry mml = (mmlEntry)e.nextElement();
	if (selected != null && 
  	    (mml.mote == null || selected.contains(mml.mote)))
  	  selectedItems.addElement(mml);
      }
    }

    public int getColumnCount() { 
      return 2; 
    }

    public int getRowCount() {
      if (!selectedOnly) return allItems.size();
      if (selected == null) return 0;
      return selectedItems.size();
    }

    public boolean isCellEditable(int row, int column) {
      return false;
    }
    public Class getColumnClass(int column) {
      return mmlEntry.class;
    }
    public String getColumnName(int column) {
      if (column == 0) return "Mote";
      if (column == 1) return "Message";
      return null;
    }

    public Object getValueAt(int row, int column) {
      mmlEntry mml;
      if (!selectedOnly) {
	mml = (mmlEntry)allItems.elementAt(row);
      } else {
	if (selected == null) throw new ArrayIndexOutOfBoundsException("no motes in selected set");
	mml = (mmlEntry)selectedItems.elementAt(row);
      }
      return mml;
    }
  }


}
