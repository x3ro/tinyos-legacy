// $Id: SimObject.java,v 1.4 2003/11/21 01:32:45 mikedemmer Exp $

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
 * Authors:	Nelson Lee
 * Date:        December 09, 2002
 * Desc:        Template object for AdvSim
 *
 */

/**
 * @author Nelson Lee
 */

package net.tinyos.sim;
import net.tinyos.sim.event.*;
import java.awt.*;
import java.awt.event.*;
import java.util.Hashtable;

public abstract class SimObject implements SimConst {

  protected Hashtable attrs = new Hashtable();
  protected SimEventBus eventBus;
  protected SimState simState;

  protected boolean visible = true;
  protected int objectSize;

  private boolean selected = false;

  public SimObject(SimDriver driver, int objectSize) {
    this.objectSize = objectSize;
    this.eventBus = driver.getEventBus();
    this.simState = driver.getSimState();
  }

  public void addAttribute(Attribute a) {
    synchronized (simState) {
      attrs.put(a.getClass().getName(), a);
    }
  }
  public void addAttribute(String name, Attribute a) {
    synchronized (simState) {
      attrs.put(name, a);
    }
  }

  public Attribute getAttribute(String name) {
    synchronized (simState) {
      return (Attribute)attrs.get(name);
    }
  }

  public void removeAttribute(String name) {
    synchronized (simState) {
      attrs.remove(name);
    }
  }

  public boolean isSelected() {
    synchronized (simState) {
      return selected;
    }
  }

  public void setSelected() {
    synchronized (simState) {
      selected = true;
    }
  }

  public void setUnselected() {
    synchronized (simState) {
      selected = false;
    }
  }	

  public boolean isVisible() {
    synchronized (simState) {
      return visible;
    }
  }

  public void setVisible() {
    synchronized (simState) {
      visible = true;
    }
  }

  public void setNotVisible() {
    synchronized (simState) {
      visible = false;
    }    
  }

  public int getObjectSize() {
    // Kind of overkill with the synchronization, b/c there are no functions
    // for changing objectSize
    synchronized (simState) {
      return objectSize;
    }
  }

  // called by MouseHandler to get the appropriate popup menu
  public abstract SimObjectPopupMenu getPopupMenu();

  // function used by MouseHandler to determine if an object has been
  // selected by clicking
  public abstract boolean pointInSimObjectSpace(double simX, double simY);

  // function used by MouseHandler when object is selected and has
  // been dragged a certain distance (dx, dy)
  public abstract void moveSimObject(double dx, double dy);

  // function exposed to move an object to the given position
  public abstract void moveSimObjectTo(double x, double y);

  // this method is used by MouseHandler to determine if someone's
  // been selected by pressing and dragging
  public abstract boolean simObjectInQuad(double x1, double y1,
                                          double x2, double y2);

  public abstract void addCoordinateChangedEvent();
}
