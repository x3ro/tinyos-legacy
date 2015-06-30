// $Id: CodeWriter.java,v 1.4 2003/10/17 00:00:34 scipio Exp $

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
import java.util.*;
import net.tinyos.script.tree.*;

public class CodeWriter {
    private Writer writer;
    private int labelLength;
    private Vector elements;
    private int numInstructions;
    
    public CodeWriter(Writer writer){
	this.writer = writer;
	elements = new Vector();
	labelLength = 0;
	numInstructions = 0;
    }

    public void writeInstr(String text) throws IOException {
	Instr instr = new Instr(text);
	numInstructions++;
	elements.add(instr);
    }

    public void writeLabel(String text) throws IOException {
	Label label = new Label(text);
	elements.add(label);
    }

    public void optimize() {
	// do nothing for now
    }
    
    public void flush() throws IOException {
	Enumeration enum = elements.elements();
	while (enum.hasMoreElements()) {
	    CodeEntry entry = (CodeEntry)enum.nextElement();
	    String text = entry.text();
	    if (entry.isLabel()) {
		writer.write(text + ":");
		labelLength = text.length() + 1;
	    }
	    else if (entry.isComment()) {
		writer.write("# " + text + "\n");
	    }
	    else {
		String heading = "";
		for (int i = labelLength; i < 16; i++) {
		    heading = heading + " ";
		}
		labelLength = 0;
	    	writer.write(heading + text + "\n");
	    }
	}
	writer.flush();
	elements.clear();
    }

    
    
    public void writeComment(String comment) {
	Comment c = new Comment(comment);
	elements.add(c);
    }

    public int numInstructions() {
	return numInstructions;
    }
    
    protected class CodeEntry {
	private String text;
	public CodeEntry(String text) {this.text = text;}
	public String text() {return text;}
	public boolean isLabel() {return false;}
	public boolean isComment() {return false;}
    }
    
    protected class Label extends CodeEntry {
	public Label(String label) {super(label);}
	public boolean isLabel() {return true;}
    }
    protected class Instr extends CodeEntry {
	public Instr(String instr) {super(instr);}
    }
    protected class Comment extends CodeEntry {
	public Comment(String text) {super(text);}
	public boolean isComment() {return true;}
    }
}
