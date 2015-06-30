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

import net.tinyos.task.taskviz.sensor.SensorMote;

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
public class MoveEventHandler2 implements ZMouseMotionListener, ZEventHandler {
  private ZCanvas canvas;
  private Point pt;
  private boolean active;
  private ZNode node;
  private int imageWidth;
  private int imageHeight;
  private ZNode oldNode = null;
  private boolean highlight;
  private JPopupMenu menu = null;

  /**
   * Constructor for the move event handler with highlight set to false
   *
   * @param canvas Canvas being watched for events
   * @param imageWidth Width of the background image
   * @param imageHeight Height of the background image
   */
  public MoveEventHandler2(ZCanvas canvas, int imageWidth, int imageHeight) {
    this.canvas = canvas;
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
   * @param imageWidth Width of the background image
   * @param imageHeight Height of the background image
   * @param highlight Indicates whether or not to hightlight motes
   */
  public MoveEventHandler2(ZCanvas canvas, int imageWidth, int imageHeight, boolean highlight) {
    this(canvas, imageWidth, imageHeight);
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
      
    if (highlight) {
      // unhighlight previously highlighted mote, if any
      if (oldNode instanceof ZVisualLeaf) {
        ZVisualComponent vis = ((ZVisualLeaf)oldNode).getFirstVisualComponent();
        if (vis instanceof SensorMote) {
          SensorMote mote = (SensorMote)vis;
          mote.setFillPaint(Mote.FILL_COLOR);
          if (menu != null) {
            menu.setVisible(false);
          }
        }
      }

      ZNode pickNode = path.getNode();
      oldNode = pickNode;

      // highlight mote nodes as mouse crosses over them
      if (oldNode instanceof ZVisualLeaf) {
        ZVisualComponent vis = ((ZVisualLeaf)oldNode).getFirstVisualComponent();
        if (vis instanceof SensorMote) {
          SensorMote mote = (SensorMote)vis;
          mote.setFillPaint(Mote.HIGHLIGHT_COLOR);
          menu = new JPopupMenu();
          menu.add(new JMenuItem(String.valueOf(mote.getId())));
          menu.addSeparator();
          for (int i=0; i<SensorMote.SENSOR_SIZE; i++) {
            int val = mote.getSensorValue(i);
//System.out.println("menu: "+i+", "+val);
            if (val > 0) {
              String att = mote.getSensorAttribute(i);
              menu.add(new JMenuItem(att+": "+String.valueOf(val)));
            }
          }
          menu.show(canvas, me.getX(), me.getY());
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

