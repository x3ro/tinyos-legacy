// $Id: OpcodeTable.java,v 1.2 2004/07/15 02:54:26 scipio Exp $

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
 * Desc:        Generates VM files from opcodes, contexts, and options.
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.util.*;

public class OpcodeTable {

  private Hashtable nameToBytes;
  private Hashtable nameToDescs;
  
  public OpcodeTable() {
    nameToBytes = new Hashtable();
    nameToDescs = new Hashtable();
  }

  public void addOpcode(Operation op, int val) {
    //System.err.println("Adding opcode (" + nameToDescs.size() + ") " + op);
    String name = op.get("opcode").toLowerCase();
    nameToBytes.put(name, new Integer(val));
    nameToDescs.put(name, op);
  }

  public int getOpcode(String name) throws InvalidInstructionException {
    Integer i = (Integer)nameToBytes.get(name.toLowerCase());
    if (i == null) {
      throw new InvalidInstructionException("No opcode for " + name);
    }
    else {
      return i.intValue();
    }
  }

  public Operation getOperation(String name) throws NoSuchOpcodeException {
    Operation op = (Operation)nameToDescs.get(name.toLowerCase());
    if (op == null) {
      throw new NoSuchOpcodeException("No opcode for " + name);
    }
    else {
      return op;
    }
  }

  public Enumeration getNames() {
    return nameToBytes.keys();
  }

  public Enumeration getNamesSortedNumerically() {
    Vector names = new Vector();
    Enumeration ops = getNames();
    while (ops.hasMoreElements()) {
      String name = (String)ops.nextElement();
      boolean inserted = false;
      for (int i = 0; i < names.size(); i++) {
	String comparison = (String)names.elementAt(i);
	Integer i1 = (Integer)nameToBytes.get(name.toLowerCase());
	Integer i2 = (Integer)nameToBytes.get(comparison.toLowerCase());
	if (i1.intValue() < i2.intValue()) {
	  names.insertElementAt(name, i);
	  inserted = true;
	  break;
	}
      }
      if (!inserted) {
	  names.addElement(name);
      }
    }
    return names.elements();
  }

  public Enumeration getNamesSortedLexicographically() {
    Vector names = new Vector();
    Enumeration ops = getNames();
    //System.err.print("Sorting names: ");
    while (ops.hasMoreElements()) {
      String name = (String)ops.nextElement();
      //System.err.print(name + ", ");
      boolean inserted = false;
      for (int i = 0; i < names.size(); i++) {
	String comparison = (String)names.elementAt(i);
	if (name.compareTo(comparison) < 0) {
	  names.insertElementAt(name, i);
	  inserted = true;
	  break;
	}
      }
      if (!inserted) {
	names.addElement(name);
      }
    }
    //System.err.println();
    return names.elements();
  }
  
}
