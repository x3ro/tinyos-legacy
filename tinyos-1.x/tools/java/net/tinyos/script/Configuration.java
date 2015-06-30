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
 * Date:        Sep 30 2003
 * Desc:        Main window for script injector.
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
import net.tinyos.script.tree.*;

public class Configuration {
  private Vector primitives = new Vector();
  private DFTokenizer tokenizer;
  private String className;
  private String name;
  private String desc;
  private String language;
  private boolean hasDeluge = false;
  
  private ConstantMapper capsuleMap;
  private ConstantMapper optionMap;
  private ConstantMapper errorMap;
  private ConstantMapper opcodeMap;
  private ConstantMapper virusMap;
  private ConstantMapper dataMap;


  public Configuration(String filename) throws Exception {
    FileReader reader = new FileReader(filename);
    tokenizer = new DFTokenizer(reader);
    while(tokenizer.hasMoreStatements()) {
      readEntry();
    }
    capsuleMap = new ConstantMapper(className, "MATE_CAPSULE_");
    optionMap = new ConstantMapper(className, "MATE_OPTION_");
    errorMap = new ConstantMapper(className, "MATE_ERROR_");
    opcodeMap = new ConstantMapper(className, "OP_");
    virusMap = new ConstantMapper(className, "MVIRUS_");
    dataMap = new ConstantMapper(className, "MATE_TYPE_");
  }

  public ConstantMapper getCapsuleMap() {return capsuleMap;}
  public ConstantMapper getOptionMap() {return optionMap;}
  public ConstantMapper getErrorMap() {return errorMap;}
  public ConstantMapper getOpcodeMap() {return opcodeMap;}
  public ConstantMapper getVirusMap() {return virusMap;}
  public ConstantMapper getDataMap() {return dataMap;}
  
  public Enumeration functions() {
    return FunctionSet.functionNames();
  }
  
  public String constantClassName() {return className;}
  public String vmName() {return name;}
  public String desc() {return desc;}
  public String language() {return language;}
  public boolean hasDeluge() {return hasDeluge;}
  
  private void readEntry() throws ConfigurationException, IOException, StatementFormatException, OpcodeFormatException {
    DFStatement stmt = null;
    stmt = tokenizer.nextStatement();
    if (stmt == null) {
      return;
    }
    else if (stmt.getType().equals("VM")) {
      readVM(stmt);
    }
    else if (stmt.getType().equals("FUNCTION")) {
      FunctionSet.addFunction(new Function(stmt));
    }
  }
  
  
  private void readVM(DFStatement stmt) throws ConfigurationException {
    if ((className = stmt.get("className")) == null) 
      throw new ConfigurationException("No class name specified for the VM constants.");
    if ((name = stmt.get("name")) == null)
      name = "NONE";
    if ((desc = stmt.get("desc")) == null) 
      desc = "NONE";
    if ((language = stmt.get("language")) == null) 
      throw new ConfigurationException("No language specified: can't compile.");

    hasDeluge = (stmt.get("deluge") != null);
    SymbolTable.setLanguage(language);
  }
  
  public static void main(String[] args) throws Exception {
    String arg = "test.txt";
    if (args.length > 0) {
      arg = args[0];
    }
    Configuration cf = new Configuration(arg);
    System.out.println("File: " + cf.constantClassName());
    Enumeration names = PrimitiveSet.primitiveNames();
    while (names.hasMoreElements()) {
      String name = (String)names.nextElement();
      System.out.println(PrimitiveSet.getPrimitive(name));
    }
  }
  
}
