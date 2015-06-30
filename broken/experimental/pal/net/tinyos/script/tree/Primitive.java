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
import net.tinyos.script.DFStatement;
import net.tinyos.script.DFTokenizer;
import net.tinyos.script.BuilderContext;
import net.tinyos.script.Capsule;

public class Primitive {
  private Hashtable nvPairs;
  private Vector contexts;
  private Vector capsules;
  
  public Primitive(File odFile) throws IOException {
    this.contexts = new Vector();
    this.capsules = new Vector();
    
    FileReader reader = new FileReader(odFile);
    DFTokenizer tokenizer = new DFTokenizer(reader);
    DFStatement stmt = tokenizer.nextStatement();
    
    this.nvPairs = stmt.pairs();

    while(tokenizer.hasMoreStatements()) {
      stmt = tokenizer.nextStatement();
      if (stmt != null) {
	if (stmt.getType().equals("CONTEXT")) {
	  BuilderContext c = new BuilderContext(stmt);
	  contexts.addElement(c);
	}
	else if (stmt.getType().equals("CAPSULE")) {
	  Capsule c = new Capsule(stmt);
	  capsules.addElement(c);
	}
      }
    }
  }

  public Primitive(DFStatement stmt) {
    nvPairs = stmt.pairs();
    this.contexts = new Vector();
    this.capsules = new Vector();
  }

  public Object get(String key) {
    return nvPairs.get(key.toLowerCase());
  }
    
  public String toString() {
    String rval = "<PRIMITIVE ";
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

  public boolean hasContexts() {
    return (!contexts.isEmpty());
  }

  public Enumeration contexts() {
    return contexts.elements();
  }

  public boolean hasCapsules() {
    return (!capsules.isEmpty());
  }
  
  public Enumeration capsules() {
    return capsules.elements();
  }

  public boolean hasLocks() {
    return nvPairs.containsKey("locks");
  }
  
  public static void main(String[] args) throws IOException {
    File f = new File(args[0]);
    Primitive p = new Primitive(f);
    System.out.println(""+p);
    System.out.println(p.contexts());
    Enumeration e = p.capsules();
    while (e.hasMoreElements()) 
      System.out.println(e.nextElement());
  }

  
}
