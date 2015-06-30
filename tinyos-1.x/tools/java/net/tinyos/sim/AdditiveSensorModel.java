// $Id: AdditiveSensorModel.java,v 1.1 2004/04/14 18:24:29 mikedemmer Exp $

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
 * Desc:        Models for sensor interactions between motes and other objects
 *
 */

package net.tinyos.sim;

import net.tinyos.sim.*;
import java.util.*;

/*
 * Sensor models that combine multiple values additively can derive
 * from this class to do the looping and aggregation, and all they
 * need to define is the sensor propagation function.
 */
abstract class AdditiveSensorModel implements SensorModel {
  private static SimDebug debug = SimDebug.get("sensor");

  public abstract int getValue(double distance, int sensorValue);
  
  public int getValue(MoteSimObject mote, String field, Set sensableObjects) {
    Iterator it = sensableObjects.iterator();
    int value = 0;
    
    while (it.hasNext()) {
      SimObject obj = (SimObject)it.next();
      CoordinateAttribute coord = obj.getCoordinate();
      SensorAttribute sensor = (SensorAttribute)obj.getAttribute(field);
      
      if (coord == null) {
        throw new RuntimeException
          ("sensable object "+obj+" doesn't have a coordinate");
      }

      if (sensor == null) {
        throw new RuntimeException
          ("sensable object "+obj+" doesn't have sensor attribute " + field);
      }
      int sensorVal = sensor.getValue();
      double distance = mote.getDistance(coord.getX(), coord.getY());

      int newval = getValue(distance, sensorVal);
      debug.err.println("SENSOR ("+field+"): mote["+mote.getID()+"] " +
                        "distance["+distance+"] + new value " + newval);
      value += newval;
    }
    
    return value;
  }
}
