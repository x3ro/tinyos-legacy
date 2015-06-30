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
 * This class is a dialog that allows a user to edit or create a configuration for a sensor network. This 
 * includes giving it a name, a background image (like a map), registering the image with a
 * coordinate system and placing motes on the image.
 */
public class ConfigurationDialog extends JDialog implements ActionListener {

  private boolean validData = false;
  private Configuration config;
  private JTextField height, width, configName, imageName;
  private JLabel label1;

  private Vector usedNames;

  /**
   * Constructor for the dialog
   *
   * @param aFrame Parent frame for the dialog
   * @param mode New or Edit mode for the configuration
   * @param config Configuration being edited or created
   * @param usedNames List of names of configurations already in use
   */
  public ConfigurationDialog(Frame aFrame, String mode, Configuration config, Vector usedNames) {
    super(aFrame, true);
    if (mode.equals(setup.NEW)) {
      setTitle("New Configuration Editor");
    }
    else {
      setTitle("Configuration Editor");
    }

    if (usedNames == null) {
      usedNames = new Vector();
    }

    this.config = config;
    if (mode.equals(setup.NEW)) {
      label1 = new JLabel("Enter the name of the configuration:");
      configName = new JTextField(15);
    }
    else {
      label1 = new JLabel("Name of the configuration:");
      configName = new JTextField(config.getName(),15);
      configName.setEditable(false);
    }
    configName.setMaximumSize(new Dimension(15*11, 20));
    configName.setMinimumSize(new Dimension(15*11, 20));

    JLabel label2 = new JLabel("Enter the dimensions (in pixels) for a blank image or select an image to use:");
    height = new JTextField(" height ");
    width = new JTextField(" width ");
    JButton select = new JButton("Select");
    imageName = new JTextField(" No file selected ", 20);
    imageName.setEditable(false);
    select.addActionListener(this);
    JButton ok = new JButton("OK");
    ok.addActionListener(this);
    JButton cancel = new JButton("Cancel");
    cancel.addActionListener(this);

    JPanel main = new JPanel(new GridLayout(0,1));
    JPanel name = new JPanel(new BorderLayout(5,5));
    name.add(label1, BorderLayout.WEST);
    name.add(configName, BorderLayout.EAST);
    main.add(name);

    main.add(label2);
    JPanel image = new JPanel(new FlowLayout(FlowLayout.CENTER,5,5));
    image.add(height);
    image.add(width);
    image.add(select);
    image.add(imageName);
    main.add(image);

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
   * Event handler for button input
   *
   * @param e User input event to handle
   */
  public void actionPerformed(ActionEvent e) {
    String command = e.getActionCommand();

    // if OK clicked, validate data
    if (command.equals("OK")) {
      if (validateData()) {
        setVisible(false);
      }
    }
    // if CANCEL clicked, exit
    else if (command.equals("Cancel")) {
      setVisible(false);
    }
    // if SELECT clicked, bring up a filechooser to allow picking of a background image
    else if (command.equals("Select")) {
      System.out.println("select");
      JFileChooser chooser = new JFileChooser();
      chooser.addChoosableFileFilter(new ImageFilter());
      chooser.setFileView(new ImageFileView());
      chooser.setAccessory(new ImagePreview(chooser));

      int returnVal = chooser.showDialog(this, "Select");
      if (returnVal == JFileChooser.APPROVE_OPTION) {
        File file = chooser.getSelectedFile();
        imageName.setText(file.getAbsolutePath());
      }
      else {
        imageName.setText(" No file selected ");
      }
    }
  }

  /**
   * Checks whether the user-entered data is valid
   *
   * @return whether the user-entered data is valid
   */
  private boolean validateData() {
    // make sure entry in every box
    // make sure config name is not already used
    // make sure that if height and width both entered, both are valid integers
    // make sure that if height and width not both entered, then image name is valid
    String cName = configName.getText().trim();
    String iName = imageName.getText().trim();
    String wVal = width.getText().trim();
    String hVal = height.getText().trim();
    int iWidth = 0;
    int iHeight = 0;

    boolean error = false;
    if (cName.length() == 0) {
      JOptionPane.showMessageDialog(this, "You need to supply a name for this configuration", "Error", JOptionPane.ERROR_MESSAGE);
      error = true;
    }
    else if ((usedNames != null) && usedNames.contains(cName)) {
      JOptionPane.showMessageDialog(this, "Configuration with this name, "+cName+", already exists", "Error", JOptionPane.ERROR_MESSAGE);
      error = true;
    }
    else if (iName.equalsIgnoreCase("No file selected")) {
      if ((wVal.length() == 0) || (hVal.length() == 0)) {
        JOptionPane.showMessageDialog(this, "You need to either select an image or enter a width and height of a blank image", "Error", JOptionPane.ERROR_MESSAGE); 
        error = true;
      }
      else {
        try {
          iHeight = Integer.parseInt(hVal);
          iWidth = Integer.parseInt(wVal);
        } catch (NumberFormatException nfe) {
            JOptionPane.showMessageDialog(this, "Invalid width or height data", "Error", JOptionPane.ERROR_MESSAGE);
            error = true;
        }
        if ((!error) && ((iHeight < 10) || (iWidth < 10))) {
          JOptionPane.showMessageDialog(this, "Invalid width or height data: must be greater than 10", "Error", JOptionPane.ERROR_MESSAGE);
          error = true;
        }
      }
    }
 
    if (!error) {
      config.setName(cName);
      if (!iName.equalsIgnoreCase("No file selected")) {
        config.setImageName(iName);
      }
      else {
        config.setImageHeight(iHeight);
        config.setImageWidth(iWidth);
      }
      validData = true;
    }
    return !error;
  }

  /**
   * Indicates whether the data is valid or not
   *
   * @return whether the data is valid or not
   */
  public boolean isDataValid() {
    return validData;
  }
}