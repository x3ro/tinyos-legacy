
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.MoteSimObject;
import net.tinyos.sim.script.ScriptInterpreter;

import java.util.*;
import org.python.core.*;

// The motes variable is special since it allows for python style
// access to the motes array
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
  
