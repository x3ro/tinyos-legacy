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

import net.tinyos.script.*;

public class ForUnconditionalStatement extends Statement  {
    private SingleReference variableSet;
    private Expression initialValue;
    private ConstantExpression endValue;
    private ConstantExpression step;
    private StatementList statements;
    private SingleAccess variableGet;
    private int constantValue;
    
  public ForUnconditionalStatement(int lineNumber, SingleReference variableSet, Expression initialValue, ConstantExpression endValue, ConstantExpression step, StatementList statements, SingleAccess variableGet) {
    super(lineNumber);
    this.variableSet = variableSet;
    this.initialValue = initialValue;
    this.endValue = endValue;
    this.step = step;
    this.statements = statements;
    this.variableGet = variableGet;
  }

        
  public void checkStatement(SymbolTable table) throws SemanticException {
    if (!variableSet.toString().equals(variableGet.toString())) {
      throw new SemanticException("Loop value and increment value must be same variable: " + variableSet + "(" + variableSet.symbol() + ") and " + variableGet + "(" + variableGet.symbol() + ")", lineNumber());
    }
    
    variableSet.checkStatement(table);
    initialValue.checkStatement(table);
    endValue.checkStatement(table);
    statements.checkStatement(table);
    variableGet.checkStatement(table);
  }
  
    public void generateCode(SymbolTable table, CodeWriter writer) throws IOException {
	writer.writeComment("Beginning of unconditional loop");

	initialValue.generateCode(table, writer);
	variableSet.generateCode(table, writer);

	String label = "label" + table.getBranchSym();
	writer.writeLabel(label);
	statements.generateCode(table, writer);

	variableGet.generateCode(table, writer);
	if (step.value() != 0) {
	  step.generateCode(table, writer);
	  writer.writeInstr("add");
	  writer.writeInstr("copy");
	  variableSet.generateCode(table, writer);
	}
	  
	endValue.generateCode(table, writer);

	writer.writeInstr("lt");
	writer.writeInstr("2jumps10 " + label);
	writer.writeComment("End of unconditional loop");
    }
    
}
