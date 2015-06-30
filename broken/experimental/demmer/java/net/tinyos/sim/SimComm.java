// $Id: SimComm.java,v 1.9 2003/12/01 23:27:17 scipio Exp $

/*									tab:2
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
 * Authors:	Dennis Chi, Nelson Lee
 * Date:        October 16 2002
 * Desc:        
 *
 */

/**
 * @author Dennis Chi
 * @author Nelson Lee
 */


package net.tinyos.sim;

import java.io.*;
import java.util.*;
import java.net.*;

import net.tinyos.message.*;
import net.tinyos.sf.*;
import net.tinyos.sim.msg.*;
import net.tinyos.sim.event.*;

public class SimComm {
  private static final SimDebug debug = SimDebug.get("comm");
  private SimDriver driver;
  private Thread packetThread = null; 
  private long delay = 0;
  private Socket eventSocket, cmdSocket;
  private int state;
  private static final int STATE_STOPPED = 0;
  private static final int STATE_CONNECTING = 1;
  private static final int STATE_PAUSED = 2;
  private static final int STATE_RUNNING = 3;
  private SimProtocol eventProtocol, cmdProtocol;
  private SimEventBus eventBus;
  private int eventPort, cmdPort;
  private boolean run_sf, sf_started = false;
  private boolean pauseOnInit = true;
  private SerialForwarder sf;
  private boolean seen_init = false;

  public SimComm(SimDriver driver, boolean run_sf, boolean pauseOnInit) {
    this(driver, run_sf, pauseOnInit, 
	SimProtocol.TOSSIM_EVENT_PORT, SimProtocol.TOSSIM_COMMAND_PORT);
  }

  public SimComm(SimDriver driver, boolean run_sf, boolean pauseOnInit, 
		 int eventPort, int cmdPort) {
    this.driver = driver;
    this.run_sf = run_sf;
    this.pauseOnInit = pauseOnInit;
    this.eventBus = driver.getEventBus();
    this.eventPort = eventPort;
    this.cmdPort = cmdPort;
    this.state = STATE_STOPPED;
  }
  
  public void start() {
    if (state != STATE_STOPPED) return;
    
    debug.err.println("SimComm: start() called");
    driver.setStatus("Connecting to simulator...");
    state = STATE_CONNECTING;
    seen_init = false;
    try {
      debug.err.println("SimComm: Opening event socket...");
      eventSocket = new Socket("127.0.0.1", eventPort);
      InputStream input = eventSocket.getInputStream();
      OutputStream output = eventSocket.getOutputStream();
      eventProtocol = new SimProtocol(input, output, false);
    } catch (Exception e) {
      debug.err.println("SimComm: Socket connection failed: "+e);
      driver.setStatus("Connection to simulator failed");

      // XXX/demmer this doesn't really make sense but too many things
      // depend on it. seems to me it should stay in connecting state
      // until the thing actually gets a connection
      state = STATE_STOPPED;
      return;
    }

    debug.err.println("Connection to simulator established");
    driver.setStatus("Connection to simulator established");

    if (pauseOnInit) {
      debug.err.println("SimComm: pausing to wait for sync-up");
      state = STATE_PAUSED;
    } else {
      debug.err.println("SimComm: running");
      state = STATE_RUNNING;
    }

    try {
      packetThread = new PacketThread();
      packetThread.start();
    }
    catch (Exception exception) {
      System.err.println(exception);
      System.exit(-1);
    }

    if (run_sf) {
      if (!sf_started) {
        debug.err.println("SimComm: starting serial forwarder");
	try {
	  String args[] = { "-quiet", "-no-gui", "-comm", "tossim-serial" };
	  sf = new SerialForwarder(args);
	  sf_started = true;
          debug.err.println("SimComm: sf started");
	} catch (IOException ioe) {
	  debug.err.println("SimComm: Can't start SerialForward: "+ioe);
	  driver.setStatus("Unable to start serial forwarder");
	}
      } else {
	sf.stopListenServer();
	sf.startListenServer();
      }
    }
  }

  public synchronized void stop() {
    if (state == STATE_STOPPED) return;
    if (state == STATE_CONNECTING) return;
    state = STATE_STOPPED;
    seen_init = false;

    if (eventSocket != null) {
      try {
	debug.err.println("SimComm: Closing event socket...");
	eventSocket.close();
      } catch (Exception e) {
	// Ignore
      }
    }

    if (cmdSocket != null) {
      try {
	debug.err.println("SimComm: Closing command socket...");
	cmdSocket.close();
	cmdSocket = null;
      } catch (Exception e) {
	// Ignore
      }
    }

    this.notify();
    try {
      // Don't wait forever
      this.wait(500);
    } catch (InterruptedException ie) {
      // Ignore
    }
    driver.refreshPauseState();
    debug.err.println("SimComm: Stopped.");
    return;
  }

  public synchronized boolean isStopped() {
    return (state == STATE_STOPPED);
  }

  public synchronized boolean isPaused() {
    return (state == STATE_PAUSED || state == STATE_CONNECTING);
  }

