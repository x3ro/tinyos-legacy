// $Id: MoteLabelAttribute.java,v 1.1 2004/01/10 00:58:22 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
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
 * Authors:	Michael Demmer
 * Date:        January 9, 2004
 * Desc:        Mote label string attribute
 *              
 *              
 *
 */

/**
 * @author Michael Demmer
 */

package net.tinyos.sim;

public class MoteLabelAttribute implements Attribute {    
  private String label;
  private int x; // relative to mote center
  private int y;
    
  public MoteLabelAttribute(String label, int x, int y) {
    this.label = label;
    this.x = x;
    this.y = y;
  }

  public String getLabel() {
    return label;
  }

  public int getX() {
    return x;
  }

  public int getY() {
    return y;
  }
}

