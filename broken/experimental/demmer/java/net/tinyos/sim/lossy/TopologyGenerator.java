// $Id: TopologyGenerator.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

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
 * Authors:	Phil Levis
 * Date:        October 11 2002
 * Desc:        Generates network loss rates from physical topology.
 *
 */

/**
 * @author Phil Levis
 */


package net.tinyos.sim.lossy;

import java.io.*;
import java.util.*;
import net.tinyos.sim.*;

public class TopologyGenerator {

    public static void generate(Writer output,
				Vector motes,
				double scalingConstant,
				PropagationModel model) {
	try {
	    int size = motes.size();
	    for (int i = 0; i < size; i++) {
		for (int j = 0; j < size; j++) {
		    Mote m1 = (Mote)motes.elementAt(i);
		    Mote m2 = (Mote)motes.elementAt(j);
		    double dx = (double)(m1.getX() - m2.getX());
		    double dy = (double)(m1.getY() - m2.getY());
		    double distance = Math.sqrt((dx * dx) + (dy * dy));
		    double loss = model.getBitLossRate(model.getPacketLossRate(distance, scalingConstant));
		    output.write("" + m1.getID() + ":" + m2.getID() + ":" + loss + " \n");
		}
	    }
	}
	catch (IOException ex) {
	    System.err.println("Error with file: " + ex);
	}
    }
}
