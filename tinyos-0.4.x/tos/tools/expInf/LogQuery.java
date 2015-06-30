/*									tab:4
 * LogQuery.java
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:  Solomon Bien
 *
 */


package expInf;

import java.util.Vector;
import java.io.ByteArrayOutputStream;

/**
 * This class provides an interface to the AM handlers of the LOG_QUERY 
 * component.  It allows the user to request single or multiple lines of 
 * data from the log, from various points in the log.
 */
public class LogQuery extends ExpInfComp implements AMHandler {
    /**
     * AM handler to query the log
     */
    public static final byte AM_LOG_QUERY_MSG = 96;
    /**
     * AM handler that indicates the receipt of log data
     */
    public static final byte AM_LOG_QUERY_RESPONSE_MSG = 97;

    /**
     * UART address
     */
    public static final short TOS_LOCAL_ADDR = 0x7e;

    /**
     * Number of lines in the EEPROM
     */
    public static final int NUM_EEPROM_LINES = 1024;

    private int nextLine;
    private Vector logLines;

    /**
     * Constructor takes as an argument an AMInterface object that is 
     * already open
     */
    public LogQuery(AMInterface aif) {
	super(aif);
	super.aif.registerHandler(this,AM_LOG_QUERY_RESPONSE_MSG);
	this.nextLine = 0;
	this.logLines = new Vector();
    }
    
    /**
     * Queries node <nodeID> for the next line of data in its log
     */
    public void readNextLine(short nodeID) throws java.io.IOException {
	this.readLine(nodeID,this.nextLine);
	this.nextLine = (this.nextLine + 1) % NUM_EEPROM_LINES;
    }

    /**
     * Queries node <nodeID> for the data of line <lineNumber> of its log
     */
    public void readLine(short nodeID, int lineNumber) throws java.io.IOException {
	this.readLines(nodeID,lineNumber,1);
	this.nextLine = (lineNumber + 1) % NUM_EEPROM_LINES;
    }

    /**
     * Queries node <nodeID> for <numLines> lines of data starting at 
     * line <lineNumber> of its log
     */
    public void readLines(short nodeID, int startLineNumber, int numLines) throws java.io.IOException {
	this.readLog(startLineNumber,false,numLines,nodeID);
	this.nextLine = (startLineNumber + numLines) % NUM_EEPROM_LINES;
    }
    
    /**
     * Queries node <nodeID> for all of its lines of data starting at 
     * line <lineNumber> of its log
     */
    public void readLinesToEnd(short nodeID, int startLineNumber) throws java.io.IOException {
	this.readLog(startLineNumber,true,0,nodeID);
	this.nextLine = 0;
    }
    
    private void readLog(int startLineNumber, boolean isReadingToEnd, int numLines, short nodeID) throws java.io.IOException {
	byte [] data = new byte[super.aif.AM_SIZE];
	
	//&&&&&&&&&&&&CHANGE THIS&&&&&&&&
	//data[0] = (byte)(TOS_LOCAL_ADDR & 0x00FF);
	//data[1] = (byte)((TOS_LOCAL_ADDR >> 8) & 0x00FF);
	data[0] = (byte) (AMInterface.TOS_BCAST_ADDR & 0xff);
	data[1] = (byte) ((AMInterface.TOS_BCAST_ADDR >> 8) & 0xff);

	data[2] = (byte)(startLineNumber & 0x00FF);
	data[3] = (byte)((startLineNumber >> 8) & 0x00FF);
	data[4] = (byte)((startLineNumber >> 16) & 0x00FF);
	data[5] = (byte)((startLineNumber >> 24) & 0x00FF);
	
	if(isReadingToEnd) {
	    data[6] = (byte) 1;
	} else {
	    data[6] = (byte) 0;
	}

	data[7] = (byte)(numLines & 0x00FF);
	data[8] = (byte)((numLines >> 8) & 0x00FF);
	data[9] = (byte)((numLines >> 16) & 0x00FF);
	data[10] = (byte)((numLines >> 24) & 0x00FF);
	
	super.aif.sendAM(data,AM_LOG_QUERY_MSG,nodeID);
    }

    public void handleAM(byte[] data, short addr, byte id, byte group) {
	for(int i = 0;i<data.length;i++) {
	    System.out.print(data[i]);
	}
	System.out.println("");
	/*
	ByteArrayOutputStream b = new ByteArrayOutputStream();
	b.write(data,0,data.length);
	this.logLines.add(b);*/
    }
}





