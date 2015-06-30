// $Id: MoteLedsAttribute.java,v 1.5 2004/02/20 20:24:30 mikedemmer Exp $

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
 * Date:        December 09 2002
 * Desc:        mote leds attribute
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim;

public class MoteLedsAttribute implements Attribute {
    byte leds = 7;

    public String toString() {
      return "MoteLedsAttribute: 0x"+Integer.toHexString(leds);
    }
    
    public String shortString() {
        return  "" +
            (redLedOn()    ? "R" : "") +
            (greenLedOn()  ? "G" : "") +
            (yellowLedOn() ? "Y" : "");
    }
    
    public void setLeds(byte leds) {
	this.leds = leds;
    }

    public byte getLeds() {
	return leds;
    }

    public boolean redLedOn() {
	if ((leds & 1) != 0) {
	    return true;
	}
	return false;
    }

    public boolean greenLedOn() {
	if ((leds & 2) != 0) {
	    return true;
	}
	return false;
    }

    public boolean yellowLedOn() {
	if ((leds & 4) != 0) {
	    return true;
	}
	return false;
    }

    public void setRedOn() {
	leds |= 1;
    }

    public void setGreenOn() {
	leds |= 2;
    }

    public void setYellowOn() {
	leds |= 4;
    }
    
    public void setRedOff() {
	leds &=6;
    }
    
    public void setGreenOff() {
	leds &=5;
    }
    
    public void setYellowOff() {
	leds &=3;
    }
    
}    

    
    
