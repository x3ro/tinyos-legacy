// $Id: SimCommands.java,v 1.4 2004/06/10 19:26:42 mikedemmer Exp $

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

/**
 *
 * The set of basic commands that can be called on TOSSIM.
 *
 * @author Philip Levis
 */


package net.tinyos.sim;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.script.ScriptInterpreter;

import java.io.*;
import java.util.*;
import java.net.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;


public class SimCommands {
    private static MessageFactory mf = new MessageFactory();
    private static TOSMsg template;
  private SimDebug dbg = SimDebug.get("commands");
  private SimComm comm;
  private SimDriver driver;
  
  public SimCommands(SimDriver driver) {
    this.driver = driver;
    template = mf.createTOSMsg(10);
    this.comm = driver.getSimComm();
  }
    
  public void sendRadioMessage(short moteID, long time, Message msg) throws IOException {
    int amType = msg.amType();
    byte[] data = msg.dataGet();

    dbg.out.println("COMMANDS: sendRadioMessage mote: "+moteID+" time: "+time+" msgType: "+amType);
	
    TOSMsg tm = mf.createTOSMsg(template.offset_data(0) + data.length);
	
    tm.set_addr((short)0xffff);
    tm.set_type((short)amType);
    tm.set_length((short)data.length);
    tm.dataSet(data, 0, tm.offset_data(0), data.length);
	
    net.tinyos.sim.event.RadioMsgSendCommand cmd;
    cmd = new net.tinyos.sim.event.RadioMsgSendCommand(moteID, time, tm.dataGet());
    comm.sendCommand(cmd);
  }
    
  public void sendUARTMessage(short moteID, long time, Message msg) throws IOException {
    int amType = msg.amType();
    byte[] data = msg.dataGet();
	
    dbg.out.println("COMMANDS: sendUARTMessage mote: "+moteID+" time: "+time+" msgType: "+amType);
    
    TOSMsg tm = mf.createTOSMsg(template.offset_data(0) + data.length);
	
    tm.set_addr((short)0xffff);
    tm.set_type((short)amType);
    tm.set_length((short)data.length);
    tm.dataSet(data, 0, tm.offset_data(0), data.length);
	
    net.tinyos.sim.event.UARTMsgSendCommand cmd;
    cmd = new net.tinyos.sim.event.UARTMsgSendCommand(moteID, time, tm.dataGet());
    comm.sendCommand(cmd);
  }
    
  public void turnMoteOff(short moteID, long time) throws IOException {
    dbg.out.println("COMMANDS: turnMoteOff mote: "+moteID+" time: "+time);
    comm.sendCommand(new net.tinyos.sim.event.TurnOffMoteCommand(moteID, time));
  }
    
  public void turnMoteOn(short moteID, long time) throws IOException {
    dbg.out.println("COMMANDS: turnMoteOn mote: "+moteID+" time: "+time);
    comm.sendCommand(new net.tinyos.sim.event.TurnOnMoteCommand(moteID, time));
  }

  public void setADCValue(short moteID, long time, byte port, short value) throws IOException {
    dbg.out.println("COMMANDS: setADCValue mote: "+moteID+" time: "+time+" port: "+port+" value: "+value);
    comm.sendCommand(new SetADCPortValueCommand(moteID, time, port, value));
  }

  public void setSimRate(double rate) throws IOException {
    dbg.out.println("COMMANDS: setSimRate rate: "+rate);
    comm.sendCommand(new SetRateCommand((int)(rate * 1000.0)));
  }

  public void setLinkBitErrorProbability(short src, long time, short dest, double errorRate)
    throws IOException {
    dbg.out.println("COMMANDS: setLinkBitError src: "+src+" dest: "+dest+" time: "+time+" rate: "+errorRate);
    comm.sendCommand(new SetLinkProbCommand(src, time, dest, (long)(errorRate * 10000.0)));
  }

  
  public void interruptInFuture(long time, int interruptID) throws IOException {
    dbg.out.println("COMMANDS: interruptInFuture: interruptID: "+interruptID+" time: "+time);
    comm.sendCommand(new InterruptCommand(time, interruptID));
  }

  public void setDBG(long dbgnum) throws IOException {
    dbg.out.println("COMMANDS: setDBG: dbg: "+dbgnum);
    comm.sendCommand(new SetDBGCommand(dbgnum));
  }

  public void setEventMask(short mask) throws IOException {
    dbg.out.println("COMMANDS: setEventMask: mask: "+mask);
    if (mask == 0) {
      System.out.println("WARNING: setting event mask to 0, will block all events");
    }
    comm.sendCommand(new SetEventMaskCommand(mask));
  }
  
  public VariableResolveResponse resolveVariable(short moteID, String name) throws IOException {
    dbg.out.println("COMMANDS: variableResolve: moteID: "+moteID+" var: "+name);
    VariableResolveResponse e;
    e = (VariableResolveResponse)comm.sendCommandGetReply(new VariableResolveCommand(moteID, name));
    return e;
  }

  public VariableRequestResponse requestVariable(long addr, short len) throws IOException {
    VariableRequestResponse e;
    e = (VariableRequestResponse)comm.sendCommandGetReply(new VariableRequestCommand(addr, len));
    return e;
  }
}
