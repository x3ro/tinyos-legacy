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
import edu.umd.cs.jazz.component.ZRectangle;
import edu.umd.cs.jazz.util.ZRenderContext;

// this class does not do serialization correctly, unlike ZRectangle

/**
 * This object represents and renders a rectangle with transparency
 */
public class TransparencyRectangle extends ZRectangle {

  protected Color color;

  /**
   * Constructor that calls ZRectangle constructor
   *
   * @param x X coordinate of top left corner
   * @param y Y coordinate of top left corner
   * @param w Width of rectangle
   * @param h Height of rectangle
   */
  public TransparencyRectangle(int x, int y, int w, int h) {
    super(x,y,w,h);
  }

  /**
   * Creates a composite value to allow transparency
   *
   * @param alpha Amount of transparency
   */
  private AlphaComposite makeComposite(float alpha) {
    int type = AlphaComposite.SRC_OVER;
    return(AlphaComposite.getInstance(type, alpha));
  }

  /**
   * Sets the fill color for the rectangle
   */
  public void setFill(Color color) {
    this.color = color;
  }

  /**
   * Renders the sensor mote according to the selected sensor type and the visualization type
   *
   * @param renderContext Jazz object to use for rendering
   */
  public void render(ZRenderContext renderContext) {
    Graphics2D g2 = renderContext.getGraphics2D(); 

    Composite originalComposite = g2.getComposite();
    g2.setComposite(makeComposite(0.7f));
    g2.setPaint(getFillPaint());
    g2.fillRect(((int)rectangle.getX()), ((int)rectangle.getY()), ((int)rectangle.getWidth()), ((int)rectangle.getHeight()));
    g2.setComposite(originalComposite);
  }
}