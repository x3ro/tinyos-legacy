// $Id: LinearSensorModel.java,v 1.1 2004/04/14 18:24:29 mikedemmer Exp $

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
 * Date:        March 4 2004
 * Desc:        Linear sensor model
 *
 */

package net.tinyos.sim;

/*
 * Model that scales the object's sensor value linearly with distance
 * between a lower and upper bound and resolves multiple inputs
 * additively. The sensor's value returned when distance is below the
 * limit, zero is returned if above the limit, and the middle range
 * scales linearly.
 */
public class LinearSensorModel extends AdditiveSensorModel {
  private double low_bound, high_bound;

  public LinearSensorModel(double low_bound, double high_bound) {
    this.low_bound = low_bound;
    this.high_bound = high_bound;
  }
  
  public int getValue(double distance, int sensor) {
    if (distance <= low_bound) return sensor;
    if (distance >= high_bound) return 0;
    
    double value = ((double)sensor) *
                   (1 - ((distance - low_bound) / (high_bound - low_bound)));

    if (value < 0)
      value = 0;
    
    return (int)value;
  }
}
