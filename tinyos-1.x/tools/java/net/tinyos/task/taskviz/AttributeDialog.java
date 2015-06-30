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
import java.io.*;
import javax.swing.*; 
import javax.swing.plaf.basic.*; 

import net.tinyos.task.taskapi.*;

/**
 * This class allows a user to enter/edit the id for a mote. The id must be a positive integer that
 * has not already been used before.
 */
public class AttributeDialog extends JDialog implements ActionListener {

  private boolean validData = false;
  private JTextField field, arg1, arg2;
  private JComboBox aggList, opMenu;
  private String op = null;
  private String attribute;
  private Vector aggregators;

  public static final int NO_ARGUMENT = -1;
  public static final int BAD_ARGUMENT = -2;
  
  class MyComboBoxRenderer extends BasicComboBoxRenderer {
    public Component getListCellRendererComponent(JList list, Object value, int index, boolean isSelected, boolean cellHasFocus) {
      if (isSelected) {
        setBackground(list.getSelectionBackground());
        setForeground(list.getSelectionForeground());
        if (index > 0) {
          list.setToolTipText(((TASKAggInfo)aggregators.elementAt(index-1)).getDescription()+":"+
                              ((TASKAggInfo)aggregators.elementAt(index-1)).getNumConstArgs());
        }
        else if (index == 0) {
          list.setToolTipText("");
        }
      }
      else {
        setBackground(list.getBackground());
        setForeground(list.getForeground());
      }
      setFont(list.getFont());
      setText((value == null) ? "" : value.toString());
      return this;
    }
  }

