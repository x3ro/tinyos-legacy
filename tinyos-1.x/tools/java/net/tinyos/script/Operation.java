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
import net.tinyos.script.Context;
import net.tinyos.script.Capsule;
import net.tinyos.script.DFStatement;
import net.tinyos.script.DFTokenizer;
import net.tinyos.script.StatementFormatException;

public abstract class Operation {
  private Hashtable nvPairs;
  private Vector paths = new Vector();
  private Vector capsules = new Vector();
  
  public abstract String getType();
  
  public Operation(File odFile) throws IOException, StatementFormatException {
    FileReader reader = new FileReader(odFile);
    DFTokenizer tokenizer = new DFTokenizer(reader);
    DFStatement stmt = tokenizer.nextStatement();

    if (!stmt.getType().toLowerCase().equals(getType().toLowerCase())) {
      throw new StatementFormatException("Operation of type " + getType() + " used to create a " + stmt.getType());
    }
    
    this.nvPairs = stmt.pairs();

    while(tokenizer.hasMoreStatements()) {
      stmt = tokenizer.nextStatement();
      if (stmt != null) {
	if (stmt.getType().equals("SEARCH")) {
	  String path = stmt.get("PATH");
	  if (path != null &&
	      !path.equals("")) {
	    boolean absolute = (path.charAt(0) == '/');
	    if (!absolute) {
	      File f = new File(odFile.getParentFile(), path);
	      path = f.getAbsolutePath();
	    }
	    path = path.replace('\\', '/');
	    paths.addElement(path);
	  }
	}
	else if (stmt.getType().equals("CAPSULE")) {
	  Capsule c = new Capsule(stmt);
	  capsules.addElement(c);
	}
      }
    }
  }

  public Operation(DFStatement stmt) throws StatementFormatException {
    if (!stmt.getType().toLowerCase().equals(getType().toLowerCase())) {
      throw new StatementFormatException("Operation of type " + getType() + " used to create a " + stmt.getType());
    }
    nvPairs = stmt.pairs();
  }

  public String get(String key) {
    return (String)nvPairs.get(key.toLowerCase());
  }
    
  public String toString() {
    String rval = "<" + getType() + " ";
    String key;
    Object value;
    Enumeration keys = nvPairs.keys();

    while (keys.hasMoreElements()) {
      key = (String)keys.nextElement();
      value = nvPairs.get(key);
      rval += key + "=\"" + value + "\" ";
    }

    rval += ">";
    return rval;
  }

  public String getName() {
    return get("name").toLowerCase();
  }

  public String getOpcode() {
    return get("opcode").toLowerCase();
  }

  public String getComponent() {
    String comp = get("component");
    if (comp == null) {
      return getOpcode();
    }
    return comp;
  }
  
  public boolean hasCapsules() {
    return (!capsules.isEmpty());
  }
  
  public Vector capsules() {
    return new Vector(capsules);
  }

  public boolean hasLocks() {
    return nvPairs.containsKey("locks");
  }


  public boolean hasPaths() {
    return (!paths.isEmpty());
  }

  public Vector paths() {
    return new Vector(paths);
  }
  
  public int width() {
    return 1;
  }

  public int embeddedOperandBits() {
    return 0;
  }

  public int opcodeSlots() {
    int val = (1 << embeddedOperandBits());
    val = val >> (8 * (width() - 1));
    return val;
  }
}
