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
 * This class is a dialog that allows a user to edit or create a configuration for a sensor network. This 
 * includes giving it a name, a background image (like a map), registering the image with a
 * coordinate system and placing motes on the image.
 */
public class ConfigurationDialog extends JDialog implements ActionListener {

  private boolean validData = false;
  private Configuration config;
  private JTextField height, width, configName, imageName;
  private JLabel label1;
  private String mode;
  private Vector usedNames;

  /**
   * Constructor for the dialog
   *
   * @param aFrame Parent frame for the dialog
   * @param mode New or Edit mode for the configuration
   * @param config Configuration being edited or created
   * @param usedNames List of names of configurations already in use
   */
  public ConfigurationDialog(Frame aFrame, String mode, Configuration config, Vector names) {
    super(aFrame, true);
    if (mode.equals(TASKDeploy.NEW)) {
      setTitle("New Configuration Editor");
    }
    else {
      setTitle("Configuration Editor");
    }
    this.mode = mode;
    this.usedNames = names;
    if (usedNames == null) {
      usedNames = new Vector();
    }

    this.config = config;
    if (mode.equals(TASKDeploy.NEW)) {
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
	if (mode.equals(TASKDeploy.NEW)) {
      height = new JTextField(" height ");
      width = new JTextField(" width ");
	}
	else {
      height = new JTextField(Integer.toString(config.getImageHeight()),8);
	  width = new JTextField(Integer.toString(config.getImageWidth()),8);
	}
    JButton select = new JButton("Select");
    
    if (mode.equals(TASKDeploy.NEW)) {
      imageName = new JTextField(" No file selected ", 20);
    }
    else {
      imageName = new JTextField(config.getImageName(), 20);
    }

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
    else if (mode.equals(TASKDeploy.NEW)) {
      if ((usedNames != null) && usedNames.contains(cName)) {
        JOptionPane.showMessageDialog(this, "Configuration with this name, "+cName+", already exists", "Error", JOptionPane.ERROR_MESSAGE);
        error = true;
      }
    }
    
    if (!error) {
      if (iName.equals("No file selected")) {
        if ((wVal.equals("width")) || (hVal.equals("height"))) {
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
    }
 
    if (!error) {
      config.setName(cName);
      if (!iName.equalsIgnoreCase("No file selected")) {
        config.setImageName(iName);
      }
      else {
        config.setImageHeight(iHeight);
        config.setImageWidth(iWidth);
System.out.println(config.getImageHeight()+", "+config.getImageWidth());
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
