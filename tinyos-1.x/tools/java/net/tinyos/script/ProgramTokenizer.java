// $Id: ProgramTokenizer.java,v 1.1 2004/03/22 02:15:48 scipio Exp $

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
 * Desc:        Assembly program tokenizer for TinyOS VMs.
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

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
