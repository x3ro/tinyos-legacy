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

  public Vector getBuffers() {
    Vector v = new Vector();
    Enumeration vars = variables.elements();
    while (vars.hasMoreElements()) {
      Declaration decl = (Declaration)vars.nextElement();
      if (decl instanceof BufferDeclaration) {
	v.addElement(decl);
      }
    }
    return v;
  }

  public Vector getConstants() {
    Vector v = new Vector();
    Enumeration vars = variables.elements();
    while (vars.hasMoreElements()) {
      Declaration decl = (Declaration)vars.nextElement();
      if (decl instanceof ConstantDeclaration) {
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
    Enumeration vars = variables.elements();
    while (vars.hasMoreElements()) {
      val += vars.nextElement() + "\n";
    }
    Enumeration stmts = statements.elements();
    while (stmts.hasMoreElements()) {
      val += stmts.nextElement() + "\n";
    }
    return val;
  }
  
  public void generateCode(CodeWriter writer) throws IOException, SemanticException, NoFreeVariableException  {
      SymbolTable table = generateTable();
      
      Enumeration stmts = statements.elements();
      while(stmts.hasMoreElements()) {
	Statement s = (Statement)stmts.nextElement();
	s.checkStatement(table);
      }
      
      stmts = statements.elements();
      while(stmts.hasMoreElements()) {
	Statement s = (Statement)stmts.nextElement();
	s.generateCode(table, writer);
      }
      writer.flush();
    }
  
    public SymbolTable generateTable() throws NoFreeVariableException {
	SymbolTable table = new SymbolTable();
	Enumeration vars = variables.elements();
	while (vars.hasMoreElements()) {
	    Declaration d = (Declaration)vars.nextElement();
	    if (d instanceof PrivateDeclaration) {
	      table.addVariable(d.getName());
	    }
	    else if (d instanceof SharedDeclaration) {
	      table.addSharedVariable(d.getName());
	    }
	    else if (d instanceof BufferDeclaration) {
	      table.addBuffer(d.getName());
	    }
	    else if (d instanceof ConstantDeclaration) {
	      ConstantDeclaration cd = (ConstantDeclaration)d;
	      table.addConstant(cd);
	    }
	    else if (d instanceof LoadDeclaration) {
	      LoadDeclaration ld = (LoadDeclaration)d;
	      Vector decls = ld.getConstants();
	      Enumeration declEnum = decls.elements();
	      while (declEnum.hasMoreElements()) {
		ConstantDeclaration cd = (ConstantDeclaration)declEnum.nextElement();
		table.addConstant(cd);
	      }
	    }
	}
	return table;
    }
    
}
