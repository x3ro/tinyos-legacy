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
package net.tinyos.script;

import java.io.*;
import java.util.*;

public class Language {
  private String name = "UNKNOWN";
  private Vector primitives = new Vector();
  private String description = "UNKNOWN";
  private File languageFile = null;
  private boolean hasFirstOrderFunctions = false;
  
  public Language(File languageFile) throws IOException, StatementFormatException, OpcodeFormatException {
    this.languageFile = languageFile;
    processFile();
  }
  
  public Language(String name, String desc, File languageFile) throws IOException, StatementFormatException, OpcodeFormatException {
    this.name = name;
    this.description = desc;
    this.languageFile = languageFile;
    processFile();
  }
  public boolean hasFirstOrderFunctions() {return hasFirstOrderFunctions;}
  public String getDescription() {return description;}
  public String getName() {return name;}
  public Vector getPrimitives() {
    return new Vector(primitives);
  }
  
  private void processFile() throws IOException, StatementFormatException, OpcodeFormatException {
    DFTokenizer tokenizer = new DFTokenizer(new FileReader(languageFile));
    while (tokenizer.hasMoreStatements()) {
      DFStatement stmt = tokenizer.nextStatement();
      if (stmt == null) {
	continue;
      }
      else if (stmt.getType().toUpperCase().equals("PRIMITIVE")) {
	primitives.add(new Primitive(stmt));
      }
      else if (stmt.getType().toUpperCase().equals("LANGUAGE")) {
	this.name = stmt.get("name");
	this.description = stmt.get("desc");
	if (stmt.get("firstorderfunctions") != null) {
	  this.hasFirstOrderFunctions = true;
	}
      }
      else {
	System.err.println("Non-primitive statement found in language file for \"" + getName() + "\". File: " + languageFile + ", statement: " + stmt);
      }
    }    
    
  }
}
