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
import java_cup.runtime.Symbol;

import net.tinyos.script.NoFreeVariableException;

public class SymbolTable {


  private Hashtable vars = new Hashtable();
  private Hashtable constants = new Hashtable();
  private static Hashtable shared;
  private static Hashtable buffers;

  private int branchSymbols = 0;

  private static int numShared = 0;
  private static int numPrivate = 0;
  private static int numBuffer = 0;
  
  static {
    shared = new Hashtable();
    buffers = new Hashtable();
  }

  public static void setLanguage(String language) {
    if (language.toLowerCase().equals("microscript")) {
      numShared = 2;
      numPrivate = 2;
      numBuffer = 2;
    }
    else if (language.toLowerCase().equals("tinyscript")) {
      numShared = 16;
      numPrivate = 8;
      numBuffer = 8;
    }
    else {
      System.err.println("Could not recongize language " + language + ", defaulting to TinyScript.\n");
      numShared = 16;
      numPrivate = 8;
      numBuffer = 8;      
    }
  }
  
  public void addVariable(String var) throws NoFreeVariableException {
    if (vars.size() >= numPrivate) {
      throw new NoFreeVariableException("All private variables already in use.");
    }
    else {
      vars.put(var.toLowerCase(), new Integer(vars.size()));
    }
  }

  public void addConstant(ConstantDeclaration d) {
    ConstantExpression e = new ConstantExpression(d.getLineNumber(),
						  d.getValue(),
						  d.getSymbol());
    constants.put(d.getName().toLowerCase(), e);
  }
  
  public static void addSharedVariable(String var) throws NoFreeVariableException {
    Integer val = null;
    
    if (shared.containsKey(var.toLowerCase())) {
      return;
    }
    
    for (int i = 0; i < numShared; i++) {
      Integer testVal = new Integer(i);
      if (!shared.containsValue(testVal)) {
	val = testVal;
	break;
      }
    }

    if (val == null) {
      throw new NoFreeVariableException("All shared variables already in use.");
    }
    
    shared.put(var.toLowerCase(), val);
    
  }

  public static void revokeSharedVariable(String var) {
    shared.remove(var);
  }

  public static void revokeBuffer(String var) {
    buffers.remove(var);
  }

  
  
  public static void putSharedVariable(String var, int val) {
    shared.put(var.toLowerCase(), new Integer(val));
  }

  public static void putBuffer(String var, int val) {
    buffers.put(var.toLowerCase(), new Integer(val));
  }
  
  public static void addBuffer(String var) throws NoFreeVariableException{
    Integer val = null;
    
    if (buffers.containsKey(var.toLowerCase())) {
      return;
    }
    
    for (int i = 0; i < numBuffer; i++) {
      Integer testVal = new Integer(i);
      if (!buffers.containsValue(testVal)) {
	val = testVal;
	break;
      }
    }
    
    if (val == null) {
      throw new NoFreeVariableException("All buffers already in use.");
    }
    
    buffers.put(var.toLowerCase(), val);
  }
    

  public static int getShared(String var) {
    Integer i = (Integer)shared.get(var.toLowerCase());
    return i.intValue();
  }
  public int getVariable(String var) {
    Integer i = (Integer)vars.get(var.toLowerCase());
    return i.intValue();
  }
  public static int getBuffer(String var) {
    Integer i = (Integer)buffers.get(var.toLowerCase());
    return i.intValue();
  }
  public ConstantExpression getConstant(String var) {
    ConstantExpression e = (ConstantExpression)constants.get(var.toLowerCase());
    return e;
  }

  public static Vector getSharedVariables() {
    Vector v = new Vector();
    Enumeration e = shared.keys();
    while (e.hasMoreElements()) {
      v.addElement(e.nextElement());
    }
    
    return v;
  }

  public static Vector getSharedAndBuffers() {
    Vector v = new Vector();
    Enumeration e = shared.keys();
    while (e.hasMoreElements()) {
      v.addElement("value: " + e.nextElement());
    }
    e = buffers.keys();
    while (e.hasMoreElements()) {
      v.addElement("buffer: " + e.nextElement());
    }

    for (int i = 0; i < v.size(); i++) {
      String val = (String)v.elementAt(i);
      for (int j = i + 1; j < v.size(); j++) {
	String otherVal = (String)v.elementAt(j);
	if (otherVal.compareTo(val) < 0) {
	  v.removeElement(otherVal);
	  v.insertElementAt(otherVal, i);
	  val = otherVal;
	}
      }
    }
    return v;
  }

  public static Vector getBuffers() {
    Vector v = new Vector();
    Enumeration e = buffers.keys();
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

  public boolean constantDeclared(String var) {
    return constants.containsKey(var.toLowerCase());
  }
  
  public int getBranchSym() { 
    return branchSymbols++;
  }
    
}
