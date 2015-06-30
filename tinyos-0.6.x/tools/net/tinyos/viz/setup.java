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

import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;
import java.util.*;
import java.sql.*;
import java.text.DecimalFormat;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

import gwe.sql.gweMysqlDriver;

/**
 * This class supports a user in setting up and configuring a sensor network
 */
public class setup implements ActionListener, MoveEventListener, AddEventListener, ChangeListener {

  public static final boolean HAVE_DB = true;  // debugging flag for testing at home

  /**
   * The default type of database
   */
  public static final String DEFAULT_DB_TYPE = "mysql"; 

  /**
   * The default host running the database
   */
  public static final String DEFAULT_DB_HOST = "10.212.2.158";

  /**
   * The default port the database is running on
   */
  public static final int DEFAULT_DB_PORT = 3306;

  /**
   * The default name of the database
   */
  public static final String DEFAULT_DB_PATH = "retreattest";

  /**
   * The default username for accessing the database
   */
  public static final String DEFAULT_DB_USER = "tinyos";

  /**
   * The default password for accessing the database
   */
  public static final String DEFAULT_DB_PASSWORD = "mote";

  /**
   * The default table containing the configuration information
   */
  public static final String DEFAULT_DB_CONFIG_TABLE = "vizconfig";

  /**
   * Edit configuration mode
   */
  public static final String EDIT = "edit";

  /**
   * New configuration mode
   */
  public static final String NEW = "new";

  /**
   * Width of the scrolling pane
   */
  public static final int SCROLL_WIDTH = 600;

  /**
   * Height of the scrolling pane
   */
  public static final int SCROLL_HEIGHT = 600;

  /**
   * Distance between the grid lines
   */
  public static final int GRID_DISTANCE = 5; // in meters/feet

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
   * Auto mode for interaction
   */
  public static final int AUTO_MODE = 4;

  private JMenuItem configLoad, configNew, configEdit, configSave, configClose, configExit;
  private JFrame frame;
  private Configuration config;
  private String dbConnection, dbUser, dbPass;
  private JMenu configuration;
  private JScrollPane imagePane;

  private boolean showGrid = false;
  BufferedImage imageWithGrid;
  
  private ZEventHandler currentEventHandler = null;
  private ZPanEventHandler panEventHandler = null;
  private ZoomEventHandler zoomEventHandler = null;
  private AddEventHandler addEventHandler = null;
  private MoveEventHandler moveEventHandler = null;
  private RemoveEventHandler removeEventHandler = null;
  private AutoEventHandler autoEventHandler = null;
  ZImageCanvas canvas = null;
  JLabel xpos, ypos, moteId;
  JScrollPane scrollPane;
  JPanel view;

  DecimalFormat formatter;
  
  Motes motes = new Motes();
  private ToolBarButton add, remove, auto;
  private String dbType;

  /**
   * Constructor that begins the setup of configuration management using default database connections
   */
  public setup() {
    dbConnection = "jdbc:"+DEFAULT_DB_TYPE+"://"+DEFAULT_DB_HOST+":"+DEFAULT_DB_PORT+"/"+DEFAULT_DB_PATH;
    dbType = DEFAULT_DB_TYPE;
    dbUser = DEFAULT_DB_USER;
    dbPass = DEFAULT_DB_PASSWORD;
    beginSetup();
  }

  /**
   * Constructor that begins the setup of configuration management using the given database connections
   *
   * @param dbType Type of database
   * @param dbHost Name of the machine hosting the database
   * @param dbPort Port number the database is running on
   * @param dbPath Name of the database
   * @param dbUser Username to access the database
   * @param dbPass Password to access the database
   */
  public setup(String dbType, String dbHost, int dbPort, String dbPath, String dbUser, String dbPass) {
    dbConnection = "jdbc:"+dbType+"://"+dbHost+":"+dbPort+"/"+dbPath;
    this.dbType = dbType;
    this.dbUser = dbUser;
    this.dbPass = dbPass;
    beginSetup();
  }

  /**
   * This method makes sure the database can be reached and that the configuration table exists.
   * If the table doesn't exist, it creates the table
   */
  private void beginSetup() {
    try {
      if (dbType.equals("mysql")) {
        Class.forName("gwe.sql.gweMysqlDriver");
      }
      else if (dbType.equals("postgresql")) {
        Class.forName("org.postgresql.Driver");
      }
    } catch (ClassNotFoundException cnfe) {
        System.out.println("setup constructor ClassNotFound: "+cnfe);
        System.out.println("Could not load the mysql driver: please check your classpath");
        System.exit(-1);
    }

    try {
      if (!tableExists(DEFAULT_DB_CONFIG_TABLE)) {
        createConfigTable(DEFAULT_DB_CONFIG_TABLE);
      }
    } catch (SQLException sqle) {
        System.out.println("setup beginSetup SQLException: "+sqle);
        System.out.println("Trouble interacting with vizConfig database table");
        System.exit(-2);
    }
    prepareFrame();
  }

