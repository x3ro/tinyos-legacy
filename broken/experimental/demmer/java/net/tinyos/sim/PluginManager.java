// $Id: PluginManager.java,v 1.6 2003/12/02 22:59:13 mikedemmer Exp $

/*
 *
 *
 * "Copyright (c) 2003 and The Regents of the University 
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
 * Authors:	Michael Demmer
 * Date:        October 30 2003
 * Desc:        Manager object for plugin registration / deregistration
 *
 */

/**
 * @author Nelson Lee
 * @author Michael Demmer
 */

package net.tinyos.sim;

import net.tinyos.sim.event.*;
import java.util.*;

public class PluginManager {
  private static SimDebug debug = SimDebug.get("plugins");

  private SimDriver driver;
  private PluginReader pluginReader;

  private Vector plugins;
  
  public PluginManager(SimDriver driver) {
    this.driver = driver;
    plugins = new Vector();
  }
  
  public void loadPlugins(String plugin_path) {
    pluginReader = new PluginReader(plugin_path);
    Plugin[] parr = pluginReader.plugins();
    for (int i = 0; i < parr.length; i++) {
      Plugin plugin = parr[i];
      addPlugin(plugin);
    }
    
    if (parr.length < 2)
      System.err.println("WARNING: Could not find any plugins. " +
                         "Check your plugin path.");
  }

  public void addPlugin(Plugin plugin) {
    debug.err.println("PLUGINS: added plugin " + plugin);
    plugins.add(plugin);
    plugin.initialize(driver);
  }

  public void register(Plugin plugin) {
    if (plugin.isRegistered()) return; 
    debug.err.println("PLUGINS: registering plugin " + plugin);
    plugin.setRegistered(true);
    plugin.register();
    plugin.reset();
    driver.getEventBus().register(plugin);

    /* Send all current option settings to this plugin */
    Enumeration e = driver.getOptions();
    while (e.hasMoreElements()) {
      String option = (String)e.nextElement();
      plugin.handleEvent(new OptionSetEvent(option, driver.getOption(option)));
    }
  }
  
  public void deregister(Plugin plugin) {
    if (!plugin.isRegistered()) return;
    debug.err.println("PLUGINS: deregistering plugin " + plugin);
    plugin.setRegistered(false);
    plugin.reset();
    driver.getEventBus().deregister(plugin);
    plugin.deregister();
  }

  public Plugin[] plugins() {
    Plugin parr[] = new Plugin[plugins.size()];
    // XXX/demmer why is this synchronized?
    synchronized (driver.getEventBus()) {
      int n = 0;
      Enumeration e = plugins.elements();
      while (e.hasMoreElements()) {
	Plugin p = (Plugin)e.nextElement();
	parr[n++] = p;
      }
      return parr;
    }
  }

  public Plugin getPlugin(String name) {
    Enumeration e = plugins.elements();
    while (e.hasMoreElements()) {
      Plugin plugin = (Plugin)e.nextElement();
      if (plugin.getClass().getName().endsWith(name)) {
	return plugin;
      }
    }
    return null;
  }

  public void reset() {
    Enumeration e = plugins.elements();
    while (e.hasMoreElements()) {
      Plugin plugin = (Plugin)e.nextElement();
      if (plugin.isRegistered())
        plugin.reset();
    }
  }
}

