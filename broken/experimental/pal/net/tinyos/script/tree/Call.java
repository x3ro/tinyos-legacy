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
    
  public Call(String name, ParameterList list, Symbol s) {
    this.name = name;
    this.list = list;
    this.symbol = s;
    this.isStatement = false;
  }
  

  public void setStatement(boolean isStatement) {
    this.isStatement = isStatement;
  }
  public boolean isStatement() {return isStatement;}
    

  public void checkStatement(SymbolTable table) throws SemanticException {
    Primitive prim = PrimitiveSet.getPrimitive(name);
    
    if (prim == null) {
      throw new SemanticException("Primitive " + name + " does not exist");
    }

    Integer numParams = new Integer((String)prim.get("numParams"));
    if (numParams.intValue() != list.numParams()) {
      throw new SemanticException("" + symbol.value + ": Primitive parameter count mismatch: " + name + " expects " + prim.get("numParams") + ", was passed " + list.numParams());
    }

    Boolean returnVal = new Boolean((String)prim.get("returnVal"));
    if (!returnVal.booleanValue() && !isStatement()) {
      // Expecting a return val but do not have one
      throw new SemanticException("" + symbol.value + ": Primitive has no return value, but exists in expression that expects one.");
    }
    
    Enumeration enum = list.getParams();
    while(enum.hasMoreElements()) {
      Expression e = (Expression)enum.nextElement();
      e.setIsParam(true);
      e.checkStatement(table);
    }
  }

  public void generateCode(SymbolTable table, CodeWriter writer) throws IOException {
    Primitive prim = PrimitiveSet.getPrimitive(name);
    Enumeration enum = list.getParams();
    while(enum.hasMoreElements()) {
      Expression e = (Expression)enum.nextElement();
      e.generateCode(table, writer);
    }
    writer.writeInstr((String)prim.get("opcode"));
  }
  
  
  public String toString () {
    return "CALL " + name + list;
  }
}
