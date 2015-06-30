// $Id: Packets.java,v 1.4 2004/10/21 22:26:37 selfreference Exp $

/*									tab:2
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
 * Authors:	Philip Levis
 * Date:        January 9, 2004
 * Desc:        
 *
 */

package net.tinyos.sim.script.reflect;

import net.tinyos.message.Message;
import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.MoteSimObject;
import net.tinyos.sim.script.ScriptInterpreter;

import java.util.*;
import org.python.core.*;

/**
 * The Packets class is a special reflected class to provide access to
 * the simulator's packet transmission history. <p>
 *
 * This class implements a python dictionary, and as such, should be
 * accessed using the python builtin operators. The index into the
 * dictionary is the transmitting mote id. The contents of each slice
 * is a list of packet information that was sent by that mote.<p>
 *
 * The class is bound into the simcore module as the <i>packets</i>
 * global instance.
 */
public class Packets extends PyDictionary {
  protected ScriptInterpreter interp;
  protected SimDriver driver;

  public Packets(ScriptInterpreter interp, SimDriver driver) {
    super();
    this.interp = interp;
    this.driver = driver;
  }

  public PyObject __finditem__(PyObject key) {
    if (!(key instanceof PyInteger)) {
      return null;
    }
    else {
      PyInteger pi = (PyInteger)key;
      int mote = pi.getValue();
      Vector v = driver.getPacketLogger().getPackets(mote);
      Vector v2 = new Vector();
      for (int i = 0; i < v.size(); i++) {
        v2.addElement(new PyJavaInstance(v.elementAt(i)));
      }
      
      return new PyList(v2);
    }
  }

  public void __setitem__(int index, PyObject value) {
    throw Py.TypeError("Packet dictionary is immutable");
  }
  public void __setitem__(PyObject index, PyObject value) {
    throw Py.TypeError("Packet dictionary is immutable");
  }
  public void __delitem__(PyObject index) {
    throw Py.TypeError("Packet dictionary is immutable");
  }
  public int __len__() {
    return driver.getPacketLogger().numTransmitters();
  }

  public PyList items() {
    Enumeration motes = driver.getPacketLogger().getTransmittingMotes();
    Vector v = new Vector();
    while (motes.hasMoreElements()) {
      Integer iVal = (Integer)motes.nextElement();
      Vector motePackets = driver.getPacketLogger().getPackets(iVal.intValue());
      Vector pyVector = new Vector();

      for (int i = 0; i < motePackets.size(); i++) {
        pyVector.addElement(new PyJavaInstance(motePackets.elementAt(i)));
      }
      PyList pList = new PyList(pyVector);
			
      PyObject objs[] = new PyObject[2];
      objs[0] = new PyInteger(iVal.intValue());
      objs[1] = pList;

      PyTuple tuple = new PyTuple(objs);
      v.addElement(tuple);
    }
    return new PyList(v);
  }

  public String toString() {
    Enumeration keys = driver.getPacketLogger().getTransmittingMotes();
    StringBuffer buf = new StringBuffer("{");
    while (keys.hasMoreElements()) {
      Integer iVal = (Integer)keys.nextElement();
      buf.append(iVal + ": ");
      Vector v = driver.getPacketLogger().getPackets(iVal.intValue());
      for (int i = 0; i < v.size(); i++) {
        buf.append(v.elementAt(i));
        buf.append(", ");
      }
      buf.append(", ");
    }
    buf.append("}");
    return buf.toString();
  }
	
  public PyList keys() {
    Enumeration motes = driver.getPacketLogger().getTransmittingMotes();
    Vector v = new Vector();
    while (motes.hasMoreElements()) {
      Integer i = (Integer)motes.nextElement();
      v.addElement(new PyInteger(i.intValue()));
    }
    return new PyList(v);
  }
	
  protected PyObject getslice(PyObject start, PyObject stop, PyObject step) {
    throw Py.TypeError("can't apply slice to packets?");
  }

  public PyDictionary copy() {
    Hashtable table = new Hashtable();
    Enumeration motes = driver.getPacketLogger().getTransmittingMotes();
    while (motes.hasMoreElements()) {
      Integer iVal = (Integer)motes.nextElement(); 
      PyInteger pi = new PyInteger(iVal.intValue());

      Vector v = (Vector)driver.getPacketLogger().getPackets(iVal.intValue());
      Vector v2 = new Vector();
      for (int i = 0; i < v.size(); i++) {
        v2.addElement(new PyJavaInstance(v.elementAt(i)));
      }
      PyList plist = new PyList(v2);
      table.put(pi, plist);
    }
    return new PyDictionary(table);
  }

  /**
   * Create a new dictionary for packets of a particular message type.
   * Note -- in previous versions this would automatically bind a
   * variable into the interpreter for the new dictionary using an
   * internal Jython API. Instead, this method now returns the new
   * dictionary that the caller should store a reference to.
   *
   * @return the new dictionary
   */
  public PacketType addPacketType(Message message) {
    return new PacketType(interp, driver, message);
  }
}
  