  /**
   * Constructor that creates the dialog allowing a user to edit/add the id of a mote.
   *
   * @param aFrame Parent frame for the dialog box
   * @param motes List of existing motes
   * @param mode Edit or Add mode
   */
  public AttributeDialog(Frame aFrame, String attribute, Vector aggs, String[] operators) {
    super(aFrame, true);

    setTitle("Attribute Aggregate/Filter Dialog: "+attribute);

    this.attribute = attribute;
    this.aggregators = aggs;

    JPanel aggPanel = new JPanel();
    aggPanel.setBorder(BorderFactory.createTitledBorder("Aggregators"));

    Vector v = new Vector();
    v.addElement("No Aggregator");
    for (int i=0; i<aggregators.size(); i++) {
      v.addElement(((TASKAggInfo)aggregators.elementAt(i)).getName());
    }

    aggList = new JComboBox(v);
    aggList.setSelectedIndex(0);
    aggList.setRenderer(new MyComboBoxRenderer());
    aggPanel.add(aggList);

    aggList.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent e) { 
        JComboBox cb = (JComboBox)e.getSource();
        int index = cb.getSelectedIndex();
        if (index == 0) {
          arg1.setEnabled(false);
          arg1.setText("N/A");
          arg2.setEnabled(false);
          arg2.setText("N/A");
        }
        else {
          TASKAggInfo ai = (TASKAggInfo)aggregators.elementAt(index-1);
          if (ai.getNumConstArgs() == 1) {
            arg1.setEnabled(true);
            if (arg1.getText().equals("N/A")) {
              arg1.setText("Argument 1");
            }
            arg2.setEnabled(false);
            arg2.setText("N/A");
          }
          else {
            arg1.setEnabled(true);
            if (arg1.getText().equals("N/A")) {
              arg1.setText("Argument 1");
            }
            arg2.setEnabled(true);
            if (arg2.getText().equals("N/A")) {
              arg2.setText("Argument 2");
            }
          }
        }
      }
    });
        
    arg1 = new JTextField(10);
    arg2 = new JTextField(10);
    aggPanel.add(arg1);
    aggPanel.add(arg2);
    arg1.setEnabled(false);
    arg1.setText("N/A");
    arg2.setEnabled(false);
    arg2.setText("N/A");

    JPanel filterPanel = new JPanel(new FlowLayout());
    JLabel label = new JLabel(attribute);
    filterPanel.setBorder(BorderFactory.createTitledBorder("Filter"));
    opMenu = new JComboBox(operators);
    field = new JTextField(30);
    filterPanel.add(label);
    filterPanel.add(opMenu);
    filterPanel.add(field);

    JButton ok = new JButton("OK");
    ok.addActionListener(this);
    JButton cancel = new JButton("Cancel");
    cancel.addActionListener(this);
    JPanel submit = new JPanel(new FlowLayout(FlowLayout.CENTER,5,5));
    submit.add(ok);
    submit.add(cancel);

    JPanel main = new JPanel(new GridLayout(0,1));
    main.add(aggPanel);
    main.add(filterPanel);
    main.add(submit);
    
    getContentPane().add(main);

    addWindowListener(new WindowAdapter() {
      public void windowClosing(WindowEvent e) {
      }
    });

    setResizable(false);
  }

  /**
   * This method is called when an user input event is routed to this dialog. It handles the selection 
   * of the buttons.
   *
   * @param e User input event
   */
  public void actionPerformed(ActionEvent e) {
    String command = e.getActionCommand();
    if (command.equals("OK")) {
      if (validateData()) {
        validData = true;
        setVisible(false);
        int index = aggList.getSelectedIndex();
        if (index != 0) {
          TASKAggInfo agg = (TASKAggInfo)aggregators.elementAt(aggList.getSelectedIndex()-1);
        }
      }
    }
    else if (command.equals("Cancel")) {
      setVisible(false);
    }
  }

  /**
   * This method validates the data, ensuring that the given id is a positive integer and has not been
   * used before
   *
   * @return Whether the mote id entered is valid
   */
  private boolean validateData() {
    TASKAggInfo agg = null;
    int index = aggList.getSelectedIndex();
    if (index != 0) {
       agg = (TASKAggInfo)aggregators.elementAt(aggList.getSelectedIndex()-1);
    }

    if (getArgument1() == BAD_ARGUMENT) {
      JOptionPane.showMessageDialog(this, "Argument 1 must be of type: "+TASKTypes.TypeName[agg.getArgType()], "Error", JOptionPane.ERROR_MESSAGE);
      return false;
    }
    else if (getArgument2() == BAD_ARGUMENT) {
      JOptionPane.showMessageDialog(this, "Argument 2 must be of type: "+TASKTypes.TypeName[agg.getArgType()], "Error", JOptionPane.ERROR_MESSAGE);
      return false;
    }
    else if (getOperand() == BAD_ARGUMENT) {
      JOptionPane.showMessageDialog(this, "Filter value must be of type integer", "Error", JOptionPane.ERROR_MESSAGE);
      return false;
    }
    return true;
  }

  /**
   * This method indicates whether the input provided by the user is valid or not
   *
   * @return whether the user input is valid or not
   */
  public boolean isDataValid() {
    return validData;
  }

  public Clause getClause() {
    return new Clause(attribute, (String)aggList.getSelectedItem(), opMenu.getSelectedIndex(), getOperand(), getArgument1(), getArgument2());
  }

  public int getArgument1() {
    int arg;
    if (arg1.getText().equals("N/A")) {
      return NO_ARGUMENT;
    }
    try {
      arg = Integer.parseInt(arg1.getText());
    } catch (NumberFormatException nfe) {
        System.out.println("AttributeDialog arg1: nfe: "+ nfe);
        return BAD_ARGUMENT;
    }
    return arg;
  }

  public int getArgument2() {
    int arg;
    if (arg2.getText().equals("N/A")) {
      return NO_ARGUMENT;
    }
    try {
      arg = Integer.parseInt(arg2.getText());
    } catch (NumberFormatException nfe) {
        System.out.println("AttributeDialog arg2: nfe: "+ nfe);
        return BAD_ARGUMENT;
    }
    return arg;
  }

  public int getOperand() {
    int operand = NO_ARGUMENT;
    if (field.getText().trim().length() == 0) {
      return operand;
    }
    try {
      operand = Integer.parseInt(field.getText());
    } catch (NumberFormatException nfe) {
        return BAD_ARGUMENT;
    }
    return operand;
  }
}
