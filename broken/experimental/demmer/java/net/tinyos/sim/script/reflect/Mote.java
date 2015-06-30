
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;
import net.tinyos.sim.script.ScriptInterpreter;

import java.io.*;

import org.python.core.*;

public class Mote extends SimReflect {
  private SimComm simComm;
  private SimState simState;
  private MoteVariables moteVars;
  private MoteSimObject mote;
  
  public Mote(ScriptInterpreter interp, SimDriver driver,
               MoteSimObject mote) {
    super(interp, driver);
    simComm = driver.getSimComm();
    simState = driver.getSimState();
    moteVars = driver.getVariables();
    this.mote = mote;
  }

  public int getID() {
    return mote.getID();
  }

  public String getCoord() {
    return "("+getXCoord()+", "+getYCoord()+")";
  }
  
  public double getXCoord() {
    return mote.getCoordinate().getX();
  }

  public double getYCoord() {
    return mote.getCoordinate().getY();
  }

  public String toString() {
    String msg = "Mote " + getID() + ": ";
    msg += "[power=" + (isOn()? "on":"off") + "] ";
    msg += "[state=active] ";
    msg += "[pos=" + (int)getXCoord() + "," + (int)getYCoord() + "]";
    return msg;
  }
  
  public double getDistance(int moteID) {
    MoteSimObject other = simState.getMoteSimObject(moteID);
    if (other == null) {
      throw Py.IndexError("mote index out of bounds " + moteID);
    }
    return mote.getDistance(other);
  }
  
  public double getDistance(double x, double y) {
    return mote.getDistance(x, y);
  }

  public void turnOn() throws IOException {
    boolean wasOn = mote.getPower();
    if (wasOn) return;
    
    mote.setPower(true);
    simComm.sendCommand(new TurnOnMoteCommand((short)mote.getID(), 0L));
    driver.refreshMotePanel();
  }

  public boolean isOn() {
    return mote.getPower();
  }
  
  public void turnOff() throws IOException {
    boolean wasOn = mote.getPower();
    if (! wasOn) return;
    
    mote.setPower(false);
    simComm.sendCommand(new TurnOffMoteCommand((short)mote.getID(), 0L));
    driver.refreshMotePanel();
  }

  public void setLabel(String label, int xoff, int yoff) {
    mote.addAttribute(new MoteLabelAttribute(label, xoff, yoff));
    driver.refreshMotePanel();
  }

  public void move(double dx, double dy) {
    mote.moveSimObject(dx, dy);
    mote.addCoordinateChangedEvent();
    // XXX/demmer this shouldn't be necessary. the MotePlugin should
    // listen for the AttributeChangedEvent
    driver.refreshMotePanel();
  }

  public void moveTo(double x, double y) {
    mote.moveSimObjectTo(x, y);
    driver.refreshMotePanel();
  }

  public byte[] getBytes(String var) throws IOException {
    return moteVars.getBytes((short)mote.getID(), var);
  }

  public long getLong(String var) throws IOException {
    return moteVars.getLong((short)mote.getID(), var);
  }

  public int getInt(String var) throws IOException {
    return (int)moteVars.getLong((short)mote.getID(), var);
  }

  public short getShort(String var) throws IOException {
    return (short)moteVars.getShort((short)mote.getID(), var);
  }

  public byte getByte(String var) throws IOException {
    byte b[] = getBytes(var);
    if (b.length > 0) {
      return b[0];
    }
    else {
       throw Py.IndexError(var + " is not a valid variable (it has length 0)");
    }
  }
}
  
