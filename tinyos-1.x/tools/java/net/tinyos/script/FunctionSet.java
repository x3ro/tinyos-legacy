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

import java.util.*;

public class FunctionSet {

  static private Hashtable table;

  static {
    table = new Hashtable();
  }

  public static void addFunction(Function fn) {
    String name = (String)fn.get("name");
    table.put(name.toLowerCase(), fn);
  }


  public static boolean functionExists(String name) {
    return table.containsKey(name.toLowerCase());
  }

  public static Enumeration functionNames() {
    Vector alphaKeys = new Vector();
    Enumeration keys = table.keys();
    while (keys.hasMoreElements()) {
      String key = (String)keys.nextElement();
      for (int i = 0; i <= alphaKeys.size(); i++) {
	if (i == alphaKeys.size()) {
	  alphaKeys.insertElementAt(key, i);
	  break;
	}
	else {
	  String otherKey = (String)alphaKeys.elementAt(i);
	  if (key.compareTo(otherKey) < 0) {
	    alphaKeys.insertElementAt(key, i);
	    break;
	  }
	}
      }
    }
    return alphaKeys.elements();
  }
  
  public static Function getFunction(String name) {
    if (functionExists(name)) {
      return (Function)table.get(name.toLowerCase());
    }
    else {
      return null;
    }
  }

}
