// $Id: PluginReader.java,v 1.3 2003/12/02 22:59:13 mikedemmer Exp $

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
 * Date:        December 05 2002
 * Desc:        Class that finds loads all classes that extend Plugin
 *
 */

/**
 * @author Phil Levis
 * @author Nelson Lee
 */


package net.tinyos.sim;

import java.io.*;
import java.util.*;

public class PluginReader {
  private SimDebug dbg = SimDebug.get("pluginreader");
  private String pluginPath;
  private Vector plugins = new Vector();
  private Set pluginClasses = new HashSet();
  private Class pluginClass;
  private String pathsep = null;

  public static final int MAX_DEPTH = 12;

  void loadpathsep()
  {
    pathsep = System.getProperty( "path.separator" );
    if( pathsep == null )
      pathsep = ":";
  }

  public PluginReader() {
    this(null);
  }

  public PluginReader(String pluginPath) {
    loadpathsep();
    this.pluginPath = pluginPath;
    
    try {
      this.pluginClass = Class.forName("net.tinyos.sim.Plugin");
    } catch (Exception e) {
      throw new RuntimeException("Fatal error: Cannot access class net.tinyos.sim.Plugin - exiting: "+e);
    }
    loadDefaultPlugins();
    if (pluginPath != null) {
      loadPlugins();
    }
  }

  private void loadDefaultPlugins() {
    // Always load MotePlugin and MoteLayoutPlugin
    Plugin motePlugin = new MotePlugin();
    plugins.addElement(motePlugin);
    pluginClasses.add(motePlugin.getClass());
 
    Plugin moteLayoutPlugin = new MoteLayoutPlugin();
    plugins.addElement(moteLayoutPlugin);
    pluginClasses.add(moteLayoutPlugin.getClass());

    // Open default plugins list and load each whitespace-delimited entry
    try {
      java.net.URL plist_res = this.getClass().getResource("plugins/plugins.list");
      StreamTokenizer st = new StreamTokenizer(new BufferedReader(new InputStreamReader(plist_res.openStream())));
      st.wordChars('/','/');
      while (st.nextToken() != st.TT_EOF) {
	loadPluginClass(st.sval);
      }
    } catch (Exception e) {
      // Give up
    }
  }

  public Plugin[] plugins() {
    Object o[] = plugins.toArray();
    if (o == null) return null;
    else {
      Plugin[] p = new Plugin[o.length];
      for (int i = 0; i < o.length; i++) p[i] = (Plugin)o[i];
      return p;
    }
  }

  public String getPluginPath() {
    return pluginPath;
  }

  private void loadPlugins() {
    dbg.err.println("loadPlugins: path "+pluginPath);
    loadpathsep();
    StringTokenizer st = new StringTokenizer(pluginPath, pathsep);
    while (st.hasMoreTokens()) {
      String dir = st.nextToken();
      File rootFile = new File(dir);
      findPlugins(rootFile);
    }
  }

  private boolean isRelated(Class subC, Class superC) {
    if (subC == superC) {return false;}
    for (Class tmp = subC.getSuperclass(); tmp != null; tmp = tmp.getSuperclass()) {
      if (tmp.equals(superC)) {
	return true;
      }
    }
    return false;
  }

  private void loadPluginClass(String className) {
    dbg.err.println("loadPluginClass: "+className);

    // If it's a filename, munge into a class name
    String classEnd = ".class";
    if (className.endsWith(classEnd)) {
      className = className.substring(0, className.length() - classEnd.length());
    }
    className = className.replace('\\', '/');
    if (className.startsWith("./")) {
      className = className.substring(2);
    }
    className = className.replace('/', '.');

    boolean loaded = false;
    int loadCount = 0;
    while (!loaded) {
      if (++loadCount > MAX_DEPTH) {
	// Give up
	loaded = true;
	break;
      }
      try {
	dbg.err.println("Loading class: "+className);
	Class newClass = Class.forName(className);
	dbg.err.println("Loaded OK.");
	loaded = true;
	if (isRelated(newClass, pluginClass)) {
	  if (!pluginClasses.contains(newClass)) {
	    Plugin p = (Plugin)newClass.newInstance();
	    dbg.err.println("Found plugin: " +className);
	    plugins.addElement(p);
	    pluginClasses.add(p.getClass());
	  }
	}
      } catch (NoClassDefFoundError er) {
	// If we find a class file but we're trying to load it with 
	// the wrong name
	String m = er.getMessage();
	int index = m.indexOf("wrong name: ");
	if (index == -1) { loaded = true; break; }
	index += new String("wrong name: ").length();
	className = m.substring(index, m.length()-1);
	className = className.replace('/', '.');

      } catch (ClassNotFoundException cnfe) {
	// If we can't find the class, look in our package
	dbg.err.println("Trying "+SimConst.PACKAGE_NAME+"...");
	className = SimConst.PACKAGE_NAME + "." + className;

      } catch (Exception e) {
	dbg.err.println("Got a different exception: "+e);
	loaded = true;
      }
    }
  }

  private void findPlugins(File file) {
    dbg.err.println("findPlugins: file "+file);
    try {
      if (file.isDirectory()) {
	String[] dirents = file.list();
	for (int i = 0; i < dirents.length; i++) {
	  File subFile = new File(file.getPath() + "/" + dirents[i]);
	  if (!subFile.isDirectory()) findPlugins(subFile);
	}
      } else if (file.isFile()) { // Could be a Java class
	String fileName = file.getPath();
	String classEnd = ".class";
	if (fileName.endsWith(classEnd)) {
	  loadPluginClass(fileName);
	}
      }
    } catch (Exception e) {
      System.err.println("findPlugins("+file+") got exception: "+e);
    }
  }

  public static void main(String[] args) {
    PluginReader pluginReader = new PluginReader(".");
    Plugin[] theplugins = pluginReader.plugins();
    for (int i = 0; i < theplugins.length; i++) {
      System.out.println(theplugins[i]);
    }
  }
}
