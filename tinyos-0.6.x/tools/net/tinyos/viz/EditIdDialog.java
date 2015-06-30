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
 * This class allows a user to enter/edit the id for a mote. The id must be a positive integer that
 * has not already been used before.
 */
public class EditIdDialog extends JDialog implements ActionListener {

  private boolean validData = false;
  private Configuration config;
  private JTextField moteId;
  private JLabel label1, label2;
  private Motes motes;
  private int id = Mote.INVALID_ID;

  /**
   * Add mode
   */
  public static final int ADD = 1;

  /**
   * Edit mode
   */
  public static final int EDIT = 2;

  /**
   * Constructor that creates the dialog allowing a user to edit/add the id of a mote.
   *
   * @param aFrame Parent frame for the dialog box
   * @param motes List of existing motes
   * @param mode Edit or Add mode
   */
  public EditIdDialog(Frame aFrame, Motes motes, int id, int mode) {
    super(aFrame, true);

    this.motes = motes;

    if (mode == ADD) {
      setTitle("Enter Mote Id");
      label1 = new JLabel("Enter the mote id:");
      moteId = new JTextField(6);
    }
    else {
      setTitle("Edit Mote Id");
      label1 = new JLabel("Edit the mote id:");
      moteId = new JTextField(String.valueOf(id),6);
    }
    moteId.setMaximumSize(new Dimension(6*11, 20));
    moteId.setMinimumSize(new Dimension(6*11, 20));

    JButton ok = new JButton("OK");
    ok.addActionListener(this);
    JButton cancel = new JButton("Cancel");
    cancel.addActionListener(this);

    JPanel main = new JPanel(new GridLayout(0,1));
    JPanel name = new JPanel(new BorderLayout(5,5));
    name.add(label1, BorderLayout.WEST);
    name.add(moteId, BorderLayout.EAST);
    main.add(name);

    label2 = new JLabel("Status Message: ...");
    label2.setMinimumSize(new Dimension(50*11, 20));
    main.add(label2);

    JPanel submit = new JPanel(new FlowLayout(FlowLayout.CENTER,5,5));
    submit.add(ok);
    submit.add(cancel);
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
    // make sure valid int given and unused int given
    try {
      id = Integer.valueOf(moteId.getText()).intValue();
    } catch (NumberFormatException nfe) {
        label2.setText("Not an integer");
        return false;
    }
    
    if (motes.idExists(id)) {
      label2.setText("Id already in use");
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

  /**
   * This method returns the mote id entered by the user
   *
   * @return Mote id entered by the user
   */
  public int getId() {
    return id;
  }
}