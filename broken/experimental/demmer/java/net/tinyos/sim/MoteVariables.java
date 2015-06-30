// $Id: MoteVariables.java,v 1.2 2003/12/05 04:48:22 mikedemmer Exp $

/*									tab:2
 *
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
 * Authors:	Michael Demmer
 * Date:        November 27, 2003
 * Desc:        Hooks to get/set Mote variables
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim;

import java.util.*;
import java.io.*;

import net.tinyos.sim.event.*;

public class MoteVariables {
  private Hashtable mappings;
  private SimComm simComm;

  class Mapping {
    long addr;
    short len;
    Mapping(long addr, short len) {
      this.addr = addr;
      this.len = len;
    }
  };

  public MoteVariables(SimDriver driver) {
    this.simComm = driver.getSimComm();
    this.mappings = new Hashtable();
  }

  private String hashkey(short moteID, String var) {
    return "Mote["+moteID+"]$"+var;
  }
  
  private VariableValueEvent getEvent(short moteID, String var) throws IOException {
    String key = hashkey(moteID, var);
    Mapping m = (Mapping)mappings.get(key);
    if (m == null) {
      // resolve the var and get a new mapping
      VariableResolveEvent e = (VariableResolveEvent)
        simComm.sendCommandGetReply(new VariableResolveCommand(moteID, var));

      if (e.get_addr() == 0 || e.get_length() < 0) {
        throw new IndexOutOfBoundsException("Can't resolve variable " + var);
      }
      
      m = new Mapping(e.get_addr(), e.get_length());
      mappings.put(key, m);
    }
    
    VariableValueEvent e = (VariableValueEvent)
      simComm.sendCommandGetReply(new VariableRequestCommand(m.addr, m.len));

    return e;
  }

  public byte[] getBytes(short moteID, String var) throws IOException {
    VariableValueEvent e = getEvent(moteID, var);
    byte[] ret = new byte[e.get_length()];
    for (int i = 0; i < e.get_length(); i++) {
      ret[i] = e.getElement_value(i);
    }
    return ret;
  }
  
  public int getShort(short moteID, String var) throws IOException {
    VariableValueEvent e = getEvent(moteID, var);
    return e.getShort_value(0);
  }
  
  public long getLong(short moteID, String var) throws IOException {
    VariableValueEvent e = getEvent(moteID, var);
    return e.getLong_value(0);
  }
}

