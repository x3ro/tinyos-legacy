// $Id: SimEventBus.java,v 1.16 2004/10/22 18:46:44 selfreference Exp $

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
 * Authors:	Dennis Chi, Nelson Lee
 * Date:        October 16 2002
 * Desc:        
 *
 */

/**
 * @author Dennis Chi
 * @author Nelson Lee
 */


package net.tinyos.sim.event;

import net.tinyos.sim.*;
import java.util.*;
import java.awt.*;

/**
 * This class receives events and forwards those events to all registered listeners.
 */

public class SimEventBus {
    private Vector eventListeners;
    private LinkedList events;
    private EventThread eThread;
    private SimDriver driver;

    private static SimDebug debug = SimDebug.get("event");

    // XXX MDW
    //private boolean paused = SimConst.START_PAUSED;
    private boolean paused = false;
    
    public SimEventBus(SimDriver driver) {
	this.driver = driver;
	eventListeners = new Vector();
	events = new LinkedList();
    }

    public void start() {
        debug.out.println("EVENTBUS: Starting up...");
	eThread = new EventThread();
	eThread.start();
    }

    // will have to eventually synchronize these, but for now assuming 
    // that none will be added during runtime
    //
    // nalee 12/04: seems that it is okay if listeners are added dynamically
    // and without synchronizing them.  If they must be synchronized, we can 
    // create a GUIEvent that will be inserted on the queue/bus and be 
    // handled appropriately
    //
    public void register (Plugin listener) {
      debug.out.println("EVENTBUS: Registering plugin " +
                        listener.getClass().toString());
      eventListeners.add(listener);
    }
    
    public void deregister (Plugin listener) {
	eventListeners.remove(listener);
    }

    synchronized public void addEvent (SimEvent event) {
      debug.out.println("EVENTBUS: Adding event " + event);
      events.add(event);
      notifyAll();
    }
    
    synchronized private SimEvent removeEvent() {
	if (events.isEmpty())
	  return null;
	else {
	  SimEvent ev = (SimEvent)events.removeFirst();
	  this.notifyAll();
	  return ev;
	}
    }

    synchronized private SimEvent removeEventBlock() {
      while (events.isEmpty()) {
	try {
	  wait();
	} catch (InterruptedException ie) {
	  // Ignore
	}
      }
      SimEvent ev = (SimEvent)events.removeFirst();
      this.notifyAll();
      return ev;
    }

    synchronized public Vector getEventListeners() {
	Vector v = new Vector();
	Enumeration listeners = eventListeners.elements();
	while (listeners.hasMoreElements()) {
	    v.add(listeners.nextElement());
	}
	return v;
    }

    public void pause() {
      synchronized (this) {
	paused = true;
      }
    }
    public void clear() {
      synchronized (this) {
	events = new LinkedList();
      }
    }
    public void resume() {
      synchronized (this) {
	paused = false;
	notifyAll();
      }
    }
    public boolean isPaused() {
      synchronized (this) {
	return paused;
      }
    }

    /** Wait until all events have been processed. */
    public void processAll() throws InterruptedException {
      synchronized (this) {
	while (!events.isEmpty()) {
	  this.wait();
	}
      }
    }

    protected class EventThread extends Thread {
      public EventThread() {
        super("SimEventBus::EventThread");
      }
      
      public void run() {
	SimEvent event;
	while (true) {
	  synchronized (SimEventBus.this) {
	    while (paused) {
	      try {
		SimEventBus.this.wait();
	      } catch (InterruptedException ie) {
		// Ignore
	      }
	    }

	    event = removeEventBlock();

	    if (event != null) {
  	        debug.out.println("EVENTBUS: forwarding event " + event);
		Enumeration listeners = getEventListeners().elements();
		while (listeners.hasMoreElements()) {
		    Plugin plugin = (Plugin)listeners.nextElement();
		    plugin.handleEvent(event);
		}
		if (event instanceof TossimEvent) 
		    driver.getSimComm().ackEventRead();
	    }
	  }	    
	}
      }
    }
}


