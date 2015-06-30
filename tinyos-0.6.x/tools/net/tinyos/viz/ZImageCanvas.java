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

import java.awt.Image;
import java.awt.Color;

import edu.umd.cs.jazz.ZVisualLeaf;
import edu.umd.cs.jazz.component.ZRectangle;
import edu.umd.cs.jazz.component.ZImage;
import edu.umd.cs.jazz.util.ZCanvas;

/**
 * This class implements a zoomable (Jazz) canvas that displays a background image
 */
public class ZImageCanvas extends ZCanvas {

  private int imageWidth = 0;
  private int imageHeight = 0;
  private Image image;

  /**
   * Constructor that creates a zoomable canvas with the given background image
   *
   * @param image Image to use as the background 
   */
  public ZImageCanvas(Image image) {
    super();
    this.image = image;
    imageHeight = image.getHeight(null);
    imageWidth = image.getWidth(null);
    createCanvas(true);
  }

  /**
   * Constructor that creates a zoomable canvas with an empty background image
   *
   * @param width Width of the empty background image
   * @param height Height of the empty background image
   */
  public ZImageCanvas(int width, int height) {
    super();
    imageWidth = width;
    imageHeight = height;
    createCanvas(false);
  }

  /**
   * Method that actually adds the image and adds it to the Jazz rendering tree
   *
   * @param haveImage Whether a real image is being used or not
   */
  private void createCanvas(boolean haveImage) {
    // add a rectangle to frame the background image
    ZRectangle zrect = new ZRectangle(0, 0, imageWidth, imageHeight);
    zrect.setPenPaint(Color.black);
    zrect.setPenWidth(2.0);

    ZVisualLeaf leaf2 = new ZVisualLeaf(zrect);
    getLayer().addChild(leaf2);

    // add the image if there is one
    if (haveImage) {
      ZVisualLeaf leaf = new ZVisualLeaf(new ZImage(image));
      getLayer().addChild(leaf);
    }
    else {
      zrect.setFillPaint(Color.lightGray);
    } 
      
    // set the default navigation handlers to be inactive
    setNavEventHandlersActive(false);
  }
}