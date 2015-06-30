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
import net.tinyos.script.*;

public class Call extends Expression {
  private String name;
  private ParameterList list;
  private Symbol symbol;
  private boolean isStatement;
    
  public Call(int lineNumber, String name, ParameterList list, Symbol s) {
    super(lineNumber);
    this.name = name;
    this.list = list;
    this.symbol = s;
    this.isStatement = false;
  }
  

  public void setStatement(boolean isStatement) {
    this.isStatement = isStatement;
  }
  public boolean isStatement() {return isStatement;}
    
  public boolean hasReturnValue() {
    Function fn = FunctionSet.getFunction(name);
    return fn.hasReturnValue();
  }
  
  public void checkStatement(SymbolTable table) throws SemanticException {
    Function fn = FunctionSet.getFunction(name);
    
    if (fn == null) {
      throw new SemanticException("Function " + name + " does not exist", lineNumber());
    }

    Integer numParams = new Integer((String)fn.get("numParams"));
    if (numParams.intValue() != list.numParams()) {
      throw new SemanticException("" + symbol.value + ": Function parameter count mismatch: " + name + " expects " + fn.get("numParams") + ", was passed " + list.numParams(), lineNumber());
    }

    Boolean returnVal = new Boolean((String)fn.get("returnVal"));
    if (!returnVal.booleanValue() && !isStatement()) {
      // Expecting a return val but do not have one
      throw new SemanticException("" + symbol.value + ": Function has no return value, but exists in expression that expects one.");
    }
    
    Enumeration params = list.getParams();
    while(params.hasMoreElements()) {
      Expression e = (Expression)params.nextElement();
      e.setIsParam(true);
      e.checkStatement(table);
    }
  }

  public void generateCode(SymbolTable table, CodeWriter writer) throws IOException {
    Function fn = FunctionSet.getFunction(name);
    Enumeration params = list.getParams();
    while(params.hasMoreElements()) {
      Expression e = (Expression)params.nextElement();
      e.generateCode(table, writer);
    }
    writer.writeInstr((String)fn.get("opcode"));
  }
  
  
  public String toString () {
    return name + list;
  }
}
