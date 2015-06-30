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
 * Desc:        Assembly program tokenizer for TinyOS VMs.
 *
 */

package net.tinyos.vm_asm;

import java.io.*;

/**
 * This class reads in an ASCII assembly program and tokenizes it into
 * individual instructions. If an instruction has an embedded operand,
 * that operand can be fetched with <tt>argument()</tt>.
 *
 */

public class ProgramTokenizer {
    private StreamTokenizer tokenizer;
    private byte argument = 0;
    
    public ProgramTokenizer(Reader reader) throws IOException {
	tokenizer = new StreamTokenizer(reader);
	tokenizer.resetSyntax();
	tokenizer.eolIsSignificant(false);
	tokenizer.wordChars('A', 'Z');
	tokenizer.wordChars('a', 'z');
	tokenizer.whitespaceChars(0, 32); //Unreadable chars and whitespace
	tokenizer.whitespaceChars(127, 127); //DEL
	tokenizer.parseNumbers();
    }

    public boolean hasMoreInstructions() throws IOException{
	int type = tokenizer.nextToken();
	if (type == StreamTokenizer.TT_EOF) {
	    return false;
	}
	else {
	    tokenizer.pushBack();
	    return true;
	}
    }

    public byte argument() {
	return argument;
    }
    
    public String nextInstruction() throws IOException {
	int type = tokenizer.nextToken();
	if (type != StreamTokenizer.TT_WORD) {
	    throw new IOException("File parse failed on line " + tokenizer.lineno());
	}

	String instr = tokenizer.sval;
	//System.out.println("Parsing <" + instr + ">");
	
	type = tokenizer.nextToken();

	if (type == StreamTokenizer.TT_NUMBER) {
	    argument = (byte)tokenizer.nval;
	}
	else {
	    tokenizer.pushBack();
	}

	return instr;
    }
}
