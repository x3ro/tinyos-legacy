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

import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;
import javax.swing.border.*;
import java.awt.geom.*;
import javax.swing.*;
import javax.swing.event.*;
import java.util.*;
import java.io.File;
import java.io.IOException;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

import net.tinyos.task.taskapi.*;

/**
 */
public class TASKConfiguration {

  public String TAB1TIP = "Use to create queries for the network";

  public String LABEL1 = "Data to collect (click or shift-click) ";
  public String LABEL2 = "Sample Period (ms) ";
  public String LABEL3 = "Enter name to store results as: ";
  public String BUTTON1 = "Remove Entry";
  public String BUTTON2 = "Clear List";
  public String BUTTON3 = "Start Sensor Query";
  public String BUTTON4 = "Start Health Query";
  public String BUTTON5 = "Stop Sensor Query";
  public String BUTTON6 = "Stop Health Query";
  public JList  list1;
  public DefaultListModel clauseListModel;
  public JList  list2;
  public JTextField textfield1;
  public JTextField textfield2;
  public JTextField textfield3;
  public JButton button1;
  public JButton button2;
  public JButton button3;
  public JButton button4;
  public JButton button5;
  public JButton button6;
  public JButton sensorQueryEditButton;  
  public JButton sensorQuerySubmitButton;  

  private JFrame parentFrame;
  private TASKClient client;
  private JPanel parentPanel;

  private JRadioButtonMenuItem[] sensorItems = new JRadioButtonMenuItem[20];
  Vector atts = new Vector();

  Vector aggs = new Vector();
  Vector v = new Vector();
  public int samplePeriod;
  TASKQuery healthConstQuery, sensorQuery, currentQuery, oldQuery;
  JTextArea sensorQueryArea;
  JTextArea healthQueryArea;
  JTextArea currentQueryArea;

  DefaultBoundedRangeModel ttlModel;
  FollowerRangeModel spModel;
  ConversionPanel spPanel;

  String configName;

  public TASKConfiguration(JFrame parentFrame, TASKClient client, JPanel parentPanel) {
    this.parentFrame = parentFrame;
    this.client = client;
    this.parentPanel = parentPanel;

    Vector selectEntries = new Vector();
    TASKAttributeInfo tai = client.getAttribute("nodeid");
    if (tai != null) {
      selectEntries.add(new TASKAttrExpr(tai));
    }
    else {
      System.out.println("attribute nodeid not defined");
    }

    tai = client.getAttribute("parent");
    if (tai != null) {
      selectEntries.add(new TASKAttrExpr(tai));
    }
    else {
      System.out.println("attribute parent not defined");
    }

    tai = client.getAttribute("depth");
    if (tai != null) {
      selectEntries.add(new TASKAttrExpr(tai));
    }
    else {
      System.out.println("attribute depth not defined");
    }

    tai = client.getAttribute("qual");
    if (tai != null) {
      selectEntries.add(new TASKAttrExpr(tai));
    }
    else {
      System.out.println("attribute qual not defined");
    }

    tai = client.getAttribute("freeram");
    if (tai != null) {
      selectEntries.add(new TASKAttrExpr(tai));
    }
    else {
      System.out.println("attribute freeram not defined");
    }

    healthConstQuery = new TASKQuery(selectEntries, new Vector(), 2048, null);
  }

  /**
   * Prepares the frame for the configuration. 
   */
  public void preparePanel(String cName) {
    parentPanel.removeAll();

    configName = cName;

     // utility classes
    Border b = BorderFactory.createBevelBorder(BevelBorder.LOWERED);

    ///////////////
    // tab1 
    // set up the first tab
    BoxLayout bl = new BoxLayout(parentPanel, BoxLayout.Y_AXIS);
    parentPanel.setLayout(bl);

    ///////////////
    // panel 1
    JPanel panel1 = new JPanel();
    panel1.setBorder(b);
    panel1.setLayout(new BorderLayout());

    JPanel row = new JPanel();
    row.setLayout(new BorderLayout());
    row.add(new Label(LABEL1), BorderLayout.WEST);

    atts = client.getAttributes();
    v = new Vector();
    for (int i=0; i<atts.size(); i++) {
      TASKAttributeInfo info = (TASKAttributeInfo)atts.elementAt(i);
      v.addElement(info.name+": "+info.description);
    }

    aggs = client.getAggregates();

    list1 = new JList(v) {
      public String getToolTipText(MouseEvent me) {
        int index = locationToIndex(me.getPoint());
        if (index > -1) {
          return ((TASKAttributeInfo)atts.elementAt(index)).description;
        }
        else {
          return null;
        }
      }
    };
    list1.setToolTipText("");
    list1.setVisibleRowCount(5);
    list1.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);

