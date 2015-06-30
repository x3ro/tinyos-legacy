// $Id: MouseHandler.java,v 1.8 2004/10/21 22:26:38 selfreference Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Phil Levis, Nelson Lee
 * Date:        October 11 2002
 * Desc:        Template for Java classes in the sim package.
 *
 */

/**
 * @author Phil Levis
 * @author Nelson Lee
 */


package net.tinyos.sim;

import net.tinyos.sim.event.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

public class MouseHandler implements MouseListener, MouseMotionListener {
  private SimDebug debug = SimDebug.get("mouse");

  private MotePanel motePanel;

  private int pressedX;
  private int pressedY;
  private int lastX;
  private int lastY;

  private Vector objectsMoved = new Vector();
  private boolean objectMoved = false;  
  private boolean selected = false;  
  private boolean highlighting = false;
  private SimEventBus eventBus = null;
  private SimState state = null;
  private CoordinateTransformer cT;

  public MouseHandler(MotePanel motePanel, TinyViz tv) {
    this.motePanel = motePanel;
    this.eventBus = tv.getSimDriver().getEventBus();
    this.state = tv.getSimDriver().getSimState();
    this.cT = tv.getCoordTransformer();
  }

    public void draw(Graphics graphics) {
      int cornerX;
      int cornerY;
      int widthX;
      int widthY;
      if (highlighting) {
	if (pressedX > lastX) {
	  cornerX = lastX;
	  widthX = pressedX-lastX;
	}
	else {
	  cornerX = pressedX;
	  widthX = lastX-pressedX;
	}
	if (pressedY > lastY) {
	  cornerY = lastY;
	  widthY = pressedY-lastY;
	}
	else {
	  cornerY = pressedY;
	  widthY = lastY-pressedY;
	}
	
	debug.out.println("mouse: drawing in mousehandler");
	graphics.setColor(Color.lightGray);
	debug.out.println("mouse: pressedX = " + pressedX + ", pressedY = " + pressedY);
	graphics.drawRect(cornerX, cornerY, widthX, widthY);
      }
    }

  public void activatePopupMenu(SimObject s, MouseEvent e) {
    SimObjectPopupMenu popup = s.getPopupMenu();
    if (popup != null) {
      popup.setSimObjectSelected(s);
      motePanel.refresh(popup, e);
    }
  }
    
  public void selectAllSimObjects() {
    double x1,x2,y1,y2;

    if (pressedX > lastX) {
      x1 = lastX;
      x2 = pressedX;
    }
    else {
      x1 = pressedX;
      x2 = lastX;
    }

    if (pressedY > lastY) {
      y1 = lastY;
      y2 = pressedY;
    }
    else {
      y1 = pressedY;
      y2 = lastY;
    }

    debug.out.println("mouse: before getSimObjects");
    Iterator it = state.getSimObjects().iterator();
    debug.out.println("mouse: before while loop");
    while (it.hasNext()) {
	debug.out.println("mouse: getting next sim object");	  
	SimObject s = (SimObject)it.next();
	debug.out.println("mouse: checking if in object space");
	if (s.simObjectInQuad(cT.guiXToSimX(x1), cT.guiYToSimY(y1),
                              cT.guiXToSimX(x2), cT.guiYToSimY(y2))) {
	    debug.out.println("mouse: selecting object");
	    s.setSelected();
	    selected = true;
	    debug.out.println("mouse: done selecting object");
	}
	debug.out.println("mouse: done with if check");
    }
  }

  public void unselectAllSimObjects() {
    Iterator it = state.getSimObjects().iterator();
    while (it.hasNext()) {
      SimObject s = (SimObject)it.next();
      s.setUnselected();
    }
    selected = false;
  }

