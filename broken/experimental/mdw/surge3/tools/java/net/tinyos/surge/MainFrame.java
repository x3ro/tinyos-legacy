/* "Copyright (c) 2001 and The Regents of the University  
* of California.  All rights reserved. 
* 
* Permission to use, copy, modify, and distribute this software and its 
* documentation for any purpose, without fee, and without written agreement is 
* hereby granted, provided that the above copyright notice and the following 
* two paragraphs appear in all copies of this software. 
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001 
* Authors:   Wei Hong, modified for tinydb
*            Matt Welsh, updated for Surge 3.0
*/

package net.tinyos.surge;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import net.tinyos.surge.GraphDisplayPanel;
import net.tinyos.surge.Dialog.*;

public class MainFrame extends javax.swing.JFrame  
{

  public static Font defaultFont = new Font("Helvetica", Font.PLAIN, 10);
  public static Font bigFont = new Font("Helvetica", Font.PLAIN, 12);
  public static Font boldFont = new Font("Helvetica", Font.BOLD, 10);
  public static Color labelColor = new Color(255, 0, 0);
  public static volatile boolean DEBUG_MODE = false;
  public static volatile boolean STATUS_MODE = true;
  public static volatile boolean SENSOR_MODE = true;

  // Constants
  public static int MIN_BEACON_RATE = 1000;
  public static int MAX_BEACON_RATE = 10000;
  public static int DEFAULT_BEACON_RATE = 1000;

  public static int MIN_SAMPLE_RATE = 1000;
  public static int MAX_SAMPLE_RATE = 10000;
  public static int DEFAULT_SAMPLE_RATE = 1000;

  // Base address
  public static final short BEACON_BASE_ADDRESS = 0x007e;

  public MainFrame()
  {
    // setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
    setTitle("Sensor Network Topology");
    getContentPane().setLayout(new BorderLayout(0,0));
    setSize(700,500);
    setVisible(false);
    MainPanel.setLayout(new FlowLayout(FlowLayout.LEFT,0,0));
    getContentPane().add(BorderLayout.NORTH, MainPanel);
    MainToolBar.setAlignmentY(0.222222F);
    MainToolBar.setDoubleBuffered(true);
    MainPanel.add(MainToolBar);
    SymWindow aSymWindow = new SymWindow();
    this.addWindowListener(aSymWindow);

    SymAction lSymAction = new SymAction();

    // Main menubar buttons
    fitNetworkNowButton.setFont(defaultFont);
    startRootBeaconButton.setFont(defaultFont);
    sendSleepButton.setFont(defaultFont);
    sendWakeupButton.setFont(defaultFont);
    sendUnfocusButton.setFont(defaultFont);
    sendUnfocusButton.setEnabled(false);
    debugButton.setFont(defaultFont);
    debugButton.setSelected(DEBUG_MODE);
    statusButton.setFont(defaultFont);
    statusButton.setSelected(STATUS_MODE);
    sensorButton.setFont(defaultFont);
    sensorButton.setSelected(SENSOR_MODE);

    fitNetworkNowButton.addActionListener(lSymAction);
    MainToolBar.add(fitNetworkNowButton);

    startRootBeaconButton.addActionListener(lSymAction);
    MainToolBar.add(startRootBeaconButton);

    controlPanel.setFont (defaultFont);
    controlPanel.addActionListener(lSymAction);
    controlPanel.setToolTipText("View Control Panel");
    MainToolBar.add(controlPanel);

    sendSleepButton.addActionListener(lSymAction);
    MainToolBar.add(sendSleepButton);
    sendWakeupButton.addActionListener(lSymAction);
    MainToolBar.add(sendWakeupButton);
    sendUnfocusButton.addActionListener(lSymAction);
    MainToolBar.add(sendUnfocusButton);

    debugButton.addActionListener(lSymAction);
    MainToolBar.addSeparator();
    MainToolBar.add(debugButton);
    statusButton.addActionListener(lSymAction);
    MainToolBar.addSeparator();
    MainToolBar.add(statusButton);
    sensorButton.addActionListener(lSymAction);
    MainToolBar.addSeparator();
    MainToolBar.add(sensorButton);

    getContentPane().add(BorderLayout.CENTER, MainScrollPane);
    MainScrollPane.setOpaque(true);
    MainScrollPane.setViewportView(GraphDisplayPanel);		
    MainScrollPane.getViewport().add(GraphDisplayPanel);
    GraphDisplayPanel.setBounds(0,0,430,270);
    GraphDisplayPanel.setLayout(null);
    GraphDisplayPanel.setAutoscrolls(true);
    //GraphDisplayPanel.setBounds(0,0,100,100);
    //GraphDisplayPanel.setPreferredSize(new Dimension(100,100));
    MainScrollPane.getViewport().add(GraphDisplayPanel);
  }

