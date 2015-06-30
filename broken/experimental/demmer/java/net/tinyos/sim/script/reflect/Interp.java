
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.script.ScriptInterpreter;
import org.python.core.*;

public class Interp extends SimReflect {
  public Interp(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    interp.set("interp", this);
  }

  public int addEventHandler(PyFunction callback, PyJavaClass eventclass)
    throws ClassNotFoundException {

    Class javaclass = null;
    if (eventclass != null) {
      javaclass = Class.forName(eventclass.__name__);
    }
    
    return interp.addEventHandler(callback, javaclass);
  }
  
  public int addEventHandler(PyFunction callback) {
    return interp.addEventHandler(callback, null);
  }

  public void removeEventHandler(int id) {
    interp.removeEventHandler(id);
  }
}
