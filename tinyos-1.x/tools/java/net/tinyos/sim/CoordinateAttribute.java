// $Id: CoordinateAttribute.java,v 1.1 2004/03/06 02:32:03 mikedemmer Exp $

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
 * Desc:        mote coordinate attribute
 *              this attribute is special in the sense that it is the only
 *              one that is shared among all plugins
 *
 */

/**
 * @author Nelson Lee
 */

package net.tinyos.sim;

import java.util.*;

public class CoordinateAttribute implements Attribute {    
    double x;
    double y;
    
    CoordinateAttribute(double x, double y) {
	this.x = x;
	this.y = y;
    }

    public double getX() {return x;}

    public double getY() {return y;}

    public void setX(double x) {
	this.x = x;
    }
    
    public void setY(double y) {
	this.y = y;
    }

    public String toString() {
	return "CoordinateAttribute: [x="+x+"] [y="+y+"]";
    }
    
}

