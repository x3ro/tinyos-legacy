/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Jun 13 2004
 * Desc:        Main window for script injector.
 *               
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.script.tree.*;
import vm_specific.*;

public class ProgramState {
  private String filename = "programs.txt";
  private VersionTable versionTable = new VersionTable();
  private ProgramTable programTable = new ProgramTable();
  private CompiledTable compiledTable = new CompiledTable();

  public ProgramState() {}

  public ProgramState(String filename) throws FileNotFoundException, IOException, ParserException, Exception  {
    File file = new File(filename);
    if (!file.exists()) {
      System.out.println("Program file " + filename + " does not exist, creating.");
      return;
    }
    FileReader reader = new FileReader(file);
    DFTokenizer tok = new DFTokenizer(reader);

    while (tok.hasMoreStatements()) {
      DFStatement statement = tok.nextStatement();
      if (statement == null) {continue;}

      if (statement.getType().toUpperCase().equals("HANDLER")) {
	String name = statement.get("name");
	String version = statement.get("version");
	String code = statement.get("code");

	//System.err.println("  Recompiling stored " + name + " handler.");
	StringReader stringReader = new StringReader(code);
	Parser p = new Parser(new Yylex(stringReader));
	p.parse();
	Program prog = Parser.getProgram();
	update(name, Integer.parseInt(version), code, prog);
	//compiledTable.put(name, prog);
	//programTable.put(name, code);
	//versionTable.put(name, Integer.parseInt(version));
      }
      else if (statement.getType().toUpperCase().equals("VARIABLE")) {
	String name = statement.get("name");
	String val = statement.get("val");
	Integer iVal = new Integer(val);
	SymbolTable.putSharedVariable(name, iVal.intValue());
      }
      else if (statement.getType().toUpperCase().equals("BUFFER")) {
	String name = statement.get("name");
	String val = statement.get("val");
	Integer iVal = new Integer(val);
	SymbolTable.putBuffer(name, iVal.intValue());
      }
    }
    this.filename = filename;
  }

  public int getVersion(String context) {
    return versionTable.get(context);
  }

  public String getProgram(String context) {
    return programTable.get(context);
  }

  public Enumeration getProgramKeys() {
    return programTable.keys();
  }
  
  public Program getCompiled(String context) {
    return compiledTable.get(context);
  }
  
  public void update(String context, int version,
		     String program, Program compiled) {
   // System.out.println("Putting " + context + " v" + version + " " + program + " " + ( compiled == null));
    versionTable.put(context, version);
    programTable.put(context, program);
    compiledTable.put(context, compiled);
    gcSharedVariables();
    gcBuffers();
    if (compiled == null) {
      throw new NullPointerException(context + " has no program");
    }
  }
  
  public void update(String context, String program, Program compiled) {
    update(context, getVersion(context) + 1, program, compiled);
  }
  
  /* See if any shared variables are no longer in use. If this
      is the case, clear them. */
  private void gcSharedVariables() {
//    System.out.println("Garbage collecting variables");
    Enumeration vars = SymbolTable.getSharedVariables().elements();
    while (vars.hasMoreElements()) { // For each variable
      boolean used = false;
      String var = (String)vars.nextElement();
      Enumeration progs = getProgramKeys();

      while (progs.hasMoreElements()) {        // In each program
	String progName = (String)progs.nextElement();
	Program prog = getCompiled(progName);
	if (prog == null) {
//	  System.err.println(progName + " has an entry in the program table,");
//	  System.err.println(getProgram(progName));
//	  System.err.println(".. but no compiled image!");
	  continue;
	}
	
	Enumeration referenced = prog.getSharedVariables().elements();

	while (referenced.hasMoreElements()) {
	  SharedDeclaration decl = (SharedDeclaration)referenced.nextElement();
	  if (decl.getName().toLowerCase().equals(var.toLowerCase())) {
	    used = true;
	    break;
	  }
	}
	if (used) {
	  break;
	}
      }
      if (!used) {
	//System.err.println("Revoking shared variable " + var);
	SymbolTable.revokeSharedVariable(var);
      }
    }
  }

  private void gcBuffers() {
  //  System.out.println("Garbage collecting variables");
    Enumeration vars = SymbolTable.getBuffers().elements();
    while (vars.hasMoreElements()) { // For each variable
      boolean used = false;
      String var = (String)vars.nextElement();
      Enumeration progs = getProgramKeys();

      while (progs.hasMoreElements()) {        // In each program
	String progName = (String)progs.nextElement();
	Program prog = getCompiled(progName);
	if (prog == null) {
//	  System.err.println(progName + " has an entry in the program table,");
//System.err.println(getProgram(progName));
//System.err.println(".. but no compiled image!");
	  continue;
	}

	Vector buffers = prog.getBuffers();
	Enumeration referenced = buffers.elements();
	
	while (referenced.hasMoreElements()) {
	  BufferDeclaration decl = (BufferDeclaration)referenced.nextElement();
	  if (decl.getName().toLowerCase().equals(var.toLowerCase())) {
	    used = true;
	    break;
	  }
	}
	if (used) {
	  break;
	}
      }
      if (!used) {
	//System.err.println("Revoking shared variable " + var);
	SymbolTable.revokeBuffer(var);
      }
    }
  }
  
  public void writeState() throws IOException {
    System.out.println("Writing state.");

    Writer writer = new FileWriter(filename);
    Enumeration handlers = getProgramKeys();
    Date d = new Date();
    writer.write("// Generated  at " + d + "\n");
    while (handlers.hasMoreElements()) {
      // Don't save null programs
      String name = (String)handlers.nextElement();
      if (getProgram(name).trim().equals("")) {continue;}
      writer.write("<HANDLER ");
      writer.write("name=\"" + name + "\" ");
      writer.write("version=\"" + getVersion(name) + "\" ");
      String prog = getProgram(name);
      prog = prog.replaceAll("\\\"", "\\\\\"");
      writer.write("code=\"" + prog + "\" ");
      writer.write(">\n");
    }
    
    Enumeration vars = SymbolTable.getSharedVariables().elements();
    while (vars.hasMoreElements()) {
      String var = (String)vars.nextElement();
      writer.write("<VARIABLE ");
      writer.write("name=\"" + var + "\" ");
      writer.write("val=\"" + SymbolTable.getShared(var) + "\" ");
      writer.write(">\n");
    }
    
    Enumeration bufs = SymbolTable.getBuffers().elements();
    while (bufs.hasMoreElements()) {
      String var = (String)bufs.nextElement();
      writer.write("<BUFFER ");
      writer.write("name=\"" + var + "\" ");
      writer.write("val=\"" + SymbolTable.getBuffer(var) + "\" ");
      writer.write(">\n");
    }
      
    writer.write("\n");
    writer.close();
  }
  
}
