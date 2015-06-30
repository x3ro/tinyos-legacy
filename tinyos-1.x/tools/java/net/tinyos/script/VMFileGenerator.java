
// $Id: VMFileGenerator.java,v 1.15 2005/05/19 17:52:12 idgay Exp $

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
 * Date:        Jan 6 2004
 * Desc:        Generates VM files from opcodes, contexts, and options.
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

public class VMFileGenerator {
  private File directory;
  private VMDescription vmDesc;
  private String javaName;
  
  public VMFileGenerator(File directory, VMDescription description) {
    this.directory = directory;
    this.vmDesc = description;
    this.javaName = description.getName() + "Constants";
  }

  /**
   * Return the set of selected contexts.
   */
  
  private Enumeration getContexts() {
    return vmDesc.getContexts().elements();
  }

  /**
   * Return the set of language primitives.
   */
  
  private Enumeration getPrimitives() {
    return vmDesc.getPrimitives().elements();
  }

  /**
   * Return the set of explicitly added functions.
   */
  
  private Enumeration getSelectedFunctions() {
    return vmDesc.getFunctions().elements();
  }

  private Enumeration getPaths() {
    Vector paths = new Vector(vmDesc.getPaths());
    Enumeration functions = getAllFunctions();
    while (functions.hasMoreElements()) {
      Operation op = (Operation)functions.nextElement();
      paths.addAll(op.paths());
    }

    Enumeration contexts = getContexts();
    while (contexts.hasMoreElements()) {
      Context ctx = (Context)contexts.nextElement();
      paths.addAll(ctx.paths());
    }

    // Now change the paths to proper Unix paths
    Enumeration elements = paths.elements();

    paths = new Vector();
    while (elements.hasMoreElements()) {
      String path = (String)elements.nextElement();
      path = path.replace('\\', '/');
      paths.addElement(path);
    }
    return paths.elements();
  }
  
  /**
   * Return the full set of functions, including those included by contexts.
   */
  
  private Enumeration getAllFunctions() {
    Vector funcs = vmDesc.getFunctions();
    Enumeration contexts = getContexts();
    while (contexts.hasMoreElements()) {
      Context context = (Context)contexts.nextElement();
      if (context.hasFunctions()) {
	funcs.addAll(context.functions());
      }
    }
    return funcs.elements();
  }
  
  
  /**
   * Return the set of capsules determined by contexts and primitives.
   */
  
  private Enumeration getCapsules() {
     Vector vector = new Vector();
     Enumeration contexts = getContexts();
     while (contexts.hasMoreElements()) {
       Context context = (Context)contexts.nextElement();
       vector.addElement(context.capsule());
     }

     Enumeration primitives = getPrimitives() ;
     while (primitives.hasMoreElements()) {
       Primitive primitive = (Primitive)primitives.nextElement();
       Vector capsules = primitive.capsules();
       vector.addAll(capsules);
     }
     
     Enumeration functions = getAllFunctions();
     while (functions.hasMoreElements()) {
       Function fn = (Function)functions.nextElement();
       Vector capsules = fn.capsules();
       vector.addAll(capsules);
     }

     return vector.elements();
  }

  private Enumeration getHandlers() {
    Vector vector = new Vector();
    Enumeration contexts = getContexts();
    while (contexts.hasMoreElements()) {
      Context context = (Context)contexts.nextElement();
      vector.addElement(context.capsule());
    }
    
    Enumeration primitives = getPrimitives() ;
    while (primitives.hasMoreElements()) {
      Primitive primitive = (Primitive)primitives.nextElement();
      Vector capsules = primitive.capsules();
      vector.addAll(capsules);
    }
    
    Enumeration functions = getAllFunctions();
    while (functions.hasMoreElements()) {
      Function fn = (Function)functions.nextElement();
      Vector capsules = fn.capsules();
      vector.addAll(capsules);
    }
    
    return vector.elements();
  }
  
  /**
   * Generate an array of vectors of all instructions, sorted by how
   * many bits of opcode space they consume. For example, instructions
   * in element 0 in the array consume 0 bits, that is, have a single
   * opcode value, while instructions in element 2 of the array
   * consume 2 bits, that is, have 4 opcode values.
   */
  
