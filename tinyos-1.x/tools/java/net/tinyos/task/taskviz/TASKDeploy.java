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

public class TASKDeploy implements MoveEventListener, AddEventListener, ChangeListener, ZGroupListener, ZMouseListener {

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
   * TASK Client Info tag for configuration information
   */
  public static final String CONFIGURATION = "CONFIGURATION";

  private Configuration config;
  private JScrollPane imagePane;

  private ZEventHandler currentEventHandler = null;
  private ZPanEventHandler panEventHandler = null;
  private ZoomEventHandler zoomEventHandler = null;
  private AddEventHandler addEventHandler = null;
  private MoveEventHandler moveEventHandler = null;
  private RemoveEventHandler removeEventHandler = null;
  private ZCompositeSelectionHandler selectionHandler = null;
  ZImageCanvas canvas = null;
  JLabel xpos, ypos, moteId;
  JScrollPane scrollPane;
  JPanel view;

  DecimalFormat formatter;
  
  Motes motes = new Motes();
//  private ToolBarButton add, remove, pan;
  private JToggleButton add, remove, pan;

  private TASKClient client;

  private TASKVisualizer parent;
  private JFrame parentFrame;
  private JPanel parentPanel;
  private JToolBar toolbar = null;

  /**
   * Constructor that begins the setup of configuration management using default TASK Server port
   *
   * @param host TASKServer host
   */
  public TASKDeploy(JFrame parentFrame, TASKVisualizer parent, TASKClient client, JPanel panel) {
    this.parentFrame = parentFrame;
    this.parent = parent;
    this.client = client;
    this.parentPanel = panel;
    config = new Configuration();
    motes = new Motes();
  }

