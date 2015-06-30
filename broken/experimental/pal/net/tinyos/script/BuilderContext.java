// $Id: BuilderContext.java,v 1.4 2004/02/17 23:06:37 scipio Exp $

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
 * Date:        Sep 26 2003
 * Desc:        Main window for VM builder
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
import net.tinyos.util.*;

import net.tinyos.script.tree.Primitive;

public class BuilderContext {
  private File file;
  private Hashtable nvPairs;
  private Vector primitives;
  private Capsule capsule;
  
  public BuilderContext(File file) throws IOException {
    this.primitives = new Vector();
    FileReader reader = new FileReader(file);
    DFTokenizer tokenizer = new DFTokenizer(reader);
    DFStatement stmt = tokenizer.nextStatement();
    nvPairs = stmt.pairs();

    if (!stmt.getType().equals("CONTEXT")) {
      throw new IOException("Context description file did not describe a context: " + stmt.getType());
    }

    while (tokenizer.hasMoreStatements()) {
      stmt = tokenizer.nextStatement();
      if (stmt != null &&
	  stmt.getType().equals("PRIMITIVE")) {
	Primitive prim = new Primitive(stmt);
	primitives.addElement(prim);
      }
    }
    
    this.file = file;
    capsule = new Capsule(this);
  }

  public BuilderContext(DFStatement statement) {
    nvPairs = statement.pairs();
    primitives = new Vector();
    capsule = new Capsule(this);
    file = null;
  }
  
  public String toString() {
    String rval = "<CONTEXT ";
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

  public String name() {
    return get("name");
  }

  public boolean hasPrimitives() {
    return !(primitives.isEmpty());
  }

  public String get(String name) {
    return (String)nvPairs.get(name.toLowerCase());
  }

  public Enumeration primitives() {
    return primitives.elements();
  }
  
  public void addPrimitive(Primitive p) {
    primitives.addElement(p);
  }

  public Capsule capsule() {
    return capsule;
  }
  
}
