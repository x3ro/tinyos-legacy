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


package net.tinyos.sim;

import java.io.*;
import java.util.*;

public class SpatialReader {
    public static final int READING_MOTEID = 0;
    public static final int READING_X_COORD = 1;
    public static final int READING_Y_COORD = 2;    

    private Hashtable hTable = new Hashtable();

    public void addEntry(int moteID, double x, double y) {
	hTable.put(Integer.toString(moteID), new SREntry(moteID, x, y));
    }
    
    public SREntry getEntry(int moteID) {
	return (SREntry)hTable.get(Integer.toString(moteID));
    }

    public SpatialReader(File f) throws IOException {
	Reader reader = new FileReader(f);
	StreamTokenizer tok = new StreamTokenizer(reader);
	tok.eolIsSignificant(false);
	tok.parseNumbers();
	
	double x = 0.0;
	double y = 0.0;
	int moteID = 0;
	int state = READING_MOTEID;
	
	while(tok.nextToken() != StreamTokenizer.TT_EOF) {
	    switch(tok.ttype) {
	    case StreamTokenizer.TT_NUMBER:
		//System.out.println("tok got next token: [nval "+tok.nval+"]");
		
		
		if (state == READING_MOTEID) {
		    moteID = (int)tok.nval;
		    state = READING_X_COORD;
		}
		else if (state == READING_X_COORD) {
		    x = tok.nval;
		    state = READING_Y_COORD;
		}
		else if (state == READING_Y_COORD) {
		    y = tok.nval;
		    state = READING_MOTEID;
		    addEntry(moteID, x, y);
		}
		else {
		    System.out.println("SpatialReader: Error in parsing spatial file. In erroneous state: " + state);
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

    public void print() {
	Enumeration enum = hTable.elements();
	while (enum.hasMoreElements()) {
	    SREntry sREntry = (SREntry)enum.nextElement();
	    System.out.println(sREntry);
	}
    }
    
    
    public class SREntry {
	double x;
	double y;
	int moteID;
	
	public SREntry(int moteID, double x, double y) {
	    this.x = x;
	    this.y = y;
	    this.moteID = moteID;
	}
    
	public double getX() {return x;}
	
	public double getY() {return y;}
	
	public int getMoteID() {return moteID;}

	public String toString() {
	    return "SREntry [moteID "+moteID+"] [x "+x+"] [y "+y+"]";
	}
    }

    public static void main(String[] args) throws IOException {
	SpatialReader spatialReader = new SpatialReader(new File(args[0]));
	spatialReader.print();
	
    }

}
