/*
 * IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 * By downloading, copying, installing or using the software you agree to this
 * license.  If you do not agree to this license, do not download, install,
 * copy or use the software.
 * 
 * Intel Open Source License 
 * 
 * Copyright (c) 1996-2002 Intel Corporation. All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 	Redistributions of source code must retain the above copyright notice,
 * 	this list of conditions and the following disclaimer. 
 * 
 * 	Redistributions in binary form must reproduce the above copyright
 * 	notice, this list of conditions and the following disclaimer in the
 * 	documentation and/or other materials provided with the distribution. 
 * 
 * 	Neither the name of the Intel Corporation nor the names of its
 * 	contributors may be used to endorse or promote products derived from
 * 	this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.viz.sensor;

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
}