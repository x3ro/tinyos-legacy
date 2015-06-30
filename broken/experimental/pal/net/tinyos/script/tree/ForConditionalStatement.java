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

public class ForConditionalStatement extends Statement  {
    private SingleReference variable;
    private ConstantExpression initialValue;
    private ForStep step;
    private ForCondition condition;
    private StatementList statements;
    private SingleReference variable2;
    
    public ForConditionalStatement(SingleReference variable, ConstantExpression initialValue, ForStep step, ForCondition condition,  StatementList statements, SingleReference variable2) {
	this.variable = variable;
	this.initialValue = initialValue;
	this.step = step;
	this.condition = condition;
	this.statements = statements;
	this.variable2 = variable2;
    }

           
    public void checkStatement(SymbolTable table) throws SemanticException {
	if (!variable.toString().equals(variable2.toString())) {
	    throw new SemanticException("Loop value and increment value must be same variable: " + variable + "(" + variable.symbol() + ") and " + variable2 + "(" + variable2.symbol() + ")");
	}

	variable.checkStatement(table);
	initialValue.checkStatement(table);
	condition.checkStatement(table);
	statements.checkStatement(table);
	variable2.checkStatement(table);
    }
    
    public void generateCode(SymbolTable table, CodeWriter writer) throws IOException {
	writer.writeComment("Beginning of conditional loop");
	initialValue.generateCode(table, writer);
	variable.generateCode(table, writer);
	String label = "label" + table.getBranchSym();
	writer.writeLabel(label);
	statements.generateCode(table, writer);
	int index = table.getVariable(variable.name());
	writer.writeInstr("getvar4 " + index);
	int stepVal = step.getStep().intValue();
	writer.writeInstr("pushc6 " + stepVal);
	writer.writeInstr("add");
	writer.writeInstr("setvar4 " + index);
	condition.generateCode(table, writer);
	writer.writeInstr("2jumps10 " + label);
	writer.writeComment("End of conditional loop");
    }
    
}
