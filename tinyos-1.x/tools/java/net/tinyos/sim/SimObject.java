// $Id: SimObject.java,v 1.6 2004/04/14 18:27:53 mikedemmer Exp $

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

public class SimObject implements SimConst {

  public final Color BASIC_COLOR = Color.black;
  public final Color SELECTED_COLOR = new Color(150, 150, 255);
  public final Color BASIC_COLOR_OFF = Color.lightGray;
  public final Color SELECTED_COLOR_OFF = SELECTED_COLOR;

  protected Hashtable attrs = new Hashtable();
  protected SimEventBus eventBus;
  protected SimState simState;

  protected boolean visible = true;
  protected int objectSize;
  protected CoordinateAttribute coord;

  private boolean selected = false;

  public SimObject(SimDriver driver, int objectSize, double x, double y) {
    this.objectSize = objectSize;
    this.eventBus = driver.getEventBus();
    this.simState = driver.getSimState();
    
    coord = new CoordinateAttribute(x, y);
    addAttribute(coord);

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

  public CoordinateAttribute getCoordinate() {
    synchronized (simState) {
      return coord;
    }
  }

  // generic objects are represented by just a square
  public void draw(Graphics graphics, CoordinateTransformer cT) {
    int x = (int)cT.simXToGUIX(coord.getX());
    int y = (int)cT.simYToGUIY(coord.getY());
    
    // Figure out coordinates and the color
    int size = (int)cT.simXToGUIX(objectSize);
    int xl = x-(size/2);
    int yl = y-(size/2);
    
    if (isSelected()) {
      graphics.setColor(SELECTED_COLOR);
    } else {
      graphics.setColor(BASIC_COLOR);
    }
    
    graphics.fillRect(xl, yl, size, size);
  }
  
  public double getDistance(double x, double y) {
    double moteX = coord.getX();
    double moteY = coord.getY();
    double dx = x - moteX;
    double dy = y - moteY;
    return Math.sqrt((dx * dx) + (dy * dy));
  }

  public double getDistance(SimObject other) {
    synchronized (simState) {
      CoordinateAttribute otherCoord = other.getCoordinate();
      return getDistance(otherCoord.getX(), otherCoord.getY());
    }
  }
  
  public boolean pointInSimObjectSpace(double x, double y) {
    synchronized (simState) {
      int distance = (int)getDistance(x, y);
      if (distance <= getObjectSize()) {
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
    synchronized(eventBus) {
      synchronized (simState) {	
        coord.setX(dx + coord.getX());
        coord.setY(dy + coord.getY());
        boundsCheck();
        addAttributeChangedEvent(coord);
      }
    }
  }

  public void moveSimObjectNoEvent(double dx, double dy) {
    synchronized(eventBus) {
      synchronized (simState) {	
        coord.setX(dx + coord.getX());
        coord.setY(dy + coord.getY());
        boundsCheck();
      }
    }
  }

  public void moveSimObjectTo(double x, double y) {
    synchronized(eventBus) {
      synchronized (simState) {	
        coord.setX(x);
        coord.setY(y);
        boundsCheck();
        addAttributeChangedEvent(coord);
      }
    }
  }

  public void addAttributeChangedEvent(Attribute attr) {
    synchronized(eventBus) {
      synchronized (simState) {
	eventBus.addEvent(new AttributeEvent(ATTRIBUTE_CHANGED, this, attr));
      }
    }
  }

  // called by MouseHandler to get the appropriate popup menu
  public SimObjectPopupMenu getPopupMenu() {
    return null;
  }
}
