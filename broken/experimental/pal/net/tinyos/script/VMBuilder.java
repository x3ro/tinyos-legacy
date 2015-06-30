// $Id: VMBuilder.java,v 1.16 2004/02/17 23:06:38 scipio Exp $

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

public class VMBuilder extends JFrame {
  private BuilderMenu  menu;
  private ContextPanel contexts;
  private InstructionPanel instructions;
  private OptionPanel options;
  private AdvancedPanel advanced;
  private boolean showAdvanced = false;
  private PrintWriter configFile;
  private PrintWriter constantsFile;
  private PrintWriter componentFile;
  private File language;

  private String vmName;
  private String vmJavaName;
  private String vmDesc;
    
  public VMBuilder() {
    super("VM Builder");
    TinyLook.setLookAndFeel(this);
	
    contexts = new ContextPanel();
    instructions = new InstructionPanel();
    options = new OptionPanel();
    menu = new BuilderMenu(this);
    advanced = new AdvancedPanel();

    TinyLook.setLookAndFeel(contexts);
    TinyLook.setLookAndFeel(instructions);
    TinyLook.setLookAndFeel(options);
    TinyLook.setLookAndFeel(menu);

    getContentPane().setLayout(new BoxLayout(getContentPane(), BoxLayout.Y_AXIS));
    getContentPane().add(contexts);
    getContentPane().add(instructions);
    getContentPane().add(options);
    setJMenuBar(menu);
    //pack();
    //setVisible(true);
    //repaint();
  }

  public VMBuilder(String filename) {
    VMBuilderFromFile vm = new VMBuilderFromFile(filename);
    try {
      vm.build();
    }
    catch (IOException exception) {
      System.err.println("Error building the VM.");
      exception.printStackTrace();
    }
  }
  
  public Enumeration getContexts() {
    return contexts.getSelectedContexts();
  }

  public Enumeration getCapsules() {
    Vector vector = new Vector();
    Enumeration enum = contexts.getSelectedContexts();
    while (enum.hasMoreElements()) {
      BuilderContext context = (BuilderContext)enum.nextElement();
      vector.addElement(context.capsule());
    }

    enum = instructions.getSelectedInstructions();
    while (enum.hasMoreElements()) {
      Primitive primitive = (Primitive)enum.nextElement();
      Enumeration capsules = primitive.capsules();
      while (capsules.hasMoreElements()) {
	vector.addElement(capsules.nextElement());
      }
    }

    return vector.elements();
  }
  
  public Enumeration getInstructions() {
    Vector instrList = new Vector();
    Enumeration current = instructions.getSelectedInstructions();
    while (current.hasMoreElements()) {
      instrList.addElement(current.nextElement());
    }
    current = contexts.getContextInstructions();
    while (current.hasMoreElements()) {
      instrList.addElement(current.nextElement());
    }
    return instrList.elements();
  }

  public void addInstruction(Primitive instr) {
    instructions.loadInstruction(instr);
  }

  protected void setLanguageFile(File file) {
    language = file;
  }
    
  public void addContext(BuilderContext context) {
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
    vmName = dialog.getName();
    vmJavaName = vmName + "Constants";
    vmDesc = dialog.getDesc();
  }
    
  public void createFiles(File directory) { 
    VMFileGenerator g = new VMFileGenerator(directory, vmName, vmDesc, language, contexts.getSelectedContexts(), instructions.getSelectedInstructions(), advanced);

    try {
      g.createFiles();
    } catch (Exception e) {
      System.err.println("Error generating files:");
      e.printStackTrace();
    }
  }


  public static void main(String[] args) {
    boolean windowed = true;
    String buildFile = "";
    Vector options = new Vector();
    VMBuilder builder;
    for (int i = 0; i < args.length; i++) {
      if (args[i].equals("-nw")) {
	windowed = false;
      }
      else if (args[i].substring(0, 3).equals("-t=") ||
	       args[i].substring(0, 3).equals("-d=") ||
	       args[i].substring(0, 3).equals("-f=") ||
	       args[i].substring(0, 3).equals("-l=")) {
	options.addElement(args[i]);
      }
      else {
	buildFile = args[i];
      }
    }

    if (windowed) {
      builder = new VMBuilder();
    }
    else {
      builder = new VMBuilder(buildFile);
    }

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
    if (windowed) {
      builder.pack();
      builder.setVisible(true);
      builder.repaint();     
    }
  }
	
  protected void actOnFile(File file) {
    String name = file.getName();
    String contextSuffix = "Context.cdf";
    try {
      if (name.endsWith(contextSuffix)) {
	addContext(new BuilderContext(file));
      }
      else if (name.substring(0, 2).equals("OP") &&
	       name.endsWith(".odf")) {
	Primitive p = new Primitive(file);
	addInstruction(p);
      }
    }
    catch (IOException e) {
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
