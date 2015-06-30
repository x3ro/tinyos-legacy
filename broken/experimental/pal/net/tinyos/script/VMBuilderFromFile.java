// $Id: VMBuilderFromFile.java,v 1.4 2004/03/18 03:42:07 scipio Exp $

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

public class VMBuilderFromFile extends JFrame {
  private String filename;
  private File file;

  private Vector searchPaths;
  private Vector primitives;
  private Vector contexts;
  private Vector languages;
  private Hashtable options;

  private String vmName;
  private String vmDesc;

  private String directoryFileName;
  private File directory;
  
  public VMBuilderFromFile(String filename) {
    this.filename = filename;
  }

  public void build() throws IOException {
    this.file = new File(filename);
    FileReader reader = new FileReader(this.file);

    searchPaths = new Vector();
    primitives = new Vector();
    contexts = new Vector();
    languages = new Vector();
    options = new Hashtable();

    parseFile(reader);
    
    VMFileOptions vmOptions = new VMFileOptions(options);

    directory = new File(directoryFileName);
    if (!directory.exists()) {
      directory.mkdir();
    }

    for (int i = 0; i < searchPaths.size(); i++) {
      vmOptions.addSearchPath((String)searchPaths.elementAt(i));
    }
    
    VMFileGenerator generator = new VMFileGenerator(directory, vmName, vmDesc, (File)languages.firstElement(), contexts.elements(), primitives.elements(), vmOptions);

    generator.createFiles();
  }

  private void parseFile(FileReader reader) throws IOException {
    DFTokenizer tokenizer = new DFTokenizer(reader);

    while(tokenizer.hasMoreStatements()) {
      DFStatement stmt = tokenizer.nextStatement();
      if (stmt == null) {continue;}
      if (stmt.getType().equals("VM")) {
	vmName = stmt.get("NAME");
	vmDesc = stmt.get("DESC");
	directoryFileName = stmt.get("DIR");
      }
      else if (stmt.getType().equals("SEARCH")) {
	searchPaths.addElement(stmt.get("PATH"));
      }
      else if (stmt.getType().equals("LANGUAGE")) {
	String lang = stmt.get("NAME");
	lang = lang + ".ldf";
	languages.addElement(findFile(lang));
      }
      else if (stmt.getType().equals("PRIMITIVE")) {
	String pName = stmt.get("NAME");
	pName = "OP" + pName + ".odf";
	File pFile = findFile(pName);
	Primitive prim = new Primitive(pFile);
	primitives.addElement(prim);
      }
      else if (stmt.getType().equals("CONTEXT")) {
	String cName = stmt.get("NAME") + "Context.cdf";
	File cFile = findFile(cName);
	BuilderContext context = new BuilderContext(cFile);
	System.err.println("Need context " + cName);
	contexts.addElement(context);
      }
      else if (stmt.getType().equals("OPTION")) {
	Hashtable opts = stmt.pairs();
	Enumeration keys = opts.keys();
	while (keys.hasMoreElements()) {
	  String key = (String)keys.nextElement();
	  options.put(key, stmt.get(key));
	}
      }
    }
  }

  private File findFile(String filename) throws IOException {
    Enumeration paths = searchPaths.elements();

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
    
    paths = searchPaths.elements();
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
      options.put("OPDEPTH", "16");
      options.put("CALLDEPTH", "8");
      options.put("BUF_LEN", "10");
      options.put("PGMSIZE", "240");
    }

    public void addSearchPath(String path) {
      paths.addElement(path);
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
    
    public String getProgramSize() {
      return (String)options.get("PGMSIZE");
    }

    public Enumeration getSearchPaths() {
      return paths.elements();
    }
  }
}
