// $Id: TinyViz.java,v 1.23 2004/01/10 00:58:22 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Phil Levis, Nelson Lee
 * Date:        November 27, 2002
 * Desc:        Base GUI; plugins connect to this one
 *
 */

/**
 * @author Phil Levis
 * @author Nelson Lee
 */


package net.tinyos.sim;

import java.awt.*;
import javax.swing.*;
import java.util.*;
import java.io.*;
import net.tinyos.sim.event.*;
import java.net.URL;

public class TinyViz implements SimConst {

  private SimDriver driver;
  private JFrame mainFrame;
  private MainMenuBar menuBar;
  private MotePanel motePanel;
  private CoordinateTransformer cT;
  private PluginPanel pluginPanel;

  public static final Font defaultFont = new Font("Helvetica", Font.PLAIN, 10);
  public static final Font labelFont = new Font("Helvetica", Font.BOLD, 11);
  public static final Font smallFont = new Font("Helvetica", Font.PLAIN, 9);
  public static final Font constFont = new Font("Courier", Font.PLAIN, 9);
  public static final Font constBoldFont = new Font("Courier", Font.BOLD, 9);
  public static final Font boldFont = new Font("Helvetica", Font.BOLD, 10);
  public static final Color paleBlue = new Color(0x97, 0x97, 0xc8);

  public SimDriver getSimDriver() {
    return driver;
  }

  public Frame getMainFrame() {
    return mainFrame;
  }

  public double getTosTime() {
    return Double.valueOf(menuBar.timeLabel.getText()).doubleValue();
  }

  public MainMenuBar getMenuBar() {
    return menuBar;
  }

  public CoordinateTransformer getCoordTransformer() {
    return cT;
  }

  public MotePanel getMotePanel() {
    return motePanel;
  }

  public PluginPanel getPluginPanel() {
    return pluginPanel;
  }

  // Called by AutoRun and within reset()
  public void refreshAndWait() {
    motePanel.refreshAndWait();
  }

  // Called by SimComm when its internal state changes and by
  // pause/resume
  public void refreshPauseState() {
    menuBar.refreshPausePlayButton();
  }

  // Sets the status line
  public void setStatus(String s) {
    pluginPanel.setStatus(s);
  }

  // Called by SimEventBus when a new event comes in
  public void timeUpdate(String time) {
    menuBar.timeLabel.setText(time);
  }

  // Called by AutoRun after loading the specified plugins
  public void refreshPluginRegistrations() {
    pluginPanel.refreshRegistrations();
  }

  public void pause() {
    driver.pause();
  }

  public void resume() {
    driver.resume();
  }

  public TinyViz(SimDriver driver, boolean lookandfeel) {
    this.driver = driver;

    /* Set up look and feel */
    if (lookandfeel) {
      try {
	Class oclass =
          Class.forName("com.oyoaha.swing.plaf.oyoaha.OyoahaLookAndFeel");
	Object olnf = oclass.newInstance();
	URL otm_res = this.getClass().getResource("ui/slushy8.otm");
	if(otm_res != null) {
	  Class params[] = new Class[1];
	  Object args[] = new Object[1];
	  java.lang.reflect.Method method;
          
	  params[0] = otm_res.getClass();
	  args[0] = otm_res;
          method = oclass.getMethod("setOyoahaTheme", params);
	  method.invoke(olnf, args);
	}
	UIManager.setLookAndFeel((javax.swing.LookAndFeel)olnf); 
      } catch (Exception e) {
	System.err.println("Got exception loading Oyoaha: "+e);
	System.err.println("Using default look and feel");
      }
    }

    /* Create GUI components */
    mainFrame = new JFrame("TinyViz");
    mainFrame.setFont(defaultFont);
    menuBar = new MainMenuBar(this);
    menuBar.setFont(defaultFont);
    mainFrame.setJMenuBar(menuBar);

    cT = new CoordinateTransformer(MOTE_SCALE_WIDTH, MOTE_SCALE_HEIGHT,
				   MOTE_PANEL_WIDTH, MOTE_PANEL_HEIGHT);
    motePanel = new MotePanel(this);
    pluginPanel = new PluginPanel(this);

    MoteSimObject.setPopupMenu(new SimObjectPopupMenu(this));

    menuBar.addToolbar();
    mainFrame.getContentPane().setLayout(new GridLayout(1,2));
    mainFrame.getContentPane().add(motePanel);
    mainFrame.getContentPane().add(pluginPanel);
    mainFrame.pack();

    boolean visible_flag = true;
    if (driver.getAutoRun() != null) {
      visible_flag = driver.getAutoRun().visible_flag;
    }
    mainFrame.setVisible(visible_flag);
  }
  
  public static void main(String[] args) throws IOException {
    String[] args2 = new String[args.length + 1];
    for (int i = 0; i < args.length; ++i) {
      args2[i] = args[i];
    }
    args2[args.length] = "-gui";
    new SimDriver(args2);
  }
}
