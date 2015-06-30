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
import javax.swing.JOptionPane;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

/**
 * This class is an event handler for dealing with mouse events, for the purpose of removing motes
 * from the screen.
 */
public class RemoveEventHandler extends ZMouseAdapter implements ZEventHandler {

  private ZCanvas canvas = null;
  // The camera node on which this event handler listens
  ZNode node = null;
  // The layer to which new links are added
  ZLayerGroup moteLayer;

  boolean active = false;
  private Motes motes;
  private ChangeListener listener;

  /**
   * Constructor for the remove event handler
   *
   * @param canvas Canvas to remove motes from
   * @param layer Jazz layer containing motes to modify
   * @param motes List of motes to modify
   * @param listener Listener object for change events in mote population
   */
  public RemoveEventHandler(ZCanvas canvas, ZLayerGroup layer, Motes motes, ChangeListener listener) {
    this.canvas = canvas;
    this.node = canvas.getCameraNode();
    this.moteLayer = layer;
    this.motes = motes;
    this.active = false;
    this.listener = listener;
  }

  /**
   * Returns whether the event handler is active or not.
   *
   * @return Whether the event handler is active or not
   */
  public boolean isActive() {
    return active;
  }

  /**
   * This method handles mouse pressed events. If the mouse is pressed over a mote, the user is
   * asked to confirm the removal of a mote. If confirmed, the mote is removed from the screen and
   * all data structures.
   *
   * @param e Mouse press event to handle
   */
  public void mousePressed(ZMouseEvent e) {
    if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) == MouseEvent.BUTTON1_MASK) {
      ZNode pickNode = e.getPath().getNode();
      if (pickNode instanceof ZVisualLeaf) {
        ZVisualComponent vis = ((ZVisualLeaf)pickNode).getFirstVisualComponent();
        if (vis instanceof Mote) {
          int option = JOptionPane.showConfirmDialog(canvas, "Delete this mote?", "Delete this mote?", JOptionPane.YES_NO_OPTION);
          if (option == JOptionPane.YES_OPTION) {
            motes.remove((Mote)vis);
            ZLayerGroup layer = canvas.getLayer();
            layer.removeChild((ZVisualLeaf)pickNode);
            listener.changed();
          }
        }
      }
    }
  }

  /**
   * Sets the event handler to be active or not
   *
   * @param active Whether the event handler should be active or not
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