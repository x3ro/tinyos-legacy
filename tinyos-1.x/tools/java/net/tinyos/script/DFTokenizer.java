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
 * This class reads in a configuration file and tokenizes it.
 */

public class DFTokenizer {
  private StreamTokenizer tokenizer;

  public DFTokenizer(Reader reader) throws IOException {
	tokenizer = new StreamTokenizer(reader);
	tokenizer.resetSyntax();
	tokenizer.eolIsSignificant(true);
	tokenizer.wordChars('A', 'Z');
	tokenizer.wordChars('a', 'z');
	tokenizer.wordChars('0', '9');
	tokenizer.wordChars('!', '!');
	tokenizer.wordChars('#', '.');
	tokenizer.wordChars(':', ';');
	tokenizer.wordChars('?', '@');
	tokenizer.wordChars('[', '[');
	tokenizer.wordChars(']', '_');
	tokenizer.wordChars('{', '~');
	
	tokenizer.slashSlashComments(true);
	tokenizer.slashStarComments(true);
	
	tokenizer.whitespaceChars(0, 32); //Unreadable chars and whitespace
	tokenizer.whitespaceChars(127, 127); //DEL

  }
  
  public boolean hasMoreStatements() throws IOException{
    int type = tokenizer.nextToken();
    if (type == StreamTokenizer.TT_EOF) {
      return false;
    }
    else {
      tokenizer.pushBack();
      return true;
    }
  }
  
  public DFStatement nextStatement() throws IOException, StatementFormatException {
    DFStatement stmt;
    int type = tokenizer.nextToken();
    String key;
    String value;
    
    while (type != '<' && type != tokenizer.TT_EOF) {
      type = tokenizer.nextToken();
    }
    if (type == tokenizer.TT_EOF) {
      return null;
    }
    
    tokenizer.nextToken(); // this will give the confStmt's type (e.g. VM, PRIMITIVE, etc.)
    stmt = new DFStatement(tokenizer.sval); // create the stmt with type
    tokenizer.nextToken();
    
    while (type != '>' && type != tokenizer.TT_EOF) {
      // get each name-value pair for this statement
      key = tokenizer.sval;
      type = tokenizer.nextToken(); // the equals sign
      if (type != '=') {
        throw new StatementFormatException("expecting equals sign. Statment format invalid "+ stmt);
      }
      type = tokenizer.nextToken();
      if (type == '\"') {
	value = "";
	tokenizer.ordinaryChars(0, 32); //Unreadable chars and whitespace
	tokenizer.ordinaryChars(127, 127); //DEL
	type = tokenizer.nextToken();
	while (type != '\"' && type != tokenizer.TT_EOF) {
	  if (type == tokenizer.TT_WORD) {
	    value += tokenizer.sval;
	  }
	  else if (type == '\\') {
	    type = tokenizer.nextToken();
	    if (type == '\"') {
	      value += "\"";
	    }
	  }
	  else {
	    value += (char)type;
	  }
	  type = tokenizer.nextToken();
	}
	value = value.trim();
      	tokenizer.whitespaceChars(0, 32); //Unreadable chars and whitespace
	tokenizer.whitespaceChars(127, 127); //DEL
      }
      else {
	value = tokenizer.sval;
      }
      stmt.put(key, value);
      type = tokenizer.nextToken();
    }

    return stmt;
  }

  public static void main(String[] args) {
    try {
      DFTokenizer t = new DFTokenizer(new FileReader("test.txt"));
      while (t.hasMoreStatements()) {
        DFStatement c = t.nextStatement();
        System.out.println(c);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}
