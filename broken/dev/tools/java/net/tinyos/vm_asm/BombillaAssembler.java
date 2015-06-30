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
 * Date:        Aug 8 2002
 * Desc:        Assembler for Bombilla VM.
 *
 */

package net.tinyos.vm_asm;

import java.util.*;
import java.io.*;

public class BombillaAssembler implements Assembler {

    private Hashtable table;
    
    public BombillaAssembler() {
	table = new Hashtable();
	// Zero operand instructions begin
	table.put("halt",     new Byte((byte)0x00));
	table.put("id",       new Byte((byte)0x01));
	table.put("rand",     new Byte((byte)0x02));
	table.put("ctrue",    new Byte((byte)0x03));
	table.put("cfalse",   new Byte((byte)0x04));
	table.put("cpush",    new Byte((byte)0x05));
	table.put("logp",     new Byte((byte)0x06));
	table.put("bpush0",   new Byte((byte)0x07));
	table.put("bpush1",   new Byte((byte)0x08));
	table.put("depth",    new Byte((byte)0x09));
	table.put("err",      new Byte((byte)0x0a));
	table.put("ret",      new Byte((byte)0x0b));
	table.put("call0",    new Byte((byte)0x0c));	
	table.put("call1",    new Byte((byte)0x0d));
	table.put("call2",    new Byte((byte)0x0e));
	table.put("call3",    new Byte((byte)0x0f));

	// One operand instructions begin
	table.put("inv",      new Byte((byte)0x10));
	table.put("cpull",    new Byte((byte)0x11));
	table.put("not",      new Byte((byte)0x12));
	table.put("lnot",     new Byte((byte)0x13));
	table.put("sense",    new Byte((byte)0x14));
	table.put("send",     new Byte((byte)0x15));
	table.put("sendr",    new Byte((byte)0x16));
	table.put("uart",     new Byte((byte)0x17));
	table.put("logw",     new Byte((byte)0x18));
	table.put("bhead",    new Byte((byte)0x19));
	table.put("btail",    new Byte((byte)0x1a));
	table.put("bclear",   new Byte((byte)0x1b));
	table.put("bsize",    new Byte((byte)0x1c));
	table.put("copy",     new Byte((byte)0x1d));
	table.put("pop",      new Byte((byte)0x1e));

       	table.put("bsorta",   new Byte((byte)0x20));
	table.put("bsortd",   new Byte((byte)0x21));
	table.put("bfull",    new Byte((byte)0x22));
	table.put("putled",   new Byte((byte)0x23));
	table.put("cast",     new Byte((byte)0x24));
	table.put("unlock",   new Byte((byte)0x25));
	table.put("unlockb",  new Byte((byte)0x26));
	table.put("punlock",  new Byte((byte)0x27));
	table.put("punlockb", new Byte((byte)0x28));

	// Two operand instructions begin
	table.put("logwl",    new Byte((byte)0x2b));
	table.put("logr",     new Byte((byte)0x2c));
	table.put("bget",     new Byte((byte)0x2d));
	table.put("byank",    new Byte((byte)0x2e));

	// Special variable (1+) operand  instruction
	table.put("motectl",  new Byte((byte)0x2f));

	// Two operand instructions continue
	table.put("swap",     new Byte((byte)0x30));
	table.put("land",     new Byte((byte)0x31));
	table.put("lor",      new Byte((byte)0x32));
	table.put("and",      new Byte((byte)0x33));
	table.put("or",       new Byte((byte)0x34));
	table.put("shiftr",   new Byte((byte)0x35));
	table.put("shiftl",   new Byte((byte)0x36));
	table.put("add",      new Byte((byte)0x37));
	table.put("mod",      new Byte((byte)0x38));
	table.put("eq",       new Byte((byte)0x39));
	table.put("neq",      new Byte((byte)0x3a));
	table.put("lt",       new Byte((byte)0x3b));
	table.put("gt",       new Byte((byte)0x3c));
	table.put("lte",      new Byte((byte)0x3d));
	table.put("gte",      new Byte((byte)0x3e));
	table.put("eqtype",   new Byte((byte)0x3f));	

	table.put("getms",    new Byte((byte)0x40));
	table.put("getmb",    new Byte((byte)0x48));
	table.put("setms",    new Byte((byte)0x50));
	table.put("setmb",    new Byte((byte)0x58));
	table.put("getvar",   new Byte((byte)0x60));
	table.put("setvar",   new Byte((byte)0x70));

	table.put("jumpc",    new Byte((byte)0x80));
	table.put("jumps",    new Byte((byte)0xa0));
	table.put("pushc",    new Byte((byte)0xc0));
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
	    if (instr.equals("blez") || instr.equals("pushc")) {
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
