// $Id: Mote.java,v 1.7 2004/04/14 18:30:31 mikedemmer Exp $

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
 * Desc:        Reflected Mote object
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;
import net.tinyos.sim.script.ScriptInterpreter;

import java.io.*;

import org.python.core.*;

/**
 * The Mote class provides access to the simulated mote objects.<p>
 *
 * Each mote that is simulated has a corresponding simulator object.
 * These simulator objects are bound into the simcore module as the
 * <i>motes</i> list. Hence for example, <tt>motes[3].turnOn()</tt>
 * will turn on mote number 3.
 *
 * Generic methods that are available on all simulator objects are
 * described in {@link SimObject}.
 *
 */
public class Mote extends net.tinyos.sim.script.reflect.SimObject {
  private MoteVariables moteVars;
  private MoteSimObject mote;
  
  public Mote(ScriptInterpreter interp, SimDriver driver, MoteSimObject mote) {
    super(interp, driver, mote);
    moteVars = driver.getVariables();
    this.mote = mote;
  }

  /**
   * Return the mote's ID.
   */
  public int getID() {
    return mote.getID();
  }

  /**
   * Return a string representing the mote's state (i.e. power,
   * position).
   */
  public String toString() {
    String msg = "Mote " + getID() + ": ";
    msg += "[power=" + (isOn()? "on":"off") + "] ";
    msg += "[state=active] ";
    msg += "[pos=" + (int)getXCoord() + "," + (int)getYCoord() + "]";
    return msg;
  }

  /**
   * Turn the mote on.
   */
  public void turnOn() throws IOException {
    boolean wasOn = mote.getPower();
    if (wasOn) return;
    
    mote.setPower(true);
    driver.getSimComm().sendCommand(
      new TurnOnMoteCommand((short)mote.getID(), 0L));
    driver.refreshMotePanel();
  }

  /**
   * Turn the mote off.
   */
  public void turnOff() throws IOException {
    boolean wasOn = mote.getPower();
    if (! wasOn) return;
    
    mote.setPower(false);
    driver.getSimComm().sendCommand(
      new TurnOffMoteCommand((short)mote.getID(), 0L));
    driver.refreshMotePanel();
  }

  /**
   * Return whether or not the mote is on.
   */
  public boolean isOn() {
    return mote.getPower();
  }

  /**
   * Set a label in the TinyViz GUI for the given mote at a constant
   * offset to the mote's position. Has no effect if the gui is not
   * enabled.
   *
   * @param label	the string to display
   * @param xoff	x offset of the label
   * @param yoff	y offset of the label
   */
  public void setLabel(String label, int xoff, int yoff) {
    mote.addAttribute(new MoteLabelAttribute(label, xoff, yoff));
    driver.refreshMotePanel();
  }

  /**
   * Resolve and return the value of a mote frame variable, specifying
   * the length and the offset, and return it as a byte array.
   *
   * @param var		variable name to resolve and return
   */   
  public byte[] getBytes(String var, long len, long offset) throws IOException {
    return moteVars.getBytes((short)mote.getID(), var, len, offset);
  }

  /**
   * Resolve and return the value of a mote frame variable, and return
   * it as a byte array.
   *
   * @param var		variable name to resolve and return
   */   
  public byte[] getBytes(String var) throws IOException {
    return moteVars.getBytes((short)mote.getID(), var);
  }

  /**
   * Resolve and return the value of a mote frame variable, and return
   * it as a long.
   *
   * @param var		variable name to resolve and return
   */   
  public long getLong(String var) throws IOException {
    return moteVars.getLong((short)mote.getID(), var);
  }

  /**
   * Resolve and return the value of a mote frame variable, and return
   * it as an int.
   *
   * @param var		variable name to resolve and return
   */   
  public int getInt(String var) throws IOException {
    return (int)moteVars.getLong((short)mote.getID(), var);
  }

  /**
   * Resolve and return the value of a mote frame variable, and return
   * it as a short.
   *
   * @param var		variable name to resolve and return
   */   
  public short getShort(String var) throws IOException {
    return (short)moteVars.getShort((short)mote.getID(), var);
  }

  /**
   * Resolve and return the value of a mote frame variable, and return
   * it as a byte.
   *
   * @param var		variable name to resolve and return
   */   
  public byte getByte(String var) throws IOException {
    byte b[] = getBytes(var);
    if (b.length > 0) {
      return b[0];
    }
    else {
       throw Py.IndexError(var + " is not a valid variable (it has length 0)");
    }
  }
}
  