  /**
   * Creates a new instance of JFrame1 with the given title.
   * @param sTitle the title for the new frame.
   * @see #JFrame1()
   */
  public MainFrame(String sTitle) {
    this();
    setTitle(sTitle);
  }

  /**
   * Notifies this component that it has been added to a container
   * This method should be called by <code>Container.add</code>, and 
   * not by user code directly.
   * Overridden here to adjust the size of the frame if needed.
   * @see java.awt.Container#removeNotify
   */

  public void addNotify()
  {
    // Record the size of the window prior to calling parents addNotify.
    Dimension size = getSize();

    super.addNotify();

    if (frameSizeAdjusted)
      return;
    frameSizeAdjusted = true;

    // Adjust size of frame according to the insets and menu bar
    javax.swing.JMenuBar menuBar = getRootPane().getJMenuBar();
    int menuBarHeight = 0;
    if (menuBar != null)
      menuBarHeight = menuBar.getPreferredSize().height;
    Insets insets = getInsets();
    setSize(insets.left + insets.right + size.width, insets.top + insets.bottom + size.height + menuBarHeight);
  }

  // Used by addNotify
  boolean frameSizeAdjusted = false;

  javax.swing.JPanel MainPanel = new javax.swing.JPanel();
  javax.swing.JToolBar MainToolBar = new javax.swing.JToolBar();
  javax.swing.JScrollPane MainScrollPane = new javax.swing.JScrollPane();
  net.tinyos.surge.GraphDisplayPanel GraphDisplayPanel = new net.tinyos.surge.GraphDisplayPanel();
  JButton fitNetworkNowButton = new JButton("Fit to screen");
  JButton startRootBeaconButton = new JButton("Start root beacon");
  JButton controlPanel = new JButton ("Control Panel");
  JButton sendSleepButton = new JButton("Send sleep");
  JButton sendWakeupButton = new JButton("Send wakeup");
  JButton sendUnfocusButton = new JButton("Cancel focus");
  JCheckBox statusButton = new JCheckBox("Status");
  JCheckBox sensorButton = new JCheckBox("Readings");
  JCheckBox debugButton = new JCheckBox("Debug");
  Integer focusedNode = null;
  boolean root_beacon_on = false;
  public int tentativeSampleRate = DEFAULT_SAMPLE_RATE;
  public int sampleRate = DEFAULT_SAMPLE_RATE;

  class SymWindow extends java.awt.event.WindowAdapter {
    public void windowClosing(java.awt.event.WindowEvent event) {
      Object object = event.getSource();
      if (object == MainFrame.this)
	MainFrame_windowClosing(event);
    }
  }

  void MainFrame_windowClosing(java.awt.event.WindowEvent event) {
    MainClass.displayManager.stopDisplayThread();
    System.exit(0);
  }

  class SymAction implements java.awt.event.ActionListener
  {
    public void actionPerformed(java.awt.event.ActionEvent event)
    {

      Object object = event.getSource();
      if (object == fitNetworkNowButton)
	fitNetworkNowMenuItem_action(event);
      else if (object == startRootBeaconButton) 
	startRootBeaconMenuItem_action(event);
      else if (object == sendSleepButton) 
	sendSleepMenuItem_action(event);
      else if (object == sendWakeupButton) 
	sendWakeupMenuItem_action(event);
      else if (object == sendUnfocusButton) 
	sendUnfocusMenuItem_action(event);
      else if (object == debugButton) 
	debugMenuItem_action(event);
      else if (object == statusButton) 
	statusMenuItem_action(event);
      else if (object == sensorButton) 
	sensorMenuItem_action(event);
      else if (object == controlPanel)
	controlPanel_action(event);
    }
  }

  public net.tinyos.surge.GraphDisplayPanel GetGraphDisplayPanel()
  {
    return GraphDisplayPanel;
  }

  public javax.swing.JScrollPane GetMainScrollPane()
  {
    return MainScrollPane;
  } 

  void fitNetworkNowMenuItem_action(java.awt.event.ActionEvent event)
  {
    try {
      net.tinyos.surge.MainClass.mainFrame.GetGraphDisplayPanel().FitToScreen();
    } catch (java.lang.Exception e) {
    }
  }

  void controlPanel_action (java.awt.event.ActionEvent event)
  {
    try {
      ControlPanelDialog cp = new ControlPanelDialog();
      controlPanel.setEnabled(false);
      cp.show();
    }
    catch (java.lang.Exception e) {
    }
  }


  public class ControlPanelDialog extends javax.swing.JDialog
  {	
    JButton changeSampleRateButton = new JButton();
    JSlider BeaconRate = new JSlider(JSlider.CENTER, MIN_BEACON_RATE, 
	MAX_BEACON_RATE, DEFAULT_BEACON_RATE);
    JLabel BeaconRateLabel = new JLabel("Root beacon rate", JLabel.CENTER);

