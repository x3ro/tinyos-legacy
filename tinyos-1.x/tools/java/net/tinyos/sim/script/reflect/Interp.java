// $Id: Interp.java,v 1.2 2004/01/31 00:51:48 mikedemmer Exp $

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
 * Desc:        Reflected interpreter object
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.script.ScriptInterpreter;
import org.python.core.*;

import java.io.IOException;

/**
 * The Interp class controls operations on the python interpreter,
 * specifically the management of events.<p>
 *
 * The class is bound into the simcore module as the <i>interp</i>
 * global instance.
 */
public class Interp extends SimReflect {
  public Interp(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    interp.set("interp", this);
  }

  /**
   * Registers a given python function as a callback. If eventClass is
   * non-null, then only events of that particular subclass of
   * net.tinyos.sim.event will call the callback. If null, the
   * callback is called for all events.
   *
   * @param callback	python function to call on matching events
   * @param eventClass	event class match
   * @return 		unique id for the event handler
   */
  public int addEventHandler(PyFunction callback, PyJavaClass eventclass)
    throws ClassNotFoundException {

    Class javaclass = null;
    if (eventclass != null) {
      javaclass = Class.forName(eventclass.__name__);
    }
    
    return interp.addEventHandler(callback, javaclass);
  }
  
  
  /**
   * Equivalent to addEventHandler(callback, null);
   */
  public int addEventHandler(PyFunction callback) {
    return interp.addEventHandler(callback, null);
  }

  /**
   * Removes the previously registered handler.
   *
   * @param id		event handler id to remove
   */
  public void removeEventHandler(int id) {
    interp.removeEventHandler(id);
  }

  /**
   * Get a unique interrupt ID.
   */
  public int getInterruptID() {
    return driver.getSimComm().getInterruptID();
  }

  /**
   * Schedule an interrupt event.
   *
   * @param time	simulator time when to do the operation
   * @param interruptID	id code for the interrupt event
   */
  public void interruptInFuture(long time, int interruptID)
    throws IOException {
    driver.getSimCommands().interruptInFuture(time, interruptID);
  }
}