  /**
   * Creates the frame for setting up and managing configurations
   */
  public void prepareFrame() {
    config = new Configuration();

    // create the frame
    frame = new JFrame("Sensor Network Visualization and Diagnostic Tool");
    frame.addWindowListener(new WindowAdapter() {
      public void windowClosing(WindowEvent e) {
        System.exit(0);
      }
    });

     // create the menu bar
    JMenuBar menubar = new JMenuBar();
    frame.setJMenuBar(menubar);
    
    configuration = new JMenu("Configuration");
    menubar.add(configuration);
    configuration.setMnemonic(KeyEvent.VK_C);

    configNew = new JMenuItem("New", KeyEvent.VK_N);
    configNew.setActionCommand("New Configuration");
    configNew.setToolTipText("New Configuration");
    configNew.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        newConfiguration();
      }
    });
    configuration.add(configNew);

    configEdit = new JMenuItem("Edit", KeyEvent.VK_E);
    configEdit.setActionCommand("Edit Configuration");
    configEdit.setToolTipText("Edit Configuration");
    configEdit.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        editConfiguration(DEFAULT_DB_CONFIG_TABLE);
      }
    });
    configuration.add(configEdit);

    configLoad = new JMenuItem("Load", KeyEvent.VK_L);
    configLoad.setActionCommand("Load Configuration");
    configLoad.setToolTipText("Load Configuration");
    configLoad.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        loadConfiguration(DEFAULT_DB_CONFIG_TABLE);
      }
    });
    configuration.add(configLoad);

    configSave = new JMenuItem("Save", KeyEvent.VK_S);
    configSave.setActionCommand("Save Configuration");
    configSave.setToolTipText("Save Configuration");
    configSave.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        saveConfiguration(DEFAULT_DB_CONFIG_TABLE);
      }
    });
    configuration.add(configSave);
    configSave.setEnabled(false);

    configuration.addSeparator();

    configClose = new JMenuItem("Close", KeyEvent.VK_C);
    configClose.setActionCommand("Close Configuration");
    configClose.setToolTipText("Close Configuration");
    configClose.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        closeConfiguration();
      }
    });
    configuration.add(configClose);
    configClose.setEnabled(false);

    configuration.addSeparator();

    configExit = new JMenuItem("Exit", KeyEvent.VK_X);
    configExit.setActionCommand("Exit");
    configExit.setToolTipText("Exit Application");
    configExit.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        exitConfiguration();
      }
    });
    configuration.add(configExit);

    Vector configNames = getConfigurations(DEFAULT_DB_CONFIG_TABLE);
    if (configNames.size() == 0) {
      configEdit.setEnabled(false);
      configLoad.setEnabled(false);
    }

    frame.getContentPane().add(createToolBar(), BorderLayout.NORTH);

    frame.setSize(400,200);
    frame.setVisible(true);
  }

  /**
   * Creates the toolbar for the user interface
   *
   * @return The created toolbar
   */
  private JToolBar createToolBar() {
    JToolBar toolbar = new JToolBar();
    Insets margins = new Insets(0, 0, 0, 0);

    ButtonGroup group1 = new ButtonGroup();

    ToolBarButton edit = new ToolBarButton("images/E.gif");
    edit.setToolTipText("Edit motes");
    edit.setMargin(margins);
    edit.setActionCommand("edit");
    edit.setSelected(true);
    edit.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(ADD_MODE);
        add.enable();
        remove.enable();
        auto.enable();
        add.setSelected(true);
      }
    });
    group1.add(edit);
    toolbar.add(edit);

    ToolBarButton vis = new ToolBarButton("images/V.gif");
    vis.setToolTipText("Visualize mote network");
    vis.setMargin(margins);
    vis.setActionCommand("visualize");
    vis.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