    JSlider SampleRate = new JSlider (JSlider.CENTER, MIN_SAMPLE_RATE, 
	MAX_SAMPLE_RATE, DEFAULT_SAMPLE_RATE);
    JLabel SampleRateLabel = new JLabel("Sample rate", JLabel.CENTER);

    SymAction lSymAction = new SymAction();
    SymChange lSymChange = new SymChange();

    boolean beaconPressed = false;

    public ControlPanelDialog()
    {
      super ((Frame)null);

      setDefaultCloseOperation(javax.swing.JFrame.DISPOSE_ON_CLOSE);

      // this setting makes sure you can click on other things
      setModal(false);

      setTitle("Control Panel");
      getContentPane().setLayout(null);
      setSize(170,200);
      //setVisible(false);

      // don't add beacon rate to content pane yet
      BeaconRateLabel.setBounds(0, 5, 150, 20);
      BeaconRateLabel.setFont(defaultFont);

      BeaconRate.setMajorTickSpacing (MAX_BEACON_RATE - MIN_BEACON_RATE);
      BeaconRate.setMinorTickSpacing(1000);
      BeaconRate.setPaintTicks(true);
      Hashtable lt = new Hashtable();
      JLabel minl = new JLabel(new Integer(MIN_BEACON_RATE/1000).toString()+" sec");
      minl.setFont(defaultFont);
      JLabel maxl = new JLabel(new Integer(MAX_BEACON_RATE/1000).toString()+" sec");
      maxl.setFont(defaultFont);
      lt.put(new Integer(MIN_BEACON_RATE), minl);
      lt.put(new Integer(MAX_BEACON_RATE), maxl);
      BeaconRate.setLabelTable(lt);

      BeaconRate.setPaintLabels(true);
      BeaconRate.setBounds(0, 25, 150, 50);
      BeaconRate.addChangeListener(lSymChange);

      getContentPane().add(BeaconRateLabel);		
      getContentPane().add(BeaconRate);

      SampleRateLabel.setBounds (0, 75, 150, 20);
      SampleRateLabel.setFont(defaultFont);
      getContentPane().add(SampleRateLabel);

      SampleRate.setBounds(0, 95, 150, 50);
      SampleRate.setMajorTickSpacing (MAX_SAMPLE_RATE - MIN_SAMPLE_RATE);
      SampleRate.setMinorTickSpacing(1000);
      SampleRate.setPaintTicks(true);
      lt = new Hashtable();
      minl = new JLabel(new Integer(MIN_SAMPLE_RATE/1000).toString()+" sec");
      minl.setFont(defaultFont);
      maxl = new JLabel(new Integer(MAX_SAMPLE_RATE/1000).toString()+" sec");
      maxl.setFont(defaultFont);
      lt.put(new Integer(MIN_SAMPLE_RATE), minl);
      lt.put(new Integer(MAX_SAMPLE_RATE), maxl);
      SampleRate.setLabelTable(lt);
      SampleRate.setPaintLabels(true);
      getContentPane().add(SampleRate);
      SampleRate.addChangeListener(lSymChange);

      changeSampleRateButton.setText("Change sample rate");
      changeSampleRateButton.setFont(defaultFont);
      // x, y, width, height
      changeSampleRateButton.setBounds(5,145,150,30);
      getContentPane().add(changeSampleRateButton);
      changeSampleRateButton.addActionListener(lSymAction);

      addWindowListener(new java.awt.event.WindowAdapter() {
	  public void windowClosed(WindowEvent e) {
	  this_windowClosed(e);
	  }
	  });
    }

    void this_windowClosed(WindowEvent e) {
      controlPanel.setEnabled(true);
    }

    class SymAction implements java.awt.event.ActionListener
    {
      public void actionPerformed(java.awt.event.ActionEvent event)
      {
	Object object = event.getSource();
	if (object == changeSampleRateButton)
	  changeSampleRateButton_actionPerformed(event);
      }
    }

    class SymChange implements javax.swing.event.ChangeListener
    {
      public void stateChanged(javax.swing.event.ChangeEvent event)
      {
	Object object = event.getSource();
	if (object == BeaconRate)
	  BeaconRate_stateChanged(event);
	else if (object == SampleRate)
	  SampleRate_stateChanged(event);

      }
    }

    void changeSampleRateButton_actionPerformed(java.awt.event.ActionEvent event) {
      try {
       	// Send change sample rate command
	sampleRate = tentativeSampleRate;
	SurgeMsg sm = new SurgeMsg();
	sm.set_type((short)2);
	sm.set_args_newrate(sampleRate);
	sm.set_parentaddr(0);
	sm.set_sourceaddr(0);
	sm.set_hopcount((short)0);
	MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
	MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
	MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
	if (DEBUG_MODE) System.err.println("SENDING: "+sm);
      } catch (java.lang.Exception e) {
      }
    }

