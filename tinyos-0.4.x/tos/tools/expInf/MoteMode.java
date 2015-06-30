/*									tab:4
 * MoteMode.java
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

/**
 * This class provides an interface to the AM handler of the EXPERIMENT 
 * component that changes the mode/role of a node.
 */
public class MoteMode extends ExpInfComp {

    /**
     * AM handler to change the mote mode/role
     */
    public static final byte AM_MOTE_MODE_MSG = 95;
    
    /**
     * The role of a monitoring node
     */
    public static final byte MONITOR_MODE = 0;

    /**
     * The role of a node taking part in the experiment
     */
    public static final byte EXPERIMENT_MODE = 1;

    /**
     * Constructor takes as an argument an AMInterface object that is 
     * already open
     */
    public MoteMode(AMInterface aif) {
	super(aif);
    }

    /**
     * Sets the mode/role of node <nodeID> to <mode>
     */
    public void setMode(byte mode, short nodeID) throws java.io.IOException {
	byte [] data = new byte[super.aif.AM_SIZE];
	
	data[0] = mode;

	super.aif.sendAM(data,AM_MOTE_MODE_MSG,nodeID);
    }



}
