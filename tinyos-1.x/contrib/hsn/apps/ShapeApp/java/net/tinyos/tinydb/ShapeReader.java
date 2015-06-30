
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
package net.tinyos.tinydb;

import net.tinyos.util.ByteOps;

/**
 * Implements reader for SHAPE aggregate
 *
 */
public class ShapeReader implements AggregateResultsReader {
    /**
     * Reads data from the byte array from QueryResultMessage
     */
    public void read(byte[] data) {
	System.out.println("Value data: " + data[0] + " and " + data[1]);
	System.out.println("IDs data  : " + data[2] + " and " + data[3]);
	System.out.println("Shape data: " + data[4] + " Guess data " + data[5]);
	myState = new ShapeData();
	myState.vlow = data[0];
	myState.vhigh = data[1];
	myState.ilow = data[2];
	myState.ihigh = data[3];
	myState.byteshape = data[4];
	myState.byteguess = data[5];
    }
	
    /**
     * Calculates final value of the aggregate.
     */
    public void finalizeValue() {
	//int[] done = new int[2];
	//	myState.shape = ByteOps.makeInt(myState.slow,myState.shigh);
	myState.shape = new Integer(myState.byteshape).intValue();
	System.out.println("final shape is " + myState.shape);
	System.out.println("final guess is " + new Integer(myState.byteguess).intValue());
    }
	
    /**
     * Returns string representation of the finalized value
     */
    public String getValue() {
	String res = new String("");
	switch (myState.shape) {
	case 0:
	    System.out.println("No Shape");
	    res = res.concat("No Shape");
	    break;
	case 1:
	    System.out.println("Square");
	    res = res.concat("Square");
	    break;
	case 2:
	    System.out.println("Triangle");
	    res = res.concat("Triangle");
	    break;
	case 4:
	    System.out.println("H-Rectangle");
	    res = res.concat("H-Rectangle");
	    break;
	case 8:
	    System.out.println("V-Rectangle");
	    res = res.concat("V-Rectangle");
	    break;
	case 16:
	    System.out.println("Plus");
	    res = res.concat("Plus");
	    break;
	default:
	    System.out.println("returning ?? " + myState.shape);
	    res = res.concat("eh? " + myState.shape);
	    break;
	}
	
	res = res.concat(" -- Possibly: ");
	if ((myState.byteguess & 0x01) > 0) {
	    System.out.println("Possible sqr");
	    res = res.concat("Sqr ");
	}
	if ((myState.byteguess & 0x02) > 0) {
	    res = res.concat("Tri ");
	    System.out.println("Possible tri");
	}
	if ((myState.byteguess & 0x04) > 0) {
	    res = res.concat("HRect ");
	    System.out.println("Possible HRect");
	}
	if ((myState.byteguess & 0x08) > 0) {
	    res = res.concat("VRect ");
	    System.out.println("Possible VRect");
	}
	if ((myState.byteguess & 0x10) > 0) {
	    res = res.concat("Pls ");
	    System.out.println("Possible Pls");
	}
	
	return res;
    }
	
    public void copyResultState(AggregateResultsReader reader) {
	if (! (reader instanceof ShapeReader)) throw new IllegalArgumentException("Wrong type reader");
		
	ShapeReader other = (ShapeReader)reader;
	other.myState.vlow = myState.vlow;
	other.myState.vhigh = myState.vhigh;
	other.myState.ilow = myState.ilow;
	other.myState.ihigh = myState.ihigh;
	other.myState.byteshape = myState.byteshape;
	other.myState.byteguess = myState.byteguess;
	other.myState.shape = myState.shape;
    }
    ShapeData myState;
}

class ShapeData {
    byte vlow = 0;
    byte vhigh = 0;
    byte ilow = 0;
    byte ihigh = 0;
    byte byteshape = 0;
    byte byteguess = 0;
    int value = 0;
    int ids = 0;
    int shape = 0;
}





