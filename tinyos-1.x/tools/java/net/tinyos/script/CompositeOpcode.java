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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Jan 6 2004
 * Desc:        A composite opcode.
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

public class CompositeOpcode {
  private String name;
  private String code;
  private Vector opcodes;
  private ScriptAssembler assembler;
  
  public CompositeOpcode(String name, String code) throws Exception {
    this.name = name;
    this.code = code;
    this.opcodes = new Vector();
    this.assembler = new ScriptAssembler(null);
    
    buildOpcodeList();
  }

  public String getModule() {
    String msg = "module OP" + name + "M {\n";
    msg += "  provides interface BombillaBytecode;\n";
    msg += "  uses {\n";
    for (int i = 0; i < opcodes.size(); i++) {
      msg += "    interface BombillaBytecode as Operation" + i + ";\n";
    }
    msg += "  }\n";
    msg += "}\n\n";

    msg += "implementation {\n";
    msg += "  command result_t BombillaBytecode.execute(uint8_t instr,\n";
    msg += "                                    BombillaContext* context) {\n";
    for (int i = 0; i < opcodes.size(); i++) {
      String instr = (String)opcodes.elementAt(i);
      String operand = "0";
      String opcode = instr;
      if (assembler.hasEmbeddedOperand(instr)) {
	operand = getOperand(instr);
	opcode = getOpcode(instr);
      }
      msg += "    if (call Operation" + i + ".execute(" + operand + ", context) == FAIL) {return FAIL;}\n";
    }
    msg += "    return SUCCESS;\n";
    msg += "  }\n";
    msg += "}\n";
    return msg;
  }

  public String getConfiguration() {
    String module = "OP" + name + "M";
    String conf = "OP" + name;
    String msg = "configuration " + conf + " {\n";
    msg += "  provides interface BombillaBytecode;\n";
    msg += "}\n\n";
    msg += "implementation {\n";
    msg += "  components " + module + ";\n";
    for (int i = 0; i < opcodes.size(); i++) {
      String instr = (String)opcodes.elementAt(i);
      String opcode = getOpcode(instr);
      msg += "  components OP" + opcode + ";\n";
    }
    msg += "\n";

    msg += "  BombillaBytecode = " + module + ";\n";
    for (int i = 0; i < opcodes.size(); i++) {
      String instr = (String)opcodes.elementAt(i);
      String opcode = getOpcode(instr);
      msg += "  " + module + ".Operation" + i + " -> OP" + opcode + ";\n";
    }
    msg += "}\n\n";
    return msg;
  }

  private void buildOpcodeList() throws Exception {
    StringReader reader = new StringReader(code);
    Parser p = new Parser(new Yylex(reader));
    String program;
    try {
      System.out.println("Parsing program.");
      p.parse();
      System.out.println("Getting program.");
      Program prog = Parser.getProgram();
      StringWriter writer = new StringWriter();
      System.out.println("Generating code.");
      prog.generateCode(new CodeWriter(writer));
      System.out.println("Getting assembly text.");
      program = writer.getBuffer().toString();
    }
    catch (Exception e) {
      System.err.println(e);
      e.printStackTrace();
      return;
    }

    reader = new StringReader(program);
    AssemblyTokenizer tok = new AssemblyTokenizer(reader);
    while(tok.hasMoreInstructions()) {
      String instr = tok.nextLine();
      if (instr != null &&
	  !instr.equals("")) {
	opcodes.addElement(instr);
      }
    }
  }

  private String getOperand(String instr) {
    if (!assembler.hasEmbeddedOperand(instr)) {
      return null;
    }
    else {
      String[] vals = instr.split(" ");
      return vals[1];
    }
  }

  private String getOpcode(String instr) {
    if (!assembler.hasEmbeddedOperand(instr)) {
      return instr;
    }
    else {
      String[] vals = instr.split(" ");
      return vals[0];
    }
  }
}
