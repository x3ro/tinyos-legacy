
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.script.ScriptInterpreter;

public abstract class SimReflect {
  protected ScriptInterpreter interp;
  protected SimDriver driver;

  public SimReflect(ScriptInterpreter interp, SimDriver driver) {
    this.interp = interp;
    this.driver = driver;
  }
}
