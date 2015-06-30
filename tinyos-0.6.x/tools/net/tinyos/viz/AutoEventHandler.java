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

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

/**
 * This class deals with mouse presses when in the automatic mode. This class doesn't work yet.
 * The idea is that when a user clicks on a mote, a menu will popup allowing them to remove or 
 * edit the mote or add a new one. If a user clicks, but not on a mote, a new mote should be 
 * automatically added.
 */
public class AutoEventHandler extends ZMouseAdapter implements ZEventHandler {

  private ZCanvas canvas;
  private boolean active;
  private Motes motes;
  private ZLayerGroup layer;
  private ZNode node;
  private int imageWidth, imageHeight;
  private ZNode pickNode;
  private ZVisualComponent vis;
  private double x, y;

  /**
   * Simple constructor that just stores the incoming parameters
   *
   * @param canvas The canvas to add motes onto
   * @param motes The collection of motes being added to and manipulated
   * @param imageWidth The width of the underlying image being rendered on the canvas
   * @param imageHeight The height of the underlying image being rendered on the canvas
   */
  public AutoEventHandler(ZCanvas canvas, Motes motes, int imageWidth, int imageHeight) {
    this.canvas = canvas;
    this.motes = motes;
    this.imageHeight = imageHeight;
    this.imageWidth = imageWidth;
    this.node = canvas.getCameraNode();
    layer = canvas.getLayer();
  }

  /**
   * On a MousePressed Event, if a mote was the target of the mouse press, a menu is popped up 
   * allowing the user to remove the mote, add a new mote or edit the mote's id. If no mote was the
   * target of the mouse press, a new mote is automatically added and a dialog box appears allowing 
   * the user to enter an id for the mote.
   *
   * @param me The incoming ZMouseEvent: mousePress
   */
  public void mousePressed(ZMouseEvent me) {
    if ((me.getModifiers() & MouseEvent.BUTTON1_MASK) == MouseEvent.BUTTON1_MASK) {
      boolean noMote = true;
      pickNode = me.getPath().getNode();
      if (pickNode instanceof ZVisualLeaf) {
        vis = ((ZVisualLeaf)pickNode).getFirstVisualComponent();

        // if the element clicked on was a mote
        if (vis instanceof Mote) {
          ZSceneGraphPath path = me.getPath();
          Point pt = new Point();
          pt.setLocation(me.getX(), me.getY());
          path.screenToGlobal(pt);
          x = pt.getX();
          y = pt.getY();
   
           // create a popup menu 
          JPopupMenu menu = new JPopupMenu();
          JMenuItem add = new JMenuItem("Add Mote");
          add.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent ae) {
              addMote();
            }
          });
          menu.add(add);

          JMenuItem remove = new JMenuItem("Remove Mote");
          remove.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent ae) {
              int option = JOptionPane.showConfirmDialog(null, "Delete this mote?", "Delete this mote?", JOptionPane.YES_NO_OPTION);
              if (option == JOptionPane.YES_OPTION) {
                motes.remove((Mote)vis);
                layer.removeChild((ZVisualLeaf)pickNode);
              }
            }
          });
          menu.add(remove);

          JMenuItem edit = new JMenuItem("Edit Mote Id");
          edit.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent ae) {
              // use code from addEventHandler (when it's done) to edit mote id
            }
          });
          menu.add(edit);

          canvas.add(menu);
          noMote = false;
        }
      }

      // otherwise, just add a mote
      if (noMote) {
        ZSceneGraphPath path = me.getPath();
        Point pt = new Point();
        pt.setLocation(me.getX(), me.getY());
        path.screenToGlobal(pt);
        x = pt.getX();
        y = pt.getY();
        addMote();
      }
    }
  }

  /**
   * This method adds a mote to the canvas
   */
  private void addMote() {
    // place the mote in the given image space
    if (x < 0) {
      x = 0;
    }
    else if (x >= imageWidth) {
      x = (imageWidth-1);
    }
    if (y < 0) {
      y = 0;
    }
    else if (y >= imageHeight) {
      y = (imageHeight-1);
    }

    Mote mote = new Mote(x,y);
    mote.setPenWidth(Mote.PEN_WIDTH);
    mote.setFillPaint(Color.yellow);
    ZVisualLeaf leaf = new ZVisualLeaf(mote);
    layer.addChild(leaf);

    // AKD - pop up dialog box asking for id
    // AKD - if id is valid (valid int and not already used), then call motes.addMote(mote);
  }

  /**
   * Returns whether this event handler is active or not
   *
   * @return whether this event handler is active or not
   */
  public boolean isActive() {
    return active;
  }

  /**
   * This method sets whether the event handler is active or not.
   *
   * @param active Boolean indicating whether to set the event handler to active or inactive.
   */
  public void setActive(boolean active) {
    if (this.active && !active) {
      this.active = false;
      node.removeMouseListener(this);
    } 
    else if (!this.active && active) {
      this.active = true;
      node.addMouseListener(this);
    }
  }
}