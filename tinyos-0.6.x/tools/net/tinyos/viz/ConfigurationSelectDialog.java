/*
 * IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 * By downloading, copying, installing or using the software you agree to this
 * license.  If you do not agree to this license, do not download, install,
 * copy or use the software.
 * 
 * Intel Open Source License 
 * 
 * Copyright (c) 1996-2002 Intel Corporation. All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 	Redistributions of source code must retain the above copyright notice,
 * 	this list of conditions and the following disclaimer. 
 * 
 * 	Redistributions in binary form must reproduce the above copyright
 * 	notice, this list of conditions and the following disclaimer in the
 * 	documentation and/or other materials provided with the distribution. 
 * 
 * 	Neither the name of the Intel Corporation nor the names of its
 * 	contributors may be used to endorse or promote products derived from
 * 	this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.viz;

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
    JLabel label1 = new JLabel("Choose the configuration to" +action+":");

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
}
