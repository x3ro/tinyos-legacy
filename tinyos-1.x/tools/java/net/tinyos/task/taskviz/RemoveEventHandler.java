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
