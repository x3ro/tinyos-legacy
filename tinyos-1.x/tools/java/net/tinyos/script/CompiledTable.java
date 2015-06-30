// $Id: CompiledTable.java,v 1.2 2004/07/15 02:54:26 scipio Exp $

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

import java.util.*;
import net.tinyos.script.tree.*;

public class CompiledTable {

  private Hashtable table;

  public CompiledTable() {
    table = new Hashtable();
  }

  public void put(String context, Program p) {
    table.put(context.toLowerCase(), p);
  }

  public Program get(String context) {
    return (Program)table.get(context.toLowerCase());
  }
  
  public Enumeration keys() {
    return table.keys();
  }

  public Enumeration getElementsSortedLexicographically() {
    Vector names = new Vector();
    Enumeration ops = keys();
    //System.err.print("Sorting names: ");
    while (ops.hasMoreElements()) {
      String name = (String)ops.nextElement();
      //System.err.print(name + ", ");
      boolean inserted = false;
      for (int i = 0; i < names.size(); i++) {
	String comparison = (String)names.elementAt(i);
	if (name.compareTo(comparison) < 0) {
	  names.insertElementAt(name, i);
	  inserted = true;
	  break;
	}
      }
      if (!inserted) {
	names.addElement(name);
      }
    }
    //System.err.println();
    return names.elements();
  }
  
}
