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
 * Date:        October 30, 2003
 * Desc:        Dynamic debugging class
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim;

import java.io.*;
import java.util.*;

public class SimDebug {
  public boolean enabled;
  public PrintStream out;
  public PrintStream err;

  protected static Hashtable allModes = new Hashtable();
  protected static boolean allModesInitted = false;

  protected static void initAllModes() {
    /*
     * All valid debug modes must have an entry here, otherwise they
     * can't be used.
     */
    allModes.put("comm", new SimDebug());
    allModes.put("commands", new SimDebug());
    allModes.put("driver", new SimDebug());
    allModes.put("event", new SimDebug());
    allModes.put("interp", new SimDebug());
    allModes.put("layout", new SimDebug());
    allModes.put("mote", new SimDebug());
    allModes.put("mouse", new SimDebug());
    allModes.put("plugins", new SimDebug());
    allModes.put("pluginreader", new SimDebug());
    allModes.put("packetlog", new SimDebug());
    allModes.put("radio", new SimDebug());
    allModes.put("script", new SimDebug());
    allModes.put("pluginreader", new SimDebug());

    String modes = System.getProperty("SIMDBG");
    SimDebug dbg;

    if (modes == null || modes.equals("")) {
	return;
    }
    else if (modes.equals("all")) {
      Enumeration e = allModes.elements();
      while (e.hasMoreElements()) {
        dbg = (SimDebug)e.nextElement();
        dbg.enable();
      }
    } else {
      boolean invert = false;
      
      if (modes.charAt(0) == '^') {
        invert = true;
        modes = modes.substring(1);
        Enumeration e = allModes.elements();
        while (e.hasMoreElements()) {
          dbg = (SimDebug)e.nextElement();
          dbg.enable();
        }
      }
      StringTokenizer parse = new StringTokenizer(modes, ",");
      while (parse.hasMoreTokens()) {
        String token = parse.nextToken();
        dbg = (SimDebug)allModes.get(token);
        if (dbg == null) {
          System.err.println("Warning: Invalid simdebug mode "+token);
        } else {
          if (invert) {
            dbg.disable();
          } else {
            dbg.enable();
          }
        }
      }
    }
    
    allModesInitted = true;
  }

  public static SimDebug get(String mode) {
    synchronized (allModes) {
	if (!allModesInitted) initAllModes();
    }
        
    SimDebug dbg = (SimDebug)allModes.get(mode);
    if (dbg == null) {
      throw new RuntimeException("Invalid debug mode " + mode);
    }
    return dbg;
  }

  static public String listAllModes() {
    StringBuffer buffer = new StringBuffer();

    Enumeration e = allModes.keys();
    if (! e.hasMoreElements()) {
      return "";
    }
    
    buffer.append(e.nextElement());
    while (e.hasMoreElements()) {
      buffer.append(", " + e.nextElement());
    }
    
    return buffer.toString();
  }

  protected SimDebug() {
    this.out = nullStream;
    this.err = nullStream;
    this.enabled = false;
  }

  public void enable() {
    enabled = true;
    out = System.err;
    err = System.err;
  }

  public void disable() {
    enabled = false;
    out = nullStream;
    err = nullStream;
  }

  static class NullOutputStream extends OutputStream {
    public NullOutputStream() {}
    public final void close() {}
    public final void flush() {}
    public final void write(byte[] b) {}
    public final void write(byte[] b, int off, int len) {}
    public final void write(int b) {}
  }
  protected static NullOutputStream outStream = new NullOutputStream();
  protected PrintStream nullStream = new PrintStream(outStream);
  
}
