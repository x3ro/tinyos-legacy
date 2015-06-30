// $Id: VMBuilderFromFile.java,v 1.7 2005/04/28 00:34:04 scipio Exp $

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
import net.tinyos.script.tree.*;
import net.tinyos.util.*;
import java.io.*;
import java.util.regex.*;

public class VMBuilderFromFile {
  private String filename;
  private File file;

  private Hashtable options;
  private VMDescription description;
  
  private String directoryFileName;
  private File directory;
  
  public VMBuilderFromFile(String filename) {
    this.filename = filename;
  }

  public void build() throws IOException, StatementFormatException, OpcodeFormatException, InvalidInstructionException, ConfigurationException, InvalidContextException, InvalidHandlerException {
    file = new File(filename);
    description = new VMDescription();
    options = new Hashtable();

    parseFile(file);
    
    VMFileOptions vmOptions = new VMFileOptions(options);
    description.setVMOptions(vmOptions);

    checkFile();
    directory = new File(directoryFileName);
    if (!directory.exists()) {
      directory.mkdir();
    }
    
    VMFileGenerator generator = new VMFileGenerator(directory, description);
    generator.createFiles();
  }

  private void checkFile() throws ConfigurationException {
    if (directoryFileName == null) {
      throw new ConfigurationException("VM element must include a DIR tag, which states where to put the VM code.");
    }
    if (description.getName() == null ||
	description.getName().equals("")) {
      throw new ConfigurationException("VM element must include a NAME tag.");
    }
    if (description.getLanguage() == null) {
      throw new ConfigurationException("There must be a LANGUAGE element, with a NAME tag indicating which language to use.");
    }
    if (description.getContexts().size() == 0) {
      throw new ConfigurationException("A VM must have at least one context.");
    }
  }
  
  private void parseFile(File file) throws IOException, StatementFormatException, OpcodeFormatException, ConfigurationException {
    FileReader reader = new FileReader(file);
    DFTokenizer tokenizer = new DFTokenizer(reader);

    while(tokenizer.hasMoreStatements()) {
      DFStatement stmt = tokenizer.nextStatement();
      if (stmt == null) {continue;}
      if (stmt.getType().equals("VM")) {
	description.setName(stmt.get("NAME"));
	description.setDescription(stmt.get("DESC"));
	directoryFileName = stmt.get("DIR");
      }
      else if (stmt.getType().equals("SENSORBOARD")) {
	String name  = stmt.get("NAME");
	description.setSensorboard(name);
      }
      else if (stmt.getType().equals("SEARCH")) {
	File path  = new File(file.getParentFile(), stmt.get("PATH"));
	description.addPath(path.getAbsolutePath());
      }
      else if (stmt.getType().equals("LANGUAGE")) {
	String lName = stmt.get("NAME");
	lName += ".ldf";
	Language language = new Language(findFile(lName));
	description.setLanguage(language);
      }
      else if (stmt.getType().equals("FUNCTION")) {
	String fnName = stmt.get("NAME");
	fnName = "OP" + fnName + ".odf";
	File fnFile = findFile(fnName);
	Function func = new Function(fnFile);
	description.addFunction(func);
      }
      else if (stmt.getType().equals("CONTEXT")) {
	String cName = stmt.get("NAME") + "Context.cdf";
	File cFile = findFile(cName);
	Context context = new Context(cFile);
	description.addContext(context);
      }
      else if (stmt.getType().equals("OPTION")) {
	Hashtable opts = stmt.pairs();
	Enumeration keys = opts.keys();
	while (keys.hasMoreElements()) {
	  String key = (String)keys.nextElement();
	  options.put(key.toUpperCase(), stmt.get(key));
	}
      }
      else if (stmt.getType().equals("LOAD")) {
	String fName = stmt.get("FILE");
	parseFile(new File(fName));
      }
      else {
	System.err.println("Unknown file command, ignoring: " + stmt.getType());
      }
    }
  }

  private File findFile(String filename) throws IOException {
    Enumeration paths = description.getPaths().elements();

    while (paths.hasMoreElements()) {
      String path = (String)paths.nextElement();
      File file = new File(path);
      if (filename.equals(file.getName())) {
	return file;
      }
      else if (file.isDirectory()) {
	File[] files = file.listFiles();
	for (int i = 0; i < files.length; i++) {
	  if (filename.equals(files[i].getName())) {
	    return files[i];
	  }
	}
      }
    }
    String msg = "File " + filename + " not found in search path:\n";
    
    paths = description.getPaths().elements();
    while (paths.hasMoreElements()) {
      msg += "\t" + paths.nextElement() + "\n";
    }
    throw new IOException(msg);
  }
  
  private class VMFileOptions implements VMOptions {
    private Hashtable options;
    private Vector paths;
    
    public VMFileOptions(Hashtable options) {
      this.options = options;
      paths = new Vector();
      if (!options.containsKey("OPDEPTH")) {
	options.put("OPDEPTH", "8");
      }
      if (!options.containsKey("CALLDEPTH")) {
	options.put("CALLDEPTH", "8");
      }
      if (!options.containsKey("BUF_LEN")) {
	options.put("BUF_LEN", "10");
      }
      if (!options.containsKey("HANDLER_SIZE")) {
	options.put("HANDLER_SIZE", "128");
      }
      if (!options.containsKey("CAPSULE_SIZE")) {
	options.put("CAPSULE_SIZE", "128");
      }
    }

    public String getOpDepth() {
      return (String)options.get("OPDEPTH");
    }
    
    public String getCallDepth() {
      return (String)options.get("CALLDEPTH");
    }
    
    public String getBufLen() {
      return (String)options.get("BUF_LEN");
    }
    
    public String getCapsuleSize() {
      return (String)options.get("CAPSULE_SIZE");
    }

    public String getHandlerSize() {
      return (String)options.get("HANDLER_SIZE");
    }

    public boolean hasDeluge() {
      return ((String)options.get("DELUGE") != null);
    }

  }
}
