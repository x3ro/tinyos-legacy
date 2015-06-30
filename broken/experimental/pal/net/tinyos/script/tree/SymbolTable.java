/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.script.tree;

import java.io.*;
import java.util.*;

import net.tinyos.script.NoFreeVariableException;

public class SymbolTable {


  private Hashtable vars = new Hashtable();;
  private Hashtable buffers = new Hashtable();
  private static Hashtable shared;
  private int branchSymbols = 0;

  static {
    shared = new Hashtable();
  }
  
  public void addVariable(String var) {
    vars.put(var.toLowerCase(), new Integer(vars.size()));
  }

  public static void addSharedVariable(String var) throws NoFreeVariableException {
    Integer val = null;
    
    if (shared.containsKey(var.toLowerCase())) {
      return;
    }
    
    for (int i = 0; i < 16; i++) {
      Integer testVal = new Integer(i);
      if (!shared.containsKey(testVal)) {
	val = testVal;
	break;
      }
    }

    if (val == null) {
      System.err.println("All shared variables already in use.");
      throw new NoFreeVariableException();
    }
    
    shared.put(var.toLowerCase(), val);
    
  }

  public static void revokeSharedVariable(String var) {
    shared.remove(var);
  }
  
  public static void putSharedVariable(String var, int val) {
    shared.put(var.toLowerCase(), new Integer(val));
  }
  
  public void addBuffer(String var) {
    buffers.put(var.toLowerCase(), new Integer(buffers.size()));
  }
    

  public static int getShared(String var) {
    Integer i = (Integer)shared.get(var.toLowerCase());
    return i.intValue();
  }
  public int getVariable(String var) {
    Integer i = (Integer)vars.get(var.toLowerCase());
    return i.intValue();
  }
  public int getBuffer(String var) {
    Integer i = (Integer)buffers.get(var.toLowerCase());
    return i.intValue();
  }

  public static Vector getSharedVariables() {
    Vector v = new Vector();
    Enumeration e = shared.keys();
    while (e.hasMoreElements()) {
      v.addElement(e.nextElement());
    }
    
    return v;
  }
  
  public int numShared() {
    return shared.size();
  }
  public int numVariables() {
    return vars.size();
  }
  public int numBuffers() {
    return buffers.size();
  }

  public boolean sharedDeclared(String var) {
    return shared.containsKey(var.toLowerCase());
  }

  public boolean varDeclared(String var) {
    return vars.containsKey(var.toLowerCase());
  }

  public boolean bufferDeclared(String var) {
    return buffers.containsKey(var.toLowerCase());
  }

  public int getBranchSym() { 
    return branchSymbols++;
  }
    
}
