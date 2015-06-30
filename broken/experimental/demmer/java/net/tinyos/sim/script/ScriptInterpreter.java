
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
  protected String scriptargs;

  public ScriptInterpreter(SimDriver driver, String script, String scriptargs) {

    // create the the various interface objects and pull in the class
    // definitions into the interpreter namespace
    new SimBindings(driver, this);

    debug.out.println("Creating interpreter for script " +
                      script + ", args " + scriptargs);
    
    this.driver = driver;
    this.script = script;
    this.scriptargs = scriptargs;

    eventHandlerPlugin = new EventHandlerPlugin();
    driver.getPluginManager().addPlugin(eventHandlerPlugin);
    driver.getPluginManager().register(eventHandlerPlugin);
  }

  public ScriptInterpreter(SimDriver driver) {
    this(driver, null, null);
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
    debug.out.println("INTERP: evaluating script");
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
          // XXX/demmer this should be passed as a list
          interp.set("argv", scriptargs);
          interp.execfile(script);

          // if the script returned and the simulation is still
          // paused, resume it
//             debug.out.println("INTERP: script returned");
//             if (driver.isPaused())
//               driver.resume();
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
        // XXX/demmer this may have race conditions with the
        // run thread...
        debug.out.println("INTERP: event handler " + id + " firing!");
        callback.__call__(new PyJavaInstance(event));
      }
    }
  }


  class EventHandlerPlugin extends Plugin {

    public void register() {}
    
    public void handleEvent(SimEvent event) {
      if (event instanceof TossimInitEvent) {
        if (script != null)
          runscript();
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
