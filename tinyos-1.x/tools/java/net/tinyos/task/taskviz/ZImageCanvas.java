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
    private ZVisualLeaf leaf = null;

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

    public ZVisualLeaf getLeaf() {
	return leaf;

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
    leaf2.setSelectable(false);
    leaf2.setPickable(false);
    leaf2.setFindable(false);
    getLayer().addChild(leaf2);

    // add the image if there is one
    if (haveImage) {
      leaf = new ZVisualLeaf(new ZImage(image));
      leaf.setSelectable(false);
      leaf.setPickable(false);
      leaf.setFindable(false);
      getLayer().addChild(leaf);
    }
    else {
      zrect.setFillPaint(Color.lightGray);
    } 
      
    // set the default navigation handlers to be inactive
    setNavEventHandlersActive(false);
  }
}
