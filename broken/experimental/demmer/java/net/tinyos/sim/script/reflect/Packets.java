
package net.tinyos.sim.script.reflect;

import net.tinyos.message.Message;
import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.MoteSimObject;
import net.tinyos.sim.script.ScriptInterpreter;

import java.util.*;
import org.python.core.*;

// The motes variable is special since it allows for python style
// access to the motes array
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
    Enumeration e = driver.getPacketLogger().getTransmittingMotes();
    Vector v = new Vector();
    while (e.hasMoreElements()) {
      Integer iVal = (Integer)e.nextElement();
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
      Vector v2 = new Vector();
      for (int i = 0; i < v.size(); i++) {
        v2.addElement(new PyJavaInstance(v.elementAt(i)));
      }
      PyList plist = new PyList(v2);
      table.put(pi, plist);
    }
    return new PyDictionary(table);
  }

  public void addPacketType(Message message) {
    PacketType type = new PacketType(interp, driver, message);
  }
}
  
