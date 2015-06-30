// $Id: LossyBuilder.java,v 1.1 2004/02/24 05:03:51 scipio Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Date:        October 11 2002
 * Desc:        Top-level class for graphically building networks for sim.
 *
 */

/**
 * @author Phil Levis
 */


package net.tinyos.sim;

import java.io.*;
import java.util.*;
import net.tinyos.sim.lossy.*;

public class LossyBuilder {

    private static void usage() {
	System.err.println("usage: java net.tinyos.sim.NetworkBuilder [options]");
	System.err.println("options:");
	System.err.println("  -t grid:       Topology (grid only and default)");
	System.err.println("  -d <m> <n>:    Grid size (m by n) (default: 10 x 10)");
	System.err.println("  -s <scale>:    Spacing factor (default: 5.0)");
	System.err.println("  -o <file>:     Output file");
	System.err.println("  -i <file>:     Input file of positions");
	System.err.println("  -p:            Generate positions, not losses");
	System.err.println("  -packet:       Generate packet values, not bit");
    }
    
    private static void fail(String message) {
	System.err.println(message);
	System.exit(1);
    }
    
    public static void main(String[] args) {
	String topology = "grid";
	int gridMotesX = 10;
	int gridMotesY = 10;
	double spacing = 5.0;
	Writer output = new PrintWriter(System.out);
	Reader input = null;
	Vector motes = new Vector();
	boolean isJustPositions = false;
	boolean isPacket = false;
	try {
	    System.err.println("Starting NetworkBuilder.");
	    for (int i = 0; i < args.length; i++) {
		String arg = args[i];
		if (arg.equals("-d")) {
		    i++;
		    String x = args[i];
		    i++;
		    String y = args[i];
		    gridMotesX = Integer.parseInt(x);
		    gridMotesY = Integer.parseInt(y);
		}
		else if (arg.equals("-s")) {
		    i++;
		    String val = args[i];
		    spacing = Double.parseDouble(val);
		}
		else if (arg.equals("-t")) {
		    i++;
		    topology = args[i];
		}
		else if (arg.equals("-p")) {
		    isJustPositions = true;
		}
		else if (arg.equals("-packet")) {
		  isPacket = true;
		}
		else if (arg.equals("-i")) {
		    i++;
		    String file = args[i];
		    input = new FileReader(new File(file));
		}
		else if (arg.equals("-o")) {
		    i++;
		    String file = args[i];
		    output = new FileWriter(new File(file));
		}
		else if (arg.equals("-h") || arg.equals("--help")) {
		    usage();
		    System.exit(0);
		}
		else {
		    fail("Unrecognized option: " + arg);
		}
	    }
	    
	    if (input != null) {
		net.tinyos.sim.lossy.SpatialReader.read(input, motes);
	    }
	    else if (topology.equals("grid")) {
		System.out.println("Generating " + gridMotesX + " by " + gridMotesY + " grid.");
		for (int i = 0; i < gridMotesX; i++) {
		    for (int j = 0; j < gridMotesY; j++) {
			double x = 10.0 + ((double)i) * spacing;
			double y = 10.0 + ((double)j) * spacing;
			int id = (i * gridMotesY) + j;
			Mote m = new Mote(id, x, y);
			motes.addElement(m);
		    }
		}
	    }
	    else if (topology.equals("uniform")) {
		System.out.println("Generating " + (gridMotesX * gridMotesY) + " motes in a " + spacing + "x" + spacing + " area.");
		int total = gridMotesX * gridMotesY;
		for (int i = 0; i < total; i++) {
		    double x = Math.random() * spacing;
		    double y = Math.random() * spacing;
		    Mote m = new Mote(i, x, y);
		    motes.addElement(m);
		}
	    }
	    else {
		System.err.println("Unknown topology: " + topology);
		System.exit(1);
	    }

	    if (isJustPositions) {
		for (int i = 0; i < motes.size(); i++) {
		    Mote mote = (Mote)motes.elementAt(i);
		    output.write("" + mote.getX() + " " + mote.getY() + "\n");
		}
	    }
	    else {
	      PropagationModel model = new EmpiricalModel();
	      if (isPacket) {
		TopologyGenerator.generatePacket(output, motes, 1.0, model);
	      }
	      else {
		TopologyGenerator.generate(output, motes, 1.0, model);
	      }
	    output.flush();
	    }
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }

}
