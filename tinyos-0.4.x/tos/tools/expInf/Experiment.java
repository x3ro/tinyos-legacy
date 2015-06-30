/*									tab:4
 * Experiment.java
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
 * This class provides an interface to the AM handlers of the EXPERIMENT 
 * component.  It allows the user to start and stop experiments, set the 
 * experimental ID, start and stop the topology_query component, and 
 * query a node for its information.
 */
public class Experiment extends ExpInfComp implements AMHandler {
    /**
     * AM handler to set an experimental ID
     */
    public static final byte AM_SET_EXP_ID_MSG = 92;
    /**
     * AM handler to query a node for its information
     */
    public static final byte AM_DISCOVER_MSG = 91;
    /**
     * AM handler to start an experiment
     */
    public static final byte AM_START_EXP_MSG = 90;
    /** 
     * AM handler to stop an experiment
     */
    public static final byte AM_STOP_EXP_MSG = 89;
    
    /**
     * UART address
     */
    public static final short GENERIC_BASE_ADDR = 0x7e;

    /**
     * Constructor takes as an argument an AMInterface object that is already 
     * open.
     */
    public Experiment(AMInterface aif) {
	super(aif);
	super.aif.registerHandler(this,AM_DISCOVER_MSG);
    }

    /**
     * Changes the experimental ID of node <nodeID> to <newExpID>
     */
    public void setExpID(byte newExpID, short nodeID) throws java.io.IOException {
	byte [] data = new byte[super.aif.AM_SIZE];
	
	data[0] = newExpID;
	
	super.aif.sendAM(data,AM_SET_EXP_ID_MSG,nodeID);
    }

    public void handleAM(byte[] data, short addr, byte id, byte group) {
	for(int i = 0;i<data.length;i++) {
	    System.out.print(data[i] + " ");
	}
	System.out.println("");
    }

    /**
     * Queries a node <nodeID> for its information
     */
    public void discover(short nodeID) throws java.io.IOException {
	byte [] data = new byte[super.aif.AM_SIZE];
	
	//&&&&&&&&&&&&CHANGE THIS&&&&&&&&
	//data[0] = (byte) (GENERIC_BASE_ADDR & 0xff);
	//data[1] = (byte) ((GENERIC_BASE_ADDR >> 8) & 0xff);	

	data[0] = (byte) (AMInterface.TOS_BCAST_ADDR & 0xff);
	data[1] = (byte) ((AMInterface.TOS_BCAST_ADDR >> 8) & 0xff);

	super.aif.sendAM(data,AM_DISCOVER_MSG,nodeID);
    }

    /**
     * Starts the experiment on node <nodeID> in <delay> clock ticks and 
     * runs it for <duration> clock ticks.  If <startConnectivity> is 1, 
     * it starts topology_query.  If 0, the loaded experiment is run.
     */
    private void startExp(byte startConnectivity, byte delay, byte duration, short nodeID) throws java.io.IOException {
	byte [] data = new byte[super.aif.AM_SIZE];
	
	data[0] = startConnectivity;
	data[1] = delay;
	data[2] = duration;

	super.aif.sendAM(data,AM_START_EXP_MSG,nodeID);
    }

    /**
     * Starts the experiment on node <nodeID> in <delay> clock ticks and runs 
     * it for <duration> clock ticks
     */
    public void startExperiment(byte delay, byte duration, short nodeID) throws java.io.IOException {
	if(duration == 0) {
	    duration = -1;
	}
	this.startExp((byte) 0,delay,duration,nodeID);
    }

    /**
     * Stops the experiment currently running on node <nodeID> in <delay> 
     * clock ticks
     */
    public void startExperiment(byte delay, short nodeID) throws java.io.IOException {
	this.startExperiment(delay,(byte) -1,nodeID);
    }

    /**
     * Starts TOPOLOGY_QUERY on node <nodeID>
     */
    public void startConnectivity(short nodeID) throws java.io.IOException {
	this.startExp((byte) 1,(byte) 0,(byte) -1,nodeID);
    }

    /**
     * Stops the experiment on node <nodeID> in <delay> clock ticks.  If 
     * <startConnectivity> is 1, it starts topology_query.  If 0, the 
     * loaded experiment is run.
     */
    private void stopExp(byte stopConnectivity, byte delay, short nodeID) throws java.io.IOException {
	byte [] data = new byte[super.aif.AM_SIZE];
	
	data[0] = stopConnectivity;
	data[1] = delay;

	super.aif.sendAM(data,AM_STOP_EXP_MSG,nodeID);
    }

    /**
     * Stops the experiment running on node <nodeID> in <delay> clock ticks
     */
    public void stopExperiment(byte delay, short nodeID) throws java.io.IOException {
	this.stopExp((byte) 0,delay,nodeID);
    }

    /**
     * Stops TOPOLOGY_QUERY on node <nodeID>
     */
    public void stopConnectivity(short nodeID) throws java.io.IOException {
	this.stopExp((byte) 1,(byte) 0,nodeID);
    }

}
