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
import java.awt.geom.*;
import javax.swing.*;
import javax.swing.event.*;
import java.util.*;
import java.sql.*;
import java.text.DecimalFormat;
import java.io.IOException;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

import net.tinyos.task.taskapi.TASKClient;
import net.tinyos.task.taskapi.TASKClientInfo;
import net.tinyos.task.taskapi.TASKMoteClientInfo;

/**
 * This class supports a user in setting up and configuring a sensor network
 */
public class TASKVisualizer implements javax.swing.event.ChangeListener /*
implements ActionListener, MoveEventListener, AddEventListener, ChangeListener, ZGroupListener, ZMouseListener*/
 {

  /**
   * Width of the scrolling pane
   */
  public static final int SCROLL_WIDTH = 1024;

  /**
   * Height of the scrolling pane
   */
  public static final int SCROLL_HEIGHT = 800;

  /**
   * Pan mode for interaction
   */
  public static final int PAN_MODE = 1;

  /**
   * Add mode for interaction
   */
  public static final int ADD_MODE = 2;

  /**
   * Remove mode for interaction
   */
  public static final int REMOVE_MODE = 3;

  /**
   * Deployment mode for tab
   */
  public static final int DEPLOYMENT_MODE = 0;

  /**
   * Configuration mode for tab
   */
  public static final int CONFIGURATION_MODE = 1;

  /**
   * Command mode for interaction
   */
  public static final int COMMAND_MODE = 2;

  /**
   * Visualization mode for interaction
   */
  public static final int VISUALIZATION_MODE = 3;

  public static final String NEW = "NEW";
  public static final String EDIT = "EDIT";

  /**
   * TASK Client Info tag for configuration information
   */
  public static final String CONFIGURATION = "CONFIGURATION";

  private JMenuItem configLoad, configNew, configSave, configExit;
  private JFrame frame;
  private Configuration config;
  private JMenu configurationMenu;
  Motes motes = new Motes();
  private TASKClient client;
  JTabbedPane jtb;
  private JPanel tab1, tab2, tab3, tab4;
  TASKDeploy deploy;
  TASKCommands commands;
  TASKConfiguration configuration;
  TASKVisualization visualization;
  JMenuBar menubar;
  JMenu sensorMenu;

  /**
   * Constructor that begins the setup of configuration management using default TASK Server port
   *
   * @param host TASKServer host
   */
  public TASKVisualizer(String host) {
    try {
      client = new TASKClient(host);
    } catch (IOException ioe) {
        System.out.println("setup IOE: "+ioe);
        System.exit(-1);
    }
    prepareFrame();
  }

  /**
   * Constructor that begins the setup of configuration management using the given TASK Server info
   *
   * @param host TASKServer host
   * @param port TASKServer port
   */
  public TASKVisualizer(String host, int port) {
    try {
      client = new TASKClient(host,port);
    } catch (IOException ioe) {
        System.out.println("setup IOE: "+ioe);
        System.exit(-1);
    }
    prepareFrame();
  }

  /**
   * Creates the frame for setting up and managing configurations
   */
  public void prepareFrame() {
    config = new Configuration();

    // create the frame
    frame = new JFrame("Tiny Application Sensor Kit (TASK) Client Tool");
    frame.addWindowListener(new WindowAdapter() {
      public void windowClosing(WindowEvent e) {
        System.exit(0);
      }
    });

     // create the menu bar
    menubar = new JMenuBar();
    frame.setJMenuBar(menubar);
    
    configurationMenu = new JMenu("Configuration");
    menubar.add(configurationMenu);
    configurationMenu.setMnemonic(KeyEvent.VK_C);

    configNew = new JMenuItem("New", KeyEvent.VK_N);
    configNew.setActionCommand("New Configuration");
    configNew.setToolTipText("New Configuration");
    configNew.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        newConfiguration();
      }
    });
    configurationMenu.add(configNew);

    configLoad = new JMenuItem("Load", KeyEvent.VK_L);
    configLoad.setActionCommand("Load Configuration");
    configLoad.setToolTipText("Load Configuration");
    configLoad.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        loadConfiguration();
      }
    });
    configurationMenu.add(configLoad);
    configLoad.setEnabled(true);


    configSave = new JMenuItem("Save", KeyEvent.VK_S);
    configSave.setActionCommand("Save Configuration");
    configSave.setToolTipText("Save Configuration");
    configSave.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        saveConfiguration();
      }
    });
    configurationMenu.add(configSave);
    configSave.setEnabled(false);

    configurationMenu.addSeparator();

    configExit = new JMenuItem("Exit", KeyEvent.VK_X);
    configExit.setActionCommand("Exit");
    configExit.setToolTipText("Exit Application");
    configExit.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        exitConfiguration();
      }
    });
    configurationMenu.add(configExit);

    Vector configs = getConfigurations();

    if (configs.size() == 0) {
      configLoad.setEnabled(false);
    }

    jtb = new JTabbedPane();

    // make the tabs
    tab1 = new JPanel();
    tab2 = new JPanel();
    tab3 = new JPanel();
    tab4 = new JPanel();
    jtb.addTab("Deployment",    null, tab1, "Sensor Network Deployment Tool");
    jtb.addTab("Query",         null, tab2, "Sensor Network Query Tool");
    jtb.addTab("Command",       null, tab3, "Sensor Network Command Tool");
    jtb.addTab("Visualization", null, tab4, "Sensor Network Visualization Tool");

    jtb.addChangeListener(this);

    // to start, configuration, command, visualization tabs need to be disabled
    frame.getContentPane().add(jtb);
    SpringLayout sl = new SpringLayout();
    frame.getContentPane().setLayout(sl);
    frame.validate();
    frame.setSize(SCROLL_WIDTH,SCROLL_HEIGHT);

    frame.setVisible(true);

    deploy = new TASKDeploy(frame,this,client,tab1);
    configuration = new TASKConfiguration(frame,client,tab2);
    commands = new TASKCommands(frame,client,tab3);
    visualization = new TASKVisualization(frame,this,client,tab4);
    TASKVisualization.setContainerSize(frame.getContentPane(), 5);
  }

  public void newConfiguration() {
    deploy.checkSave();
    // in new configuration, 
    jtb.setSelectedIndex(DEPLOYMENT_MODE);
    deploy.newConfiguration();
  }

  public void loadConfiguration() {
    deploy.checkSave();
    // in load configuration, 

    // get the existing configurations and allow a user to select one
    Vector configs = getConfigurations();
    if (configs.size() == 0) {
      JOptionPane.showMessageDialog(frame, "There are no configurations to load", "No Configurations Available", JOptionPane.ERROR_MESSAGE);
      return;
    }

    ConfigurationSelectDialog csdialog = new ConfigurationSelectDialog(frame, "load", configs);
    csdialog.pack();
    csdialog.setLocationRelativeTo(frame);
    csdialog.setVisible(true);

    if (csdialog.isDataValid()) {
      config = new Configuration(client.getClientInfo(csdialog.getSelectedConfiguration()));
      config.verifyFileName(frame);

      switch(jtb.getSelectedIndex()) {
        case DEPLOYMENT_MODE:
          // AKD - added to address re-editing concern
          int edit = JOptionPane.showConfirmDialog(frame, "Do you want to edit this configuration?", "Edit Configuration", JOptionPane.YES_NO_OPTION); 
          if (edit == JOptionPane.YES_OPTION) {
            deploy.editConfiguration(config, configs);
          }
          else {
            deploy.viewConfiguration(config);
          }
          break;
        case CONFIGURATION_MODE:
          configuration.preparePanel(csdialog.getSelectedConfiguration());
          break;
        case COMMAND_MODE:
          commands.preparePanel(csdialog.getSelectedConfiguration());
          break;
        case VISUALIZATION_MODE:
          visualization.preparePanel(config);
          break;
      }
    }
  }

  /**
   * Save configuration to the given table
   *
   * @param table Table to save configuration to
   */
  private void saveConfiguration() {
    deploy.saveConfiguration();
    configSave.setEnabled(false);
    configLoad.setEnabled(true);
  }

  /**
   * Exits the application, prompting for saving the current configuration if necessary
   */
  private void exitConfiguration() {
    deploy.checkSave();
    System.exit(0);
  }

  public void setConfiguration(Configuration c) {
    this.config = c;
    if (config.needsSave()) {
      configSave.setEnabled(true);
    }
  }

  public void setMotes(Motes m) {
    this.motes = m;
  }

  public void stateChanged(ChangeEvent e) {
    if (config.getName() != null) {
      switch(jtb.getSelectedIndex()) {
        case DEPLOYMENT_MODE:
          configNew.setEnabled(true);
          configLoad.setEnabled(true);
          configExit.setEnabled(true);
          deploy.checkSave();
          removeSensorMenu();
          deploy.viewConfiguration(config);
          break;
        case CONFIGURATION_MODE:
          configLoad.setEnabled(true);
          configExit.setEnabled(true);
          deploy.checkSave();
          removeSensorMenu();
          configuration.preparePanel(config.getName());
          break;
        case COMMAND_MODE:
          configLoad.setEnabled(true);
          configExit.setEnabled(true);
          deploy.checkSave();
          commands.preparePanel(config.getName());
          removeSensorMenu();
          break;
        case VISUALIZATION_MODE:
          configLoad.setEnabled(true);
          configExit.setEnabled(true);
          deploy.checkSave();
          visualization.preparePanel(config);
          break;
      }
    }
  }

  /**
   * Retrieves the existing configurations from the TASK Server
   *
   * @return Names of the existing configurations
   */
  public Vector getConfigurations() {
    String clientInfos[] = client.getClientInfos();
    Vector configs = new Vector();
    for (int i=0; i<clientInfos.length; i++) {
      configs.addElement(clientInfos[i]);
    }
    return configs;
  }

  public void addSensorMenu(JMenu sensorMenu) {
    this.sensorMenu = sensorMenu;
    menubar.add(sensorMenu);
  }

  public void removeSensorMenu() {
    if (sensorMenu != null) {
      menubar.remove(sensorMenu);
    }
  }
    
  /**
   * Main method for the configuration setup 
   */
  public static void main(String argv[]) {
    if (argv.length == 2) {
      TASKVisualizer viz = new TASKVisualizer(argv[0], Integer.parseInt(argv[1]));
    }
    else if (argv.length == 1) {
      TASKVisualizer viz = new TASKVisualizer(argv[0]);
    }
    else {
      System.out.println("USAGE: net.tinyos.task.taskviz.TASKVisualizer <TASKServer host> [TASKServer port]");
    }
  }
}
