/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


package net.tinyos.task.taskviz.sensor;

import java.awt.*;
import java.util.Date;

import edu.umd.cs.jazz.ZVisualLeaf;
import edu.umd.cs.jazz.component.ZLine;

// this class does not do serialization correctly, unlike ZLine
/**
 * This class represents and renders a mote with sensors
 */
public class SensorLine extends ZVisualLeaf {

  private long time;
  private ZLine line;
  private double x1, x2, y1, y2;

  /**
   * Constructor that creates a line
   *
   * @param x1 X coordinate to start line at
   * @param y1 Y coordinate to start line at
   * @param x2 X coordinate to end line at
   * @param y2 Y coordinate to end line at
   */
  public SensorLine(double x1, double y1, double x2, double y2) {
    super();
    time = new Date().getTime();
    this.x1 = x1;
    this.x2 = x2;
    this.y1 = y1;
    this.y2 = y2;
    ZLine line = new ZLine(x1,y1,x2,y2);
    line.setPenPaint(Color.green);
    line.setPenWidth(1);
    addVisualComponent(line);
  }

  /**
   * Constructor that creates a line
   *
   * @param x1 X coordinate to start line at
   * @param y1 Y coordinate to start line at
   * @param x2 X coordinate to end line at
   * @param y2 Y coordinate to end line at
   */
  public SensorLine(double x1, double y1, double x2, double y2, boolean parent) {
    super();
    time = new Date().getTime();
    this.x1 = x1;
    this.x2 = x2;
    this.y1 = y1;
    this.y2 = y2;
    ZLine line = new ZLine(x1,y1,x2,y2);
    if (parent) {
      line.setPenPaint(Color.red);
      line.setPenWidth(4);
    }
    else {
      line.setPenPaint(Color.green);
      line.setPenWidth(1);
    }
    addVisualComponent(line);
  }

  public long getTime() {
    return time;
  } 

  public double getX1() {
    return x1;
  }

  public double getX2() {
    return x2;
  }

  public double getY1() {
    return y1;
  }

  public double getY2() {
    return y2;
  }
}
