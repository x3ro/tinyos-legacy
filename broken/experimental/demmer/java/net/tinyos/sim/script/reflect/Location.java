
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.MoteSimObject;
import net.tinyos.sim.MoteCoordinateAttribute;
import net.tinyos.sim.script.ScriptInterpreter;
import net.tinyos.sim.plugins.RadioModelPlugin;

import org.python.core.*;

public class Location extends SimReflect {
  SimDriver driver;
  
  public Location(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    this.driver = driver;
  }
  
  public MoteCoordinateAttribute getCoordinates(int moteID) {
    SimState state = driver.getSimState();
    MoteSimObject obj = state.getMoteSimObject(moteID);
    return obj.getCoordinate();
  }

  public void setCoordinates(int moteID, double x, double y) {
    SimState state = driver.getSimState();
    MoteSimObject obj = state.getMoteSimObject(moteID);
    obj.getCoordinate().setX(x);
    obj.getCoordinate().setY(y);
  }
}
  
