// $Id: VMBuilderGui.java,v 1.1 2005/04/28 00:34:04 scipio Exp $

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

public class VMBuilderGui extends JFrame {
  private BuilderMenu  menu;
  private ContextPanel contexts;
  private FunctionPanel functions;
  private OptionPanel options;
  private AdvancedPanel advanced;
  private boolean showAdvanced = false;
  private Language language;
  private VMDescription vmDesc = new VMDescription();
  
  public VMBuilderGui() {
    super("VM Builder");
    TinyLook.setLookAndFeel(this);
	
    contexts = new ContextPanel();
    functions = new FunctionPanel();
    options = new OptionPanel();
    menu = new BuilderMenu(this);
    advanced = new AdvancedPanel();

    TinyLook.setLookAndFeel(contexts);
    TinyLook.setLookAndFeel(functions);
    TinyLook.setLookAndFeel(options);
    TinyLook.setLookAndFeel(menu);

    getContentPane().setLayout(new BoxLayout(getContentPane(), BoxLayout.Y_AXIS));
    getContentPane().add(contexts);
    getContentPane().add(functions);
    //getContentPane().add(options);
    setJMenuBar(menu);
    //pack();
    //setVisible(true);
    //repaint();
  }

  public Language getLanguage() {
    return language;
  }
  
  public Vector getContexts() {
    Vector contextList = new Vector();
    Enumeration current = contexts.getSelectedContexts();
    while (current.hasMoreElements()) {
      contextList.addElement(current.nextElement());
    }
    return contextList;
  }

  public Enumeration getCapsules() {
    Vector vector = new Vector();
    Enumeration conts = contexts.getSelectedContexts();
    while (conts.hasMoreElements()) {
      Context context = (Context)conts.nextElement();
      vector.addElement(context.capsule());
    }

    Enumeration funcs = functions.getSelectedFunctions();
    while (funcs.hasMoreElements()) {
      Function fn = (Function)funcs.nextElement();
      Vector capsules = fn.capsules();
      vector.addAll(capsules);
    }

    return vector.elements();
  }
  
  public Vector getFunctions() {
    Vector fnList = new Vector();
    Enumeration current = functions.getSelectedFunctions();
    while (current.hasMoreElements()) {
      fnList.addElement(current.nextElement());
    }
    current = contexts.getContextFunctions();
    while (current.hasMoreElements()) {
      fnList.addElement(current.nextElement());
    }
    return fnList;
  }

  public void addFunction(Function fn) {
    functions.loadFunction(fn);
  }

  protected void setLanguageFile(File file) throws IOException, StatementFormatException, OpcodeFormatException  {
    language = new Language(file);
  }
    
  public void addContext(Context context) {
    contexts.loadContext(context);
  }
  
  public void showAdvanced(boolean val) {
    if (val != showAdvanced) {
      showAdvanced = val;
      if (showAdvanced) {
	getContentPane().add(advanced);
      }
      else {
	getContentPane().remove(advanced);
      }
      pack();
      repaint();
    }
  }

  public void getDescription() {
    VMDescriptionDialog dialog = new VMDescriptionDialog(this);
    vmDesc.setName(dialog.getName());
    vmDesc.setDescription(dialog.getDesc());
  }
    
  public void createFiles(File directory) {
    vmDesc.setLanguage(getLanguage());
    vmDesc.setContexts(getContexts());
    vmDesc.setFunctions(getFunctions());
    vmDesc.setVMOptions(advanced);
    VMFileGenerator g = new VMFileGenerator(directory, vmDesc);
    try {
      g.createFiles();
    } catch (Exception e) {
      System.err.println("Error generating files:");
      e.printStackTrace();
    }
  }


  public static void main(String[] args) throws Exception {
    Vector options = new Vector();
    for (int i = 0; i < args.length; i++) {
      if (args[i].substring(0, 3).equals("-t=") ||
	  args[i].substring(0, 3).equals("-d=") ||
	  args[i].substring(0, 3).equals("-f=") ||
	  args[i].substring(0, 3).equals("-l=")) {
	options.addElement(args[i]);
      }
    }

    VMBuilderGui builder = new VMBuilderGui();
    for (int i = 0; i < options.size(); i++) {
      String arg = (String)options.elementAt(i);
      if (arg.substring(0, 3).equals("-t=")) {
	String tree = arg.substring(3);
	File file = new File(tree);
	builder.actOnTree(file);
      }
      else if (arg.substring(0, 3).equals("-d=")) {
	String dir = arg.substring(3);
	File file = new File(dir);
	builder.actOnDirectory(file);
      }
      else if (arg.substring(0, 3).equals("-f=")) {
	String filename = arg.substring(3);
	File file = new File(filename);
	builder.actOnFile(file);
      }
      else  if (arg.substring(0, 3).equals("-l=")) {
	String filename = arg.substring(3);
	File file = new File(filename);
	builder.setLanguageFile(file);
      }
    }
    builder.pack();
    builder.setVisible(true);
    builder.repaint();     
  }
	
  protected void actOnFile(File file) {
    String name = file.getName();
    String contextSuffix = "Context.cdf";
    try {
      if (name.endsWith(contextSuffix)) {
	addContext(new Context(file));
      }
      else if (name.substring(0, 2).equals("OP") &&
	       name.endsWith(".odf")) {
	Function f = new Function(file);
	addFunction(f);
      }
    }
    catch (IOException e) {
      System.err.println(e);
    }
    catch (StatementFormatException e) {
      System.err.println(e);
    }
  }

  protected void actOnDirectory(File file) {
    File[] files = file.listFiles();
    for (int i = 0; i < files.length; i++) {
      actOnFile(files[i]);
    }
  }
	
  protected void actOnTree(File file) {
    if (!file.isDirectory()) {
      return;
    }
    File[] files = file.listFiles();
    for (int i = 0; i < files.length; i++) {
      File tempFile = files[i];
      if ((tempFile.getName().equals("opcodes") ||
	   tempFile.getName().equals("contexts")) &&
	  tempFile.isDirectory()) {
	actOnDirectory(tempFile);
      }
    }
  }
      

    
}
