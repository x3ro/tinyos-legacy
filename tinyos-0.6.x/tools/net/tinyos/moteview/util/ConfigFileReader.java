/* "Copyright (c) 2001 and The Regents of the University
* of California.  All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written agreement is
* hereby granted, provided that the above copyright notice and the following
* two paragraphs appear in all copies of this software.
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001
*/

package net.tinyos.moteview.util;

import net.tinyos.moteview.util.*;
import java.io.*;
import java.util.*;

/** Reads a configuration file and creates a Configuration object.
 * To be called on program instantiation
 * @author Joe Polastre
 */
public class ConfigFileReader {

    private Configuration config = null;
    private Vector packetAnalyzers = null;
    private Vector packetSenders = null;
    private Vector packetReaders = null;

    /** Primary constructor that creates a Configuration object
     * from a configuration file
     * @param file configuration file to be read
     */
    public ConfigFileReader(String file)
    {
	packetAnalyzers = new Vector();
	packetSenders = new Vector();
	packetReaders = new Vector();
	config = readFile(new File(file));
    }

    /** Returns the configuration generated from a file
     * @return configuration
     */
    public Configuration getConfiguration()
    {
	return config;
    }

    private Configuration readFile(File f)
    {
	int line = 0;
	String sLine = null;
	Configuration ctemp = new Configuration();

	try{
	    LineNumberReader reader = new LineNumberReader(new FileReader(f));
            sLine = reader.readLine();

	    while (sLine != null)
	    {
		// if not a comment, operate on the line
		if (!(sLine.trim()).equals("") && (sLine.charAt(0) != '#'))
		{
		    // operate on line
		    String sLeftSide = null;
		    String sRightSide = null;
		    int i = sLine.indexOf('=');
		    if (i > 0)
		    {
			sLeftSide = ((sLine.substring(0,i-1)).trim()).toUpperCase();
			sRightSide = (sLine.substring(i+1,sLine.length())).trim();

			if (sLeftSide.equals("PACKETANALYZER"))
			    packetAnalyzers.add(sRightSide);
			if (sLeftSide.equals("PACKETSENDER"))
			    packetSenders.add(sRightSide);
			if (sLeftSide.equals("PACKETREADER"))
			    packetReaders.add(sRightSide);
			if (sLeftSide.equals("DEBUG"))
			{
			    sRightSide = sRightSide.toUpperCase();
			    if (sRightSide.equals("TRUE"))
				ctemp.setDebug(true);
			    else
				ctemp.setDebug(false);
			}
			if (sLeftSide.equals("VERBOSE"))
			{
			    sRightSide = sRightSide.toUpperCase();
			    if (sRightSide.equals("TRUE"))
				ctemp.setVerbose(true);
			    else
				ctemp.setVerbose(false);
			}
		    }

		}
		reader.setLineNumber(line++);
	        sLine = reader.readLine();
	    }
	}
	catch(IOException e) {
	    e.printStackTrace();
	}

	ctemp.setPacketAnalyzers(packetAnalyzers);
	ctemp.setPacketReaders(packetReaders);
	ctemp.setPacketSenders(packetSenders);

	return ctemp;
    }
}
