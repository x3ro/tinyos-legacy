// $Id: ScriptInterpreter.java,v 1.5 2004/02/20 20:24:57 mikedemmer Exp $

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
 * Desc:        Python interpreter
 *
 */

/**
 * @author Michael Demmer
 */

package net.tinyos.sim.script;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;
import net.tinyos.sim.script.reflect.SimBindings;

import java.util.*;

import org.python.util.InteractiveInterpreter;
import org.python.core.*;

public class ScriptInterpreter {
  protected SimDebug debug = SimDebug.get("interp");
  protected SimDriver driver;
  protected InteractiveInterpreter interp = new InteractiveInterpreter();
  protected Hashtable eventHandlers = new Hashtable();
  protected int maxHandlerID = 0;
  protected EventHandlerPlugin eventHandlerPlugin;
  protected String script;

  public ScriptInterpreter(SimDriver driver, String script) {

    // create the the various interface objects and pull in the class
    // definitions into the interpreter namespace
    new SimBindings(driver, this);

    debug.out.println("Creating interpreter for script " + script);
    
    this.driver = driver;
    this.script = script;

    eventHandlerPlugin = new EventHandlerPlugin();
    driver.getPluginManager().addPlugin(eventHandlerPlugin);
    driver.getPluginManager().register(eventHandlerPlugin);

    if (script != null) {
      runscript();
    }
  }
  
  public ScriptInterpreter(SimDriver driver) {
    this(driver, null);
  }
  
  /*
   * Exported interface to the actual underlying interpreter.
   */
  public void set(String var, Object obj) {
    interp.set(var, obj);
  }
  
  public void exec(String script) {
    interp.exec(script);
  }
  
  public void execfile(String filename) {
    debug.out.println("INTERP: evaluating script "+filename);
    interp.execfile(filename);
  }

  public boolean runsource(String source) {
    return interp.runsource(source);
  }

  public void setOut(java.io.OutputStream outStream) {
    interp.setOut(outStream);
  }
  
  public void setErr(java.io.OutputStream outStream) {
    interp.setErr(outStream);
  }

  /*
   * Spin a thread to exec the script, if there is one.
   */
  public void runscript() {
    debug.out.println("INTERP: evaluating script...");
    
    Thread runthread = new Thread("ScriptInterpreter::runscript") {
        public void run() {
          interp.execfile(script);
        }
      };
    runthread.start();
  }

  /*
   * Methods to handle events coming from the system and reflecting
   * them to python.
   */
  public int addEventHandler(PyFunction callback, Class eventclass) {
    int id;
    
    synchronized (eventHandlers) {
      id = maxHandlerID++;
      EventHandler h = new EventHandler(id, callback, eventclass);
      eventHandlers.put(new Integer(id), h);
    }
    
    debug.out.println("INTERP: adding event handler " + id);

    return id;
  }

  public void removeEventHandler(int id) {
    debug.out.println("INTERP: removing event handler " + id);

    EventHandler h;
    synchronized (eventHandlers) {
      h = (EventHandler)eventHandlers.remove(new Integer(id));
    }
    
    if (h == null) {
      throw new IndexOutOfBoundsException("No event handler with id " + id);
    }
  }

  class EventHandler {
    int id;
    PyFunction callback;
    Class eventClass;

    EventHandler(int id, PyFunction callback, Class eventClass) {
      this.id = id;
      this.callback = callback;
      this.eventClass = eventClass;
    }
    
    public void handleEvent(SimEvent event) {
      if (eventClass == null ||
          eventClass.isInstance(event))
      {
        // Warning: this may have race conditions with the main script
        // thread.
        debug.out.println("INTERP: event handler " + id + " firing!");
        callback.__call__(new PyJavaInstance(event));
      }
    }
  }


  class EventHandlerPlugin extends Plugin {

    public void register() {}
    
    public void handleEvent(SimEvent event) {
      if (event instanceof TossimInitEvent) {
        if (script != null) {
//           System.out.println("Pausing to run script " + script);
//           driver.pause();
//          runscript();
        }
      }
      
      debug.out.println("INTERP: forwarding event to handlers: " + event);
      synchronized (eventHandlers) {
	Enumeration e = eventHandlers.elements();
	while(e.hasMoreElements()) {
	  EventHandler h = (EventHandler)e.nextElement();
	  h.handleEvent(event);
	}
      }
    }
  }
}
