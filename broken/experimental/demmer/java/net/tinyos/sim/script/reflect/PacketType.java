
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

// The motes variable is special since it allows for python style
// access to the motes array
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
    
    interp.set(name, this);
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
    Enumeration e = driver.getPacketLogger().getTransmittingMotes();
    Vector v = new Vector();
    while (e.hasMoreElements()) {
      Integer iVal = (Integer)e.nextElement();
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
    Enumeration e = driver.getPacketLogger().getTransmittingMotes();
    Vector v = new Vector();
    while (e.hasMoreElements()) {
      Integer i = (Integer)e.nextElement();
      v.addElement(new PyInteger(i.intValue()));
    }
    return new PyList(v);
  }
	
  protected PyObject getslice(PyObject start, PyObject stop, PyObject step) {
    throw Py.TypeError("can't apply slice to packets?");
  }

  public PyDictionary copy() {
    Hashtable table = new Hashtable();
    Enumeration enum = driver.getPacketLogger().getTransmittingMotes();
    while (enum.hasMoreElements()) {
      Integer iVal = (Integer)enum.nextElement(); 
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
    Enumeration enum = driver.getPacketLogger().getTransmittingMotes();
    while (enum.hasMoreElements()) {
      Integer iVal = (Integer)enum.nextElement(); 
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
  