    JScrollPane scrollPane = new JScrollPane(list1);
    row.add(scrollPane, BorderLayout.CENTER);
    panel1.add(row, BorderLayout.NORTH);


    row = new JPanel();
    bl = new BoxLayout(row, BoxLayout.X_AXIS);
    row.setLayout(bl);
    row.add(new Label(LABEL2));
    textfield1 = new JTextField("1");
//    row.add(textfield1);

    ttlModel = new DefaultBoundedRangeModel();
    spModel = new FollowerRangeModel(ttlModel,this);
    ttlModel.setMinimum(1);
    ttlModel.setMaximum(720);		//lifetime in days
    spModel.setMinimum(1);
    spModel.setMaximum(6400);		// sample period in ms 
    ConversionPanel ttlPanel = new ConversionPanel("Time to Live (days)", ttlModel, 15);
    spPanel = new ConversionPanel("Sample Period (ms)", spModel, 1084);

    JPanel col = new JPanel();
    bl = new BoxLayout(col, BoxLayout.Y_AXIS);
    col.setLayout(bl);
    col.add(row);

    row = new JPanel();
    bl = new BoxLayout(row, BoxLayout.X_AXIS);
    row.setLayout(bl);
    row.add(ttlPanel);
    row.add(spPanel);
    col.add(row);
    panel1.add(col, BorderLayout.SOUTH);


    //////////////

    ///////////////
    // panel 2
    JPanel panel2 = new JPanel();
    panel2.setBorder(BorderFactory.createTitledBorder(b,"Editing Sensor Query"));

    JPanel column2 = new JPanel();
    bl = new BoxLayout(column2, BoxLayout.Y_AXIS);
    column2.setLayout(bl);
    
    clauseListModel = new DefaultListModel();
    list2 = new JList(clauseListModel);
    scrollPane = new JScrollPane(list2);

    currentQueryArea = new JTextArea(3,40);
    currentQueryArea.setEditable(false);
    currentQueryArea.setText("English version of edited query here");

    column2.add(scrollPane);
    column2.add(currentQueryArea);

    JPanel column = new JPanel();
    bl = new BoxLayout(column, BoxLayout.Y_AXIS);
    column.setLayout(bl);
    button1 = new JButton(BUTTON1);
    button1.setActionCommand(BUTTON1);
    button1.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        int index = list2.getSelectedIndex();
        if (index >= 0) {
          clauseListModel.remove(index);
          int size = clauseListModel.getSize();
          if (size == 0){ 
            button1.setEnabled(false);
            button2.setEnabled(false);
          }
          else {
            if (index == clauseListModel.getSize()) {
              index --;
            }
            else {
              list2.setSelectedIndex(index);
            }
          }
          currentQuery = createQuery(clauseListModel);
          currentQueryArea.setText(currentQuery.toSQL());
        }
      }
    });

    button2 = new JButton(BUTTON2);
    button2.setActionCommand(BUTTON2);
    button2.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        clauseListModel.clear();
        button1.setEnabled(false);
        button2.setEnabled(false);
        currentQueryArea.setText("");
      }
    });

    sensorQuerySubmitButton = new JButton("Submit Query");
    sensorQuerySubmitButton.setActionCommand("Submit Query");
    sensorQuerySubmitButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        try {
          samplePeriod = spPanel.getValue();
        } catch (NumberFormatException nfe) {
            JOptionPane.showMessageDialog(parentFrame, "Sample period must be of type integer", "Error", JOptionPane.ERROR_MESSAGE);
            return;
        }

        if (clauseListModel.size() > 0) {
          currentQuery.setSamplePeriod(samplePeriod);
          sensorQuery = currentQuery;
          currentQueryArea.setText(sensorQuery.toSQL());
          sensorQueryArea.setText(sensorQuery.toSQL());
          sensorQueryEditButton.setEnabled(true);
          button3.setEnabled(true);
          button3.setText("Start Sensor Query");
        }
      }
    });

    column.add(button1);
    column.add(button2);
    column.add(sensorQuerySubmitButton);



    panel2.add(column2, BorderLayout.CENTER);
    panel2.add(column, BorderLayout.EAST);
    ///////////////

    JPanel panel6 = new JPanel();
    panel6.setBorder(BorderFactory.createTitledBorder(b,"Current Sensor Query"));
    sensorQueryArea = new JTextArea(3,30);
    sensorQueryArea.setEditable(false);
    sensorQueryEditButton = new JButton("Edit");
    sensorQueryEditButton.setEnabled(false);
    panel6.add(sensorQueryArea);
    panel6.add(sensorQueryEditButton);

    sensorQueryEditButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        clauseListModel.clear();
        Vector selects = sensorQuery.getSelectEntries();
        for (int i=0; i<selects.size(); i++) {
          Clause c = new Clause((TASKExpr)selects.elementAt(i));
          clauseListModel.addElement(c);
        }

        Vector predicates = sensorQuery.getPredicates(); 
        for (int i=0; i<predicates.size(); i++) {
          Clause c = new Clause((TASKOperExpr)predicates.elementAt(i));
          clauseListModel.addElement(c);
        }
        currentQueryArea.setText(sensorQuery.toSQL());

