// $Id: MoteVariables.java,v 1.5 2004/03/05 00:56:58 mikedemmer Exp $

/*									tab:2
 *
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
 * Authors:	Michael Demmer
 * Date:        January 9, 2004
 * Desc:        Hooks to get/set Mote variables
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim;

import java.util.*;
import java.io.*;

import net.tinyos.sim.event.*;

public class MoteVariables {
  private SimDebug dbg = SimDebug.get("vars");
  private Hashtable mappings;
  private SimComm simComm;

  class Mapping {
    long addr;
    long len;
    Mapping(long addr, long len) {
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
  
  private VariableRequestResponse getVar(short moteID, String var, long offset, long len)
    throws IOException
  {
    String key = hashkey(moteID, var);
    Mapping m = (Mapping)mappings.get(key);
    dbg.out.println("VARS: getVar["+moteID+" " + var + "] offset "+offset+" len "+len);
    
    if (m == null) {
      // resolve the var and get a new mapping
      dbg.out.println("VARS: sending resolve command");
      VariableResolveResponse e = (VariableResolveResponse)
        simComm.sendCommandGetReply(new VariableResolveCommand(moteID, var));

      dbg.out.println("VARS: resolved addr " + e.get_addr() + ", length " + e.get_length());
      
      if (e.get_addr() == 0 || e.get_length() < 0) {
        throw new IndexOutOfBoundsException("Can't resolve variable \"" + var + "\"");
      }
      
      m = new Mapping(e.get_addr(), e.get_length());
      mappings.put(key, m);
    }

    /*
     * If unspecified, use the resolved length.
     */
    if (len == 0) {
      len = m.len;
    }

    /*
     * Note that we can't really fit 256 in a short, but we (and
     * external_comm.c) will use a value of 0 to represent 256. Warn
     * if this is happening implicitly.
     */
    if (len >= 256) {
      if (len > 256)
        System.out.println("WARNING: variable size > 256 requested, result will be truncated");
      len = 0;
    } 
    
    dbg.out.println("VARS: sending request for " + (m.addr + offset) + ", length " + len);
    
    VariableRequestResponse e = (VariableRequestResponse)
      simComm.sendCommandGetReply(new VariableRequestCommand(m.addr + offset, (short)len));

    dbg.out.println("VARS: got result of length " + e.get_length());
    
    return e;
  }

  public byte[] getBytes(short moteID, String var) throws IOException {
    return getBytes(moteID, var, 0, 0);
  }
    
  public byte[] getBytes(short moteID, String var, long offset, long len) throws IOException {
    VariableRequestResponse e = getVar(moteID, var, offset, len);

    // This is a bit of a kludge, but there's no other way to shorten
    // the array.
    byte[] ret  = new byte[(int)e.get_length()];
    byte[] orig = e.get_value();
    
    for (int i = 0; i < e.get_length(); i++) {
      ret[i] = orig[i];
    }
    return ret;
  }
  
  public long getShort(short moteID, String var) throws IOException {
    VariableRequestResponse e = getVar(moteID, var, 0, 2);
    return e.getShort_value(0);
  }
  
  public long getLong(short moteID, String var) throws IOException {
    VariableRequestResponse e = getVar(moteID, var, 0, 4);
    return e.getLong_value(0);
  }
}

