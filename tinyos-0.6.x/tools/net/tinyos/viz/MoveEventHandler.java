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

import javax.swing.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

/**
 * This class handles mouse motion events to indicate when the mouse is over a mote
 */
public class MoveEventHandler implements ZMouseMotionListener, ZEventHandler {
  private ZCanvas canvas;
  private Point pt;
  private boolean active;
  private ZNode node;
  private MoveEventListener listener;
  private int imageWidth;
  private int imageHeight;
  private ZNode oldNode = null;
  private boolean highlight;

  /**
   * Constructor for the move event handler with highlight set to false
   *
   * @param canvas Canvas being watched for events
   * @param listener MoveEvent listener
   * @param imageWidth Width of the background image
   * @param imageHeight Height of the background image
   */
  public MoveEventHandler(ZCanvas canvas, MoveEventListener listener, int imageWidth, int imageHeight) {
    this.canvas = canvas;
    this.listener = listener;
    this.imageWidth = imageWidth;
    this.imageHeight = imageHeight;
    pt = new Point();
    node = canvas.getCameraNode();
    active = false;
    highlight = false;
  }

  /**
   * Constructor for the move event handler
   *
   * @param canvas Canvas being watched for events
   * @param listener MoveEvent listener
   * @param imageWidth Width of the background image
   * @param imageHeight Height of the background image
   * @param highlight Indicates whether or not to hightlight motes
   */
  public MoveEventHandler(ZCanvas canvas, MoveEventListener listener, int imageWidth, int imageHeight, boolean highlight) {
    this(canvas, listener, imageWidth, imageHeight);
    this.highlight = highlight;
  }

  /**
   * Returns whether the handler is active or not
   *
   * @return Whether the handler is active or not
   */
  public boolean isActive() {
    return active;
  }

  /**
   * This method handles mouse movement events. If the mouse is over a mote and highlight is true,
   * the mote is highlighted and the previously highlighted one is set to normal
   *
   * @param me Mouse movement event to handle
   */
  public void mouseMoved(ZMouseEvent me) {
    ZSceneGraphPath path = me.getPath();
    pt.setLocation(me.getX(), me.getY());
    path.screenToGlobal(pt);

    double x = pt.getX();
    double y = pt.getY();

    if (x < 0) {
      x = 0.0;
    }
    else if (x > imageWidth) {
      x = imageWidth-1;
    }

    if (y < 0) {
      y = 0.0;
    }
    else if (y > imageHeight) {
      y = imageHeight-1;
    }
      
    listener.setXPos((int)x);
    listener.setYPos((int)y);

    if (highlight) {
      // unhighlight previously highlighted mote, if any
      if (oldNode instanceof ZVisualLeaf) {
        ZVisualComponent vis = ((ZVisualLeaf)oldNode).getFirstVisualComponent();
        if (vis instanceof Mote) {
          Mote mote = (Mote)vis;
          mote.setFillPaint(Mote.FILL_COLOR);
          listener.setId(mote.INVALID_ID);
        }
      }

      ZNode pickNode = path.getNode();
      oldNode = pickNode;

      // highlight mote nodes as mouse crosses over them
      if (oldNode instanceof ZVisualLeaf) {
        ZVisualComponent vis = ((ZVisualLeaf)oldNode).getFirstVisualComponent();
        if (vis instanceof Mote) {
          Mote mote = (Mote)vis;
          mote.setFillPaint(Mote.HIGHLIGHT_COLOR);
          listener.setId(mote.getId());
        }
      }
    }
  }

  /**
   * Method for handling mouse drag events - empty method
   *
   * @param me Mouse drag event to handle
   */
  public void mouseDragged(ZMouseEvent me) {
  }

  /**
   * Sets the event handler to be active or inactive
   *
   * @param active Whether or not to activate the event handler
   */
  public void setActive(boolean active) {
    if (this.active && !active) {
      this.active = false;
      node.removeMouseMotionListener(this);
    }
    else if (!this.active && active) {
      this.active = true;
      node.addMouseMotionListener(this);
    }
  }
}