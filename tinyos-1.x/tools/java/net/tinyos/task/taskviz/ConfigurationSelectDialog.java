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

/**
 * This class allows a user to select a sensor network configuration to use, from a given list 
 */
public class ConfigurationSelectDialog extends JDialog implements ActionListener {

  private JList list;
  private String action;
  private boolean dataValid = false;

  /**
   * Constructor that creates the dialog allowing the user to select a configuration
   *
   * @param aFrame Parent frame for the dialog box
   * @param action Action being taken: edit or create
   * @param names List of possible configuration names
   */
  public ConfigurationSelectDialog(Frame aFrame, String action, Vector names) {
    // create the dialog
    super(aFrame, "Configuration Select", true);
    this.action = action;

    // add a label and create a scrollable list
    JLabel label1 = new JLabel("Choose the configuration to " +action+":");

    list = new JList(names);
    list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    list.setSelectedIndex(0);
    JScrollPane listScrollPane = new JScrollPane(list);
    
    // add standard buttons
    JButton ok = new JButton(action.toUpperCase());
    ok.addActionListener(this);
    JButton cancel = new JButton("Cancel");
    cancel.addActionListener(this);

    JPanel main = new JPanel(new BorderLayout());
    main.add(label1, BorderLayout.NORTH);
    main.add(listScrollPane, BorderLayout.CENTER);

    JPanel submit = new JPanel(new FlowLayout(FlowLayout.CENTER,5,5));
    submit.add(ok);
    submit.add(cancel);
    main.add(submit, BorderLayout.SOUTH);

    getContentPane().add(main);
  }

  /**
   * This method is called when an user input event is routed to this dialog. It handles the selection 
   * of the buttons.
   *
   * @param e User input event
   */
  public void actionPerformed(ActionEvent e) {
    String command = e.getActionCommand();
    if (command.equals(action.toUpperCase())) {
      dataValid = true;
      setVisible(false);
    } 
    else if (command.equals("Cancel")) {
      setVisible(false);
    }
  }

  /**
   * This method indicates whether the input provided by the user is valid or not
   *
   * @return whether the user input is valid or not
   */
  public boolean isDataValid() {
    return dataValid;
  }

  /**
   * This method returns the name of the selected configuration
   *
   * @return Name of the selected configuration
   */
  public String getSelectedConfiguration() {
    return (String)list.getSelectedValue();
  }

  /**
   * This method returns the index of the selected configuration
   *
   * @return Index of the selected configuration
   */
  public int getSelectedConfigurationIndex() {
    return list.getSelectedIndex();
  }
}
