/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
 * Date:        Jun 13 2004
 * Desc:        Main window for script injector.
 *               
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.script.tree.*;
import vm_specific.*;

public class Scripter {

  private static void usage() {
    System.err.println("usage: Scripter [options] <context> <program file>");
    System.err.println("options:  -comm <source> Set packet source, default is sf@localhost:9001");
    System.err.println("options:  -gui           Open a GUI (ignore context and program file)");
  }
  
  public static void main(String[] args) throws Exception {
    String filename = "vm.vmdf";
    String progName = "programs.txt";
    boolean windowed = false;
    
    String source = null;
    PhoenixSource phoenix = null;
    MoteIF moteIF = null;
    String context = null;
    String progFileName = null;

    /* Must be declared at this scope for proper cleanup. */
    ScripterWindowed window = null;
    
    try {
      for (int i = 0; i < args.length; i++) {
	String arg = args[i];
	if (arg.equals("-h") || arg.equals("--help")) {
	  usage();
	  System.exit(0);
	}
	else if (arg.equals("-comm")) {
	  i++;
	  source = args[i];
	}
	else if (arg.equals("-gui")) {
	  windowed = true;
	}
	else {
	  if (context != null || i >= (args.length - 1)) {
	    usage();
	    System.exit(1);
	  }
	  context = args[i];
	  i++;
	  progFileName = args[i];
	}
      }

      
      if (source == null) {
	phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
      }
      else {
	phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
      }
      moteIF = new MoteIF(phoenix);
      moteIF.start();
      
      if (windowed) {
	System.out.println("Starting Scripter GUI with source " + phoenix);
	window = new ScripterWindowed(moteIF, filename, progName);
      }
      else {
	ScripterCommandLine cl;
	if (progFileName == null) {
	  System.err.println("You must specify a file containing the program to inject.");
	  System.exit(0);
          return;
        }
	System.out.println("Injecting script");
	cl = new ScripterCommandLine(moteIF, filename, progName);
	cl.inject(progFileName, context);

	System.out.println("Waiting for 4 seconds to see if an error occurs.");
	Thread.sleep(4000);
	System.exit(0);
      }
    }
    catch (java.io.EOFException e) { // Simulation/source dumped on us, save
      if (window != null) {
	window.cleanup();
      }
      System.err.println(e);
      e.printStackTrace();
      System.exit(1);
    }
    catch (Exception e) {
      System.err.println(e);
      e.printStackTrace();
      System.err.println();
      System.err.println("ERROR: Could not create a Scripter. Are you in an application directory?");
      System.exit(1);
    }
  }

}
