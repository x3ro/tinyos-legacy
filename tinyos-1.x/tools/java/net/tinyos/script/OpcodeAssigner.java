// $Id: OpcodeAssigner.java,v 1.4 2004/10/21 22:26:37 selfreference Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Mar 31 2004
 * Desc:        Generates a primitive/operation to opcode mapping
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
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.script.tree.*;
import net.tinyos.util.*;
import java.io.*;
import java.util.regex.*;

public class OpcodeAssigner {

  private Vector primitives = new Vector();
  private Vector functions = new Vector();
  private OpcodeTable opcodeTable = new OpcodeTable();
  private FunctionTable functionTable = new FunctionTable();
  private Hashtable fnWeightTable = new Hashtable();
  private boolean assigned = false;
  private boolean isFirstClass = false;
  private int count = 0;
  
  public OpcodeAssigner(boolean isFirstClass) {
    this.isFirstClass = isFirstClass;
  }

  public int numAssigned() {
    return count;
  }
  
  public void addPrimitive(Primitive p) throws OpcodesExhaustedException {
    if ((this.count + p.opcodeSlots()) > 256) {
      throw new OpcodesExhaustedException();
    }
    else {
      this.count += p.opcodeSlots();
      primitives.addElement(p);
    }
  }

  public void addFunction(Function fn) throws OpcodesExhaustedException {
    addFunction(fn, (byte)1);
  }
  public void addFunction(Function fn, byte weight) throws OpcodesExhaustedException {
    if (!isFirstClass) {
      if ((count + 1) > 256) {
	  return;
      }
      else {
	count++;
      }
    }
    boolean inserted = false;
    for (int i = 0; i < functions.size(); i++) {
      Function testFn = (Function)functions.elementAt(i);
      Byte fnWt = (Byte)fnWeightTable.get(testFn.getName().toLowerCase());
      if (weight > fnWt.byteValue()) {
	functions.insertElementAt(fn, i);
	inserted = true;
	break;
      }
    }
    if (!inserted) {
	functions.addElement(fn);
    }
    fnWeightTable.put(fn.getName().toLowerCase(), new Byte(weight));
  }

  public void addPrimitives(Enumeration primitives) throws OpcodesExhaustedException {
    while (primitives.hasMoreElements()) {
      Primitive p = (Primitive)primitives.nextElement();
      addPrimitive(p);
    }
  }

  public void addFunctions(Enumeration primitives) throws OpcodesExhaustedException {
    while (primitives.hasMoreElements()) {
      Function fn = (Function)primitives.nextElement();
      addFunction(fn);
    }
  }
  
  public void assign() {
    int op = 0;
    Enumeration ops = primitives.elements();
    //System.err.println("Adding primitives.");
    while (ops.hasMoreElements()) {
      Primitive p = (Primitive)ops.nextElement();
      opcodeTable.addOpcode(p, op);
      op += p.opcodeSlots();
    }

    ops = functions.elements();
    //System.err.println("Adding " + functions.size() + " functions (" + op + ").");
    while (ops.hasMoreElements() && ((op & 0xff) < 256)) {
      Function func = (Function)ops.nextElement();
      opcodeTable.addOpcode(func, op);
      op++;
    }
    count = op;

    if (isFirstClass) { // Need function identifiers
      short fID = 0;
      ops = functions.elements();
      while (ops.hasMoreElements()) {
	Function fn = (Function)ops.nextElement();
	functionTable.addFunction(fn, fID);
	fID++;
      }
    }
    
    assigned = true;
  }

  public OpcodeTable getOpcodeTable() throws OpcodesUnassignedException {
    return opcodeTable;
  }

  public FunctionTable getFunctionTable() throws OpcodesUnassignedException {
    return functionTable;
  }
}
