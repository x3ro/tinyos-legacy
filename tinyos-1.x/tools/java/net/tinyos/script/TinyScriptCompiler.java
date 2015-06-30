// $Id: TinyScriptCompiler.java,v 1.5 2004/11/30 01:08:49 scipio Exp $

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
 * Date:        April 19 2004
 * Desc:        Compiles TinyScript text to assembly.
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.io.*;
import java.util.*;
import net.tinyos.script.tree.*;
  
public class TinyScriptCompiler {

  private Vector optimizers = new Vector();
  private Program program = null;
  private ConstantMapper opcodeMap = null;
  private ScriptAssembler assembler = null;
  private String assembly = null;
  private String language = null;
  
  public TinyScriptCompiler(Configuration config) {
    this.opcodeMap = config.getOpcodeMap();
    this.language = config.language();
    assembler = new ScriptAssembler(config);
  }

  public void compile(Reader programReader) throws IOException, SemanticException, NoFreeVariableException, CompileException, Exception {
    Parser parser = new Parser(new Yylex(programReader));
    try {
      parser.parse();
    }
    catch (SemanticException e) {
      throw e;
    }
    catch (IOException e) {
      throw e;
    }
    catch (NoFreeVariableException e) {
      throw e;
    }
    catch (Exception e) {
      String msg = parser.errorMessage();
      e.printStackTrace();
      if (msg != null) {
	throw new CompileException(parser.errorMessage(), parser.errorLineNumber());
      }
      else {
	throw e;
      }
    }
      
    Program prog = runOptimizers(Parser.getProgram());
    //System.out.println(prog);
    String asm = assemble(prog);
    program = prog;
    assembly = asm;
    System.out.println(assembly);
  }

  public String getAssembly() throws NoProgramException {
    if (program == null) {
      throw new NoProgramException();
    }
    return assembly;
  }
  
  private String assemble(Program prog) throws NoProgramException, IOException, SemanticException, NoFreeVariableException {
    StringWriter writer = new StringWriter();
    prog.generateCode(new CodeWriter(writer, language));
    return writer.getBuffer().toString();
  }

  public byte[] getBytecodes() throws NoProgramException, SemanticException, IOException, InvalidInstructionException {
    StringReader reader = new StringReader(getAssembly());
    AssemblyTokenizer tokenizer = new AssemblyTokenizer(reader);
    return assembler.toByteCodes(tokenizer);
  }

  public String getByteString() throws NoProgramException, IOException, InvalidInstructionException {
    StringReader reader = new StringReader(getAssembly());
    AssemblyTokenizer tokenizer = new AssemblyTokenizer(reader);
    return assembler.toHexString(tokenizer);
  }

  public void addOptimizer(TinyScriptOptimizer optimizer) {
    optimizers.add(optimizer);
  }

  public Program getProgram() throws NoProgramException {
    if (program == null) {throw new NoProgramException();}
    else {
      return program;
    }
  }
  
  private Program runOptimizers(Program prog) {
    return prog;
  }

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("usage: net.tinyos.script.TinyScriptCompiler <filename>");
      return;
    }
    FileReader r = new FileReader(args[0]);
    TinyScriptCompiler c = new TinyScriptCompiler(new Configuration("vm.vmdf"));
    c.compile(r);
  }
}
