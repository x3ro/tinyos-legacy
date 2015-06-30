// $Id: MoteSimObject.java,v 1.7 2003/12/05 07:44:58 mikedemmer Exp $

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
 * Authors:	Phil Levis, Nelson Lee
 * Date:        December 11, 2002
 * Desc:        mote object for AdvSim
 *
 */

/**
 * @author Phil Levis
 * @author Nelson Lee
 */

package net.tinyos.sim;
import net.tinyos.sim.event.*;
import java.util.*;

public class MoteSimObject extends SimObject {
  private int id;
  private MoteCoordinateAttribute coord;
  private MotePowerAttribute power;

  // A single popup menu can be assigned to all mote sim objects since
  // the mouse handler will set the target of the popup before
  // activating it.
  static private SimObjectPopupMenu motePopup;
  
  static public void setPopupMenu(SimObjectPopupMenu popup) {
    motePopup = popup;
  }

  public SimObjectPopupMenu getPopupMenu() {
    return motePopup;
  }
  
  public MoteSimObject(SimDriver driver, double x, double y, int id) {
    super(driver, MOTE_OBJECT_SIZE);
    
    this.id = id;
    
    coord = new MoteCoordinateAttribute(x, y);
    addAttribute(coord);

    power = new MotePowerAttribute(true);
    addAttribute(power);
    
    addAttribute(new MoteIDAttribute(id));
    addAttribute(new MoteLedsAttribute());
  }

  public int getID() {
    return id;
  }

  public MoteCoordinateAttribute getCoordinate() {
    return coord;
  }
  
  public boolean getPower() {
    return power.getPower();
  }
  
  public void setPower(boolean onoff) {
    power.setPower(onoff);
  }

  public double getDistance(double x, double y) {
    double moteX = coord.getX();
    double moteY = coord.getY();
    double dx = x - moteX;
    double dy = y - moteY;
    return Math.sqrt((dx * dx) + (dy * dy));
  }

  public double getDistance(MoteSimObject other) {
    synchronized (simState) {
      MoteCoordinateAttribute otherCoord = other.getCoordinate();
      return getDistance(otherCoord.getX(), otherCoord.getY());
    }
  }
  
  public boolean pointInSimObjectSpace(double x, double y) {
    synchronized (simState) {
      int distance = (int)getDistance(x, y);
      if (distance <= super.getObjectSize()) {
	return true;
      }
      return false;
    }
  }

  public boolean simObjectInQuad(double x1, double y1, double x2, double y2) {
    synchronized (simState) {
      double sMinX = coord.getX();
      double sMaxX = sMinX + getObjectSize();
      double sMaxY = coord.getY();
      double sMinY = sMaxY - getObjectSize();
      if ((((x1 <= sMinX) && (sMinX <= x2)) ||
           ((x1 <= sMaxX) && (sMaxX <= x2))) &&

	  (((y1 <= sMinY) && (sMinY <= y2)) ||
           ((y1 <= sMaxY) && (sMaxY <= y2)))) {
	return true;
      }
      return false;
    }
  }

  public void boundsCheck() {
    if (coord.getX() < 0) coord.setX(0);
    if (coord.getY() < 0) coord.setY(0);
    if (coord.getX() > MOTE_SCALE_WIDTH) coord.setX(MOTE_SCALE_WIDTH);
    if (coord.getY() > MOTE_SCALE_WIDTH) coord.setY(MOTE_SCALE_WIDTH);
  }
  
  public void moveSimObject(double dx, double dy) {
    // XXX/demmer deadlock question??
    synchronized(eventBus) {
      synchronized (simState) {	
        coord.setX(dx + coord.getX());
        coord.setY(dy + coord.getY());
        boundsCheck();
        //XXX/demmer addCoordinateChangedEvent();
      }
    }
  }

  public void moveSimObjectTo(double x, double y) {
    synchronized(eventBus) {
      synchronized (simState) {	
        coord.setX(x);
        coord.setY(y);
        boundsCheck();
        addCoordinateChangedEvent();
      }
    }
  }

  public void addCoordinateChangedEvent() {
    synchronized(eventBus) {
      synchronized (simState) {
	eventBus.addEvent(new AttributeEvent(ATTRIBUTE_CHANGED, this, coord));
      }
    }
  }

  public String toString() {
    return "[Mote "+id+"]";
  }
}


