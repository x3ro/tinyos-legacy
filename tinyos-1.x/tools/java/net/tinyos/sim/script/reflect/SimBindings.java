// $Id: SimBindings.java,v 1.5 2004/06/11 21:30:15 mikedemmer Exp $

/*
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
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
 * Date:        January 9, 2004
 * Desc:        Static instantiator for reflected objects
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimConst;
import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimDebug;
import net.tinyos.sim.script.ScriptInterpreter;

import org.python.core.*;

import java.util.*;

public class SimBindings {
  protected SimDebug dbg = SimDebug.get("script");

  public static Hashtable reflections = new Hashtable();
  
  public SimBindings(SimDriver driver, ScriptInterpreter interp) {
    // create the reflected objects
    reflections.put("sim",      new Sim(interp, driver));
    reflections.put("interp",   new Interp(interp, driver)); 
    reflections.put("radio",    new Radio(interp, driver));
    reflections.put("motes",    new Motes(interp, driver));
    reflections.put("packets",  new Packets(interp, driver));
    reflections.put("comm",     new Commands(interp, driver));
    reflections.put("sensor",   new Sensor(interp, driver));
    reflections.put("random",   new Random(interp, driver));
    
    // set up the sys.path load path by changing the : separated list
    // into a true python list
    String pathsep = System.getProperty("path.separator");
    if (pathsep == null) pathsep = ":";

    String scriptPath = driver.getScriptPath();
    if (scriptPath == null)
      scriptPath = "";
    
    StringBuffer path = new StringBuffer();
    path.append("[");
    StringTokenizer st = new StringTokenizer(scriptPath, pathsep);
    boolean first = true;
    while (st.hasMoreTokens()) {
      if (!first) {
        path.append(", ");
      }
      path.append("'"+st.nextToken()+"'");
      first = false;
    }
    path.append("]");
    
    dbg.out.println("script: setting sys.path to "+path);
    
    interp.exec("import sys");
    interp.exec("sys.path = " + path);
    
    // cons up the simcore module class to export reflected interface
    PyJavaClass simcore_class = PyJavaClass.lookup(simcore.class);
    PyObject simcore_dict     = simcore_class.__getattr__("__dict__");
    PyModule simcore_module   = new PyModule("simcore", simcore_dict);
    Py.getSystemState().modules.__setitem__("simcore", simcore_module);
  }

}

