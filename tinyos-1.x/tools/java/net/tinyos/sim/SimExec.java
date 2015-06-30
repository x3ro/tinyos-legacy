// $Id: SimExec.java,v 1.5 2004/06/11 21:30:14 mikedemmer Exp $

/*									tab:2
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
 * Date:        January 28, 2004
 * Desc:        Helper object to manage TOSSIM executions
 *
 */

/**
 * @author Michael Demmer
 */

package net.tinyos.sim;

import java.util.*;
import java.io.*;
import net.tinyos.sim.event.*;

public class SimExec implements SimConst, Runnable {
  private SimDebug dbg = SimDebug.get("exec");

  private SimDriver driver;
  private Thread runThread;
  private Process simProcess;
  private String executable;
  private int    numMotes;
  private String args;
  private static final int STATE_STARTING = 0;
  private static final int STATE_RUNNING = 1;
  private static final int STATE_EXITED = 2;
  private static final int STATE_ERROR = 2;
  private int state;
  private IOException error;
  private boolean stopProcess;
  
  public SimExec(SimDriver driver) {
    this.driver = driver;
    this.state = STATE_EXITED;
    this.runThread = null;
  }

  public void exec(String executable, int numMotes, String args) throws IOException {
    this.executable = executable;
    this.numMotes = numMotes;
    this.args = args;
    this.stopProcess = false;
    this.state = STATE_STARTING;
    this.error = null;

    if (runThread != null && runThread.isAlive()) {
      throw new RuntimeException("SimExec already at it");
    }
    
    runThread = new Thread(this, "SimExecThread");
    runThread.start();

    synchronized(runThread) {
      while (state == STATE_STARTING) {
        try {
          runThread.wait();
        } catch (InterruptedException ie) {
          continue;
        }
      }
    }
    
    if (state == STATE_ERROR) throw(error);
  }

  public void exec(String executable, int numMotes) throws IOException {
    this.exec(executable, numMotes, null);
  }

  public Exception getError() { return error; }
  
  public boolean processRunning() { return state == STATE_RUNNING; }
  public boolean processExited()  { return state == STATE_EXITED; }
  
  public void stop() {
    if (state != STATE_RUNNING) return;
    dbg.err.println("EXEC: Stopping simulation.");

    synchronized(runThread) {
      stopProcess = true;
      try {
        runThread.interrupt();
      } catch (Exception e) {
        System.err.println("Cannot interrupt runThread: "+e);
      }
      while(state == STATE_RUNNING) {
        try {
          runThread.wait();
        } catch (InterruptedException ie) {
          continue;
        }
      }
    }
  }
  
  public void run() {
    /*
     * Set up command and run it. We always enable the gui api
     * (obviously), use the lossy model, pass the random seed, and set
     * nodbgout to avoid locking up when TOSSIM writes to stdout and
     * we don't read it.
     */
    String cmdLine;
    cmdLine = executable+" -gui -r=lossy -nodbgout";
    cmdLine += " -seed=" + driver.getSimRandom().getSeed();

    if (args != null) 
      cmdLine += " " + args;
    
    cmdLine += " " + numMotes;
    
    dbg.out.println("EXEC: running simulation..."+cmdLine);
        
    try {
      simProcess = Runtime.getRuntime().exec(cmdLine);
    } catch (IOException ex) {
      System.err.println("EXEC: Unable to run simulation: "+ex);

      synchronized (runThread) {
        error = ex;
        state = STATE_ERROR;
        runThread.notifyAll();
      }
      return;
    }

    synchronized (runThread) {
      state = STATE_RUNNING;
      runThread.notifyAll();
    }
    
    while (!stopProcess) {
      try {
        simProcess.waitFor();
        System.out.println("EXEC: simulation process exited");
        state = STATE_EXITED;
        break;
      } catch (InterruptedException ie) {
        continue;
      }
    }

    dbg.err.println("EXEC: Done with run.");
    // Done running simulation
    try {
      driver.getEventBus().processAll();
    } catch (InterruptedException ie) {
      // Ignore
    }
    driver.refreshAndWait();
    driver.getSimComm().stop();

    // Sleeps are to try to make sure things really shut down
    try {
      Thread.currentThread().sleep(2000);
    } catch (InterruptedException ie) {
      // Ignore
    }
    simProcess.destroy();
    try {
      Thread.currentThread().sleep(1000);
    } catch (InterruptedException ie) {
      // Ignore
    }
      
    dbg.err.println("EXEC: Destroyed process.");
      
    synchronized (runThread) {
      state = STATE_EXITED;
      stopProcess = false;
      runThread.notifyAll();
    }
  }
}


