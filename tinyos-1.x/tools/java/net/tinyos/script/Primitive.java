/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, c1opy, modify, and distribute this software and its
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
package net.tinyos.script;

import java.io.*;
import java.util.*;
import java.util.regex.*;

import net.tinyos.script.Context;
import net.tinyos.script.Capsule;
import net.tinyos.script.DFStatement;
import net.tinyos.script.DFTokenizer;
import net.tinyos.script.StatementFormatException;

public class Primitive extends Operation {
  private int width = 1;
  private int embeddedOperandBits = 0;

  public String getType() {
    return "PRIMITIVE";
  }
  
  public Primitive(File odFile) throws IOException, StatementFormatException, OpcodeFormatException {
    super(odFile);
    computeValues();
  }

  public Primitive(DFStatement stmt) throws StatementFormatException, OpcodeFormatException {
    super(stmt);
    computeValues();
  }

  public int width() {
    return width;
  }

  public int embeddedOperandBits() {
    return embeddedOperandBits;
  }

  private void computeValues() throws OpcodeFormatException {
    String opcode = (String)get("opcode");
    Pattern regexp = Pattern.compile("(\\d*)\\D+(\\d+)");
    Matcher m = regexp.matcher(opcode);
    if (m.matches()) {
      Integer instrLen;
      if (!m.group(1).equals("")) {
	instrLen = new Integer(m.group(1));
      }
      else {
	instrLen = new Integer(1);
      }
      Integer operandSize = new Integer(m.group(2));
      this.width = instrLen.intValue();
      this.embeddedOperandBits = operandSize.intValue();
    }
    else {
      // It's a malformed or standard opcode: treat it as a width 1,
      // no embedded operand instruction (by default values).
    }
  }
  
  public static void main(String[] args) throws IOException, StatementFormatException, OpcodeFormatException {
    File f = new File(args[0]);
    Primitive p = new Primitive(f);
    System.out.println(""+p);
    Enumeration e  = p.capsules().elements();
    while (e.hasMoreElements()) 
      System.out.println(e.nextElement());
  }

  
}
