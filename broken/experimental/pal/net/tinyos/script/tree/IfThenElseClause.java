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

public class IfThenElseClause extends IfThenClause {
    private StatementList elseList;

    public IfThenElseClause(StatementList then, StatementList els) {
	super(then);
	elseList = els;
    }
    
    public String toString() {
	return super.toString() + "ELSE\n" + elseList;
    }

    public void checkStatement(SymbolTable table) throws SemanticException {
	super.checkStatement(table);
	elseList.checkStatement(table);
	return;
    }

    public StatementList getElseStatement() {
	return elseList;
    }

    public void generateCode(SymbolTable table, CodeWriter writer) throws IOException {
	StatementList thenList = getThenStatement();
	String thenLabel = "label" + table.getBranchSym();
	String endLabel = "label" + table.getBranchSym();
	writer.writeInstr("2jumps10 " + thenLabel);

	/* A neat trick, suggested by dgay (probably common knowledge
	 * that is not common to me).
	 *
	 * Since the THEN clause is on a positive conditional, the not
	 * instruction can be removed; the ELSE clause comes first (if
	 * the conditional is false), and jumps to after the THEN
	 * clause. A positive conditional jumps to the THEN clause.
	 */

	elseList.generateCode(table, writer);
	writer.writeInstr("pushc6 1");
	writer.writeInstr("2jumps10 " + endLabel);
	writer.writeLabel(thenLabel);
	thenList.generateCode(table, writer);
	writer.writeLabel(endLabel);
    }
}