// AKD        setMode(VIZ_MODE);
        add.setSelected(false);
        remove.setSelected(false);
        auto.setSelected(false);
        add.disable();
        remove.disable();
        auto.disable();
      }
    });
    group1.add(vis);
    toolbar.add(vis);

    toolbar.addSeparator();

    ButtonGroup group2 = new ButtonGroup();

    ToolBarButton pan = new ToolBarButton("images/P.gif");
    pan.setToolTipText("Pan view");
    pan.setMargin(margins);
    pan.setActionCommand("pan");
    pan.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(PAN_MODE);
      }
    });
    group2.add(pan);
    toolbar.add(pan);

    add = new ToolBarButton("images/A.gif");
    add.setToolTipText("Add mote");
    add.setMargin(margins);
    add.setActionCommand("add");
    add.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(ADD_MODE);
      }
    });
    group2.add(add);
    toolbar.add(add);

    remove = new ToolBarButton("images/R.gif");
    remove.setToolTipText("Remove mote");
    remove.setMargin(margins);
    remove.setActionCommand("pan");
    remove.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(REMOVE_MODE);
      }
    });
    group2.add(remove);
    toolbar.add(remove);

    auto = new ToolBarButton("images/T.gif");
    auto.setToolTipText("Automatic mode");
    auto.setMargin(margins);
    auto.setActionCommand("auto");
    auto.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(AUTO_MODE);
      }
    });
    group2.add(auto);
    toolbar.add(auto);

    toolbar.setFloatable(true);
    return toolbar;
  }

  /**
   * Event handler for user input - just for handling toggling the grid for now
   *
   * @param e Event to handle
   */
  public void actionPerformed(ActionEvent e) {
    String action = e.getActionCommand();
      
    System.out.println(action);
    if (action.equals("Grid")) {
      JToggleButton button = (JToggleButton)e.getSource();
      showGrid = button.isSelected();
      frame.repaint();
    }
  }

  /**
   * Checks if the current configuration has been modified since the last save. If so, a dialog prompts
   * the user to save the configuration
   */
  private void checkSave() {
    if (config.needsSave() || motes.needsSave()) {
      System.out.println("need save");
      int save = JOptionPane.showConfirmDialog(frame, "Do you want to save this configuration?", "Save Configuration", JOptionPane.YES_NO_OPTION);
      if (save == JOptionPane.YES_OPTION) {
        saveConfiguration(DEFAULT_DB_CONFIG_TABLE);
      }
    }
  }

  /**
   * When the user selects new configuration from the menu, a dialog is created to support creation
   */
  private void newConfiguration() {
    checkSave();
    config = new Configuration();

    // create a ConfigurationDialog
    ConfigurationDialog cdialog = new ConfigurationDialog(frame, NEW, config, getConfigurations());
    cdialog.pack();
    cdialog.setLocationRelativeTo(frame);
    cdialog.setVisible(true);

    // if the data is valid, create an ImageDialog to allow registration of the image
    if (cdialog.isDataValid()) {
      System.out.println("config name: "+config.getName());
      if (config.useBlankImage()) {
        System.out.println("blank image: "+config.getImageHeight()+" x "+config.getImageWidth());
      }
      else {
        System.out.println("image name: "+addSlashes(config.getImageName()));
        config.setImageName(addSlashes(config.getImageName()));
      }

      ImageDialog idialog = new ImageDialog(frame, NEW, config);
      idialog.pack();
      idialog.setLocationRelativeTo(frame);
      idialog.setVisible(true);  

      // if the ImageDialog data is valid, create a blank motes object and calls viewConfiguration
      if (idialog.isDataValid()) {
        System.out.println("minPixelX: "+config.getMinimumPixelX());
        System.out.println("minPixelY: "+config.getMinimumPixelY());
        System.out.println("maxPixelX: "+config.getMaximumPixelX());
        System.out.println("maxPixelY: "+config.getMaximumPixelY());
        System.out.println("minRealX: "+config.getMinimumRealX());
        System.out.println("minRealY: "+config.getMinimumRealY());
        System.out.println("maxRealX: "+config.getMaximumRealX());
        System.out.println("maxRealY: "+config.getMaximumRealY());
        config.notSaved();
        configSave.setEnabled(true);
        configClose.setEnabled(true);
        motes = new Motes();
        viewConfiguration(DEFAULT_DB_CONFIG_TABLE);
      }
      else {
        config = new Configuration();
      }
    }
  }

  /**
   * When the user chooses the edit a configuration, a dialog containing the current configuration is
   * loaded and is made available for editing, then views the motes information  
   *
   * @param table Table containing the configuration information
   */
  private void editConfiguration(String table) {
    checkSave();

    // get the existing configurations and allow a user to select one
    Vector configNames = getConfigurations(DEFAULT_DB_CONFIG_TABLE);
    if (configNames.size() == 0) {
      JOptionPane.showMessageDialog(frame, "There are no configurations to load", "No Configurations Available", JOptionPane.ERROR_MESSAGE);
      return;
    }
    System.out.println("Configurations: "+configNames.size());
    for (int i=0; i<configNames.size(); i++) {
      System.out.println(configNames.elementAt(i));
    }
    ConfigurationSelectDialog csdialog = new ConfigurationSelectDialog(frame, "edit", configNames);    
    csdialog.pack();
    csdialog.setLocationRelativeTo(frame);
    csdialog.setVisible(true);

    if (csdialog.isDataValid()) {
      System.out.println(csdialog.getSelectedConfiguration()+" chosen");
    }

    // load the selected configuration from the database
    try {
      String s = "SELECT * FROM "+table+" WHERE configName='"+csdialog.getSelectedConfiguration()+"'";
      Connection con = DriverManager.getConnection(dbConnection, dbUser, dbPass);
      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(s);
      rs.next();
      config = new Configuration(rs.getString(1), rs.getString(2), rs.getInt(3), rs.getInt(4),
               rs.getInt(5), rs.getInt(6), rs.getInt(7), rs.getInt(8), rs.getInt(9), rs.getInt(10), rs.getInt(11), rs.getInt(12));
      rs.close();
      stmt.close();
      con.close();
    } catch (SQLException sqle) {
        System.out.println("SQLException: "+sqle+": error reading configuration");
        return;
    }

    config.setImageName(removeSlashes(config.getImageName()));

    // open a ConfigurationDialog to allow editing of the configuration
    ConfigurationDialog cdialog = new ConfigurationDialog(frame, EDIT, config, getConfigurations());
    cdialog.pack();
    cdialog.setLocationRelativeTo(frame);
    cdialog.setVisible(true);

    // if the data is valid, load an ImageDialog to allow registration of the image
    if (cdialog.isDataValid()) {
      System.out.println("config name: "+config.getName());
      if (config.useBlankImage()) {
        System.out.println("blank image: "+config.getImageHeight()+" x "+config.getImageWidth());
      }
      else {
        System.out.println("image name: "+config.getImageName());
        config.setImageName(addSlashes(config.getImageName()));
      }

      ImageDialog idialog = new ImageDialog(frame, EDIT, config);

      idialog.pack();
      idialog.setLocationRelativeTo(frame);
      idialog.setVisible(true);  

      // if the registration information is valid, call viewConfiguration
      if (idialog.isDataValid()) {
        System.out.println("minPixelX: "+config.getMinimumPixelX());
        System.out.println("minPixelY: "+config.getMinimumPixelY());
        System.out.println("maxPixelX: "+config.getMaximumPixelX());
        System.out.println("maxPixelY: "+config.getMaximumPixelY());
        System.out.println("minRealX: "+config.getMinimumRealX());
        System.out.println("minRealY: "+config.getMinimumRealY());
        System.out.println("maxRealX: "+config.getMaximumRealX());
        System.out.println("maxRealY: "+config.getMaximumRealY());
        config.notSaved();
        configSave.setEnabled(true);
        configClose.setEnabled(true);
 
        // AKD - load up motes from d/b table
        // motes = getMotes(config.getName()+"Motes");
        motes = getMotes("motelocation");
        viewConfiguration(table);
      }
    }
  }

  /**
   * When a user selects load configuration from the menu, allow them to select a configuration,
   * load the motes information and view them
   *
   * @param table Table containing the configuration information
   */
  private void loadConfiguration(String table) {
    checkSave();
    Vector configNames = getConfigurations(table);
    System.out.println("Configurations: "+configNames.size());
    for (int i=0; i<configNames.size(); i++) {
      System.out.println(configNames.elementAt(i));
    }
System.out.println("pop up dialog");
    ConfigurationSelectDialog csdialog = new ConfigurationSelectDialog(frame, "load", configNames);
    csdialog.pack();
    csdialog.setLocationRelativeTo(frame);
    csdialog.setVisible(true);

    if (csdialog.isDataValid()) {
      System.out.println(csdialog.getSelectedConfiguration()+" chosen");
    }

System.out.println("dialog done");
    configClose.setEnabled(true);

    // load the configuration from the database
    try {
      String s = "SELECT * FROM "+table+" WHERE configName='"+csdialog.getSelectedConfiguration()+"'";
      Connection con = DriverManager.getConnection(dbConnection, dbUser, dbPass);
      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(s);
      rs.next();
      config = new Configuration(rs.getString(1), rs.getString(2), rs.getInt(3), rs.getInt(4),
               rs.getInt(5), rs.getInt(6), rs.getInt(7), rs.getInt(8), rs.getInt(9), rs.getInt(10), rs.getInt(11), rs.getInt(12));
      rs.close();
      stmt.close();
      con.close();
    } catch (SQLException sqle) {
        System.out.println("SQLException: "+sqle+": error reading configuration");
        return;
    }

    // AKD - load up motes from d/b table
    // motes = getMotes(config.getName()+"Motes");
    motes = getMotes("motelocation");
System.out.println("motes size: "+motes.size());
    viewConfiguration(table);
  }

  /**
   * This method renders the current configuration
   * 
   * @param table Table containing the configuration information
   */
  private void viewConfiguration(String table) {
    if (view != null) {
      frame.getContentPane().remove(view);
    }
    if (scrollPane != null) {
      frame.getContentPane().remove(scrollPane);
    }

    int imageWidth, imageHeight;

    // render image
    if (config.useBlankImage()) {
      imageWidth = config.getImageWidth();
      imageHeight = config.getImageHeight();
      canvas = new ZImageCanvas(imageWidth, imageHeight);
    }
    else {
      ImageIcon icon = new ImageIcon(config.getImageName(), config.getImageName());
      Image base = icon.getImage();
      imageHeight = base.getHeight(null);
      imageWidth = base.getWidth(null);
      canvas = new ZImageCanvas(base);
    }

    // render surrounding rectangle
    ZLayerGroup layer = canvas.getLayer();
    ZLine line = new ZLine(config.getMinimumPixelX(), config.getMinimumPixelY(), 
                           config.getMaximumPixelX(), config.getMinimumPixelY());
    ZVisualLeaf leaf = new ZVisualLeaf(line);
    layer.addChild(leaf);
    line = new ZLine(config.getMinimumPixelX(), config.getMinimumPixelY(), 
                     config.getMinimumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    layer.addChild(leaf);
    line = new ZLine(config.getMaximumPixelX(), config.getMinimumPixelY(), 
                     config.getMaximumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    layer.addChild(leaf);
    line = new ZLine(config.getMinimumPixelX(), config.getMaximumPixelY(), 
                     config.getMaximumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    layer.addChild(leaf);

    // render the static motes
    for (Enumeration e=motes.elements(); e.hasMoreElements(); ) {
      leaf = new ZVisualLeaf((Mote)e.nextElement());
      layer.addChild(leaf);
    }

    JPanel main = new JPanel(new BorderLayout());

    // add scroll pane
    int x=0, y = 0;
    if (imageWidth > SCROLL_WIDTH) {
      x = SCROLL_WIDTH;
    }
    else {
      x = imageWidth;
    }

    if (imageHeight > SCROLL_HEIGHT) {
      y = SCROLL_HEIGHT;
    }
    else {
      y = imageHeight;
    }

    scrollPane = new ZScrollPane(canvas);

    scrollPane.setPreferredSize(new Dimension(x+20, y+20));
    frame.getContentPane().add(scrollPane, BorderLayout.CENTER);

    view = new JPanel(new GridLayout(0,3));
    view.add(new JLabel(" X Position "));
    view.add(new JLabel(" Y Position "));
    view.add(new JLabel(" Mote ID "));
    xpos = new JLabel ("    0.0     ");
    ypos = new JLabel ("    0.0     ");
    moteId = new JLabel("   ID    ");
    view.add(xpos);
    view.add(ypos);
    view.add(moteId);
    frame.getContentPane().add(view, BorderLayout.EAST);

    frame.pack();

    formatter = new DecimalFormat("###.##");

    // create all the event handlers
    panEventHandler = new ZPanEventHandler(canvas.getCameraNode());
    zoomEventHandler = new ZoomEventHandler(canvas.getCameraNode());
    addEventHandler = new AddEventHandler(canvas, this, this, imageWidth, imageHeight, motes, frame);
    moveEventHandler = new MoveEventHandler(canvas, this, imageWidth, imageHeight, true);
    removeEventHandler = new RemoveEventHandler(canvas, canvas.getLayer(), motes, this);
    autoEventHandler = new AutoEventHandler(canvas, motes, imageWidth, imageHeight);
 
    // set the zoom and move event handlers to active
    zoomEventHandler.setActive(true);
    moveEventHandler.setActive(true);

    setMode(ADD_MODE);
/*
    imageWithGrid = new BufferedImage(imageWidth, imageHeight, BufferedImage.TYPE_INT_RGB);
    Graphics g = imageWithGrid.createGraphics();
    g.drawImage(base, 0, 0, null);
    g.setColor(Color.black);
    
    double xdist = Math.abs(config.getMaximumRealX() - config.getMinimumRealX());
    double pxdist = (double)Math.abs((config.getMaximumPixelX() - config.getMinimumPixelX()));
    double xRatio = pxdist/xdist;
    double minX = (double)Math.min(config.getMinimumPixelX(), config.getMaximumPixelX());
    double maxX = (double)Math.max(config.getMinimumPixelX(), config.getMaximumPixelX());
    for (double i=minX; i<=maxX; i+=(xRatio*GRID_DISTANCE)) {
      g.drawLine((int)i,config.getMinimumPixelY(),(int)i,config.getMaximumPixelY());
    }
    g.drawLine(config.getMaximumPixelX(), config.getMinimumPixelY(), config.getMaximumPixelX(), config.getMaximumPixelY());

    double ydist = Math.abs(config.getMaximumRealY() - config.getMinimumRealY());
    double pydist = (double)Math.abs((config.getMaximumPixelY() - config.getMinimumPixelY()));
    double yRatio = pydist/ydist;
    double minY = (double)Math.min(config.getMinimumPixelY(), config.getMaximumPixelY());
    double maxY = (double)Math.max(config.getMinimumPixelY(), config.getMaximumPixelY());
    for (double i=minY; i<=maxY; i+=(yRatio*GRID_DISTANCE)) {
      g.drawLine(config.getMinimumPixelX(),(int)i,config.getMaximumPixelX(),(int)i);
    }
    g.drawLine(config.getMinimumPixelX(), config.getMaximumPixelY(), config.getMaximumPixelX(), config.getMaximumPixelY());
*/
  }
  
  /**
   * Save configuration to the given table
   *
   * @param table Table to save configuration to
   */
  private void saveConfiguration(String table) {
    if (HAVE_DB) {
      try {
        // replace configuration or insert if new
        String s = new String("DELETE FROM "+table+" WHERE configName='"+config.getName()+"'");
        Connection con = DriverManager.getConnection(dbConnection, dbUser, dbPass);
        Statement stmt = con.createStatement();
        stmt.executeUpdate(s);
        if (dbType.equals("mysql")) {
          s = new String("REPLACE INTO "+table+" (configName, imageName, imageWidth, imageHeight, minPixelX, minPixelY, maxPixelX, maxPixelY, minX, minY, maxX, maxY)" +
                 "VALUES ('"+config.getName()+"', '"+config.getImageName()+"', "+config.getImageWidth()+", "+config.getImageHeight()+", "+config.getMinimumPixelX()+", "+config.getMinimumPixelY() + ", "+
                 config.getMaximumPixelX()+", "+config.getMaximumPixelY()+", "+config.getMinimumRealX()+", "+config.getMinimumRealY() + ", "+
                 config.getMaximumRealX()+", "+config.getMaximumRealY()+")");
        }
        else if (dbType.equals("postgresql")) {
          s = new String("INSERT INTO "+table+" (configName, imageName, imageWidth, imageHeight, minPixelX, minPixelY, maxPixelX, maxPixelY, minX, minY, maxX, maxY)" +
                 "VALUES ('"+config.getName()+"', '"+config.getImageName()+"', "+config.getImageWidth()+", "+config.getImageHeight()+", "+config.getMinimumPixelX()+", "+config.getMinimumPixelY() + ", "+
                 config.getMaximumPixelX()+", "+config.getMaximumPixelY()+", "+config.getMinimumRealX()+", "+config.getMinimumRealY() + ", "+
                 config.getMaximumRealX()+", "+config.getMaximumRealY()+")");
        }
        stmt.executeUpdate(s);

// AKD       String motesTable = config.getName()+"Motes";
        String motesTable = "motelocation";
        if (tableExists(motesTable)) {
          // delete all rows from table
          s = new String("DELETE FROM "+motesTable+" WHERE moteid > 0");
          stmt.executeUpdate(s);
        }
        else {
          // create table
          if (dbType.equals("mysql")) {
            s = new String("CREATE TABLE "+motesTable+" ( \nxCoord FLOAT,\nyCoord FLOAT,\n moteid INT)");
          }
          else if (dbType.equals("postgresql")) {
            s = new String("CREATE TABLE "+motesTable+" ( \nxCoord FLOAT,\nyCoord FLOAT,\n moteid INT)");
          }
          stmt.executeUpdate(s);
        }

        // insert all motes into table;
        for (Enumeration e=motes.elements(); e.hasMoreElements();) {
          Mote mote = (Mote)e.nextElement();
          s = new String("INSERT INTO "+motesTable+
                         " VALUES ('"+new Double(mote.getX()).intValue()+"', '"+new Double(mote.getY()).intValue()+"', '"+mote.getId()+"')");
          stmt.executeUpdate(s);
        }
 
        stmt.close();
        con.close();
      } catch (SQLException sqle) {
          System.out.println("SQLException: "+sqle+": error saving configuration - lost");
          return;
      }
      config.saved();
      motes.saved();
      configSave.setEnabled(false);
      configEdit.setEnabled(true);
      configLoad.setEnabled(true);
    }
  }

  /**
   * Close the current configuration, requesting a save if necessary
   */
  private void closeConfiguration() {
    checkSave();
    frame.getContentPane().removeAll();
    frame.repaint();
    configClose.setEnabled(false);
  }

  /**
   * Exits the application, prompting for saving the current configuration if necessary
   */
  private void exitConfiguration() {
    checkSave();
    System.exit(0);
  }

  /**
   * Checks to see if the given table exists
   *
   * @param tablename Name of the table to check on
   * @return whether the table exists or not
   * @throws SQLException when problems with check occur
   */
  private boolean tableExists(String table) throws SQLException {
    if (HAVE_DB) {
      Connection con = DriverManager.getConnection(dbConnection, dbUser, dbPass);
      Statement stmt = con.createStatement();
      ResultSet rs;
      
      if (dbType.equals("mysql")) {
        rs = stmt.executeQuery("SHOW TABLES");
      }
      else {
        rs = stmt.executeQuery("select * from pg_tables");
      }
      while(rs.next()) {
        String result = rs.getString(1);
        if (result.equals(table)) {
          return true;
        }
      }
      rs.close();
      stmt.close();
      con.close();
      return false;
    }
    else {
      return true;
    }
  }

  /**
   * Retrieves the motes information from the given table
   *
   * @param table Table containing motes information
   */
  public Motes getMotes(String table) {
    if (HAVE_DB) {
      Motes m = new Motes();
      try {
        Connection con = DriverManager.getConnection(dbConnection, dbUser, dbPass);
        Statement stmt = con.createStatement();

        ResultSet rs = stmt.executeQuery("SELECT * FROM "+table);
        while(rs.next()) {
          m.addMote(new Mote(new Integer(rs.getInt(1)).doubleValue(), new Integer(rs.getInt(2)).doubleValue(), rs.getInt(3)));
        }
        rs.close();
        stmt.close();
        con.close();
      } catch (SQLException sqle) {
          System.out.println("setup getConfigurations SQLException: "+sqle);
          System.out.println("Trouble interacting with vizConfig database table");
          System.exit(-2);
      }
      return m;
   }
   else {
     return new Motes();
   }
  }

  /**
   * Retrieves the names of the existing configurations from the default table
   *
   * @return Names of the existing configurations
   */
  public Vector getConfigurations() {
    return getConfigurations(DEFAULT_DB_CONFIG_TABLE);
  }

  /**
   * Retrieves the names of the existing configurations from the given table
   *
   * @return Names of the existing configurations
   */
  public Vector getConfigurations(String table) {
    if (HAVE_DB) {
      Vector configs = new Vector();
      try {
        Connection con = DriverManager.getConnection(dbConnection, dbUser, dbPass);
        Statement stmt = con.createStatement();

        ResultSet rs = stmt.executeQuery("SELECT configName FROM "+table);
        while(rs.next()) {
          configs.addElement(rs.getString(1));
        }
        rs.close();
        stmt.close();
        con.close();
      } catch (SQLException sqle) {
          System.out.println("setup getConfigurations SQLException: "+sqle);
          System.out.println("Trouble interacting with vizConfig database table");
          System.exit(-2);
      }
      return configs;
   }
   else {
     return new Vector();
   }
  }

  /**
   * This private method creates a database table for storing attribute values.
   *
   * @param stmt SQL statement to use
   * @throws SQLException when problems creating the table occur
   */
  private void createConfigTable(String table) throws SQLException {
    String s = new String("CREATE TABLE "+table+" ( \nconfigName TEXT,\nimageName TEXT,\n imageWidth INT, \n imageHeight INT, \n minPixelX INT, \n minPixelY INT, \n maxPixelX INT, \n maxPixelY INT, \n minX INT,\n minY INT,\n maxX INT,\n maxY INT)");
    Connection con = DriverManager.getConnection(dbConnection, dbUser, dbPass);
    Statement stmt = con.createStatement();
    stmt.executeUpdate(s);
    stmt.close();
    con.close();
  }

  /**
   * Converts the x pixel coordinate to a real x coordinate and display it
   *
   * @param x X pixel coordinate to convert
   */
  public void setXPos(int x) {
    // from MoveEventHandler
    // convert to real x coord
    // x = xP * (xmaxr - xminR) / (xmaxP - xminP)
    double tmp = config.getMaximumRealX() + (x - config.getMaximumPixelX())*(config.getMaximumRealX() - config.getMinimumRealX())/(config.getMaximumPixelX() - config.getMinimumPixelX());
    xpos.setText(formatter.format(tmp));
  }

  /**
   * Converts the y pixel coordinate to a real y coordinate and display it
   *
   * @param y Y pixel coordinate to convert
   */
  public void setYPos(int y) {
    // from MoveEventHandler
    // convert to real y coord
    // y = yP * (ymaxR - yminr) / (ymaxP - yminP)
    double tmp = config.getMaximumRealY() + (y - config.getMaximumPixelY())*(config.getMaximumRealY() - config.getMinimumRealY())/(config.getMaximumPixelY() - config.getMinimumPixelY());
    ypos.setText(formatter.format(tmp));
  }

  /**
   * Display the id of the current mote
   *
   * @param id Id of the mote to display
   */
  public void setId(int id) {
    if (id != Mote.INVALID_ID) {
      moteId.setText(String.valueOf(id));
    }
    else {
      moteId.setText("");
    }
  }

  /**
   * Method to satisfy interface - not used
   *
   * @return empty string
   */
  public Object getInfo() {
    // from AddEventHandler
    return new String();
  }

  /**
   * Method to satisfy interface - not used
   */
  public void setPixelX(int x) {
    // from AddEventHandler - leave empty
  }

  /**
   * Method to satisfy interface - not used
   */
  public void setPixelY(int y) {
    // from AddEventHandler - leave empty
  }

  /**
   * When the motes list has been changed, enable save option
   */
  public void changed() {
    // from ChangeHandler
    configSave.enable();
  }

  /**
   * Set the mode for the interface
   *
   * @param mode Mode for the interface
   */
  public void setMode(int mode) {
    if (currentEventHandler != null) {
      currentEventHandler.setActive(false);
    }

    switch (mode) {
      case ADD_MODE: currentEventHandler = addEventHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.CROSSHAIR_CURSOR));
                     break;
      case PAN_MODE: currentEventHandler = panEventHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.MOVE_CURSOR));
                     break;
      case REMOVE_MODE: currentEventHandler = removeEventHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.CROSSHAIR_CURSOR));
                     break;
      case AUTO_MODE: currentEventHandler = autoEventHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.CROSSHAIR_CURSOR));
                     break;
    }

    if (currentEventHandler != null) {
      currentEventHandler.setActive(true);
    }
  }

  /**
   * Database requires all \ in pathnames to be escaped with another \. This method converts
   * a pathname to an escaped version.
   *
   * @param in String to convert
   * @return converted string
   */
  private String addSlashes(String in) {
    StringBuffer sb = new StringBuffer();
    int index = 0;
    int i = in.indexOf("\\");
    int ii = in.indexOf("\\\\");

    if (i == -1) {
      return in;
    }

    if (i != ii) {
      sb.append(in.substring(index,i+1)+"\\");
    }
    index = i+1;
    boolean done = false;
    while (!done) {
      i = in.indexOf("\\", index);
      ii = in.indexOf("\\\\", index);
      if (i == -1) {
        sb.append(in.substring(index));
        done = true;
      }
      else if (i != ii) {
        sb.append(in.substring(index,i+1)+"\\");
        index = i+1;
      }
    }
    return sb.toString();
  }

  /**
   * Database requires all \ in pathnames to be escaped with another \. This method converts
   * a pathname to an unescaped version.
   *
   * @param in String to convert
   * @return converted string
   */
  private String removeSlashes(String in) {
    StringBuffer sb = new StringBuffer();
    int i = in.indexOf("\\\\");
    if (i != -1) {
      return in;
    }

    sb.append(in.substring(0,i+1));
 
    int index = i+2;
    boolean done = false;
    while (!done) {
      i = in.indexOf("\\\\",index);
      if (i == -1) {
        sb.append(in.substring(index));
        done = true;
      }
      else {
        sb.append(in.substring(index,i+1)+"\\");
        index = i+2;
      }
    }
    return sb.toString();
  }

  /**
   * Main method for the configuration setup 
   */
  public static void main(String argv[]) {
    if (argv.length == 6) {
      setup d = new setup(argv[0], argv[1], Integer.parseInt(argv[2]), argv[3], argv[4], argv[5]);
    }
    else if (argv.length == 1) {
      System.out.println("USAGE: viz.setup [database type] [database ip/hostname] [database port] [database path] [database user] [database password]");
    }
    else {
      setup d = new setup();
    }
  }
}