  public synchronized void pause() {
    if (state != STATE_RUNNING) return;
    state = STATE_PAUSED;
    // XXX MDW - Don't want this if it prevents selection update
    // messages from propagating while paused
    //eventBus.pause();
    debug.err.println("SimComm: pausing");
    driver.setStatus("Simulation paused");
    driver.refreshPauseState();
  }

  public synchronized void resume() {
    if (state != STATE_PAUSED && state != STATE_CONNECTING) return;
    switch (state) {
      case STATE_PAUSED:
	state = STATE_RUNNING;
	debug.err.println("SimComm: resuming");
	this.notify();
	driver.setStatus("Simulation resumed");
	driver.refreshPauseState();
	break;

      case STATE_CONNECTING:
	// Do nothing
	break;
    }
  }

  /** Wait until the TossimInitEvent has been read, or we stop. */

  // XXX/demmer this isn't really true... if the connection hasn't
  // been established yet, this returns immediately
  
  public synchronized void waitUntilInit() throws InterruptedException {
    while (state != STATE_STOPPED && !seen_init) {
      this.wait();
    }
  }

  public synchronized void setSimDelay(long delay) {
    this.delay = delay;
  }

  public synchronized void sendCommand(TossimCommand cmd) throws IOException {
    int trycount = 0;
    while (trycount < 2) {
      trycount++;
      try {
	if (cmdSocket == null) {
	  debug.err.println("SimComm: Opening command socket...");
          cmdSocket = new Socket("127.0.0.1", cmdPort);
	  debug.err.println("SimComm: Got command socket: "+cmdSocket);
	  InputStream input = cmdSocket.getInputStream();
	  OutputStream output = cmdSocket.getOutputStream();
	  cmdProtocol = new SimProtocol(input, output);
	  debug.err.println("SimComm: Opened socket to simulator command port.");
	}
	cmdProtocol.writeCommand(cmd);
	driver.setStatus("Wrote command: "+cmd.toString());
	debug.err.println("Wrote command: "+cmd.toString());
	return;
      } catch (IOException ioe) {
	driver.setStatus("Command send failed: "+ioe.getMessage());
	debug.err.println("Command send failed: "+ioe);
	try {
	  cmdSocket.close();
	  cmdSocket = null;
	} catch (Exception e) {
	  // Ignore
	}
      }
    }
    throw new IOException("Giving up on sending command: "+cmd);
  }
  
  public synchronized TossimEvent sendCommandGetReply(TossimCommand cmd) throws IOException {
    sendCommand(cmd);
    return cmdProtocol.readEvent();
  }
  
  public void ackEventRead() {
      // cannot use synchronized method isStopped();
      // race condition: PacketReadThread holds onto the lock while trying to read from
      // event stream; simulator won't send an event until its last event was acked
      // resulting in deadlock --nalee 3/25/03
      if (state != STATE_STOPPED) {
	  //debug.err.println("SimComm: Acking Event Read");
	  try {
	      eventProtocol.ackEventRead();
	  }
	  catch (Exception e) {
	      if (debug.enabled) {
		  System.err.println("SimComm: Got exception: "+e);
		  e.printStackTrace();
	      }
	  }
      }
  }
  
  protected class PacketThread extends Thread {

    public PacketThread() throws IOException {
      super("SimComm::PacketThread");
      setPriority(Thread.MIN_PRIORITY);
    }

    public void run() {

      try{
      	while (true) {
	  synchronized (SimComm.this) {
	    while (state != STATE_RUNNING) {
	      if (state == STATE_STOPPED) {
		debug.err.println("SimComm: State is stopped, resetting...");
		// XXX MDW - Don't think I want this here
		// driver.reset();
		return;
	      }
	      try {
		debug.err.println("SimComm: Packet Thread Waiting...");
		SimComm.this.wait();
		debug.err.println("SimComm: Packet Thread Woke up");
	      } catch (InterruptedException ie) {
		// Ignore
	      }
	    }
	  }

          debug.err.println("SimComm: reading event - delay "+delay);
       	  SimEvent event = eventProtocol.readEvent(delay);
          debug.err.println("SimComm: got event: "+event) ;
	  if (event instanceof net.tinyos.sim.event.TossimInitEvent) {
	      //if (DEBUG) 
	    System.err.println("SimComm: TossimInitEvent received, pausing system...");
	    driver.pause();
	    eventBus.addEvent(event);
	    try {
	      // Handle all pending events (e.g., initializations) 
	      // before reading more from the sim
	      eventBus.processAll();
	    } catch (InterruptedException ie) {
	      // Just keep going
	    }
	    //if (DEBUG) 
	    System.err.println("SimComm: Continuing");
	    synchronized (SimComm.this) {
	      seen_init = true;
	      SimComm.this.notifyAll();
	    }
	  } else {
	    eventBus.addEvent(event);
	  }
	}
      } catch (Exception e) {
	debug.err.println("SimComm: Got exception: "+e);
	if (debug.enabled) e.printStackTrace();
	SimComm.this.stop();
	// XXX MDW - Don't think I want this here
	//driver.reset();
	return;
      }
    }
  }
}
