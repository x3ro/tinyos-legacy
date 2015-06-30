// $Id: PluginPanel.java,v 1.14 2004/01/10 00:58:22 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2003 and The Regents of the University 
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
 * Authors:	Nelson Lee, Michael Demmer
 * Date:        October 30, 2003
 * Desc:        Panel that lets the user control the PluginManager
 *
 */

/**
 * @author Nelson Lee
 * @author Michael Demmer
 */


package net.tinyos.sim;

import net.tinyos.sim.event.*;
import java.util.*;
import java.awt.event.*;
import javax.swing.*;
import java.awt.*;
import java.io.*;

public class PluginPanel extends JPanel implements SimConst {
  private static SimDebug debug = SimDebug.get("plugins");

  private TinyViz tv;
  
  private PluginManager pluginManager;
  private Vector pinfoVec;

  private JMenu pluginMenu = new JMenu("Plugins");
  private JPanel pluginAreaPanel;
  private JTabbedPane pluginTabbedPane;

  private JLabel statusLine = new JLabel("Welcome to TinyViz");
  private JPanel statusLinePanel = new JPanel();

  class PluginInfo {
    GuiPlugin plugin;
    JCheckBoxMenuItem checkbox;
    JPanel panel;
    int tabNum;

    PluginInfo(GuiPlugin plugin) {
      this.plugin = plugin;
      this.checkbox = null;
      this.panel = null;
      this.tabNum = -1;
    }

    void register() {
      pluginManager.register(plugin);
      updateRegistration();
    }

    void deregister() {
      pluginManager.deregister(plugin);
      updateRegistration();
    }
    
    void updateRegistration() {
      boolean registered = plugin.isRegistered();
      
      if (checkbox != null) {
        checkbox.setSelected(registered);
      }
      
      if (tabNum >= 0) {
	pluginTabbedPane.setEnabledAt(tabNum, registered);
        if (registered)
          pluginTabbedPane.setSelectedIndex(tabNum);
      }
      
      if (panel != null && registered == false) {
        panel.removeAll();
      }
    }
  }

  public PluginPanel(TinyViz tv) {
    super();
    this.tv = tv;
    this.pluginManager = tv.getSimDriver().getPluginManager();
    this.pinfoVec = new Vector();

    // Plugin area and menu
    pluginAreaPanel = new JPanel();
    pluginAreaPanel.setLayout(new BorderLayout());
    pluginAreaPanel.setPreferredSize(new Dimension(MOTE_PANEL_WIDTH,
                                                   MOTE_PANEL_HEIGHT));
    pluginTabbedPane = new JTabbedPane();
    pluginTabbedPane.setTabPlacement(JTabbedPane.TOP);
    pluginTabbedPane.setFont(tv.labelFont);
    pluginAreaPanel.add(pluginTabbedPane, BorderLayout.CENTER);
    
    JMenuItem selAll = new JMenuItem("Select all");
    selAll.setFont(tv.defaultFont);
    selAll.addActionListener(new saListener());
    
    JMenuItem deselAll = new JMenuItem("Deselect all");
    deselAll.setFont(tv.defaultFont);
    deselAll.addActionListener(new dsaListener());
    
    pluginMenu.add(selAll);
    pluginMenu.add(deselAll);
    pluginMenu.add(new JSeparator());

    /* Loop through the loaded plugins, adding any GuiPlugins */
    Plugin[] parr = pluginManager.plugins();
    for (int i = 0; i < parr.length; i++) {
      if (parr[i] instanceof GuiPlugin) {
        addPlugin((GuiPlugin)parr[i]);
      }
    }
    
    if (parr.length > 2) {
      pluginTabbedPane.setSelectedIndex(0);
    }

    tv.getMenuBar().addMenu(pluginMenu);
    
    GridBagLayout gridbag = new GridBagLayout();
    GridBagConstraints c = new GridBagConstraints();
    setLayout(gridbag);
    //setLayout(new BorderLayout());

    // Plugin panel
    c.anchor = GridBagConstraints.NORTH;
    c.gridwidth = GridBagConstraints.REMAINDER;
    c.weightx = 1;
    c.weighty = 1;
    c.fill = GridBagConstraints.BOTH;
    gridbag.setConstraints(pluginAreaPanel, c);

    // Status
    //statusLinePanel.setBackground(Color.white);
    statusLinePanel.setLayout(new FlowLayout(FlowLayout.LEFT));
    statusLinePanel.setPreferredSize(new Dimension(MOTE_PANEL_WIDTH, 20));
    statusLinePanel.add(statusLine);
    statusLine.setFont(tv.defaultFont);
    statusLine.setForeground(Color.blue);
    c.anchor = GridBagConstraints.SOUTHWEST;
    c.fill = GridBagConstraints.HORIZONTAL;
    gridbag.setConstraints(statusLinePanel, c);

    add(pluginAreaPanel);
    add(statusLinePanel);
    //add(pluginAreaPanel, BorderLayout.CENTER);
    //add(statusLinePanel, BorderLayout.SOUTH);
  }
  
