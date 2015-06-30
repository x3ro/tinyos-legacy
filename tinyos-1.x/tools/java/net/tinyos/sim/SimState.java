// $Id: SimState.java,v 1.6 2004/03/05 22:13:55 mikedemmer Exp $

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
 * Authors:	Dennis Chi
 * Date:        October 16 2002
 * Desc:        
 *
 */

/**
 * @author Dennis Chi
 */


package net.tinyos.sim;

import java.util.*;
import net.tinyos.sim.event.*;

public class SimState {
  private SimDriver simDriver;
  private SimEventBus eventBus;
  private HashSet simObjects = new HashSet();
  private Hashtable moteObjects = new Hashtable();

  public SimState(SimDriver simDriver) {
    this.simDriver = simDriver;
    this.eventBus = simDriver.getEventBus();
  }

  synchronized public Collection getSimObjects() {
    return (Collection)simObjects.clone();
  }

  synchronized public Collection getMoteSimObjects() {
    return ((Hashtable)(moteObjects.clone())).values();
  }

  synchronized public int numSimObjects() {
    return simObjects.size();
  }
  
  synchronized public int numMoteSimObjects() {
    return moteObjects.size();
  }
  
  synchronized public Set getSelectedSimObjects() {
    HashSet selected = new HashSet();
    Iterator it = simObjects.iterator();
    while (it.hasNext()) {
      SimObject so = (SimObject)it.next();
      if (so.isSelected()) selected.add(so);
    }
    return selected;
  }

  synchronized public Set getSelectedMoteSimObjects() {
    HashSet selected = new HashSet();
    Enumeration e = moteObjects.elements();
    while (e.hasMoreElements()) {
      MoteSimObject so = (MoteSimObject)e.nextElement();
      if (so.isSelected()) selected.add(so);
    }
    return selected;
  }

  public void addSimObject(SimObject simObject) {
    // Note: this method can't be synchronized since we need to
    // release the lock on the SimState before adding an event to the
    // event bus
    synchronized (this) {
      simObjects.add(simObject);
      if (simObject instanceof MoteSimObject) {
        MoteSimObject mote = (MoteSimObject)simObject;
        moteObjects.put(new Integer(mote.getID()), mote);
      }
    }
      
    eventBus.addEvent(
      new SimObjectEvent(SimObjectEvent.OBJECT_ADDED, simObject));
  }

  public void removeSimObject(SimObject simObject) {
    // Note: this method can't be synchronized since we need to
    // release the lock on the SimState before adding an event to the
    // event bus
    synchronized (this) {
      simObjects.remove(simObject);
      if (simObject instanceof MoteSimObject) {
        MoteSimObject mote = (MoteSimObject)simObject;
        moteObjects.remove(new Integer(mote.getID()));
      }
    }
    
    eventBus.addEvent(
      new SimObjectEvent(SimObjectEvent.OBJECT_REMOVED, simObject));
  }

  synchronized public void removeAllObjects() {
    simObjects = new HashSet();
    moteObjects = new Hashtable();
  }

  synchronized public SimObject getSimObjectAtPoint(double x, double y) {
    Iterator it = simObjects.iterator();
    while (it.hasNext()) {
      SimObject s = (SimObject)it.next();
      if (s.pointInSimObjectSpace(x, y))
	return s;
    }
    return null;
  }

  synchronized public MoteSimObject getMoteSimObject (int moteID) {
    return (MoteSimObject)moteObjects.get(new Integer(moteID));
  }
}
