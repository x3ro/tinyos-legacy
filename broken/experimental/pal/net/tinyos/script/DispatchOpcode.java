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
import net.tinyos.vm_asm.*;
import net.tinyos.script.tree.*;

public class DispatchOpcode {
  private String name;
  private String code;
  private Vector subCodes;
  private Vector[] sortedCodes = new Vector[32];
  
  public DispatchOpcode(String name, Vector subCodes) throws Exception {
    this.name = name;
    this.subCodes = subCodes;
    buildOpcodeList();
  }

  public String getModule() {
    String msg = "module OP2" + name + "M {\n";
    msg += "  provides interface BombillaBytecode;\n";
    msg += "  uses {\n";
    msg += "    interface BombillaBytecode as Dispatch[uint8_t code];\n";
    msg += "    interface BombillaError as Error;\n";
    msg += "  }\n";
    msg += "}\n\n";

    msg += "implementation {\n";
    msg += "  command result_t BombillaBytecode.execute(uint8_t instr,\n";
    msg += "                                            BombillaContext* context) {\n";
    msg += "    uint8_t dispatchVal = context->pc;\n";
    msg += "    context->pc++;\n";
    msg += "    return call Dispatch[dispatch](dispatch, context);\n";
    msg += "  }\n\n";
    msg += "  default command result_t Dispatch[uint8_t c](uint8_t instr,\n";
    msg += "                                               BombillaContext* context) {\n";
    msg += "    call Error.error(ctx, BOMB_ERROR_INVALID_INSTRUCTION);\n";
    msg += "    return FAIL;\n";
    msg += "  }\n";
    msg += "}\n";
    return msg;
  }

  public String getConfiguration() {
    String module = "OP2" + name + "M";
    String conf = "OP2" + name;
    String msg = "configuration " + conf + " {\n";
    msg += "  provides interface BombillaBytecode;\n";
    msg += "}\n";
    msg += "uses {\n";
    
    msg += "\n\n";
    msg += "implementation {\n";
    msg += "  components BombillaErrorProxy;\n";
    msg += "  components " + module + ";\n";
    for (int i = 0; i < subCodes.size(); i++) {
      Primitive instr = (Primitive)subCodes.elementAt(i);
      String opcode = getOpcode(instr);
      msg += "  components OP" + opcode + ";\n";
    }
    msg += "\n";

    msg += "  BombillaBytecode = " + module + ";\n";
    msg += "  " + module + ".Error -> BombillaErrorProxy;\n";
    int counter = 0;
    for (int i = 0; i < sortedCodes.length; i++) {
      Vector codes = sortedCodes[i];
      if (codes != null) {
	counter = (int)Math.ceil((double)counter/(1 << i)) * (1 << i);
	Enumeration e = codes.elements();
	while (e.hasMoreElements()) {
          String opcode = Integer.toHexString(counter);
          Primitive p = (Primitive) e.nextElement();
	  msg += "  Dispatch[" + counter + "] -> OP" + getOpcode(p) + ";\n";
	  counter++;
        }
      }
    }
    

    msg += "}\n\n";
    return msg;
  }

  private void buildOpcodeList() throws Exception {
    Primitive p;
    Vector v;
    String operandSizeStr, instrLenStr;
    Integer operandSizeInt, instrLenInt;
    Pattern re = Pattern.compile("(\\d*)\\D+(\\d+)"); 
    int opcodesUsed = 0;
    Enumeration e = subCodes.elements();
    
    while (e.hasMoreElements()) {
      operandSizeStr = "0";
      instrLenStr = "1";
      operandSizeInt = new Integer(0);;
      instrLenInt = new Integer(1);
	
      p = (Primitive) e.nextElement();
      //System.err.println("Adding " + p);
      Matcher m = re.matcher((String)p.get("opcode"));
      if (m.matches()) {
	instrLenStr = m.group(1);
	if (!instrLenStr.equals("")) {
          instrLenInt = new Integer(instrLenStr);
	}
	operandSizeStr = m.group(2);
        operandSizeInt = new Integer(operandSizeStr);
      }

      // If an instruction is wider than a single byte,
      // then embedded operand bits are in the additional bytes.
      // E.g., a 2-byte wide instruction with 10 bits of embedded operand
      // only requires 4 instruction slots
      if (instrLenInt.intValue() > 1) {
        operandSizeInt = new Integer(operandSizeInt.intValue() - (8 * (instrLenInt.intValue() -1 )));
        //System.out.println("changing " + p.get("opcode") + " width from " + operandSizeStr + " to " + operandSizeInt);
      }
      
      v = sortedCodes[operandSizeInt.intValue()];
      if (v == null) {
	v = new Vector();
      }
      
      v.add(p);
      //System.out.println("Added " + p + " to " + operandSizeInt + " instruction set.");
      sortedCodes[operandSizeInt.intValue()] = v;
    }
  }

  private String getOpcode(Primitive prim) {
    return (String)prim.get("opcode");
  }

  public static void main(String[] args) throws Exception {
    Vector p = new Vector();
    for (int i = 0; i < args.length; i++) {
      File f = new File(args[i]);
      p.addElement(new Primitive(f));
    }

    DispatchOpcode dop = new DispatchOpcode("test", p);
    System.err.println(dop.getModule());
    System.err.println(dop.getConfiguration());
  }

}