//        textfield1.setText(Integer.toString(sensorQuery.getSamplePeriod()));
    
        button1.setEnabled(true);
        button2.setEnabled(true);
        // enable start query, submit query
      }
    });

    JPanel column4 = new JPanel();
    bl = new BoxLayout(column4, BoxLayout.Y_AXIS);
    column4.setLayout(bl);
    column4.add(panel6);
 
    JPanel row2 = new JPanel();
    bl = new BoxLayout(row2, BoxLayout.X_AXIS);
    row2.setLayout(bl);
    row2.add(new Label(LABEL3));
    textfield3 = new JTextField("Default");
    row2.add(textfield3);
    column4.add(row2);

    JPanel panel8 = new JPanel();
    panel8.setBorder(BorderFactory.createTitledBorder(b,"Current Sensor Query")); 
    panel8.add(column4);

    JPanel panel7 = new JPanel();
    panel7.setBorder(BorderFactory.createTitledBorder(b,"Current Health Query"));
    healthQueryArea = new JTextArea(3,30);
    healthQueryArea.setEditable(false);
    healthQueryArea.setText(healthConstQuery.toSQL());

    JPanel column3 = new JPanel();
    bl = new BoxLayout(column3, BoxLayout.Y_AXIS);
    column3.setLayout(bl);
    
    column3.add(healthQueryArea);

    JPanel row1 = new JPanel();
    bl = new BoxLayout(row1, BoxLayout.X_AXIS);
    row1.setLayout(bl);
    row1.add(new Label(LABEL3));
    textfield2 = new JTextField("Default");
    row1.add(textfield2);
    column3.add(row1);

    panel7.add(column3);

    ///////////////
    // panel 3
    JPanel panel3 = new JPanel();
    panel3.setBorder(b);
    panel3.setLayout(new GridLayout(2,2));
    button3 = new JButton(BUTTON3);
    button3.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        if (sensorQuery != null) {
          if (oldQuery != null) {
            if (oldQuery.toSQL().equals(sensorQuery.toSQL())) {
              sensorQuery = oldQuery;
            }
          }

          if (!textfield3.getText().equals("Default")) {
// System.out.println("setting table name to "+textfield3.getText()+"_sensor");
//            sensorQuery.setTableName(textfield3.getText().replace(' ','_')+"_sensor");
            sensorQuery.setTableName(textfield3.getText().replace(' ','_'));
          }
          if (client.submitSensorQuery(sensorQuery) == 0) {
            sensorQueryArea.setText(sensorQuery.toSQL());
            button5.setEnabled(true);
//            button3.setEnabled(false);
            button3.setText("Resend Sensor Query");
            sensorQueryEditButton.setEnabled(true);
            sensorQuerySubmitButton.setEnabled(false);
            sensorQuery = client.getSensorQuery();
            oldQuery = sensorQuery;
          }
          else {
            currentQueryArea.setText(sensorQuery.toSQL() +": QUERY FAILED!");
          }
        }
      }
    });

    button5 = new JButton(BUTTON5);
    button5.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        if (client.stopSensorQuery() == 0) {
          button3.setEnabled(true);
          button3.setText("Start Sensor Query");
//          button5.setEnabled(false);
          sensorQueryArea.setText("QUERY STOPPED: "+sensorQuery.toSQL());
          sensorQuerySubmitButton.setEnabled(true);
        }
      }
    });

    button2.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        clauseListModel.clear();
        button1.setEnabled(false);
        button2.setEnabled(false);
      }
    });


    button4 = new JButton(BUTTON4);
    button4.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        if (!textfield2.getText().equals("Default")) {
//          sensorQuery.setTableName(textfield2.getText().replace(' ','_')+"_health");
          sensorQuery.setTableName(textfield2.getText().replace(' ','_'));
        }
        if (client.submitHealthQuery(healthConstQuery) == 0) {
          healthQueryArea.setText(healthConstQuery.toSQL());
          button6.setEnabled(true);
//          button4.setEnabled(false);
          button4.setText("Resend Health Query");
          healthConstQuery = client.getHealthQuery();
        }
      }
    });


    button6 = new JButton(BUTTON6);
    button6.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        if (client.stopHealthQuery() == 0) {
          healthQueryArea.setText("QUERY STOPPED: "+healthConstQuery.toSQL());
//          button4.setEnabled(true);
          button4.setText("Start Health Query");
//          button6.setEnabled(false);
        }
      }
    });

    panel3.add(button3);
    panel3.add(button4);
    panel3.add(button5);
    panel3.add(button6);

    parentPanel.add(panel1);
    parentPanel.add(panel2);
    parentPanel.add(panel8);
    parentPanel.add(panel7);
    parentPanel.add(panel3);
    ///////////////

    MouseListener mouseListener = new MouseAdapter() {
      public void mouseClicked(MouseEvent e) {
        String selectedValue = (String)list1.getSelectedValue();
        String att = selectedValue.substring(0,selectedValue.indexOf(":"));

        if (e.getClickCount() == 1) {
          if (e.isShiftDown()) {
            int index = list1.locationToIndex(e.getPoint());
            //commented out since split is JDK 1.4 specific -- we use
            // indexOf as below.  SRM 4.26.03 -- due to William J Maurer
            //          String att = ((String)list1.getSelectedValue()).split(":")[0];
            AttributeDialog ad = new AttributeDialog(parentFrame, att, aggs, TASKOperators.OperName);

            ad.pack();
            ad.setLocationRelativeTo(parentFrame);
            ad.setVisible(true);
            if (ad.isDataValid()) {
              Clause cl = ad.getClause();
              if (cl.getType() == Clause.BOTH) {
                Clause c1 = new Clause(cl.getAttribute(), cl.getAggregator(), 0, -1, cl.getArg1(), cl.getArg2());
                Clause c2 = new Clause(cl.getAttribute(), "No Aggregator", cl.getOperator(), cl.getOperand());
                if (c1.isValid()) {
                  clauseListModel.addElement(c1);
                }
                if (c2.isValid()) {
                  clauseListModel.addElement(c2);
                }
              }
              else {
                if (cl.isValid()) {
                  clauseListModel.addElement(cl);
                }
              }
              button1.setEnabled(true);
              button2.setEnabled(true);
  
              currentQuery = createQuery(clauseListModel);
              currentQueryArea.setText(currentQuery.toSQL());
            }
          }
          else {
            // AKD create clause cl
            Clause cl = new Clause(att, "No Aggregator", 0, -1, AttributeDialog.NO_ARGUMENT, AttributeDialog.NO_ARGUMENT);
            clauseListModel.addElement(cl);
            button1.setEnabled(true);
            button2.setEnabled(true);
            currentQuery = createQuery(clauseListModel);
            currentQueryArea.setText(currentQuery.toSQL());
          }
        }
      }
    };
    list1.addMouseListener(mouseListener);

    TASKQuery query = client.getHealthQuery();
    if (query == null) {
//      button4.setEnabled(true);
      button4.setText("Start Health Query");
      button6.setEnabled(false);
      healthQueryArea.setText("No health query running");
    }
    else {
//      button4.setEnabled(false);
      button4.setText("Resend Health Query");
      button6.setEnabled(true);
      healthQueryArea.setText(query.toSQL());
      textfield2.setText(query.getTableName());
    }

    sensorQuery = client.getSensorQuery();
    if (sensorQuery == null) {
      button3.setEnabled(false);
      button3.setText("Start Sensor Query");
      button5.setEnabled(false);
      sensorQueryArea.setText("No sensor query running");
    }
    else {
//      button3.setEnabled(false);
      button3.setText("Resend Sensor Query");
      button5.setEnabled(true);
      sensorQueryArea.setText(sensorQuery.toSQL());
      sensorQueryEditButton.setEnabled(true);
      textfield3.setText(sensorQuery.getTableName());
    }

    ttlModel.setValue(15);
    spModel.setValue(1084);
  }

  private TASKAttributeInfo getAttributeInfo(String name) {
    for (int i=0; i<atts.size(); i++) {
      if (name.equals(((TASKAttributeInfo)atts.elementAt(i)).name)) {
        return (TASKAttributeInfo)atts.elementAt(i);
      }
    }
    return null;
  }

  private String queryToString(TASKQuery query) {
    StringBuffer sb = new StringBuffer("COLLECT ");

    Vector selects = query.getSelectEntries();
    for (int i=0; i<selects.size()-1; i++) {
      TASKExpr expr = (TASKExpr)selects.elementAt(i);
      if (expr instanceof TASKAttrExpr) {
        sb.append(((TASKAttrExpr)expr).toString()+", ");
      }
      else if (expr instanceof TASKAggExpr) {
        sb.append(((TASKAggExpr)expr).toString()+", ");
      }
    }
 
    if (selects.size() > 0) {
      TASKExpr expr = (TASKExpr)selects.lastElement();
      if (expr instanceof TASKAttrExpr) {
        sb.append(((TASKAttrExpr)expr).toString()+"\n");
      }
      else if (expr instanceof TASKAggExpr) {
        sb.append(((TASKAggExpr)expr).toString()+"\n");
      }
    }

    sb.append("WHERE ");

    Vector preds = query.getPredicates();
    for (int i=0; i<preds.size()-1; i++) {
      sb.append(((TASKOperExpr)preds.elementAt(i)).toString() +", ");
    }

    if (preds.size() > 0) {
      TASKOperExpr operExpr = (TASKOperExpr)preds.lastElement();
      sb.append(operExpr.toString()+"\n");
    }
    
    sb.append("WITH SAMPLE PERIOD ");
    sb.append(query.getSamplePeriod());
    return sb.toString();
  }

  private TASKQuery createQuery(DefaultListModel model) {
    if (spPanel == null) {
      return null;
    }

    int period = spPanel.getTextValue();

    TASKQuery query = new TASKQuery(new Vector(), new Vector(), period, null);

    if (model.size() > 0) {
      for (Enumeration e=model.elements(); e.hasMoreElements(); ) {
        Clause c = (Clause)e.nextElement();
        TASKAttrExpr att = new TASKAttrExpr(getAttributeInfo(c.getAttribute()));
        if (c.getType() == Clause.PREDICATE) {
          query.addPredicate(new TASKOperExpr(c.getOperator(), att, new TASKConstExpr(0, new Integer(c.getOperand()))));
        }
        else if (c.getType() == Clause.ATTRIBUTE) {
          query.addSelectEntry(att);
        }
        else if (c.getType() == Clause.AGGREGATOR) {
          if ((c.getArg1() >= 0) && (c.getArg2() >= 0)) {
            query.addSelectEntry(new TASKAggExpr(c.getAggregator(), c.getAttribute(), new Integer(c.getArg1()), new Integer(c.getArg2())));
          }
          else if ((c.getArg1() >= 0) && (c.getArg2() < 0)) {
            query.addSelectEntry(new TASKAggExpr(c.getAggregator(), c.getAttribute(), new Integer(c.getArg1()), null));
          }
          else if ((c.getArg1() < 0) && (c.getArg2() < 0)) {
            query.addSelectEntry(new TASKAggExpr(c.getAggregator(), c.getAttribute(), null, null));
          }
        }
      }
    }
    return query;
  }

  public int getTimeToLive(int sp) { // returns in days
    currentQuery = createQuery(clauseListModel);
    if (currentQuery == null) {
      return 1;
    }
    currentQueryArea.setText(currentQuery.toSQL());
    currentQuery.setSamplePeriod(sp);
//System.out.println("LT: "+client.estimateLifeTime(currentQuery, healthConstQuery));
//System.out.println("LT: "+client.estimateLifeTime(currentQuery, healthConstQuery)/(60*60*24));
    return (int)client.estimateLifeTime(currentQuery, healthConstQuery)/(60*60*24);
  }

  public int getSamplePeriod(int ttl) { // returns in minutes
    if (clauseListModel == null) {
      return 1;
    }
    currentQuery = createQuery(clauseListModel);
    if (currentQuery == null) {
      return 1;
    }
    currentQueryArea.setText(currentQuery.toSQL());
    client.estimateSamplePeriods(ttl*24*60*60, currentQuery, healthConstQuery);
    return healthConstQuery.getSamplePeriod();
  }
}
