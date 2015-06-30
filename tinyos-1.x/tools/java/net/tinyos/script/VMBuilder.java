// $Id: VMBuilder.java,v 1.5 2005/04/28 00:34:04 scipio Exp $

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
 * Date:        Sep 26 2003
 * Desc:        Main window for VM builder
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.io.*;
import java.util.*;
import net.tinyos.util.*;

public class VMBuilder {

  public static void main(String[] args) throws Exception {
    boolean windowed = false;
    String buildFile = "";
    Vector options = new Vector();
    for (int i = 0; i < args.length; i++) {
      if (args[i].equals("-gui")) {
	windowed = true;
      }
      else if (args[i].substring(0, 3).equals("-t=") ||
	       args[i].substring(0, 3).equals("-d=") ||
	       args[i].substring(0, 3).equals("-f=") ||
	       args[i].substring(0, 3).equals("-l=")) {
	options.addElement(args[i]);
      }
      else {
	buildFile = args[i];
      }
    }

    if (!windowed) {
      System.err.println("Currently, filed-based VMBuilder only works from the samples/ subdirectory.");
      System.err.println("Please be sure you execute it from there.");
      System.err.println();
      VMBuilderFromFile vm = new VMBuilderFromFile(buildFile);
      try {
	vm.build();
      }
      catch (Exception exception) {
	System.err.println("Error building the VM.");
	exception.printStackTrace();
      }
    }
    else {
      VMBuilderGui builder = new VMBuilderGui();
      for (int i = 0; i < options.size(); i++) {
	String arg = (String)options.elementAt(i);
	if (arg.substring(0, 3).equals("-t=")) {
	  String tree = arg.substring(3);
	  File file = new File(tree);
	  builder.actOnTree(file);
	}
	else if (arg.substring(0, 3).equals("-d=")) {
	  String dir = arg.substring(3);
	  File file = new File(dir);
	  builder.actOnDirectory(file);
	}
	else if (arg.substring(0, 3).equals("-f=")) {
	  String filename = arg.substring(3);
	  File file = new File(filename);
	  builder.actOnFile(file);
	}
	else  if (arg.substring(0, 3).equals("-l=")) {
	  String filename = arg.substring(3);
	  File file = new File(filename);
	  builder.setLanguageFile(file);
	}
      }
      
      builder.pack();
      builder.setVisible(true);
      builder.repaint();     
    }
  }
	
}