/*

data need to get:
	d/b ip/host, port, path, username, password, table prefix (if multiple tables, or just table name)
	need (0,0) point, (max_x, max_y) point from image
	
	menu items:
		edit mode for entering/moving nodes
			turn grids on or off
			zoom in/out
			calibration of sensors on nodes
		visualize mode
			type of data to visualize (network paths/battery levels/last update time/ sensor (heat/light)
			allow selection/hiding of nodes to view numeric data (raw/processed data/location)	
			color choices for nodes/data
	push/pull support?

	d/b info: (host/ip, port, path, user, password get externally or allow use defaults)
		config table:
			setup name
			image
			0,0
			max_x, max_y
		locations table
			id, x, y, location_name
		data table
			id, light, temperature
*/

/*
  get list of mobile motes from d/b
    then populate image with static motes and mobile motes
    mobile motes show text label with id/name
    check d/b every x seconds for each mobile mote
      get data from last y seconds
      get x,y for each static mote in data
      x = (x1*ss1 + x2*ss2 + ... + xn*ssn)/(ss1 + ss2 + ... + ssn)
      y = (y1*ss1 + y2*ss2 + ... + yn*ssn)/(ss1 + ss2 + ... + ssn)
      if (all xn are same) and (all yn are same) 
        give random offset from x,y
*/
