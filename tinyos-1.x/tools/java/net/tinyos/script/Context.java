// $Id: Context.java,v 1.4 2004/11/18 01:08:20 idgay Exp $

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

public class Context {
  private File file;
  private Hashtable nvPairs;
  private Vector functions= new Vector();
  private Vector paths = new Vector();
  private Capsule capsule;
  
  public Context(File file) throws IOException, StatementFormatException {
    FileReader reader = new FileReader(file);
    DFTokenizer tokenizer = new DFTokenizer(reader);
    DFStatement stmt = tokenizer.nextStatement();
    nvPairs = stmt.pairs();

    if (!stmt.getType().equals("CONTEXT")) {
      throw new IOException("Context description file did not describe a context: " + stmt.getType());
    }

    while (tokenizer.hasMoreStatements()) {
      stmt = tokenizer.nextStatement();
      if (stmt != null) {
	if (stmt.getType().equals("SEARCH")) {
	  String path = stmt.get("PATH");
	  if (path != null &&
	      !path.equals("")) {
	    File f = new File(file.getParentFile(), path);
	    paths.addElement(f.getAbsolutePath());
	  }
	}
	else if (stmt.getType().equals("FUNCTION")) {
	  Function fn = new Function(stmt);
	  functions.addElement(fn);
	}
      }
    }
    this.file = file;
    capsule = new Capsule(this);
  }

  public Context(DFStatement statement) {
    nvPairs = statement.pairs();
    functions = new Vector();
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

  public boolean hasFunctions() {
    return !(functions.isEmpty());
  }

  public String get(String name) {
    return (String)nvPairs.get(name.toLowerCase());
  }

  public boolean hasPaths() {
    return (!paths.isEmpty());
  }

  public Vector paths() {
    return new Vector(paths);
  }
  
  public Vector functions() {
    return new Vector(functions);
  }
  
  public void addFunction(Function fn) {
    functions.addElement(fn);
  }

  public Capsule capsule() {
    return capsule;
  }

  public int id() throws InvalidContextException  {
    if (!nvPairs.containsKey("id")) {
      throw new InvalidContextException(name() + " does not have an ID.");
    }
    else {
      Integer i = new Integer(get("id"));
      return i.intValue();
    }
  }
  
}