  public void createFiles() throws IOException, StatementFormatException, InvalidInstructionException, InvalidContextException, InvalidHandlerException { 
    OpcodeTable opTable;
    FunctionTable fnTable;
    OpcodeAssigner assigner;
    try {
      assigner = new OpcodeAssigner(vmDesc.getLanguage().hasFirstOrderFunctions());
      assigner.addPrimitives(getPrimitives());
      assigner.addFunctions(getAllFunctions());
      assigner.assign();
      opTable = assigner.getOpcodeTable();
      fnTable = assigner.getFunctionTable();
    }
    catch (OpcodesUnassignedException exception) {
      System.err.println("Error allocating opcodes, aborting build: " + exception);
      return;
    }
    catch (OpcodesExhaustedException exception) {
      System.err.println("Too many instructions. Remove some selected functions. Aborting build.");
      System.err.println(exception);
      return;
    }
    System.err.println("Writing VM to directory " + directory.getCanonicalPath());
    System.err.println("  config file vm.vmdf");
    File configFile = new File(directory, "vm.vmdf");
    PrintWriter configWriter = new PrintWriter(new FileWriter(configFile), true);
    createConfigFile(configWriter);
    
    System.err.println("  constants file MateConstants.h");
    File constantsFile = new File(directory, "MateConstants.h");
    PrintWriter constantsWriter = new PrintWriter(new FileWriter(constantsFile), true);
    createConstantsFile(constantsWriter, opTable, fnTable);
    System.err.println("    " + assigner.numAssigned() + " of 256 opcodes used.");
    
    System.err.println("  component file MateTopLevel.nc");
    File componentsFile = new File(directory, "MateTopLevel.nc");
    PrintWriter componentsWriter = new PrintWriter(new FileWriter(componentsFile), true);
    createComponentFile(componentsWriter, opTable, fnTable);
    
    System.err.println("  Makefile");
    File makefileFile = new File(directory, "Makefile");
    PrintWriter makefileWriter = new PrintWriter(new FileWriter(makefileFile), true);
    createMakefile(makefileWriter);
      
  }

