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
import java.awt.Graphics2D;
import java.awt.Font;

import edu.umd.cs.jazz.component.ZEllipse;
import edu.umd.cs.jazz.util.ZRenderContext;

/**
 * This class represents and renders a mobile mote
 * Note that this class does not do serializatoin correctly, unlike ZEllipse
 */
public class MobileMote extends ZEllipse {

  /**
   * Width and height of the mobile mote
   */
  public static final double NODE_SIZE = Mote.NODE_SIZE;

  /**
   * Color of the mobile mote: green
   */
  public static final Color FILL_COLOR = Color.green;

  private int id;
  private String name;
  private double x, y, dx, dy;

  boolean col = true;

  // creates mote centered at x, y
  /**
   * Constructor that creates a mobile mote, but does not render it
   *
   * @param id Id of the mobile mote
   * @param name Name of the mobile mote
   */
  public MobileMote(int id, String name) {
    super();
    this.id = id;
    this.name = name;
    x = 0;
    y = 0;
    dx = 0;
    dy = 0;
    setFillPaint(FILL_COLOR);
  }

  /**
   * Returns the id of the mobile mote
   *
   * @return Id of the mobile mote
   */
  public int getId() {
    return id;
  }

  /**
   * Sets the id of the mobile mote
   *
   * @param id Id of the mobile mote
   */
  public void setId(int id) {
    this.id = id;
  }

  /**
   * Returns the name of the mobile mote
   *
   * @return Name of the mobile mote
   */
  public String getName() {
    return name;
  }

  /**
   * Sets the name of the mobile mote
   *
   * @param name Name of the mobile mote
   */
  public void setName(String name) {
    this.name = name;
  }

  /**
   * Returns the x coordinate of the mobile mote
   *
   * @return X coordinate of the mobile mote
   */
  public double getX() {
    return x;
  }

  /**
   * Returns the y coordinate of the mobile mote
   *
   * @return Y coordinate of the mobile mote
   */
  public double getY() {
    return y;
  }

  /**
   * Returns the width of the mobile mote
   *
   * @return Width of the mobile mote
   */
  public double getDX() {
    return dx;
  }

  /**
   * Returns the height of the mobile mote
   *
   * @return Height of the mobile mote
   */
  public double getDY() {
    return dy;
  }

  /**
   * Sets the width of the mobile mote
   *
   * @param d Width of the mobile mote
   */
  public void setDX(double d) {
    dx = d ;
  }

  /**
   * Sets the height of the mobile mote
   *
   * @param d Height of the mobile mote
   */
  public void setDY(double d) {
    dy = d;
  }

  /**
   * Moves the mobile mote and renders it
   *
   * @param xn New x coordinate of the mobile mote
   * @param yn New y coordinate of the mobile mote
   */
  public void move(double xn, double yn) {
    setEllipse(new java.awt.geom.Ellipse2D.Double(xn, yn, NODE_SIZE, NODE_SIZE));
    x=xn;
    y=yn;
    repaint();
  }

  /**
   * Renders the mobile mote, overriding the ZEllipse render method, allowing the rendering of the 
   * first three letters of the name. 
   *
   * @param renderContext Jazz render context
   */
  public void render(ZRenderContext renderContext) {
    super.render(renderContext);
    Graphics2D g2 = renderContext.getGraphics2D(); 
    g2.setColor(Color.black);
    g2.setFont(new Font("Helvetica", Font.PLAIN, 8)); 
    if (name.length() > 3) {
      g2.drawString(name.substring(0,3), (int)(x+1+2), (int)(y+3+NODE_SIZE/2.0));
    }
    else {
      g2.drawString(name, (int)(x+1+2), (int)(y+3+NODE_SIZE/2.0));
    }
  }
}