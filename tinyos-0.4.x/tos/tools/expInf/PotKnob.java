/*									tab:4
 * PotKnob.java
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
 * This class provides an interface to the AM handlers of the POT_KNOB 
 * component.  It allows the user to increase, decrease, and set the 
 * potentiometer setting
 */
public class PotKnob extends ExpInfComp {
    /**
     * AM handler to set the potentiometer setting
     */
    public static final byte AM_SET_POT_MSG = 98;

    /**
     * Constructor takes as an argument an AMInterface object that is already 
     * open
     */
    public PotKnob(AMInterface aif) {
	super(aif);
    }

    /**
     * Increases the potentiometer setting by one on node <nodeID>
     */
    public void increasePot(short nodeID) throws java.io.IOException {
	this.increasePot(nodeID,(byte) 1);
    }
    
    /**
     * Increases the potentiometer setting by <settingOffset> on node <nodeID>
     */
    public void increasePot(short nodeID, byte settingOffset) throws java.io.IOException {
	this.setPot(false,(byte) 1,settingOffset,nodeID);
    }

    /**
     * Decreases the potentiometer setting by one on node <nodeID>
     */
    public void decreasePot(short nodeID) throws java.io.IOException {
	this.decreasePot(nodeID,(byte) 1);
    }

    /**
     * Decreases the potentiometer setting by <settingOffset> on node <nodeID>
     */    
    public void decreasePot(short nodeID, byte settingOffset) throws java.io.IOException {
	this.setPot(false,(byte) 0,settingOffset,nodeID);
    }

    /**
     * Sets the potentiometer setting to <setting> on node <nodeID>
     */
    public void setPotValue(short nodeID, byte setting) throws java.io.IOException {
	this.setPot(true,(byte) 1, setting,nodeID);
    }

    private void setPot(boolean isAbsolute, byte settingSign, byte setting, short nodeID) throws java.io.IOException {
	byte [] data = new byte[super.aif.AM_SIZE];
	
	if(isAbsolute) {
	    data[0] = (byte) 1;
	} else {
	    data[0] = (byte) 0;
	}
	data[1] = settingSign;
	data[2] = setting;

	super.aif.sendAM(data,AM_SET_POT_MSG,nodeID);
    }



}


