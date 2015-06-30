// $Id: Main.java,v 1.3 2003/11/03 21:22:50 neilp9 Exp $

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
package net.tinyos.script;

import java.io.*;
import net.tinyos.script.tree.*;

public class Main {

    public Main(){}


    public static void main(String[] args) throws IOException {
      /*
	
	Primitive led = new Primitive("LED", "putled", 1, null, false);
	Primitive clear = new Primitive("CLEAR", "bclear", 1, null, false);
	Primitive send = new Primitive("SEND", "send", 1, null, false);
	Primitive uart = new Primitive("UART", "uart", 1, null, false);
	Primitive sendr = new Primitive("SENDR", "sendr", 1, null, false);
	Primitive setradio = new Primitive("GETRADIO", "getradio", 0, null, true);
	Primitive getradio = new Primitive("SETRADIO", "setradio", 1, null, false);

	PrimitiveSet.addPrimitive(led);
	PrimitiveSet.addPrimitive(clear);
	PrimitiveSet.addPrimitive(send);
	PrimitiveSet.addPrimitive(uart);
	PrimitiveSet.addPrimitive(sendr);
	PrimitiveSet.addPrimitive(setradio);
	PrimitiveSet.addPrimitive(getradio);
      */

	Reader reader = new InputStreamReader(System.in);
	Parser p = new Parser(new Yylex(reader));
	try {
	    p.parse();
	    Program prog = Parser.getProgram();
	    CodeWriter w = new CodeWriter(new OutputStreamWriter(System.out));
	    //System.out.println(prog);
	    prog.generateCode(w);
	    System.out.println("Code length: " + w.numInstructions() + " instructions.");
	}
	catch (Exception e) {
	    System.out.println(e);
	    e.printStackTrace();
	}
    }
}
