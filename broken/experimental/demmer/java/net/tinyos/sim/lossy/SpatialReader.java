// $Id: SpatialReader.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

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
 * Desc:        Double buffer area and clicking functionaliy.
 *
 */

/**
 * @author Phil Levis
 */


package net.tinyos.sim.lossy;

import java.io.*;
import java.util.*;

public class SpatialReader {

    public static void read(Reader reader, Vector motes) throws IOException {
	StreamTokenizer tok = new StreamTokenizer(reader);
	tok.eolIsSignificant(false);
	tok.parseNumbers();

	double x = 0.0;
	double y = 0.0;
	boolean readSecond = false;
	int count = 0;
	
	while(tok.nextToken() != StreamTokenizer.TT_EOF) {
	    switch(tok.ttype) {
	    case StreamTokenizer.TT_NUMBER:
		if (readSecond) {
		    y = tok.nval;
		    Mote m = new Mote(count, x, y);
		    readSecond = false;
		    count++;
		    motes.addElement(m);
		}
		else {
		    x = tok.nval;
		    readSecond = true;
		}
		break;
	    case StreamTokenizer.TT_EOF:
		return;
	    default:
		System.err.println("Error in parsing spatial file. Offending token: " + tok.ttype + ": "+ tok.sval + "|" + tok.nval);
		return;
	    }
	}
    }
}
