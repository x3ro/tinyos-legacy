/*
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


package net.tinyos.task.taskviz;

import java.awt.Color;
import edu.umd.cs.jazz.component.ZEllipse;
import net.tinyos.task.taskapi.TASKMoteClientInfo;

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
  protected String config;

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

  /**
   * Sets the mote to the new coordinates
   *
   * @param x coordinate of the mote center
   * @param y coordinate of the mote center
   */
  public void setCoordinates(double x, double y) {
    this.x = x;
    this.y = y;
  }

  /**
   * Returns the configuration name for the mote
   *
   * @return name of the mote's configuration
   */
  public String getConfig() {
    return config;
  }

  /**
   * Sets the configuration name for the mote
   *
   * @param config Name of the mote's configuration
   */
  public void setConfig(String config) {
    this.config = config;
  }

  public Mote(TASKMoteClientInfo info) {
    this(info.xCoord, info.yCoord, info.moteId);
    this.config = info.clientInfoName;
  }

  public TASKMoteClientInfo toMoteClientInfo() {
    byte[] data = new byte[0];
    return new TASKMoteClientInfo(id, x, y, 0D, data, config);
  }
}