  /**
   * Creates the toolbar for the user interface
   *
   * @return The created toolbar
   */
  public JToolBar createToolBar() {
    JToolBar toolbar = new JToolBar(JToolBar.VERTICAL);
    Insets margins = new Insets(0, 0, 0, 0);

    ButtonGroup group2 = new ButtonGroup();

/*    pan = new ToolBarButton("images/P.gif");
    pan.setSelectedIcon(new ImageIcon("images/P-selected.gif"));
*/
    pan = new JToggleButton("Pan view");
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

/*    add = new ToolBarButton("images/A.gif");
    add.setSelectedIcon(new ImageIcon("images/A-selected.gif"));
*/
    add = new JToggleButton("Add mote");
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

/*    remove = new ToolBarButton("images/M.gif");
    remove.setSelectedIcon(new ImageIcon("images/M-selected.gif"));
*/
    remove = new JToggleButton("Modify/delete mote");
    remove.setToolTipText("Modify/Delete mote");
    remove.setMargin(margins);
    remove.setActionCommand("pan");
    remove.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(REMOVE_MODE);
      }
    });
    group2.add(remove);
    toolbar.add(remove);

    toolbar.setFloatable(true);
    return toolbar;
  }

  /**
   * When the user selects new configuration from the menu, a dialog is created to support creation
   */
  public void newConfiguration() {
    config = new Configuration();

    // create a ConfigurationDialog
    ConfigurationDialog cdialog = new ConfigurationDialog(parentFrame, NEW, config, getConfigurations());
    cdialog.pack();
    cdialog.setLocationRelativeTo(parentFrame);
    cdialog.setVisible(true);

    // if the data is valid, create an ImageDialog to allow registration of the image
    if (cdialog.isDataValid()) {
System.out.println("width: "+config.getImageWidth());
System.out.println("height: "+config.getImageHeight());
      ImageDialog idialog = new ImageDialog(parentFrame, NEW, config);
      idialog.pack();
      idialog.setLocationRelativeTo(parentFrame);
      idialog.setVisible(true);  

      // if the ImageDialog data is valid, create a blank motes object and calls viewConfiguration
      if (idialog.isDataValid()) {
        config.notSaved();
        parent.setConfiguration(config);
        motes = new Motes();
        viewConfiguration(config);
      }
      else {
        config = new Configuration();
      }
    }
  }

  /**
   * When the user chooses the edit a configuration, a dialog containing the current configuration is
   * loaded and is made available for editing, then views the motes information  
   */
  public void editConfiguration(Configuration c, Vector configs) {
    // load the selected configuration from the database
    config = c;

    // open a ConfigurationDialog to allow editing of the configuration
    ConfigurationDialog cdialog = new ConfigurationDialog(parentFrame, EDIT, config, configs);
    cdialog.pack();
    cdialog.setLocationRelativeTo(parentFrame);
    cdialog.setVisible(true);

    // if the data is valid, load an ImageDialog to allow registration of the image
    if (cdialog.isDataValid()) {
      System.out.println("config name: "+config.getName());
      ImageDialog idialog = new ImageDialog(parentFrame, EDIT, config);

      idialog.pack();
      idialog.setLocationRelativeTo(parentFrame);
      idialog.setVisible(true);  

      // if the registration information is valid, call viewConfiguration
      if (idialog.isDataValid()) {
        config.notSaved();
        parent.setConfiguration(config);
//        motes = getMotes(config.getName());
        viewConfiguration(config);
      }
    }
  }

  /**
   * This method renders the current configuration
   */
  public void viewConfiguration(Configuration config) {
    this.config = config;
    motes = getMotes(config.getName());
    if (toolbar == null) {
      toolbar = createToolBar();
      parentPanel.add(toolbar, BorderLayout.NORTH);
    }

    if (view != null) {
      parentPanel.remove(view);
    }
    if (scrollPane != null) {
      parentPanel.remove(scrollPane);
    }

    int imageWidth, imageHeight;

    // render image
    if (config.useBlankImage()) {
System.out.println("width: "+config.getImageWidth());
      imageWidth = config.getImageWidth();
      imageHeight = config.getImageHeight();
      canvas = new ZImageCanvas(imageWidth, imageHeight);
    }
    else {
	//System.out.println("LOOKING FOR IMAGE: " + config.getImageName());
	
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
    leaf.setSelectable(false);
    leaf.setPickable(false);
    leaf.setFindable(false);
    layer.addChild(leaf);

    line = new ZLine(config.getMinimumPixelX(), config.getMinimumPixelY(), 
                     config.getMinimumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    leaf.setSelectable(false);
    leaf.setPickable(false);
    leaf.setFindable(false);
    layer.addChild(leaf);

    line = new ZLine(config.getMaximumPixelX(), config.getMinimumPixelY(), 
                     config.getMaximumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    leaf.setSelectable(false);
    leaf.setPickable(false);
    leaf.setFindable(false);
    layer.addChild(leaf);

    line = new ZLine(config.getMinimumPixelX(), config.getMaximumPixelY(), 
                     config.getMaximumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    leaf.setSelectable(false);
    leaf.setPickable(false);
    leaf.setFindable(false);
    layer.addChild(leaf);

    // render the static motes
    for (Enumeration e=motes.elements(); e.hasMoreElements(); ) {
      Mote m = (Mote)e.nextElement();
      leaf = new ZVisualLeaf(m);
      layer.addChild(leaf);
      leaf.addMouseListener(this);
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
    parentPanel.add(scrollPane, BorderLayout.CENTER);

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
    parentPanel.add(view, BorderLayout.EAST);

    parentFrame.pack();

    formatter = new DecimalFormat("###.##");

    // create all the event handlers
    panEventHandler = new ZPanEventHandler(canvas.getCameraNode());
    zoomEventHandler = new ZoomEventHandler(canvas.getCameraNode());
    addEventHandler = new AddEventHandler(canvas, this, this, imageWidth, imageHeight, motes, parentFrame);
    moveEventHandler = new MoveEventHandler(canvas, this, imageWidth, imageHeight, true);
    removeEventHandler = new RemoveEventHandler(canvas, canvas.getLayer(), motes, this);
    selectionHandler = new ZCompositeSelectionHandler(canvas.getCameraNode(), canvas, canvas.getLayer(), ZCompositeSelectionHandler.DELETE|ZCompositeSelectionHandler.MODIFY|ZCompositeSelectionHandler.MOVE);
 
    // set the zoom and move event handlers to active
    zoomEventHandler.setActive(true);
    moveEventHandler.setActive(true);

    setMode(ADD_MODE);
    add.setSelected(true);

    selectionHandler.getSelectionDeleteHandler().addGroupListener(this);
  }
  
  /**
   * Save configuration to the given table
   *
   * @param table Table to save configuration to
   */
  public void saveConfiguration() {
    client.deleteClientInfo(config.getName());
    client.deleteMote(config.getName());
    
    client.addClientInfo(config.toTASKClientInfo());
    // insert all motes 
    for (Enumeration e=motes.elements(); e.hasMoreElements();) {
      Mote m = (Mote)e.nextElement();
      m.setConfig(config.getName());
      TASKMoteClientInfo info = m.toMoteClientInfo();
      System.out.println(info.moteId+","+info.clientInfoName);
      client.addMote(info);
    }
 
    config.saved();
    motes.saved();
  }

  /**
   * Close the current configuration, requesting a save if necessary
   */
  private void closeConfiguration() {
    checkSave();
    parentFrame.getContentPane().removeAll();
    parentFrame.repaint();
//    configClose.setEnabled(false);
  }

  /**
   * Exits the application, prompting for saving the current configuration if necessary
   */
  private void exitConfiguration() {
    checkSave();
    System.exit(0);
  }

  /**
   * Checks if the current configuration has been modified since the last save. If so, a dialog prompts
   * the user to save the configuration
   */
  public void checkSave() {
    if (config.needsSave() || motes.needsSave()) {
      int save = JOptionPane.showConfirmDialog(parentFrame, "Do you want to save this configuration?", "Save Configuration", JOptionPane.YES_NO_OPTION);
      if (save == JOptionPane.YES_OPTION) {
        saveConfiguration();
      }
      else {
        config.saved();
        motes.saved();
//        configSave.setEnabled(false);
//        configEdit.setEnabled(true);
//        configLoad.setEnabled(true);
      }
    }
  }

  /**
   * Retrieves the motes information for the given configuration
   *
   * @param name Configuration name
   */
  public Motes getMotes(String name) {
    Motes m = new Motes();
    Vector mInfos = client.getAllMoteClientInfo(name);
    if (mInfos != null) {
      for (int i=0; i<mInfos.size(); i++) {
        m.addMote(new Mote((TASKMoteClientInfo)mInfos.elementAt(i)));
      }
    }
    return m;
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
//    configSave.setEnabled(true);
  }

  public void nodeAdded(ZGroupEvent zge) {
  }

  public void nodeRemoved(ZGroupEvent zge) {
    ZVisualLeaf zvl = (ZVisualLeaf)zge.getChild();
    ZVisualComponent zvc = zvl.getFirstVisualComponent();
    Mote m = (Mote)zvc;
    motes.removeMote(m);
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
      case REMOVE_MODE: currentEventHandler = selectionHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.CROSSHAIR_CURSOR));
                     break;
    }

    if (currentEventHandler != null) {
      currentEventHandler.setActive(true);
    }
  }

  public void mouseClicked(ZMouseEvent me) {
  }

  public void mouseEntered(ZMouseEvent me) {
  }

  public void mouseExited(ZMouseEvent me) {
  }

  public void mousePressed(ZMouseEvent me) {
  }

  public void mouseReleased(ZMouseEvent me) {
    System.out.println(me);
    int x = me.getX();
    int y = me.getY();
    ZNode zn = me.getCurrentNode();
    ZVisualLeaf zvl = (ZVisualLeaf)zn;
    ZVisualComponent zvc = zvl.getFirstVisualComponent();
    Mote m = (Mote)zvc;
    m.setCoordinates(x,y);
  }
}