  public void mousePressed(MouseEvent e) {
      //System.err.println("Mouse pressed.");
      synchronized (eventBus) {
	  if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	      SimObject s = state.getSimObjectAtPoint(cT.guiXToSimX(e.getX()),
                                                      cT.guiYToSimY(e.getY()));
	      if (s == null) {
		  unselectAllSimObjects();
		  highlighting = true;
	      }
	      else {
		  highlighting = false;
		  if (!s.isSelected()) {
		      unselectAllSimObjects();
		      s.setSelected();
		      selected = true;
		  }
	      }

	      pressedX = e.getX();
	      pressedY = e.getY();
	      lastX = pressedX;
	      lastY = pressedY;
	  }

	  else if ((e.getModifiers() & MouseEvent.BUTTON3_MASK) != 0) {
	      if (e.isPopupTrigger()) {
		  debug.out.println("mouse: PopupTriggered in MousePressedEvent");
		  SimObject s = state.getSimObjectAtPoint(cT.guiXToSimX(e.getX()),
                                                          cT.guiYToSimY(e.getY()));
		  if (s != null) {
		      activatePopupMenu(s, e);
		  }
	      }
	  }
	  motePanel.refresh();
      }
  }
    
  public void mouseReleased(MouseEvent e) {
      //System.err.println("Mouse released.");
      synchronized (eventBus) {      
	  if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	      // once mouse button 1 is released, there is no way
	      // highlighting can still be occuring
	      highlighting = false;
	      if (selected) {
		  eventBus.addEvent(new SimObjectsSelectedEvent(state.getSelectedSimObjects()));
	      }
	      if (objectMoved) {
		  Enumeration elements = objectsMoved.elements();
		  while (elements.hasMoreElements()) {
		      SimObject s = (SimObject)elements.nextElement();
                      // XXX/demmer this could be folded into the
                      // moveSimObject call itself which would obviate
                      // the need for this api call
		      s.addAttributeChangedEvent(s.getCoordinate());
		      objectMoved = false;
		  }
		  objectsMoved = new Vector();
	      }
	  }
	  else if ((e.getModifiers() & MouseEvent.BUTTON3_MASK) != 0) {
	      if (e.isPopupTrigger()) {
		  debug.out.println("mouse: PopupTriggered in MouseReleasedEvent");
		  SimObject s = state.getSimObjectAtPoint(cT.guiXToSimX(e.getX()),
                                                          cT.guiYToSimY(e.getY()));
		  if (s != null) {
		      activatePopupMenu(s, e);
		  }
		  
	      }
	  }
	  motePanel.refresh();
      }
  }
    
  public void mouseEntered(MouseEvent e) {/* do nothing */}

  public void mouseExited(MouseEvent e) {/* do nothing */}

  public void mouseClicked(MouseEvent e) {
      debug.out.println("mouse: Mouse clicked.");
      // On left mouseclock, select the node
      synchronized (eventBus) {      
	  if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	      SimObject s = state.getSimObjectAtPoint(cT.guiXToSimX(e.getX()),
                                                      cT.guiYToSimY(e.getY()));
	      if (s == null) 
		  unselectAllSimObjects();
	  }
	  // On middle mouseclick, delete the mote
	  else if ((e.getModifiers() & MouseEvent.BUTTON2_MASK) != 0) {
            SimObject s = state.getSimObjectAtPoint(cT.guiXToSimX(e.getX()),
                                                    cT.guiYToSimY(e.getY()));
            if (s != null) {
		  debug.out.println("mouse: Removing SimObject " + s);
		  state.removeSimObject(s);
	      }
	  }
	  // On right mouseclick, place new SimObject
	  else if ((e.getModifiers() & MouseEvent.BUTTON3_MASK) != 0) {
	      if (e.isPopupTrigger()) {
		  debug.out.println("mouse: PopupTriggered in MouseClickedEvent");
		  SimObject s = state.getSimObjectAtPoint(cT.guiXToSimX(e.getX()),
                                                          cT.guiYToSimY(e.getY()));
		  if (s != null) {
		      activatePopupMenu(s, e);
		  }
		  
	      }
	  }
	  motePanel.refresh();
      }
  }

  public void mouseDragged(MouseEvent e) {
      boolean simObjectDragged = false;
      debug.out.println("mouse: Mouse dragged called.");
      synchronized (eventBus) {      
	  lastX = e.getX();
	  lastY = e.getY();
	  debug.out.println("mouse: Mouse dragged.");
	  if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) != 0) {
	      if (!highlighting) {
		  Iterator it = state.getSimObjects().iterator();
		  while (it.hasNext()) {
		      simObjectDragged = true;
		      SimObject s = (SimObject)it.next();
		      CoordinateAttribute coordAttrib = s.getCoordinate();
		      if (s.isSelected()) {
                          double dx = cT.guiXToSimX(lastX-pressedX);
                          double dy = cT.guiYToSimY(lastY-pressedY);
                          s.moveSimObjectNoEvent(dx, dy);
			  if (!objectsMoved.contains(s))
			      objectsMoved.add(s);
			  objectMoved = true;
		      }
		  }
		  if (simObjectDragged) {
		      eventBus.addEvent(new SimObjectDraggedEvent());
		  }
		  pressedX = lastX;
		  pressedY = lastY;
	      }
	      else {
		  synchronized (state) {
		      debug.out.println("mouse: before unselect");
		      unselectAllSimObjects();
		      debug.out.println("mouse: before select");
		      selectAllSimObjects();
		      debug.out.println("mouse: after select");
		  }
	      }
	      motePanel.refresh();
	  }
	  
	  else if ((e.getModifiers() & MouseEvent.BUTTON3_MASK) != 0) {
            if (e.isPopupTrigger()) {
              debug.out.println("mouse: PopupTriggered in MouseDraggedEvent");
              SimObject s = state.getSimObjectAtPoint(cT.guiXToSimX(e.getX()),
                                                      cT.guiYToSimY(e.getY()));
	      if (s != null) {
                activatePopupMenu(s, e);
	      }
	      motePanel.refresh();
            }
	  }
      }
      debug.out.println("mouse: Mouse dragged done.");
  }
    
  public void mouseMoved(MouseEvent e) {}

}






