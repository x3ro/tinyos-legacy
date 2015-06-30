// $Id: Commands.java,v 1.12 2003/12/05 07:47:41 mikedemmer Exp $

/*									tab:2
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Date:        November 16 2003
 * Desc:        
 *
 */

/**
 *
 * The set of functions exported to the Python environment.
 *
 * @author Philip Levis
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.script.ScriptInterpreter;

import java.io.*;
import java.util.*;
import java.net.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;


public class Commands extends SimReflect {
  private SimCommands commands;
  private EmpiricalModel model;
  private int id = 1;
  
  
  public static final long DBG_BOOT =   (1 << 0);
  public static final long DBG_CLOCK =  (1 << 1);
  public static final long DBG_TASK =   (1 << 2);
  public static final long DBG_SCHED =  (1 << 3);
  public static final long DBG_SENSOR = (1 << 4);
  public static final long DBG_LED =    (1 << 5);
  public static final long DBG_CRYPTO = (1 << 6);

  public static final long DBG_ROUTE =  (1 << 7);
  public static final long DBG_AM =     (1 << 8);
  public static final long DBG_CRC =    (1 << 9);
  public static final long DBG_PACKET = (1 << 10);
  public static final long DBG_ENCODE = (1 << 11);
  public static final long DBG_RADIO =  (1 << 12);

  public static final long DBG_LOG =    (1 << 13);
  public static final long DBG_ADC =    (1 << 14);
  public static final long DBG_I2C =    (1 << 15);
  public static final long DBG_UART =   (1 << 16);
  public static final long DBG_PROG =   (1 << 17);
  public static final long DBG_SOUNDER =(1 << 18);
  public static final long DBG_TIME =   (1 << 19);

  public static final long DBG_SIM =    (1 << 21);
  public static final long DBG_QUEUE =  (1 << 22);
  public static final long DBG_SIMRADIO =(1 << 23);
  public static final long DBG_HARD =   (1 << 24);
  public static final long DBG_MEM =    (1 << 25);

  public static final long DBG_USR1 =   (1 << 26);
  public static final long DBG_USR2 =   (1 << 27);
  public static final long DBG_USR3 =   (1 << 28);
  public static final long DBG_TEMP =   (1 << 28);
  public static final long DBG_ERROR =  (1 << 28);
  public static final long DBG_NONE =    0;

  public static final long DBG_ALL = ~0;

  public Commands(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    commands = new SimCommands(driver);
    model = new EmpiricalModel();
  }
  
  public void sendRadioMessage(short moteID, long time, Message msg) throws IOException {
    commands.sendRadioMessage(moteID, time, msg);
  }
		
  public void sendUARTMessage(short moteID, long time, Message msg) throws IOException {
    commands.sendUARTMessage(moteID, time, msg);
  }
		
  public void turnMoteOff(short moteID, long time) throws IOException {
    commands.turnMoteOff(moteID, time);
  }
  
  public void turnMoteOn(short moteID, long time) throws IOException {
    commands.turnMoteOn(moteID, time);
  }

  public void setADCValue(short moteID, long time, byte port, short value) throws IOException {
    commands.setADCValue(moteID, time, port, value);
  }

  public void setSimRate(double rate) throws IOException {
    commands.setSimRate(rate);
  }

  public void setLinkBitErrorProbability(short src, long time, short test, double loss) throws IOException {
    commands.setLinkBitErrorProbability(src, time, test, loss);
  }

  public double packetLossToBitError(double packetLoss) {
    return model.getBitLossRate(packetLoss);
  }

  public double distanceToPacketLoss(double distance) {
    return model.getPacketLossRate(distance, 1.0);
  }
  
  public void pauseInFuture(long time, int pauseID) throws IOException {
    commands.pauseSimInFuture(time, pauseID);
  }

  public VariableResolveEvent resolveVariable(short moteID, String name) throws IOException {
    return commands.resolveVariable(moteID, name);
  }

  public VariableValueEvent requestVariable(long addr, short length) throws IOException {
    return commands.requestVariable(addr, length);
  }

  public void setDBG(long dbg) throws IOException {
    commands.setDBG(dbg);
  }
  
  public int getPauseID() {
    return id++;
  }

  public long getCurrentTime() {
    return 0;
  }

  public void waitUntil(long time) throws IOException {
    int id = getPauseID();
    pauseInFuture(time, id);
    SimEventBus bus = driver.getEventBus();
    String notifier = new String();
    
    Plugin plugin = new WaitUntilPlugin(id, notifier, driver);

    bus.register(plugin);
    try {
      synchronized(notifier) {
	notifier.wait();
      }
    }
    catch (Exception e) {
      System.err.println(e);
    }
    bus.deregister(plugin);
  }

  public void waitFor(long time) throws IOException {
    waitUntil(driver.getTossimTime() + time);
  }

  private class WaitUntilPlugin extends Plugin {
    private int id;
    private String notifier;
    private SimDriver driver;
    
    public WaitUntilPlugin(int id, String notifier, SimDriver driver) {
      this.id = id;
      this.notifier = notifier;
      this.driver = driver;
    }
    
    public void handleEvent(SimEvent e) {
      if (e instanceof SimulationPausedEvent) {
	SimulationPausedEvent spe = (SimulationPausedEvent)e;
	if ((int)spe.get_id() == id) {
	  synchronized(notifier) {
	    notifier.notifyAll();
	  }
	  //driver.pause();
	}
      }
    }
  }
}


