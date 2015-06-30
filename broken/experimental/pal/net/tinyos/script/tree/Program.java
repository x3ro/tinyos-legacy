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


public class Program {
    private Vector variables = new Vector();
    private Vector statements = new Vector();
    
    public Program() {}
    
    public void addVariable(Declaration d) throws ParseException {
	if (variables.contains(d)) {
	    throw new ParseException("Variable " + d.getName() + " declared twice.\n");
	}
	variables.addElement(d);
    }
    
    public void addStatement(Statement s) {
	statements.addElement(s);
    }

  public Vector getSharedVariables() {
    Vector v = new Vector();
    Enumeration vars = variables.elements();
    while (vars.hasMoreElements()) {
      Declaration decl = (Declaration)vars.nextElement();
      if (decl instanceof SharedDeclaration) {
	v.addElement(decl);
      }
    }
    return v;
  }
  
    public void addStatements(StatementList l) {
	Enumeration e = l.statements();
	while(e.hasMoreElements()) {
	    statements.addElement(e.nextElement());
	}
    }
    
    public String toString() {
	String val = "";
	Enumeration enum;
	enum = variables.elements();
	while (enum.hasMoreElements()) {
	    val += enum.nextElement() + "\n";
	}
	enum = statements.elements();
	while (enum.hasMoreElements()) {
	    val += enum.nextElement() + "\n";
	}
	return val;
    }

    public void generateCode(CodeWriter writer) throws IOException, SemanticException, NoFreeVariableException  {
      SymbolTable table = generateTable();
      
      Enumeration enum = statements.elements();
      while(enum.hasMoreElements()) {
	Statement s = (Statement)enum.nextElement();
	s.checkStatement(table);
      }
      
      enum = statements.elements();
      while(enum.hasMoreElements()) {
	Statement s = (Statement)enum.nextElement();
	s.generateCode(table, writer);
      }
      writer.flush();
    }
  
    public SymbolTable generateTable() throws NoFreeVariableException {
	SymbolTable table = new SymbolTable();
	Enumeration enum = variables.elements();
	while (enum.hasMoreElements()) {
	    Declaration d = (Declaration)enum.nextElement();
	    if (d instanceof PrivateDeclaration) {
	      table.addVariable(d.getName());
	    }
	    else if (d instanceof SharedDeclaration) {
	      table.addSharedVariable(d.getName());
	    }
	    else if (d instanceof BufferDeclaration) {
	      table.addBuffer(d.getName());
	    }
	}
	return table;
    }
    
}
