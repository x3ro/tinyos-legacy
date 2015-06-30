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
import net.tinyos.script.*;
import java_cup.runtime.Symbol;

public class SingleAccess extends Expression {
    private String name;
    private Symbol symbol;
    
  public SingleAccess(int lineNumber, String name, Symbol s) {
    super(lineNumber);
    this.name = name;
    this.symbol = s;
  }
    
  public String toString() {
    return name;
  }
  
  public Symbol symbol() {
    return symbol;
  }

  public void checkStatement(SymbolTable table) throws SemanticException {
    if (isParam()) {
      checkStatementParam(table);
    }
    else if (table.varDeclared(name) || table.sharedDeclared(name)) {
      return;
    }
    else if (table.constantDeclared(name)) {
      ConstantExpression e = table.getConstant(name);
      e.checkStatement(table);
    }
    else {
      throw new SemanticException("Variable " + name + " not declared: " + symbol.value + ".\n", lineNumber());
    }
  }
  
  public void checkStatementParam(SymbolTable table) throws SemanticException {
    if (!table.varDeclared(name) &&
	!table.sharedDeclared(name) &&
	!table.bufferDeclared(name) &&
	!table.constantDeclared(name)) {
      throw new SemanticException(name + " is neither a variable nor a buffer: " + symbol.value + ".\n", lineNumber());
    }
    else if (table.constantDeclared(name)) {
      ConstantExpression e = table.getConstant(name);
      e.checkStatement(table);
    }
  }
  
  public void generateCode(SymbolTable table, CodeWriter writer) throws IOException {
    if (writer.isMicro()) {
      if (table.varDeclared(name)) {
	int index = table.getVariable(name);
	writer.writeInstr("getlocal1 " + index);
      }
      else if (table.sharedDeclared(name)) {
	int index = table.getShared(name);
	writer.writeInstr("getvar1 " + index);
      }
      else if (table.bufferDeclared(name)) {
	int index = table.getBuffer(name);
	writer.writeInstr("bpush1 " + index);
      }
      else if (table.constantDeclared(name)) {
	ConstantExpression e = table.getConstant(name);
	e.generateCode(table, writer);
      }
    }
    else {
      if (table.varDeclared(name)) {
	int index = table.getVariable(name);
	writer.writeInstr("getlocal3 " + index);
      }
      else if (table.sharedDeclared(name)) {
	int index = table.getShared(name);
	writer.writeInstr("getvar4 " + index);
      }
      else if (table.bufferDeclared(name)) {
	int index = table.getBuffer(name);
	writer.writeInstr("bpush3 " + index);
      }
      else if (table.constantDeclared(name)) {
	ConstantExpression e = table.getConstant(name);
	e.generateCode(table, writer);
      }
    }
  }
}
