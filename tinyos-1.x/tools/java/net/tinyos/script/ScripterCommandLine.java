/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
 * Date:        Jun 13 2004
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
import java.util.regex.*;
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.script.tree.*;
import vm_specific.*;

public class ScripterCommandLine implements net.tinyos.message.MessageListener {

  private MoteIF moteIF;
  private Configuration config;
  private ScriptInjector injector;
  private ProgramState programState;
  
  public ScripterCommandLine(MoteIF moteIF,
			     String configFileName,
			     String programFileName) throws Exception {
    
    this.moteIF = moteIF;
    config = new Configuration(configFileName);
    programState = new ProgramState(programFileName);
    injector = new ScriptInjector(moteIF, config.getVirusMap());
  }

  public void inject(String scriptFile, String contextName)  {
    try {
      TinyScriptCompiler compiler;
      String program = readProgram(scriptFile);

      System.out.println("Program: \n" + program);
      compiler = new TinyScriptCompiler(config);
      compiler.compile(new StringReader(program));
      byte[] code = compiler.getBytecodes();
      byte options = 0;
      byte context = config.getCapsuleMap().nameToCode(contextName.toUpperCase());
      int version = programState.getVersion(contextName);
      
      injector.inject(code, context, options, version);
      programState.update(contextName, program, compiler.getProgram());
      programState.writeState();
    }
    catch (SemanticException e) {
      //programPanel.highlightLine(e.lineNumber());
      System.err.println("Semantic error on line " + e.lineNumber() + ":\n" + e.getMessage());
    }
    catch (CompileException e) {
      //programPanel.highlightLine(e.lineNumber());
      System.err.println("Compilation error on line " + e.lineNumber() + ":\n" +  e.getMessage());
    }
    catch (InvalidInstructionException e) {
      System.err.println("Compiler generated invalid instruction. Are the scripter and VM up to date? Error: " + e.getMessage());
      e.printStackTrace();
    }
    catch (IOException e) {
      System.err.println("Error compiling program to assembly: " + e);
      e.printStackTrace();
    }
    catch (Exception e) {
      System.err.println("Compilation error: " + e.getMessage());
      e.printStackTrace();
    }
  }

  private String readProgram(String scriptFile) throws IOException {
    File file = new File(scriptFile);
    String program = "";
    BufferedReader reader = new BufferedReader(new FileReader(file));
    String line = "";
    while(line != null) {
      program += line + "\n";
      line = reader.readLine();
    }

    return program;
  }

  public void messageReceived(int to, Message message) {
    BombillaErrorMsg msg = (BombillaErrorMsg)message;
    String context = config.getCapsuleMap().codeToName((byte)msg.get_context());
    String cause = config.getErrorMap().codeToName((byte)msg.get_reason());
    String capsule = config.getCapsuleMap().codeToName((byte)msg.get_capsule());
    String instruction = "" + msg.get_instruction();

    System.err.println("Error received:");
    System.err.println("  Context:     " + context);
    System.err.println("  Cause:       " + cause);
    System.err.println("  Capsule:     " + capsule);
    System.err.println("  Instruction: " + instruction);
    System.err.println();
  }
}
