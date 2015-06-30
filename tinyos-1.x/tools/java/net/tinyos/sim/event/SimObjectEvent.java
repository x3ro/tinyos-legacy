// $Id: SimObjectEvent.java,v 1.3 2003/10/07 21:46:04 idgay Exp $

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
 * Date:        February 4, 2003
 * Desc:        
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim.event;
import net.tinyos.sim.*;
import java.util.*;

public class SimObjectEvent implements SimEvent, SimConst {
    public static final int OBJECT_ADDED = 0;
    public static final int OBJECT_REMOVED = 1;

    protected SimObject simObject;
    protected int type;

    public SimObjectEvent(int type, SimObject simObject) {
	this.type = type;
	this.simObject = simObject;
    }

    public SimObject getSimObject() {
	return simObject;
    }
    
    public int getType() {
	return type;
    }

    public String toString() {
	String typeString;
	switch (type) {
	case OBJECT_ADDED:
	    typeString = "added";
	    break;
	case OBJECT_REMOVED:
	    typeString = "removed";
	    break;
	default:
	    typeString = Integer.toString(type);
	}
	return "SimObjectEvent [type="+typeString+"] [simObject="+simObject.toString()+"]";
    }
}
