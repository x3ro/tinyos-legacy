/*
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
package net.tinyos.task.taskviz;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.table.*;
import net.tinyos.task.taskapi.*;

/** ResultFrame displays a scrolling list with
 results from queries in it, side-by-side with a graph
 of query results when such results are available.
 */
public class ResultFrame extends JFrame implements TASKResultListener {

private TASKClient client;
private Vector attributes;
private Hashtable nodeids;
private Vector nodes;
String currentAttribute;

  /** Constructor: attributes (first value is nodeid)
   */
  public ResultFrame(TASKClient client, Vector nodes, Vector attributes) {
    this.client = client;
    this.attributes = attributes;
    this.nodes = nodes;
    nodeids = new Hashtable();

    for (int i=0; i<nodes.size(); i++) {
      nodeids.put((Integer)nodes.elementAt(i), new Integer(i));
    }

    boolean listening = false;

    if (client.getHealthQuery() != null) {
      client.addHealthResultListener(this);
      listening = true;
    }
    if (client.getSensorQuery() != null) {
      client.addSensorResultListener(this);
      listening = true;
    }

    if (!listening) {
      System.out.println("no listeners");
    }
    else {
      initUI();
    }
    pack();
    show();
  }
	
  private void setupGraph(ResultGraph graph) {
    graph.setYRange(0d,1024d);
    graph.setXLabel("Time (s)");
    graph.setYLabel(currentAttribute + "(Raw Units)");
    graph.setTitle("Time vs. " + currentAttribute);
    graph.setTitleFont("helvetica-bold-24");
    graph.setLabelFont("serif-18");
  }

  /* Create the UI */
  private void initUI() {
    setTitle ("Query: " + attributes);
    getContentPane().setLayout(new BorderLayout());
    getContentPane().setBackground(java.awt.Color.white);
		
    addWindowListener(new WindowAdapter() {
      public void windowClosing(WindowEvent evt) {
        exitForm(evt);
      }
    });

    Vector headings = (Vector)attributes.clone();
    headings.insertElementAt("Epoch", 0);

    tableModel = new DefaultTableModel(headings, 0);
    resultTable = new JTable(tableModel);
    resultTable.setSize(200,150);
    resultTable.setFont(Font.decode("serif-16"));
    resultTable.getTableHeader().setFont(Font.decode("helvetica-bold-18"));
    scroller = new JScrollPane(resultTable);
		
    graphPanel = new JPanel();
    graphPanel.setLayout(new BorderLayout());
			
    graphControlPanel = new JPanel(new GridLayout(1,3));

    graphOptions = new JComboBox();
    graphOptions.setLightWeightPopupEnabled(false);

    for (int i = 1; i < attributes.size(); i++) {
      graphOptions.addItem(attributes.elementAt(i));
    }

    graphOptions.setSelectedIndex(0);
    currentAttribute = (String)attributes.elementAt(1);
    graphControlPanel.add(graphOptions);
    graphOptions.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent evt) {
        String current = (String)graphOptions.getSelectedItem();
        if (!current.equals(currentAttribute)) {
          currentAttribute = current;
          graph.clear(true);
          setupGraph(graph);
        }
      }
    });

    graph = new ResultGraph(2);
    setupGraph(graph);

    for (int i=0; i<nodes.size(); i++) {
      graph.addKey(i, ((Integer)nodes.elementAt(i)).toString());
    }

    graphOptions.setSize(100,100);

    graphPanel.add(graphControlPanel, "South");
    graphPanel.add(graph, "Center");
    split = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, true);
    getContentPane().add(split, "Center");
    split.setTopComponent(scroller);
    split.setBottomComponent(graphPanel);
    split.setDividerLocation(350);
    pack();
  }
	
  /** ResultListener method called when a new result for
      this frame's query arrives
   */
  public void addResult(TASKResult qr) {
    // check if result has a nodeid and that nodeid is in our list
    Integer nd = (Integer)qr.getField("nodeId");
    if (nd == null) {
      return;
    }
    if (nodeids.get(nd) == null) {
      return;
    }

    try {
      if (qr.getEpochNo() > epochNo) {
        epochNo = qr.getEpochNo(); //monotonically increasing
      }
    } catch (NullPointerException npe) {
        return;
    }

    Vector v = new Vector();
    v.addElement(new Integer(epochNo));
    v.addElement(nd);
    for (int i=1; i<attributes.size(); i++) {
      String att = (String)attributes.elementAt(i);
      Object ovalue = qr.getField(att);
      v.addElement(ovalue);
    }
    tableModel.addRow(v);
    resultTable.setRowSelectionInterval(tableModel.getRowCount()-1,tableModel.getRowCount()-1);

    Object ovalue = qr.getField(currentAttribute);
    int value = 0;
    if (ovalue instanceof Integer) {
      Integer tmp = (Integer)ovalue;
      value = tmp == null ? 0 : tmp.intValue();
    }
    else if (ovalue instanceof Byte) {
      Byte tmp = (Byte)ovalue;
      value = tmp == null ? 0 : tmp.intValue();
    }

    JScrollBar bar = scroller.getVerticalScrollBar();
    if (bar != null) {
      bar.setValue(bar.getMaximum() + 128);
    }

    try { //add the label for the result to the graph key
      //update the graph with the new result
      //don't draw lines that go backwards!
      Integer last = (Integer)lastEpoch.get(nd);
      if (last == null || qr.getEpochNo() >= last.intValue()) {
        lastEpoch.put(nd, new Integer(qr.getEpochNo()));

        graph.addPoint(((Integer)nodeids.get(nd)).intValue(), (double)qr.getEpochNo(), value);
// * ((double)query.epochDur / 1000.0), 
      }
    } catch (ArrayIndexOutOfBoundsException e) {
        System.out.println("Result missing value: " + qr);
    } catch (NumberFormatException e) {
        System.out.println("Bad result: " + qr);
    }
  }

  public void paint(Graphics g) {
    super.paint(g);
  }

  protected void exitForm(WindowEvent evt) {
    // AKD - need to remove listeners here
  }
	
  JTable resultTable;
  DefaultTableModel tableModel;
  JPanel bottomPanel;
  JPanel graphPanel;
  JPanel graphControlPanel;
  JScrollPane scroller;
  ResultGraph graph = null;
  JComboBox graphOptions;
  JButton resetButton;
  JButton clearButton;
  JSplitPane split;
  Hashtable lastEpoch = new Hashtable();
  int epochNo = 0;
}
