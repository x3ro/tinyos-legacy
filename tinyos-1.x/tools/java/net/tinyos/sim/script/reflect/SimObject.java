// $Id: SimObject.java,v 1.2 2004/04/14 18:30:32 mikedemmer Exp $

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
 * Date:        March 4, 2004
 * Desc:        Reflected SimObject object
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.*;
import net.tinyos.sim.script.*;
import java.io.*;

import org.python.core.*;

/**
 * The SimObject class provides internal access to simulator objects
 * that are not motes.<p>
 *
 * New objects are obtained by calling the newSimObject() method on
 * the {@link Sim} class.
 *
 */
public class SimObject extends SimReflect {

  private net.tinyos.sim.SimObject simObject;
  protected SimState simState;

  /**
   * This is an internal constructor that's called by the Mote
   * reflected object.
   */
  protected SimObject(ScriptInterpreter interp, SimDriver driver, MoteSimObject mote) {
    super(interp, driver);
    simState = driver.getSimState();
    simObject = mote;
  }

  /**
   * Constructor that's called by sim.newSimObject()
   */
  public SimObject(ScriptInterpreter interp, SimDriver driver,
                   int size, double x, double y) {
    super(interp, driver);
    simState = driver.getSimState();
    simObject = new net.tinyos.sim.SimObject(driver, size, x, y); // size?
    driver.getSimState().addSimObject(simObject);
  }

  /**
   * Add the given attribute to the object.
   *
   * @param name	the name of the attribute
   * @param attrib	the attribute
   */
  public void addAttribute(String name, Attribute attrib) {
    simObject.addAttribute(name, attrib);
    simObject.addAttributeChangedEvent(attrib);
  }

  /**
   * Return the attribute with the given name.
   *
   * @param name	the name of the attribute
   * @return 		the attribute
   */
  public Attribute getAttribute(String name) {
    return simObject.getAttribute(name);
  }

  /**
   * Remove the given attribute from the object.
   *
   * @param name	the name of the attribute
   */
  public void removeAttribute(String name) {
    simObject.removeAttribute(name);
  }

  /**
   * Register an attribute changed event for the given attribute.
   *
   * @param attrib	the attribute
   */
  public void addAttributeChangedEvent(Attribute attrib) {
    simObject.addAttributeChangedEvent(attrib);
  }

  /**
   * Return the object's coordinates as a string "(x, y)".
   */
  public String getCoord() {
    return "("+getXCoord()+", "+getYCoord()+")";
  }
  
  /**
   * Return the object's X coordinate.
   */
  public double getXCoord() {
    return simObject.getCoordinate().getX();
  }

  /**
   * Return the object's Y coordinate.
   */
  public double getYCoord() {
    return simObject.getCoordinate().getY();
  }

  /**
   * Return the distance from this mote to another.
   *
   * @param other	the other Mote instance
   */
  public double getDistance(SimObject other) {
    return simObject.getDistance(other.simObject);
  }
  
  /**
   * Return the distance from this mote to another.
   *
   * @param moteID	the other Mote id
   */
  public double getDistance(int moteID) {
    MoteSimObject other = simState.getMoteSimObject(moteID);
    if (other == null) {
      throw Py.IndexError("mote index out of bounds " + moteID);
    }
    return simObject.getDistance(other);
  }
  
  /**
   * Return the distance from this mote to the given coordinates
   *
   * @param x		the X coordinate of the target point
   * @param y		the Y coordinate of the target point
   */
  public double getDistance(double x, double y) {
    return simObject.getDistance(x, y);
  }

  /**
   * Move the mote in virtual space by a given amount.
   *
   * @param dx		distance to move in the X direction
   * @param dy		distance to move in the Y direction
   */
  public void move(double dx, double dy) {
    simObject.moveSimObject(dx, dy);
  }

  /**
   * Move the mote in virtual space to the given location
   *
   * @param x		new X coordinate
   * @param y		new Y coordinate
   */
  public void moveTo(double x, double y) {
    simObject.moveSimObjectTo(x, y);
  }

  /**
   * Move the mote in virtual space to the given location. Analogous
   * to moveTo().
   *
   * @param x		new X coordinate
   * @param y		new Y coordinate
   */
  public void setCoord(double x, double y) {
    simObject.moveSimObjectTo(x, y);
  }

  /**
   * Determine if the object is selected.
   */
  public boolean isSelected() {
    return simObject.isSelected();
  }

  /**
   * Add the object to the selected set.
   */
  public void setSelected() {
    simObject.setSelected();
  }

  /**
   * Remove the object from the selected set.
   */
  public void setUnselected() {
    simObject.setUnselected();
  }

}
  
