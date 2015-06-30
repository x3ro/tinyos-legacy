// $Id: SimExec.java,v 1.5 2003/12/01 23:27:18 scipio Exp $

/*
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
 * Authors:	Michael Demmer
 * Date:        October 9, 2003
 * Desc:        Run TOSSIM
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;


public class SimExec {
  static SimDebug dbg = SimDebug.get("exec");

  SimDriver driver;
  String executable;
  int numMotes;
  String args;
  boolean running;

  ScriptThread scriptThread;
  Thread runThread;
  
  public SimExec(SimDriver driver, String executable, int numMotes, String args) {
    this.driver = driver;
    this.executable = executable;
    this.numMotes = numMotes;
    this.args = args;
    this.running = false;

    dbg.out.println("SIMEXEC: initializing " + executable + " " + numMotes);
  }

  public void run() {
    dbg.out.println("SIMEXEC: running");
    this.running = true;
    
    scriptThread = new ScriptThread();
    runThread = new Thread(scriptThread, "SimExec::ScriptThread");
    runThread.start();
  }

  public boolean is_running() { return this.running; }
  
  public void stop() {
    dbg.err.println("SIMEXEC: Stopping simulation.");
    if (scriptThread != null) {
      scriptThread.stopProcess = true;
      try {
	runThread.interrupt();
      } catch (Exception e) {
	System.err.println("Cannot interrupt runThread: "+e);
      }
    }
  }

  class ScriptThread implements Runnable { 
    Process simProcess;
    PipeThread outpipe;
    PipeThread errpipe;
    boolean stopProcess = false;
    boolean exited = false;

    public void run() {
      /* Set up command and run it */
      String cmdLine = executable + " -gui";
      
//       if (cur_arc.numsec > 0) {
// 	cmdLine += " -t="+cur_arc.numsec;
//       }

      cmdLine += " -r=lossy";
      cmdLine += " " + args + " ";
      cmdLine += " " + numMotes;
      
      String env[] = null;
      String dbgflags = System.getProperty("DBG");
      if (dbgflags != null) {
	env = new String[1];
	env[0] = "DBG=" + dbgflags;
      }

      dbg.out.println("SIMEXEC: Running simulation: " + cmdLine);
      try {
	simProcess = Runtime.getRuntime().exec(cmdLine, env);

	// XXX/demmer use this output or the event bus?
	outpipe = new PipeThread(simProcess.getInputStream(), System.out);
	errpipe = new PipeThread(simProcess.getErrorStream(), System.err);
	outpipe.start();
	errpipe.start();
	
	while (driver.getSimComm().isStopped() && !stopProcess) {
	  
	  dbg.err.println("SIMEXEC: Connecting...");
	  Thread.currentThread().sleep(500);
	  if (driver.getSimComm().isStopped()) driver.getSimComm().start();
	  if (driver.getSimComm().isPaused())  driver.resume();
	  dbg.err.println("SIMEXEC: Waiting for init...");
	  driver.getSimComm().waitUntilInit();
          
	}

// 	// XXX/demmer always pause to give the script a chance to run
// 	dbg.err.println("SIMEXEC: SimComm initialized, pausing simulation");
// 	driver.pause();
	
// 	if (cur_arc.pauseatstart) {
// 	  dbg.err.println("SIMEXEC: Click play to start simulation.");
// 	  driver.getSimComm().pause();
// 	}
	
      } catch (Exception ex) {
	dbg.err.println("SIMEXEC: Unable to run simulation: "+ex);
	return;
      }

      while (!stopProcess) {
	try {
	  exited = false;
	  dbg.err.println("SIMEXEC: Simulation running.");
	  simProcess.waitFor();
	  dbg.err.println("SIMEXEC: Process exited.");
	  exited = true;
	  break;
	} catch (InterruptedException ie) {
	  continue;
	}
      }

      dbg.err.println("SIMEXEC: Done with run.");
      // Done running simulation
      driver.pause();
      try {
	driver.getEventBus().processAll();
      } catch (InterruptedException ie) {
	// Ignore
      }

      // Sleeps are in here to give process enough time to exit and
      // SimComm enough time to reset. Probably could use better
      // synchronization.
      driver.getSimComm().stop();
      try {
	Thread.currentThread().sleep(2000);
      } catch (InterruptedException ie) {
	// Ignore
      }
      simProcess.destroy();
      dbg.err.println("SIMEXEC: Destroyed process.");
      stopProcess = false;
      try {
	Thread.currentThread().sleep(500);
      } catch (InterruptedException ie) {
	// Ignore
      }

      synchronized (this) {
	this.notifyAll();
	return;
      }
    }
  }
}

