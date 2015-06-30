// $Id: FunctionTable.java,v 1.2 2004/07/15 02:54:26 scipio Exp $

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

public class FunctionTable {

  private Hashtable nameToBytes;
  private Hashtable nameToDescs;
  
  public FunctionTable() {
    nameToBytes = new Hashtable();
    nameToDescs = new Hashtable();
  }

  public void addFunction(Function fn, short val) {
    String name = fn.getName().toLowerCase();
    nameToBytes.put(name, new Short(val));
    nameToDescs.put(name, fn);
  }

  public short getFunctionID(String name) throws InvalidInstructionException {
    Short s = (Short)nameToBytes.get(name.toLowerCase());
    if (s == null) {
      throw new InvalidInstructionException("No function ID for " + name);
    }
    else {
      return s.shortValue();
    }
  }

  public Function getFunction(String name) throws InvalidInstructionException {
    Function fn = (Function)nameToDescs.get(name.toLowerCase());
    if (fn == null) {
      throw new InvalidInstructionException("No function " + name);
    }
    else {
      return fn;
    }
  }

  public Enumeration getNames() {
    return nameToBytes.keys();
  }
  
}