  public void addPlugin(GuiPlugin plugin) {
    PluginInfo pinfo = new PluginInfo(plugin);

    debug.err.println("PLUGINS: PluginPanel adding " + plugin);
    
    // the MotePlugin is always enabled but doesn't get a tab
    if (plugin instanceof MotePlugin) {
      plugin.initialize(tv, null);
      pinfoVec.add(pinfo);
      pinfo.register();
      return;
    }

    String name = plugin.toString();
    pinfo.tabNum = pinfoVec.size() - 1;
    pinfo.checkbox = new JCheckBoxMenuItem(name);
    pinfo.checkbox.setSelected(false);
    cbListener cbl = new cbListener(pinfo);
    pinfo.checkbox.addItemListener(cbl);
    pinfo.checkbox.setFont(tv.defaultFont);
    pluginMenu.add(pinfo.checkbox);

    pinfo.panel = new JPanel();
    //plugin_panes[n].setMinimumSize(new Dimension(400,300));
    //plugin_panes[n].setPreferredSize(new Dimension(400,300));
    pinfo.panel.setFont(tv.defaultFont);
    pluginTabbedPane.addTab(name, pinfo.panel);
    pluginTabbedPane.setEnabledAt(pinfo.tabNum, false);
    plugin.initialize(tv, pinfo.panel);
    pinfoVec.add(pinfo);
  }

  public void refreshRegistrations() {
    Enumeration en = pinfoVec.elements();
    while (en.hasMoreElements()) {
      PluginInfo pi = (PluginInfo)en.nextElement();
      pi.updateRegistration();
    }
  }
  
  public void drawPlugins(Graphics graphics) {
    Enumeration e = pinfoVec.elements();
    while (e.hasMoreElements()) {
      PluginInfo pi = (PluginInfo)e.nextElement();
      if (pi.plugin.isRegistered())
	pi.plugin.draw(graphics);
    }
  }

  public void refresh() {
    repaint();
  }

  public void paint(Graphics g) {
    synchronized (tv.getSimDriver().getEventBus()) {
      super.paint(g);
    }
  }

  public void setStatus(String s) {
    synchronized (statusLine) {
      statusLine.setText(s);
    }
  }

  protected class saListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      Enumeration en = pinfoVec.elements();
      while (en.hasMoreElements()) {
	PluginInfo pi = (PluginInfo)en.nextElement();
	if (pi.checkbox != null) {
	  if (!pi.checkbox.getState()) pi.checkbox.doClick();
	}
      }
    }
  }

  protected class dsaListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      Enumeration en = pinfoVec.elements();
      while (en.hasMoreElements()) {
	PluginInfo pi = (PluginInfo)en.nextElement();
	if (pi.checkbox != null) {
	  if (pi.checkbox.getState()) pi.checkbox.doClick();
	}
      }
    }
  }

  protected class cbListener implements ItemListener {
    private PluginInfo pinfo;

    cbListener(PluginInfo pinfo) {
      this.pinfo = pinfo;
    }

    public void itemStateChanged(ItemEvent e) {
      if (e.getStateChange() == ItemEvent.SELECTED) {
	tv.setStatus("Registering: "+pinfo.plugin);
	pinfo.register();
      } else {
	tv.setStatus("Deregistering: "+pinfo.plugin);
	pinfo.deregister();
      }
    }
  }
}

