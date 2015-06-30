// $Id: BombillaAssembler.java,v 1.5 2003/12/18 21:43:57 scipio Exp $

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
 * Date:        Aug 8 2002
 * Desc:        Assembler for Bombilla VM.
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.vm_asm;

import java.io.*;
import java.lang.reflect.*;
import java.util.*;


public class BombillaAssembler implements Assembler {

    private Hashtable table;
    private ClassLoader loader;
    public BombillaAssembler() {
	loader = this.getClass().getClassLoader();
	table = new Hashtable();
	loadOpcodes();
    }

    private void loadOpcodes() {
	try {
	    Class constants = loader.loadClass("net.tinyos.vm_asm.BombillaConstants");
	    Field[] fields = constants.getFields();
	    for (int i = 0; i < fields.length; i++) {
		Field field = fields[i];
		String name = field.getName();
		if (name.substring(0,2).equals("OP")) {
		    String code = name.substring(2);
		    byte val = (byte)(field.getShort(constants) & 0xff);
		    table.put(code, new Byte(val));
		}

	    }
	}
	catch (Exception e) {
	    System.out.println();
	    System.err.println(e);
	    e.printStackTrace();
	}
    }
    
    public String toHexString(ProgramTokenizer tokenizer) throws IOException, InvalidInstructionException {
	byte[] program = toByteCodes(tokenizer);
	String bytes = "";
	for (int i = 0; i < program.length; i++) {
	    String val = Integer.toHexString(program[i] & 0xff);
	    if (val.length() == 1) {
		val = "0" + val;
	    }
	    bytes += val;
	    bytes += " ";
	}
	return bytes;
    }

    private boolean hasEmbeddedOperand(String instr) {
	return (instr.equals("getms") ||
		instr.equals("getmb") ||
		instr.equals("setms") ||
		instr.equals("setmb") ||
		instr.equals("setvar4") ||
		instr.equals("getvar4") ||
		instr.equals("jumpc5") ||
		instr.equals("jumps5") ||
		instr.equals("pushc6"));
    }
    
    public byte[] toByteCodes(ProgramTokenizer tokenizer) throws IOException, InvalidInstructionException {
	Vector program = new Vector();
	while (tokenizer.hasMoreInstructions()) {
	    String instr = tokenizer.nextInstruction();
	    Byte obj = (Byte)table.get(instr);
	    if (obj == null) {
		throw new InvalidInstructionException(program.size(), instr);
	    }
	    //System.out.println("Opcode for " + instr + " is " + obj);
	    byte code = obj.byteValue();
	    if (hasEmbeddedOperand(instr)) {
		byte val = tokenizer.argument();
		code = (byte)(code | val);
		obj = new Byte(code);
	    }
	    program.add(obj);
	}
	int size = program.size();
	byte[] result = new byte[size + 1];
	for (int i = 0; i < size; i++) {
	    Byte instr = (Byte)program.elementAt(i);
	    result[i] = instr.byteValue();
	}
	
	result[size] = (byte)0x00;
	
	return result;
    }
    
    
    public static void main(String[] args) {
	try {
	    BombillaAssembler assembler = new BombillaAssembler();
	    FileReader reader = new FileReader(args[0]);
	    ProgramTokenizer tokenizer = new ProgramTokenizer(reader);
	    String program = assembler.toHexString(tokenizer);
	    System.out.println(program);
	}
	catch (Exception ex) {
	    ex.printStackTrace();
	}
    }
}
