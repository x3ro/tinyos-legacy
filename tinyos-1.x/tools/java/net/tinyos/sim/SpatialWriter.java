// $Id: SpatialWriter.java,v 1.2 2003/10/07 21:46:04 idgay Exp $

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
 * Authors:	Nelson Lee
 * Date:        February 27, 2003
 * Desc:        Writes out mote positions to file
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim;

import java.io.*;
import java.util.*;

public class SpatialWriter {
    FileWriter writer;

    public SpatialWriter(File f) throws IOException {
	//System.out.println("Creating SpatialWriter");
	writer = new FileWriter(f);
    }

    public void writeEntry(int moteID, double x, double y) throws IOException {
	//System.out.println("Writing entry");
	writer.write(""+moteID+" "+x+" "+y+"\n");
    }
    
    public void done() throws IOException {
	//System.out.println("SpatialWrtier closing file");
	writer.flush();
	writer.close();
    }
}

    