    void BeaconRate_stateChanged(javax.swing.event.ChangeEvent event) {
      rootBeaconThread.setDelay(BeaconRate.getValue());
    }

    void SampleRate_stateChanged(javax.swing.event.ChangeEvent event) {
      tentativeSampleRate = SampleRate.getValue();
    }
  }

  class rootBeaconer implements Runnable {
    private boolean stopped = false;
    private long delay_ms = DEFAULT_BEACON_RATE;
    private SurgeMsg beacon;

    rootBeaconer() {
      beacon = new SurgeMsg();
      beacon.set_type((short)1);
      beacon.set_originaddr(BEACON_BASE_ADDRESS);
      beacon.set_sourceaddr(BEACON_BASE_ADDRESS);
      beacon.set_hopcount((short)0);
    }

    public void run() {
      stopped = false;
      while (!stopped) {
	try {
	  MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, beacon);
	  if (DEBUG_MODE) System.err.println("SENDING BEACON: "+beacon);
	  Thread.currentThread().sleep(delay_ms);
	} catch (Exception e) {
	  // Ignore
	}
      }
      return;
    }

    void setDelay(long delay) {
      delay_ms = delay;
    }

    long getDelay() {
      return delay_ms;
    }

    void timeToStop() {
      stopped = true;
    }
  }

  rootBeaconer rootBeaconThread = new rootBeaconer();

  void startRootBeaconMenuItem_action(java.awt.event.ActionEvent event)
  {
    if (root_beacon_on) {
      System.err.println("Stopping root beacon thread...");
      rootBeaconThread.timeToStop();
      startRootBeaconButton.setText("Start root beacon");
      root_beacon_on = false;
    } else {
      System.err.println("Starting root beacon thread...");
      new Thread(rootBeaconThread).start();
      startRootBeaconButton.setText("Stop root beacon");
      root_beacon_on = true;
    }
  }

  void sendSleepMenuItem_action(java.awt.event.ActionEvent event)
  {
    try {
      // Send sleep
      SurgeMsg sm = new SurgeMsg();
      sm.set_type((short)3);
      sm.set_parentaddr(0);
      sm.set_sourceaddr(0);
      sm.set_hopcount((short)0);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      if (DEBUG_MODE) System.err.println("SENDING: "+sm);
    } catch (java.lang.Exception e) {
    }
  }

  void sendWakeupMenuItem_action(java.awt.event.ActionEvent event)
  {
    try {
      // Send wakeup
      SurgeMsg sm = new SurgeMsg();
      sm.set_type((short)4);
      sm.set_parentaddr(0);
      sm.set_sourceaddr(0);
      sm.set_hopcount((short)0);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      if (DEBUG_MODE) System.err.println("SENDING: "+sm);
    } catch (java.lang.Exception e) {
    }
  }

  void sendUnfocusMenuItem_action(java.awt.event.ActionEvent event)
  {
    try {
      // Send unfocus command
      focusedNode = null;
      SurgeMsg sm = new SurgeMsg();
      sm.set_type((short)6);
      sm.set_parentaddr(0);
      sm.set_sourceaddr(0);
      sm.set_hopcount((short)0);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      if (DEBUG_MODE) System.err.println("SENDING: "+sm);
    } catch (java.lang.Exception e) {
    }
  }

  void debugMenuItem_action(java.awt.event.ActionEvent event)
  {
    if (DEBUG_MODE) {
      DEBUG_MODE = false;
    } else {
      DEBUG_MODE = true;
    }
  }

  void statusMenuItem_action(java.awt.event.ActionEvent event)
  {
    if (STATUS_MODE) {
      STATUS_MODE = false;
    } else {
      STATUS_MODE = true;
    }
  }

  void sensorMenuItem_action(java.awt.event.ActionEvent event)
  {
    if (SENSOR_MODE) {
      SENSOR_MODE = false;
    } else {
      SENSOR_MODE = true;
    }
  }

  void sendFocusCommand(Integer nodenum) {
    try {
      focusedNode = nodenum;
      // Send focus command
      SurgeMsg sm = new SurgeMsg();
      sm.set_type((short)5);
      sm.set_args_focusaddr(nodenum.shortValue());
      sm.set_parentaddr(0);
      sm.set_sourceaddr(0);
      sm.set_hopcount((short)0);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      MainClass.getMoteIF().send(net.tinyos.message.MoteIF.TOS_BCAST_ADDR, sm);
      if (DEBUG_MODE) System.err.println("SENDING: "+sm);
    } catch (java.lang.Exception e) {
    }
    sendUnfocusButton.setEnabled(true);
  }

}
