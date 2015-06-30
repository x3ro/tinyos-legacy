
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimConst;
import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimDebug;
import net.tinyos.sim.script.ScriptInterpreter;

import java.util.*;

public class SimBindings {
  protected SimDebug dbg = SimDebug.get("script");

  public static Sim sim;
  public static Interp interp;
  public static Radio radio;
  public static Motes motes;
  public static Packets packets;
  public static Commands comm;
  public static Location location;
  
  public SimBindings(SimDriver driver, ScriptInterpreter interp) {
    // create the reflected objects
    this.sim = new Sim(interp, driver);
    this.interp = new Interp(interp, driver);
    this.radio = new Radio(interp, driver);
    this.motes = new Motes(interp, driver);
    this.packets = new Packets(interp, driver);
    this.comm = new Commands(interp, driver);
    this.location = new Location(interp, driver);
    
    // set up the sys.path load path

    String builtinPath = driver.getClass().getResource("pyscripts").getPath();
    
    String pathsep = System.getProperty("path.separator");
    if (pathsep == null)
      pathsep = ":";

    String scriptPath = driver.getScriptPath();

    if (scriptPath == null) {
      scriptPath = builtinPath;
    } else {
      scriptPath = scriptPath + pathsep + builtinPath;
    }
    
    StringBuffer path = new StringBuffer();
    path.append("[");
    StringTokenizer st = new StringTokenizer(scriptPath, pathsep);
    boolean first = true;
    while (st.hasMoreTokens()) {
      if (!first) {
        path.append(", ");
      }
      path.append("'"+st.nextToken()+"'");
      first = false;
    }
    path.append("]");

    dbg.out.println("script: setting sys.path to "+path);
    interp.exec("import sys");
    interp.exec("sys.path = " + path);

    // load the simcore module to do the reflection
    interp.exec("import simcore");
    interp.exec("from simcore import *");
  }

}
