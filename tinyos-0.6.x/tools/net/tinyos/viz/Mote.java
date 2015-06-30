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

package net.tinyos.viz;

import java.awt.Color;
import edu.umd.cs.jazz.component.ZEllipse;

// this class does not do serialization correctly, unlike ZEllipse

/**
 * This object represents and renders a static sensor mote
 */
public class Mote extends ZEllipse {

  /**
   * The diameter of a mote
   */
  public static final double NODE_SIZE = 18.0;

  /**
   * The width of the line for rendering a mote
   */
  public static final double PEN_WIDTH = 1.0;

  /**
   * The fill color for rendering a mote
   */
  public static final Color FILL_COLOR = Color.yellow;

  /**
   * The highlight color for rendering a mote 
   */
  public static final Color HIGHLIGHT_COLOR = Color.red;

  /**
   * Way to indicate that a mote's id is invalid
   */
  public static final int INVALID_ID = -1;

  private int id;
  protected double x, y;

  /**
   * Constructor that places a mote centered at x,y with the given id
   *
   * @param x X coordinate to place the mote at
   * @param y Y coordinate to place the mote at
   * @param id Id of the mote being created
   */
  public Mote(double x, double y, int id) {
    super(x-NODE_SIZE/2.0, y-NODE_SIZE/2.0, NODE_SIZE, NODE_SIZE);
    this.id = id;
    this.x = x;
    this.y = y;
    setFillPaint(FILL_COLOR);
  }

  /**
   * Constructor that places a mote centered at x,y with no id
   *
   * @param x X coordinate to place the mote at
   * @param y Y coordinate to place the mote at
   */
  public Mote(double x, double y) {
    super(x-NODE_SIZE/2.0, y-NODE_SIZE/2.0, NODE_SIZE, NODE_SIZE);
    this.x = x;
    this.y = y;
    setFillPaint(FILL_COLOR);
  }

  /**
   * Returns the id of the mote
   *
   * @return id of the mote
   */
  public int getId() {
    return id;
  }

  /**
   * Sets the id of the mote
   *
   * @param id Id of the mote
   */
  public void setId(int id) {
    this.id = id;
  }

  /**
   * Returns the x coordinate of the mote center
   *
   * @return x coordinate of the mote center
   */
  public double getX() {
    return x;
  }

  /**
   * Returns the y coordinate of the mote center
   *
   * @return y coordinate of the mote center
   */
  public double getY() {
    return y;
  }
}