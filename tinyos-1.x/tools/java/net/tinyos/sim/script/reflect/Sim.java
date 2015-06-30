// $Id: Sim.java,v 1.9 2004/06/14 20:31:51 mikedemmer Exp $

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
 * Desc:        Reflected simulator core object
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.Plugin;
import net.tinyos.sim.PluginManager;
import net.tinyos.sim.SimDriver;
import net.tinyos.sim.event.DebugMsgEvent;
import net.tinyos.sim.event.SimEvent;
import net.tinyos.sim.script.ScriptInterpreter;

import java.io.*;
import java.util.StringTokenizer;
import net.tinyos.sim.SimConst;

/**
 * The Sim class controls high-level operations on the simulation,
 * including pause/resume and execution control.<p>
 *
 * The class is bound into the simcore module as the <i>sim</i>
 * global instance.
 */
public class Sim extends SimReflect {
  /**
   * Backdoor handle on the SimDriver internal object. This should not
   * be used in scripts and will likely disappear in a future release.
   */
  public SimDriver __driver;

  /**
   * Array version of the arguments passed in the <i>-scriptargs</i>
   * command line argument.
   */
  public String[] argv = null;
  
  private DBGDumpPlugin plugin = null;

  /**
   * Constructor for the Sim object. This should not be called
   * explicitly, rather the pre-constructed instance <i>sim</i> should
   * be used.
   */
  public Sim(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);

    __driver = driver; // back door

    // set up argv
    if (driver.getScriptArgs() != null) {
      StringTokenizer t = new StringTokenizer(driver.getScriptArgs());
      int argc = t.countTokens();
      argv = new String[argc];
      for (int i = 0; i < argc; ++i) {
        argv[i] = t.nextToken();
      }
    } else {
      argv = new String[0];
    }
  }

  /**
   * Pauses the simulation.
   */
  public void pause()  { driver.pause(); }

  /**
   * Resumes the simulation.
   */
  public void resume() { driver.resume(); }

  /**
   * Indicates whether or not the simulator is paused.
   */
  public boolean isPaused() { return driver.isPaused(); }
  
  /**
   * Stops the simulator execution.
   */
  public void stop()   { driver.stop(); }

  /**
   * Returns the width of the simulator 'world' in logical space units.
   */
  public int getWorldWidth() {
    return SimConst.MOTE_SCALE_WIDTH;
  }

  /**
   * Returns the height of the simulator 'world' in logical space units.
   */
  public int getWorldHeight() {
    return SimConst.MOTE_SCALE_HEIGHT;
  }

  /**
   * Returns the current simulator time. More accurately, this
   * reflects the timestamp carried in the last event to arrive from
   * the simulator.
   */
  public long getTossimTime() {
    return driver.getTossimTime();
  }

  /**
   * Exits the simulator environment with the given error code.
   *
   * @param errcode	the exit status code
   */
  public void exit(int errcode) {
    driver.exit(errcode);
  }

  /**
   * Exits the simulator environment with an error code of 0.
   */
  public void exit() {
    driver.exit(0);
  }

  /**
   * Sets the logical simulator delay.
   *
   * @param delay_ms	delay in milliseconds
   */
  public void setSimDelay(long delay_ms) {
    driver.setSimDelay(delay_ms);
  }

  /**
   * Starts dumping debug messages to the given file.
   *
   * @param filename	path to the file for debug output
   */
  public void dumpDBG(String filename) throws IOException {
    if (plugin != null) {
      throw new IOException("Already dumping DBG output.");
    }
    
    File file = new File(filename);
    if (file.exists()) {
      throw new IOException("File " + filename + " already exists.");
    }
    FileWriter writer = new FileWriter(file);
    plugin = new DBGDumpPlugin(writer);
    driver.getPluginManager().register(plugin);
  }

  /**
   * Stops dumping debug messages.
   */
  public void stopDBGDump() throws IOException {
    if (plugin == null) {throw new IOException("Not dumping debug output.");}
    else {
      driver.getPluginManager().deregister(plugin);
      plugin.finish();
      plugin = null;
    }
  }

  /**
   * Run the simulator and block until the driver connects.
   *
   * @param executable	path to the executable
   * @param numMotes	number of motes to run
   * @param args	argument string
   */
  public void exec(String executable, int numMotes, String args) throws IOException {
    if (driver.getSimExec().processRunning() ||
        (!driver.getSimComm().isStopped())) {
      throw new RuntimeException("Process already running");
    }
    driver.getSimExec().exec(executable, numMotes, args);
    driver.connect();
  }
  
  /**
   * Run the simulator and block until the driver connects.
   *
   * @param executable	path to the executable
   * @param numMotes	number of motes to run
   */
  public void exec(String executable, int numMotes) throws IOException {
    exec(executable, numMotes, null);
  }

  /**
   * Reset the simulator, stopping the current simulation process and
   * clearing out all internal state.
   */
  public void reset() {
    driver.reset();
  }

  /**
   * Create a new generic SimObject.
   */
  public SimObject newSimObject(int size, double x, double y) {
    return new SimObject(interp, driver, size, x, y);
  }

  /**
   * Create a new generic SimObject.
   */
  public SimObject newSimObject() {
    int x = driver.getSimRandom().nextInt(getWorldWidth());
    int y = driver.getSimRandom().nextInt(getWorldHeight());
    return new SimObject(interp, driver, 2, x, y);
  }

  /**
   * Load the requested plugin.
   */
  public void loadPlugin(String pluginName) {
    Plugin p = driver.getPluginManager().getPlugin(pluginName);
    if (p == null) {
      throw new RuntimeException("no plugin " + pluginName);
    }
    driver.getPluginManager().register(p);
    driver.refreshPluginRegistrations();
  }

  private class DBGDumpPlugin extends Plugin {
    private Writer writer;

    public DBGDumpPlugin(Writer writer) {
      this.writer = writer;
    }

    public void handleEvent(SimEvent e) {
      if (e instanceof DebugMsgEvent) {
	try {
	  DebugMsgEvent dme = (DebugMsgEvent)e;
	  writer.write(dme.getMessage() + "\n");
	}
	catch (Exception exception){
	  System.err.println(exception);
	}
      }
    }

    public void finish() {
      try {
	writer.close();
      }
      catch (IOException e) {}
    }
  }
}