  private void createMakefile(PrintWriter writer) {

    writer.println("COMPONENT=MateTopLevel");
    writer.println("MATE_FILES=MateConstants.h MateTopLevel.nc vm.vmdf");
    writer.println("JAVADIR=vm_specific");
    writer.println("MSG_SIZE=" + vmDesc.getMessageSize());
    writer.println("CONSTANTS+=-DSEND_QUEUE_SIZE=8 -DMHOP_QUEUE_SIZE=4 -DTOS_MAX_TASKS_LOG2=4");
    writer.println();
    writer.println("BUILD_EXTRA_DEPS+=  $(JAVADIR)/" + javaName + ".class \\");
    writer.println("                    $(JAVADIR)/MateBCastMsg.class\\");
    writer.println("                    $(JAVADIR)/MateBufferMsg.class\\");
    writer.println("                    $(JAVADIR)/MateUARTMsg.class\\");
    writer.println("                    $(JAVADIR)/MateMultiHopMsg.class\\");
    writer.println("                    $(JAVADIR)/CapsuleChunkMsg.class \\");
    writer.println("                    $(JAVADIR)/CapsuleMsg.class \\");
    writer.println("                    $(JAVADIR)/CapsuleStatusMsg.class");
    writer.println();
    writer.print("CFLAGS+=");
    Enumeration paths = getPaths();
    while (paths.hasMoreElements()) {
      writer.print("\"-I" + paths.nextElement() + "\" ");
    }
    writer.println(" -I%T/lib/VM/components -I%T/lib/VM/opcodes -I%T/lib/VM/contexts -I%T/lib/VM/types -I%T/lib/VM/interfaces -I%T/lib/Queue -I. $(CONSTANTS)");
    writer.println();
    if (vmDesc.getVMOptions().hasDeluge()) {
      writer.println("# Support for Deluge reprogramming included");
      writer.println("TINYOS_NP = BNP");
      writer.println();
    }
    writer.println("include ../Makerules");
    writer.println();
    writer.println("$(JAVADIR)/" + javaName + ".java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tncg java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific." + javaName + " MateTopLevel.nc MateConstants.h -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("$(JAVADIR)/MateBCastMsg.java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tmig java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific.MateBCastMsg ../../tos/lib/VM/types/Mate.h MateBCastMsg -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("$(JAVADIR)/MateUARTMsg.java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tmig java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific.MateUARTMsg ../../tos/lib/VM/types/Mate.h MateUARTMsg -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("$(JAVADIR)/CapsuleMsg.java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tmig java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific.CapsuleMsg ../../tos/lib/VM/types/Mate.h MateCapsuleMsg -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("$(JAVADIR)/CapsuleChunkMsg.java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tmig java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific.CapsuleChunkMsg ../../tos/lib/VM/types/Mate.h MateCapsuleChunkMsg -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("$(JAVADIR)/CapsuleStatusMsg.java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tmig java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific.CapsuleStatusMsg ../../tos/lib/VM/types/Mate.h MateCapsuleStatusMsg -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("$(JAVADIR)/MateMultiHopMsg.java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tmig java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific.MateMultiHopMsg ../../tos/lib/VM/types/mhop.h MateRouteMsg -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("$(JAVADIR)/MateBufferMsg.java: $(MATE_FILES)");
    writer.println("\tmkdir -p $(JAVADIR)");
    writer.println("\tmig java $(CFLAGS) $(PFLAGS) -java-classname=vm_specific.MateBufferMsg ../../tos/lib/VM/types/Mate.h MateBufferMsg -o $@ -DTOSH_DATA_LENGTH=$(MSG_SIZE)");
    writer.println();
    writer.println("%.class: %.java");
    writer.println("\tjavac $<");
    writer.println();
    writer.println("$(JAVADIR)/" + javaName + ".class: $(JAVADIR)/" + javaName + ".java");
    writer.println("\tjavac $<");
    writer.println();
    writer.println("$(JAVADIR)/CapsuleMsg.class: $(JAVADIR)/CapsuleMsg.java");
    writer.println("\tjavac $<");
    writer.println();
    writer.println("$(JAVADIR)/CapsuleChunkMsg.class: $(JAVADIR)/CapsuleChunkMsg.java");
    writer.println("\tjavac $<");
    writer.println();
    writer.println("$(JAVADIR)/CapsuleStatusMsg.class: $(JAVADIR)/CapsuleStatusMsg.java");
    writer.println("\tjavac $<");
    writer.println();
    writer.println("cleanmig:");
    writer.println("\trm -f $(BUILD_EXTRA_DEPS)");
    writer.println();
    writer.println("clean: cleanmig");
    writer.println("\trm -rf build/ $(JAVADIR)/");
    writer.println("\trm -f core.* *.class *.java");
    writer.println("\trm -f programs.txt");
    writer.println("\trm -f *~");
    writer.flush();
  }
	
  private void createConfigFile(PrintWriter writer) {
    writer.println("<VM name=\"" + vmDesc.getName() + "\" desc=\"" + vmDesc.getDescription() + "\" language=\"" + vmDesc.getLanguage().getName() + "\" className=\"vm_specific." + javaName + "\" " + (vmDesc.getVMOptions().hasDeluge()? "DELUGE=TRUE": "") + " >");

    Enumeration ops = getPrimitives();
    while (ops.hasMoreElements()) {
      Primitive p = (Primitive)ops.nextElement();
      writer.println(p);
    }
    writer.println();
    
    ops = getAllFunctions();
    while (ops.hasMoreElements()) {
      Function fn = (Function)ops.nextElement();
      writer.println(fn);
    }
    writer.println();

    Enumeration contexts = getContexts();
    while (contexts.hasMoreElements()) {
      Context bc = (Context)contexts.nextElement();
      writer.println(bc);
    }
    
    writer.flush();
  }

  private void createConstantsFile(PrintWriter writer, OpcodeTable opTable, FunctionTable fnTable) throws InvalidInstructionException, InvalidContextException, InvalidHandlerException {
    int counter = 0;
    String opcode;
    Vector v;
    Primitive p;
    Context c;
    Enumeration elements;
    Capsule capsule;
    VMOptions options = vmDesc.getVMOptions();
    
    writer.println("#ifndef BOMBILLA_CONSTANTS_H_INCLUDED");
    writer.println("#define BOMBILLA_CONSTANTS_H_INCLUDED\n");
    writer.println("typedef enum {");
    writer.println("  MATE_OPTION_FORWARD     = 0x80,");
    writer.println("  MATE_OPTION_FORCE       = 0x40,");
    writer.println("  MATE_OPTION_MASK        = 0x3f,");
    writer.println("} MateCapsuleOptions;");
    writer.println();
    writer.println("typedef enum {");
    writer.println("  MHOplaceholder,");
    writer.println("} MateHandlerOptions;");
    writer.println();
    writer.println("typedef enum {");

    elements = getContexts();
    while (elements.hasMoreElements()) {
      c = (Context)elements.nextElement();
      String context = c.name();
      context = context.toUpperCase();
      writer.println("  MATE_CONTEXT_GLOBAL" + context + "\t = " + c.id() + ",");
      writer.println("  MATE_CONTEXT_" + context + "\t = unique(\"MateContextID\"),");
    }
    writer.println("  MATE_CONTEXT_NUM\t = unique(\"MateContextID\"),");
    writer.println("  MATE_CONTEXT_INVALID = 255");
    writer.println("} MateContextID;");

    
    writer.println("typedef enum {");
    elements = getHandlers();
    while (elements.hasMoreElements()) {
      capsule = (Capsule)elements.nextElement();
      String cName = capsule.name();
      cName = cName.toUpperCase();
      writer.println("  MATE_HANDLER_GLOBAL_" + cName + "\t = " + capsule.id() + ",");
      writer.println("  MATE_HANDLER_" + cName + "\t = unique(\"MateHandlerID\"),");
    }
    writer.println("  MATE_HANDLER_NUM\t = unique(\"MateHandlerID\"),");
    writer.println("  MATE_HANDLER_INVALID = 255");
    writer.println("} MateHandlerID;\n");

    writer.println("typedef enum {");
    elements = getCapsules();
    while (elements.hasMoreElements()) {
      capsule = (Capsule)elements.nextElement();
      String cName = capsule.name();
      cName = cName.toUpperCase();
      writer.println("  MATE_CAPSULE_" + cName + "\t = unique(\"MateCapsuleID\"),");
    }
    writer.println("  MATE_CAPSULE_NUM\t = unique(\"MateCapsuleID\"),");
    writer.println("  MATE_CAPSULE_INVALID = 255");
    writer.println("} MateCapsuleID;\n");

    writer.println("enum {");
    writer.println("  MATE_CALLDEPTH    = " + options.getCallDepth() + ",");
    writer.println("  MATE_OPDEPTH      = " + options.getOpDepth() + ",");
    writer.println("  MATE_LOCK_COUNT   = uniqueCount(\"MateLock\"),");
    writer.println("  MATE_BUF_LEN      = " + options.getBufLen() + ",");
    writer.println("  MATE_CAPSULE_SIZE = " + options.getCapsuleSize() + ",");
    writer.println("  MATE_HANDLER_SIZE = " + options.getHandlerSize() + ",");
    writer.println("  MATE_CPU_QUANTUM  = 4,");
    writer.println("  MATE_CPU_SLICE    = 5,");
    writer.println("} MateSizeConstants;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_TYPE_NONE      = 0,");
    writer.println("  MATE_TYPE_BUFFER    = 1,");
    writer.println("  MATE_TYPE_INTEGER   = 32,");
    writer.println("  MATE_TYPE_MSBPHOTO  = 48,");
    writer.println("  MATE_TYPE_MSBTEMP   = 49,");
    writer.println("  MATE_TYPE_MSBMIC    = 50,");
    writer.println("  MATE_TYPE_MSBMAGX   = 51,");
    writer.println("  MATE_TYPE_MSBMAGY   = 52,");
    writer.println("  MATE_TYPE_MSBACCELX = 53,");
    writer.println("  MATE_TYPE_MSBACCELY = 54,");
    writer.println("  MATE_TYPE_THUM      = 55,");
    writer.println("  MATE_TYPE_TTEMP     = 56,");
    writer.println("  MATE_TYPE_TPAR      = 57,");
    writer.println("  MATE_TYPE_TTSR      = 58,");
    writer.println("  MATE_TYPE_VOLTAGE   = 59,");
    writer.println("  MATE_TYPE_END       = 60");
    writer.println("} MateDataType;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_STATE_HALT,");
    writer.println("  MATE_STATE_WAITING,");
    writer.println("  MATE_STATE_READY,");
    writer.println("  MATE_STATE_RUN,");
    writer.println("  MATE_STATE_BLOCKED,");
    writer.println("} MateContextState;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_ERROR_TRIGGERED,");
    writer.println("  MATE_ERROR_INVALID_RUNNABLE,");
    writer.println("  MATE_ERROR_STACK_OVERFLOW,");
    writer.println("  MATE_ERROR_STACK_UNDERFLOW,");
    writer.println("  MATE_ERROR_BUFFER_OVERFLOW,");
    writer.println("  MATE_ERROR_BUFFER_UNDERFLOW,");
    writer.println("  MATE_ERROR_INDEX_OUT_OF_BOUNDS,");
    writer.println("  MATE_ERROR_INSTRUCTION_RUNOFF,");
    writer.println("  MATE_ERROR_LOCK_INVALID,");
    writer.println("  MATE_ERROR_LOCK_STEAL,");
    writer.println("  MATE_ERROR_UNLOCK_INVALID,");
    writer.println("  MATE_ERROR_QUEUE_ENQUEUE,");
    writer.println("  MATE_ERROR_QUEUE_DEQUEUE,");
    writer.println("  MATE_ERROR_QUEUE_REMOVE,");
    writer.println("  MATE_ERROR_QUEUE_INVALID,");
    writer.println("  MATE_ERROR_RSTACK_OVERFLOW,");
    writer.println("  MATE_ERROR_RSTACK_UNDERFLOW,");
    writer.println("  MATE_ERROR_INVALID_ACCESS,");
    writer.println("  MATE_ERROR_TYPE_CHECK,");
    writer.println("  MATE_ERROR_INVALID_TYPE,");
    writer.println("  MATE_ERROR_INVALID_LOCK,");
    writer.println("  MATE_ERROR_INVALID_INSTRUCTION,");
    writer.println("  MATE_ERROR_INVALID_SENSOR,");
    writer.println("  MATE_ERROR_INVALID_HANDLER,");
    writer.println("  MATE_ERROR_ARITHMETIC,");
    writer.println("  MATE_ERROR_SENSOR_FAIL,");
    writer.println("} MateErrorCode;\n");
  
    writer.println("enum {");
    writer.println("  AM_MATEUARTMSG    = 0x19,");
    writer.println("  AM_MATEBCASTMSG   = 0x1a,");
    writer.println("  AM_MATEROUTEMSG         = 0x1b,");
    writer.println("  AM_MATEVERSIONMSG       = 0x1c,");
    writer.println("  AM_MATEVERSIONREQUESTMSG= 0x22,");
    writer.println("  AM_MATEERRORMSG         = 0x1d,");
    writer.println("  AM_MATECAPSULEMSG       = 0x1e,");
    writer.println("  AM_MATEPACKETMSG        = 0x1f,");
    writer.println("  AM_MATECAPSULECHUNKMSG  = 0x20,");
    writer.println("  AM_MATECAPSULESTATUSMSG = 0x21,");
    writer.println("};\n");

    writer.println("typedef enum { // instruction set");
    Enumeration ops = opTable.getNamesSortedNumerically();
    while (ops.hasMoreElements()) {
      String name = (String)ops.nextElement();
      int val = opTable.getOpcode(name);
      writer.println("  OP_" + name.toUpperCase() + " = \t0x" + Integer.toHexString(val) + ",");
    }
    writer.println("} MateInstruction;");
    writer.println();

    writer.println("typedef enum { // Function identifiers");
    Enumeration fns = fnTable.getNames();
    while (fns.hasMoreElements()) {
      String name = (String)fns.nextElement();
      writer.println("  fn_" + name + " = unique(\"MateFunctionID\"),");
    }
    writer.println("  MFIplaceholder,");
    writer.println("} MateFunctionID;");;
    writer.println();
    
    writer.println("/*");
    writer.println(" * MVirus uses the Trickle algorithm for code propagation and maintenance.");
    writer.println(" * A full description and evaluation of the algorithm can be found in");
    writer.println(" *");
    writer.println(" * Philip Levis, Neil Patel, David Culler, and Scott Shenker.");
    writer.println(" * \"Trickle: A Self-Regulating Algorithm for Code Propagation and Maintenance");
    writer.println(" * in Wireless Sensor Networks.\" In Proceedings of the First USENIX/ACM");
    writer.println(" * Symposium on Networked Systems Design and Implementation (NSDI 2004).");
    writer.println(" *");
    writer.println(" * A copy of the paper can be downloaded from Phil Levis' web site:");
    writer.println(" *        http://www.cs.berkeley.edu/~pal/");
    writer.println(" *");
    writer.println(" * A brief description of the algorithm can be found in the comments");
    writer.println(" * at the head of MVirus.nc.");
    writer.println(" *");
    writer.println(" */");
    writer.println();
    writer.println("typedef enum {");
    writer.println("  /* These first two constants define the granularity at which t values");
    writer.println("     are calculated (in ms). Version vectors and capsules have separate");
    writer.println("     timers, as version timers decay (lengthen) while capsules timers");
    writer.println("     are constant, as they are not a continuous process.*/");
    writer.println("  MVIRUS_VERSION_TIMER = 100,           // The units of time (ms)");
    writer.println("  MVIRUS_CAPSULE_TIMER = 100,           // The units of time (ms)");
    writer.println("");
    writer.println("  /* These constants define how many times a capsule is transmitted,");
    writer.println("     the timer interval for Trickle suppression, and the redundancy constant");
    writer.println("     k. Due to inherent loss, having a repeat > 1 is preferrable, although");
    writer.println("     it should be small. It's better to broadcast the data twice rather");
    writer.println("     than require another metadata announcement to trigger another");
    writer.println("     transmission. It's not clear whether REDUNDANCY should be > or = to");
    writer.println("     REPEAT. In either case, both constants should be small (e.g, 2-4). */");
    writer.println("  ");
    writer.println("  MVIRUS_CAPSULE_REPEAT = 2,            // How many times to repeat a capsule");
    writer.println("  MVIRUS_CAPSULE_TAU = 10,              // Capsules have a fixed tau");
    writer.println("  MVIRUS_CAPSULE_REDUNDANCY = 2,        // Capsule redundancy (suppression pt.)");
    writer.println("");
    writer.println("  /* These constants define the minimum and maximum tau values for");
    writer.println("     version vector exchange, as well as the version vector redundancy");
    writer.println("     constant k. Note that the tau values are in terms of multiples");
    writer.println("     of the TIMER value above (e.g., a MIN of 10 and a TIMER of 100");
    writer.println("     means a MIN of 1000 ms, or one second). */");
    writer.println("  MVIRUS_VERSION_TAU_MIN = 10,          // Version scaling tau minimum");
    writer.println("  MVIRUS_VERSION_TAU_MAX = 600,         // Version scaling tau maximum");
    writer.println("  MVIRUS_VERSION_REDUNDANCY = 1,        // Version redundancy (suppression pt.)");
    writer.println("  ");
    writer.println("  /* These constants are all for sending data larger than a single");
    writer.println("     packet; they define the size of a program chunk, bitmasks, etc.*/");
    writer.println("  MVIRUS_CHUNK_HEADER_SIZE = 8,");
    writer.println("  MVIRUS_CHUNK_SIZE = TOSH_DATA_LENGTH - MVIRUS_CHUNK_HEADER_SIZE,");
    writer.println("  MVIRUS_BITMASK_ENTRIES = ((MATE_CAPSULE_SIZE + MVIRUS_CHUNK_SIZE - 1) / MVIRUS_CHUNK_SIZE),");
    writer.println("  MVIRUS_BITMASK_SIZE = (MVIRUS_BITMASK_ENTRIES + 7) / 8,");
    writer.println("} MVirusConstants;");
    writer.println();
    writer.println("#endif");
    writer.flush();
  }

  private void createComponentFile(PrintWriter writer, OpcodeTable opTable, FunctionTable fnTable) {
    Context c;
    Vector v;
    Primitive p;
    Enumeration elements;
    
    writer.println("includes Mate;");
    writer.println("includes MateConstants;\n");
    writer.println("configuration MateTopLevel {}");
    writer.println("implementation");
    writer.println("{");
    writer.println("\tcomponents MateEngine as VM, Main, MContextSynchProxy as ContextSynch;");
    if (vmDesc.getVMOptions().hasDeluge()) {
      writer.println("\tcomponents DelugeC;");
    }
    Enumeration opNames = opTable.getNamesSortedLexicographically();
    while (opNames.hasMoreElements()) {
      String name = (String)opNames.nextElement();
      try {
	Operation op = opTable.getOperation(name);
	writer.println("\tcomponents OP" + op.getComponent() + ";");
      }
      catch (NoSuchOpcodeException exception) {
	System.err.println("Could not find information for opcode " + name + ". Internal storage bug.");
	exception.printStackTrace();
      }
    }
    
    elements = getContexts();
    while (elements.hasMoreElements()) {
      c = (Context)elements.nextElement();
      writer.println("\tcomponents " + c.name() + "Context;");
    }

    writer.println();
    writer.println("\tMain.StdControl -> VM;");
    if (vmDesc.getVMOptions().hasDeluge()) {
      writer.println("\tMain.StdControl -> DelugeC;");
    }
    int opCodesUsed = 0;
    
    
    opNames = opTable.getNamesSortedNumerically();
    while (opNames.hasMoreElements()) {
      try {
	String name = (String)opNames.nextElement();
	Operation op = opTable.getOperation(name);
	for (int i = 0; i < op.opcodeSlots(); i++) {
	  if (i == 0) {
	    writer.println("\tVM.Bytecode[OP_" + name.toUpperCase() + "] -> OP" + op.getComponent() + ";");
	  }
	  else {
	    writer.println("\tVM.Bytecode[OP_" + name.toUpperCase() + " + " + i + "] -> OP" + op.getComponent() + ";");
	  }
	  opCodesUsed++;
	}
      }
      catch (NoSuchOpcodeException exception) {
	System.err.println("Internal error in VM generation: couldn't find a necessary VM operation code");
	exception.printStackTrace();
      }
    }
    writer.println();
    
    // Function IDs here

    opNames = fnTable.getNames();

    while(opNames.hasMoreElements()) {
      try {
	String name = (String)opNames.nextElement();
	Function fn = fnTable.getFunction(name);
	writer.println("\tVM.FunctionImpls[fn_" + name + "] -> OP" + fn.getOpcode() + ";");
      }
      catch (InvalidInstructionException exception) {
	System.err.println("Internal error in VM generation: couldn't find a necessary VM function code");
      }
    }
    
    opNames = opTable.getNamesSortedNumerically();
    while (opNames.hasMoreElements()) {
      try {
	String name = (String)opNames.nextElement();
	Operation op = opTable.getOperation(name);
	if (op.hasLocks()) {
	  for (int i = 0; i < op.opcodeSlots(); i++) {
	    if (i == 0) {
	      writer.println("\tContextSynch.CodeLocks[OP_" + name.toUpperCase() + "] -> OP" + name + ";");
	  }
	  else {
	    writer.println("\tContextSynch.CodeLocks[OP_" + name.toUpperCase() + " + " + i + "] -> OP" + name + ";");
	  }
	    opCodesUsed++;
	  }
	}
      }
      catch (NoSuchOpcodeException exception) {
	System.err.println("Internal error in VM generation: couldn't find a necessary VM operation code");
	exception.printStackTrace();
      }
    }

    writer.println("}");
    writer.flush();
  }
  
  public String arrayToStr(int[] num) {
    String numStr = "";
    
    if (num == null)
      return numStr;
    
    for (int i = 0; i < num.length; i++) {
      numStr += num[i];
    }
    
    return numStr;
  }

  public static void main(String[] args) {
    
  }

    
}
