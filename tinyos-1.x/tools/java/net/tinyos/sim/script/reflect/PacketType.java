// $Id: PacketType.java,v 1.5 2004/10/22 18:46:44 selfreference Exp $

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
import net.tinyos.message.TOSMsg;
import net.tinyos.sim.SimDebug;
import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.MoteSimObject;
import net.tinyos.sim.plugins.PacketLogEntry;
import net.tinyos.sim.script.ScriptInterpreter;


import java.util.*;
import org.python.core.*;

public class PacketType extends PyDictionary {
  protected ScriptInterpreter interp;
  protected SimDriver driver;
  private Message message;
  private String name;
  private int amID;
  private static SimDebug debug = SimDebug.get("packetlog");
  
  public PacketType(ScriptInterpreter interp, SimDriver driver, Message msg) {
    super();
    this.interp = interp;
    this.driver = driver;
    this.message = msg;

    String name = msg.getClass().getName();
    name = name.substring(name.lastIndexOf('.') + 1);
    name = name + "s";
    this.name = name;

    this.amID = msg.amType();
    debug.out.println("Adding " + name + " for type " + amID);
  }

  public PyObject __finditem__(PyObject key) {
    if (!(key instanceof PyInteger)) {
      return null;
    }
    else {
      PyInteger pi = (PyInteger)key;
      int mote = pi.getValue();
      Vector v = driver.getPacketLogger().getPackets(mote);
      v = amFilter(v);
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

      motePackets = amFilter(motePackets);
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
      v = amFilter(v);
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
      v = amFilter(v);
      Vector v2 = new Vector();
      for (int i = 0; i < v.size(); i++) {
        v2.addElement(new PyJavaInstance(v.elementAt(i)));
      }
      PyList plist = new PyList(v2);
      table.put(pi, plist);
    }
    return new PyDictionary(table);
  }

  public PyDictionary downCast() {
    Hashtable table = new Hashtable();
    Enumeration motes = driver.getPacketLogger().getTransmittingMotes();
    while (motes.hasMoreElements()) {
      Integer iVal = (Integer)motes.nextElement(); 
      PyInteger pi = new PyInteger(iVal.intValue());

      Vector v = (Vector)driver.getPacketLogger().getPackets(iVal.intValue());
      v = amFilter(v);
      Vector v2 = new Vector();
      for (int i = 0; i < v.size(); i++) {
	PacketLogEntry e = (PacketLogEntry)v.elementAt(i);
	Message newMsg = (Message)message.clone();
	TOSMsg oldMsg = (TOSMsg)e.getMessage();

	int offset = oldMsg.offset_data(0);
	int length = (oldMsg.totalSize_data() > newMsg.dataGet().length)?newMsg.dataGet().length : oldMsg.totalSize_data();
	newMsg.dataSet(oldMsg.dataGet(), offset, 0, length);
	e = new PacketLogEntry(e.getTime(), e.getMoteID(), newMsg);
	v2.addElement(new PyJavaInstance(e));
      }
      PyList plist = new PyList(v2);
      table.put(pi, plist);
    }
    return new PyDictionary(table);

  }

  
  private Vector amFilter(Vector v) {
    Vector rval = new Vector();
    for (int i = 0; i < v.size(); i++) {
      PacketLogEntry entry = (PacketLogEntry)v.elementAt(i);
      TOSMsg msg = (TOSMsg)entry.getMessage();
      if (msg.get_type() == amID) {
	rval.addElement(entry);
      }
    }
    return rval;
  }
  
}
  
