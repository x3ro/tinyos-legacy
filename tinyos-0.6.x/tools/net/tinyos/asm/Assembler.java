/*									tab:2
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Feb 19 2002
 * Desc:        Assembler for TinyOS VM.
 *
 */

package net.tinyos.asm;

import java.util.*;
import java.io.*;

public class Assembler {

    private Hashtable table;
    
    public Assembler() {
	table = new Hashtable();
	table.put("halt",   new Byte((byte)0x00));
	table.put("reset",  new Byte((byte)0x01));
	table.put("and",    new Byte((byte)0x02));
	table.put("or",     new Byte((byte)0x03));
	table.put("shiftr", new Byte((byte)0x04));
	table.put("shiftl", new Byte((byte)0x05));
	table.put("add",    new Byte((byte)0x06));
	table.put("putled", new Byte((byte)0x08));
	table.put("id",     new Byte((byte)0x09));
	table.put("inv",    new Byte((byte)0x0a));
	table.put("copy",   new Byte((byte)0x0b));
	table.put("pop",    new Byte((byte)0x0c));
	table.put("sense",  new Byte((byte)0x0d));
	table.put("send",   new Byte((byte)0x0e));
	table.put("sendr",  new Byte((byte)0x0f));

	table.put("cast",   new Byte((byte)0x10));
	table.put("pushm",  new Byte((byte)0x11));
	table.put("movm",   new Byte((byte)0x12));
	table.put("clear",  new Byte((byte)0x13));
	table.put("son",    new Byte((byte)0x14));
	table.put("soff",   new Byte((byte)0x15));
	table.put("not",    new Byte((byte)0x16));
	table.put("log",    new Byte((byte)0x17));
	table.put("logr",   new Byte((byte)0x18));
	table.put("logr2",  new Byte((byte)0x19));
	table.put("gets",   new Byte((byte)0x1a));
	table.put("sets",   new Byte((byte)0x1b));
	table.put("rand",   new Byte((byte)0x1c));
	table.put("eq",     new Byte((byte)0x1d));
	table.put("neq",    new Byte((byte)0x1e));
	table.put("call",   new Byte((byte)0x1f));
	
	table.put("swap",   new Byte((byte)0x20));
	table.put("forw",   new Byte((byte)0x2e));
	table.put("forwo",  new Byte((byte)0x2f));
	
	table.put("usr0",   new Byte((byte)0x30));
	table.put("usr1",   new Byte((byte)0x31));
	table.put("usr2",   new Byte((byte)0x32));
	table.put("usr3",   new Byte((byte)0x33));
	table.put("usr4",   new Byte((byte)0x34));
	table.put("usr5",   new Byte((byte)0x35));
	table.put("usr6",   new Byte((byte)0x36));
	table.put("usr7",   new Byte((byte)0x37));	

	table.put("setgrp", new Byte((byte)0x3a));
	table.put("pot",    new Byte((byte)0x3b));
	table.put("pots",   new Byte((byte)0x3c));
	table.put("clockc", new Byte((byte)0x3d));
	table.put("clockf", new Byte((byte)0x3e));
	table.put("ret",    new Byte((byte)0x3f));
	
	table.put("getms",  new Byte((byte)0x40));
	table.put("getmb",  new Byte((byte)0x48));
	table.put("setms",  new Byte((byte)0x50));
	table.put("setmb",  new Byte((byte)0x58));
	table.put("getfs",  new Byte((byte)0x60));
	table.put("getfb",  new Byte((byte)0x58));
	table.put("setfs",  new Byte((byte)0x70));
	table.put("setfb",  new Byte((byte)0x78));

	table.put("blez",   new Byte((byte)0x80));
	table.put("pushc",  new Byte((byte)0xC0));
    }
    
    public String toString(Reader programReader) throws IOException, InvalidInstructionException {
	byte[] program = toByteCodes(programReader);
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
    
    public byte[] toByteCodes(Reader programReader) throws IOException, InvalidInstructionException {
	ProgramParser parser = new ProgramParser(programReader);
	Vector program = new Vector();
	while (parser.hasMoreInstructions()) {
	    String instr = parser.nextInstruction();
	    Byte obj = (Byte)table.get(instr);
	    if (obj == null) {
		throw new InvalidInstructionException(program.size(), instr);
	    }
	    //System.out.println("Opcode for " + instr + " is " + obj);
	    byte code = obj.byteValue();
	    if (instr.equals("blez") || instr.equals("pushc")) {
		byte val = parser.argument();
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
	    Assembler assembler = new Assembler();
	    FileReader reader = new FileReader(args[0]);
	    String program = assembler.toString(reader);
	    System.out.println(program);
	}
	catch (Exception ex) {
	    ex.printStackTrace();
	}
    }
}
