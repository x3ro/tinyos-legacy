// $Id: Motes.java,v 1.2 2004/01/31 00:51:48 mikedemmer Exp $

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
 * Desc:        Reflected motes array
 *
 */

/**
 * @author Michael Demmer
 */

package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.MoteSimObject;
import net.tinyos.sim.script.ScriptInterpreter;

import java.util.*;
import org.python.core.*;

/**
 * The Motes class is a special reflected class to provide access to
 * the mote objects.
 *
 * This class implements a python sequence, and as such, should be
 * accessed using the python builtin operators. The index into the
 * dictionary is the mote id. The contents of each element is the Mote
 * object.<p>
 *
 * The class is bound into the simcore module as the <i>motes</i>
 * global instance.
 */
public class Motes extends PySequence {
  protected ScriptInterpreter interp;
  protected SimDriver driver;
  protected SimState state;
  protected Hashtable motes;
  
  public Motes(ScriptInterpreter interp, SimDriver driver) {
    this.interp = interp;
    this.driver = driver;
    this.state = driver.getSimState();
    this.motes = new Hashtable();
  }
  
  public int __len__() {
    int len = state.numMoteSimObjects();
    return len;
  }
  
  protected PyObject get(int index) {
    PyObject o = (PyObject)motes.get(new Integer(index));
    if (o == null) {
      MoteSimObject so = state.getMoteSimObject(index);
      if (so == null) {
        // XXX shouldn't happen
        return null; 
      }

      o = new PyJavaInstance(new Mote(interp, driver, so));
      motes.put(new Integer(index), o);
    }

    return o;
  }

  protected PyObject getslice(int start, int stop, int step) {
    throw Py.TypeError("can't apply slice to motes");
  }

  protected PyObject repeat(int count) {
    throw Py.TypeError("can't apply '*' to motes");
  }

  public String toString() {
    String msg = "[";
    int num = __len__();

    for (int i = 0; i < num; i++) {
      MoteSimObject so = state.getMoteSimObject(i);
      Mote mo = new Mote(interp, driver, so);
      msg += mo + ", ";
    }
    msg += "]";
    return msg;
  }
}
  
