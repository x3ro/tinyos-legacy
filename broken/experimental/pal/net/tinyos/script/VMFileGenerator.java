// $Id: VMFileGenerator.java,v 1.5 2004/03/18 03:42:07 scipio Exp $

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
  private File languageFile;
  private Vector contexts;
  private Vector primitives;
  private String vmName;
  private String vmDesc;
  private VMOptions options;
  
  public VMFileGenerator(File directory, String name, String desc, File languageFile, Enumeration contexts,  Enumeration primitives, VMOptions options) {
    this.directory = directory;
    this.languageFile = languageFile;
    this.options = options;
    vmName = name;
    vmDesc = desc;
    
    this.contexts = new Vector();
    while (contexts.hasMoreElements()) {
      Object context = contexts.nextElement();
      System.err.println("adding " + context);
      this.contexts.addElement(context);
    }

    this.primitives = new Vector();
    while (primitives.hasMoreElements()) {
      this.primitives.addElement(primitives.nextElement());
    }
    
  }

  public String getName() {return vmName;}
  public String getDesc() {return vmDesc;}
  public String getJavaConstantsName() {return getName() + "Constants";}
  /**
   * Return the set of selected contexts.
   */
  
  public Enumeration getContexts() {
    return contexts.elements();
  }

  /**
   * Return the set of explicitly selected primitives.
   */
  
  public Enumeration getSelectedPrimitives() {
    return primitives.elements();
  }

  /**
   * Return the set of capsules determined by contexts and primitives.
   */
  
  public Enumeration getCapsules() {
     Vector vector = new Vector();
     Enumeration enum = getContexts();
     while (enum.hasMoreElements()) {
       BuilderContext context = (BuilderContext)enum.nextElement();
       vector.addElement(context.capsule());
     }

     enum = getAllPrimitives();
     while (enum.hasMoreElements()) {
       Primitive primitive = (Primitive)enum.nextElement();
       Enumeration capsules = primitive.capsules();
       while (capsules.hasMoreElements()) {
	 vector.addElement(capsules.nextElement());
       }
     }

     return vector.elements();
  }

  /**
   * Return the full set of primitives, those explicitly selected and
   * those implicitly selected by including contexts.
   *
   */ 
  public Enumeration getAllPrimitives() {
    Vector instrList = new Vector();

    // First, get the selected primitives
    Enumeration current = getSelectedPrimitives();
    while (current.hasMoreElements()) {
      instrList.addElement(current.nextElement());
    }

    // Next, get those that contexts implicitly select
    current = getContexts();
    while (current.hasMoreElements()) {
      BuilderContext context = (BuilderContext)current.nextElement();
      if (context.hasPrimitives()) {
	Enumeration prims = context.primitives();
	while (prims.hasMoreElements()) {
	  Primitive p = (Primitive)prims.nextElement();
	  //System.err.println(p);
	  instrList.addElement(p);
	}
      }
    }

    return instrList.elements();
  }

  /**
   * Generate an array of vectors of all instructions, sorted by how
   * many bits of opcode space they consume. For example, instructions
   * in element 0 in the array consume 0 bits, that is, have a single
   * opcode value, while instructions in element 2 of the array
   * consume 2 bits, that is, have 4 opcode values.
   */
  
  private Vector[] generateSortedInstructions() throws IOException {
    Vector[] sortedInstrs = new Vector[32];
    Vector v = new Vector();

    System.err.println("Generating language-based instructions.");
    DFTokenizer tokenizer = new DFTokenizer(new FileReader(languageFile));
    while (tokenizer.hasMoreStatements()) {
      DFStatement stmt = tokenizer.nextStatement();
      if (stmt != null) {
	v.add(new Primitive(stmt));
      }
    }    
    organizeInstrs(v.elements(), sortedInstrs);

    System.err.println("Organizing function primitives.");
    organizeInstrs(getAllPrimitives(), sortedInstrs);
    return sortedInstrs;
  }
  
  public void createFiles() throws IOException { 
    System.err.println("Creating files");

    Vector[] sortedInstrs = generateSortedInstructions();
    
    System.err.println("Making Config file");
    File configFile = new File(directory, "vm.vmdf");
    PrintWriter configWriter = new PrintWriter(new FileWriter(configFile), true);
    createConfigFile(configWriter);
    
    System.err.println("Making constants file");
    File constantsFile = new File(directory, "MateConstants.h");
    PrintWriter constantsWriter = new PrintWriter(new FileWriter(constantsFile), true);
    createConstantsFile(constantsWriter, sortedInstrs);
    
    System.err.println("Making component file");
    File componentsFile = new File(directory, "MateTopLevel.nc");
    PrintWriter componentsWriter = new PrintWriter(new FileWriter(componentsFile), true);
    createComponentFile(componentsWriter, sortedInstrs);
    
    System.err.println("Making makefile (haha!)");
    File makefileFile = new File(directory, "Makefile");
    PrintWriter makefileWriter = new PrintWriter(new FileWriter(makefileFile), true);
    createMakefile(makefileWriter);
      
  }

  private void createMakefile(PrintWriter writer) {
    String vmJavaName = getJavaConstantsName();
    
    writer.println("COMPONENT=MateTopLevel");
    writer.print("CFLAGS=");
    Enumeration enum = options.getSearchPaths();
    while (enum.hasMoreElements()) {
      writer.print("-I" + enum.nextElement() + " ");
    }
    writer.println(" -I%T/lib/VM/components -I%T/lib/VM/opcodes -I%T/lib/VM/contexts -I%T/lib/VM/types -I%T/lib/VM/interfaces -I%T/lib/Queue -I%T/lib/VM/route -I.");
    writer.println("MSG_SIZE=36");
    writer.println("BUILD_EXTRA_DEPS=" + vmJavaName + ".class CapsuleChunkMsg.class CapsuleStatusMsg.class CapsuleMsg.class");
    writer.println();
    writer.println("include ../Makerules");
    writer.println();
    writer.println(vmJavaName + ".java:");
    writer.println("\tmkdir -p vm_specific");
    writer.println("\tncg java $(CFLAGS) -java-classname=vm_specific." + vmJavaName + " MateTopLevel.nc MateConstants.h -o vm_specific/$@");
    writer.println();
    writer.println("CapsuleMsg.java:");
    writer.println("\tmkdir -p vm_specific");
    writer.println("\tmig java $(CFLAGS) -java-classname=vm_specific.CapsuleMsg ../../tos/lib/VM/types/Mate.h MateCapsuleMsg -o vm_specific/$@");
    writer.println();
    writer.println("CapsuleChunkMsg.java:");
    writer.println("\tmkdir -p vm_specific");
    writer.println("\tmig java $(CFLAGS) -java-classname=vm_specific.CapsuleChunkMsg ../../tos/lib/VM/types/Mate.h MateCapsuleChunkMsg -o vm_specific/$@");
    writer.println();
    writer.println("CapsuleStatusMsg.java:");
    writer.println("\tmkdir -p vm_specific");
    writer.println("\tmig java $(CFLAGS) -java-classname=vm_specific.CapsuleStatusMsg ../../tos/lib/VM/types/Mate.h MateCapsuleStatusMsg -o vm_specific/$@");
    writer.println();
    writer.println("%.class: %.java");
    writer.println("\tjavac $<");
    writer.println();
    writer.println("" + vmJavaName + ".class: " + vmJavaName + ".java");
    writer.println("\tjavac vm_specific/$<");
    writer.println();
    writer.println("CapsuleMsg.class: CapsuleMsg.java");
    writer.println("\tjavac vm_specific/$<");
    writer.println();
    writer.println("CapsuleChunkMsg.class: CapsuleChunkMsg.java");
    writer.println("\tjavac vm_specific/$<");
    writer.println();
    writer.println("CapsuleStatusMsg.class: CapsuleStatusMsg.java");
    writer.println("\tjavac vm_specific/$<");
    writer.println();
    writer.println("cleanmig:");
    writer.println("\trm -f " + vmJavaName + ".*");
    writer.println();
    writer.println("clean: cleanmig");
    writer.println("\trm -rf build/ vm_specific/");
    writer.println("\trm -f core.* *.class *.java");
    writer.println("\trm -f *~");
    writer.flush();
  }
	
  private void createConfigFile(PrintWriter writer) {
    Enumeration instrs = getAllPrimitives();
    writer.println("<VM name=\"" + getName() + "\" desc=\"" + getDesc() + "\" className=\"vm_specific." + getJavaConstantsName() + "\">");

    while (instrs.hasMoreElements()) {
      Primitive p = (Primitive) instrs.nextElement();
      writer.println(p);
    }

    Enumeration contexts = getContexts();
    while (contexts.hasMoreElements()) {
      BuilderContext bc = (BuilderContext) contexts.nextElement();
      writer.println(bc);
    }
    
    writer.flush();
  }

  private void createConstantsFile(PrintWriter writer, Vector[] sortedInstrs) {
    int counter = 0;
    String opcode;
    Vector v;
    Primitive p;
    BuilderContext c;
    Enumeration e;
    Capsule capsule;
    
    writer.println("#ifndef BOMBILLA_CONSTANTS_H_INCLUDED");
    writer.println("#define BOMBILLA_CONSTANTS_H_INCLUDED\n");
    writer.println("typedef enum {");
    writer.println("  MATE_OPTION_FORWARD     = 0x80,");
    writer.println("  MATE_OPTION_FORCE       = 0x40,");
    writer.println("  MATE_OPTION_MASK        = 0x3f,");
    writer.println("} MateCapsuleOption;\n");
    
    writer.println("typedef enum {");

    e = getContexts();
    while (e.hasMoreElements()) {
      c = (BuilderContext)e.nextElement();
      String context = c.name();
      context = context.toUpperCase();
      writer.println("  MATE_CONTEXT_" + context + "\t = unique(\"MateContextConstant\"),");
    }
    writer.println("  MATE_CONTEXT_NUM\t = unique(\"MateContextConstant\"),");
    writer.println("  MATE_CONTEXT_INVALID = 255");
    writer.println("} MateContextType;");

    
    writer.println("typedef enum {");
    e = getCapsules();
    while (e.hasMoreElements()) {
      capsule = (Capsule)e.nextElement();
      String cName = capsule.name();
      cName = cName.toUpperCase();
      writer.println("  MATE_CAPSULE_" + cName + "\t = unique(\"MateCapsuleConstant\"),");
    }
    writer.println("  MATE_CAPSULE_NUM\t = unique(\"MateCapsuleConstant\"),");
    writer.println("  MATE_CAPSULE_INVALID = 255");
    writer.println("} MateCapsuleType;\n");

    writer.println("enum {");
    writer.println("  MATE_CALLDEPTH    = " + options.getCallDepth() + ",");
    writer.println("  MATE_OPDEPTH      = " + options.getOpDepth() + ",");
    writer.println("  MATE_HEAPSIZE     = uniqueCount(\"MateLock\"),");
    writer.println("  MATE_MAX_PARALLEL = 4,");
    writer.println("  MATE_NUM_YIELDS   = 4,");
    writer.println("  MATE_HEADERSIZES  = 3,");
    writer.println("  MATE_HEADERSIZE   = 6,");
    writer.println("  MATE_BUF_LEN      = " + options.getBufLen() + ",");
    writer.println("  MATE_PGMSIZE      = " + options.getProgramSize() + ",");
    writer.println("  MATE_BUF_NUM      = 2");
    writer.println("} MateSizeConstants;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_DATA_NONE    = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_VALUE   = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_PHOTO   = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_TEMP    = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_MIC     = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_MAGX    = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_MAGY    = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_ACCELX  = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_ACCELY  = unique(\"MateSensorType\"),");
    writer.println("  MATE_DATA_END     = unique(\"MateSensorType\")");
    writer.println("} MateSensorType;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_TYPE_INVALID = 0,");
    writer.println("  MATE_TYPE_VALUE   = (1 << unique(\"MateDataType\")),");
    writer.println("  MATE_TYPE_BUFFER  = (1 << unique(\"MateDataType\")),");
    writer.println("  MATE_TYPE_SENSE   = (1 << unique(\"MateDataType\"))");
    writer.println("} MateDataType;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_VAR_V = MATE_TYPE_VALUE,");
    writer.println("  MATE_VAR_B = MATE_TYPE_BUFFER,");
    writer.println("  MATE_VAR_S = MATE_TYPE_SENSE,");
    writer.println("  MATE_VAR_VB = MATE_VAR_V | MATE_VAR_B,");
    writer.println("  MATE_VAR_VS = MATE_VAR_V | MATE_VAR_S,");
    writer.println("  MATE_VAR_SB = MATE_VAR_B | MATE_VAR_S,");
    writer.println("  MATE_VAR_VSB = MATE_VAR_B | MATE_VAR_S | MATE_VAR_V,");
    writer.println("  MATE_VAR_ALL = MATE_VAR_B | MATE_VAR_S | MATE_VAR_V");
    writer.println("} MateDataCondensed;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_STATE_HALT        = unique(\"MateState\"),");
    writer.println("  MATE_STATE_SENDING     = unique(\"MateState\"),");
    writer.println("  MATE_STATE_LOG         = unique(\"MateState\"),");
    writer.println("  MATE_STATE_SENSE       = unique(\"MateState\"),");
    writer.println("  MATE_STATE_SEND_WAIT   = unique(\"MateState\"),");
    writer.println("  MATE_STATE_LOG_WAIT    = unique(\"MateState\"),");
    writer.println("  MATE_STATE_SENSE_WAIT  = unique(\"MateState\"),");
    writer.println("  MATE_STATE_LOCK_WAIT   = unique(\"MateState\"),");
    writer.println("  MATE_STATE_RESUMING    = unique(\"MateState\"),");
    writer.println("  MATE_STATE_RUN         = unique(\"MateState\")");
    writer.println("} MateContextState;\n");

    writer.println("typedef enum {");
    writer.println("  MATE_ERROR_TRIGGERED                =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INVALID_RUNNABLE         =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_STACK_OVERFLOW           =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_STACK_UNDERFLOW          =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_BUFFER_OVERFLOW          =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_BUFFER_UNDERFLOW         =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INDEX_OUT_OF_BOUNDS      =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INSTRUCTION_RUNOFF       =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_LOCK_INVALID             =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_LOCK_STEAL               =  unique(\"MateError\"),");
    writer.println("  MATE_ERROR_UNLOCK_INVALID           = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_QUEUE_ENQUEUE            = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_QUEUE_DEQUEUE            = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_QUEUE_REMOVE             = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_QUEUE_INVALID            = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_RSTACK_OVERFLOW          = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_RSTACK_UNDERFLOW         = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INVALID_ACCESS           = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_TYPE_CHECK               = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INVALID_TYPE             = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INVALID_LOCK             = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INVALID_INSTRUCTION      = unique(\"MateError\"),");
    writer.println("  MATE_ERROR_INVALID_SENSOR           = unique(\"MateError\")");
    writer.println("} MateErrorCode;\n");
  
    writer.println("typedef enum {");
    writer.println("  MATE_MAX_NET_ACTIVITY  = 64,");
    writer.println("  MATE_PROPAGATE_TIMER   = 737,");
    writer.println("  MATE_PROPAGATE_FACTOR  = 0x7f   // 127");
    writer.println("} MateCapsulePropagateConstants;\n");
  
    writer.println("enum {");
    writer.println("  AM_MATEROUTEMSG         = 0x1b,");
    writer.println("  AM_MATEVERSIONMSG       = 0x1c,");
    writer.println("  AM_MATEERRORMSG         = 0x1d,");
    writer.println("  AM_MATECAPSULEMSG       = 0x1e,");
    writer.println("  AM_MATEPACKETMSG        = 0x1f,");
    writer.println("  AM_MATECAPSULECHUNKMSG  = 0x20,");
    writer.println("  AM_MATECAPSULESTATUSMSG = 0x21,");
    writer.println("};\n");

    writer.println("typedef enum {");
    writer.print("// instruction set");

    for (int i = 0; i < 32; i++) {
      v = sortedInstrs[i];
      if (v != null) {
        counter = (int)Math.ceil((double)counter/(1 << i)) * (1 << i);
        e = v.elements();
        while (e.hasMoreElements()) {
          opcode = Integer.toHexString(counter);
          counter += (1 << i);
          p = (Primitive) e.nextElement();
          writer.println(",");
          writer.print("  OP" + p.get("opcode") + "\t= 0x" + opcode);
        }
      }
    }
    
    writer.println();
    writer.println("} MateInstruction;\n");
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
    writer.println("  MVIRUS_BITMASK_ENTRIES = ((MATE_PGMSIZE + MVIRUS_CHUNK_SIZE - 1) / MVIRUS_CHUNK_SIZE),");
    writer.println("  MVIRUS_BITMASK_SIZE = (MVIRUS_BITMASK_ENTRIES + 7) / 8,");
    writer.println("} MVirusConstants;");
    writer.println();
    writer.println("#endif");
    writer.flush();
  }

  private void createComponentFile(PrintWriter writer, Vector[] sortedInstrs) {
    BuilderContext c;
    Vector v;
    Primitive p;
    Enumeration e;
    
    writer.println("includes Mate;");
    writer.println("includes MateConstants;\n");
    writer.println("configuration MateTopLevel {}");
    writer.println("implementation");
    writer.println("{");
    writer.println("\tcomponents MateEngine as VM, Main, MContextSynchProxy as ContextSynch;");

    for (int i = 0; i < 32; i++) {
      v = sortedInstrs[i];
      if (v != null) {
        e = v.elements();
        while (e.hasMoreElements()) {
          p = (Primitive)e.nextElement();
	  writer.println("\tcomponents OP" + p.get("opcode") + ";");
        }
      }
    }
    
    e = getContexts();
    while (e.hasMoreElements()) {
      c = (BuilderContext)e.nextElement();
      writer.println("\tcomponents " + c.name() + "Context;");
    }

    writer.println();
    writer.println("\tMain.StdControl -> VM;");

    int opCodesUsed = 0;
    for (int i = 0; i < 32; i++) {
      v = sortedInstrs[i];
      if (v != null) {
        e = v.elements();
        while (e.hasMoreElements()) {
          p = (Primitive)e.nextElement();
	  for (int j = 0; j < Math.pow(2,i); j++) {
	    writer.println("\tVM.Bytecode[OP" + p.get("opcode") + "+" + j + "] -> OP" + p.get("opcode") + ";");
	    opCodesUsed++;
	  }
	}
	writer.println();
      }
    }
    System.err.println("" + opCodesUsed + " of 256 opcodes used.\n");
    for (int i = 0; i < 32; i++) {
      v = sortedInstrs[i];
      if (v != null) {
        e = v.elements();
        while (e.hasMoreElements()) {
          p = (Primitive)e.nextElement();
	  if (p.hasLocks()) {
	    for (int j = 0; j < Math.pow(2,i); j++)
	      writer.println("\tContextSynch.CodeLocks[OP" + p.get("opcode") + "+" + j + "] -> OP" + p.get("opcode") + ";");
	  }
	}
	writer.println();
      }
    }
    
    writer.println("}");
    writer.flush();
  }
  
  private void organizeInstrs(Enumeration e, Vector[] sortedInstrs) {
    Primitive p;
    Vector v;
    String operandSizeStr, instrLenStr;
    Integer operandSizeInt, instrLenInt;
    Pattern re = Pattern.compile("(\\d*)\\D+(\\d+)"); 
    int opcodesUsed = 0;
    
    while (e.hasMoreElements()) {
      operandSizeStr = "0";
      instrLenStr = "1";
      operandSizeInt = new Integer(0);;
      instrLenInt = new Integer(1);
	
      p = (Primitive) e.nextElement();
      //System.err.println("Adding " + p);
      Matcher m = re.matcher((String)p.get("opcode"));
      if (m.matches()) {
	instrLenStr = m.group(1);
	if (!instrLenStr.equals("")) {
          instrLenInt = new Integer(instrLenStr);
	}
	operandSizeStr = m.group(2);
        operandSizeInt = new Integer(operandSizeStr);
      }
      else {
	
      }
      // If an instruction is wider than a single byte,
      // then embedded operand bits are in the additional bytes.
      // E.g., a 2-byte wide instruction with 10 bits of embedded operand
      // only requires 4 instruction slots
      if (instrLenInt.intValue() > 1) {
        operandSizeInt = new Integer(operandSizeInt.intValue() - (8 * (instrLenInt.intValue() -1 )));
        //System.out.println("changing " + p.get("opcode") + " width from " + operandSizeStr + " to " + operandSizeInt);
      }
      
      v = sortedInstrs[operandSizeInt.intValue()];
      if (v == null) {
	v = new Vector();
      }
      
      v.add(p);
      //System.out.println("Added " + p + " to " + operandSizeInt + " instruction set.");
      sortedInstrs[operandSizeInt.intValue()] = v;
    }
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
