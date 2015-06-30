// $Id: AttributeEvent.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

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

public class AttributeEvent implements SimEvent, SimConst {

    // types of Attribute Events:
    public static final int ATTRIBUTE_ADDED = 0;
    public static final int ATTRIBUTE_REMOVED = 1;
    public static final int ATTRIBUTE_CHANGED = 2;

    protected Attribute attribute;
    protected SimObject owner;
    protected int type;

    public AttributeEvent(int type, SimObject owner, Attribute attribute) {
	this.attribute = attribute;
	this.owner = owner;
	this.type = type;	
    }

    public Attribute getAttribute() {
	return attribute;
    }

    public SimObject getOwner() {
	return owner;
    }

    public int getType() {
	return type;
    }

    public String toString() {
	String typeString;
	switch (type) {
	case ATTRIBUTE_ADDED:
	    typeString = "added";
	    break;
	case ATTRIBUTE_REMOVED:
	    typeString = "removed";
	    break;
	case ATTRIBUTE_CHANGED:
	    typeString = "changed";
	    break;
	default:
	    typeString = Integer.toString(type);
	}
	return "AttributeEvent [type="+typeString+"] [owner="+owner.toString()+"] [attribute="+attribute.toString()+"]";
    }
}
