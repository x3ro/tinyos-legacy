// $Id: Mote.java,v 1.1 2003/10/17 01:53:36 mikedemmer Exp $

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
 * Authors:	Phil Levis
 * Date:        October 11 2002
 * Desc:        Data structure representing a mote in a GUI.
 *
 */

/**
 * @author Phil Levis
 */


package net.tinyos.sim.lossy;

import java.awt.*;

public class Mote {
    private double x;
    private double y;
    private int id;
    public static final Color BASIC_COLOR = Color.black;
    public static final Color SELECTED_COLOR = Color.red;
    private Color color = BASIC_COLOR;

    
    public Mote(int id, double x, double y) {
	this.id = id;
	this.x = x;
	this.y = y;
    }

    public synchronized double getX() {return x;}
    public synchronized double getY() {return y;}
    public synchronized int getID() {return id;}
    
    public synchronized boolean isVisible() {return true;}
    public synchronized Color getColor() {return color;}

    public synchronized void setX(double x) {this.x = x;}
    public synchronized void setY(double y) {this.y = y;}
    public synchronized void setColor(Color color) {this.color = color;}

    public boolean equals(Object obj) {
	if (obj instanceof Mote) {
	    Mote mote = (Mote)obj;
	    return (mote.getID() == this.getID());
	}
	else {
	    return false;
	}
    }

    public String toString() {
	String msg = "Mote ";
	msg += id;
	msg += " at ";
	msg += x;
	msg += ", ";
	msg += y;
	return msg;
    }

}
