// $Id: RadioLinkPlugin.java,v 1.2 2003/10/20 22:35:57 mikedemmer Exp $

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
 * Authors:	Nelson Lee
 * Date:        December 11 2002
 * Desc:        Default Mote Plugin
 *              Implements functionality for viewing packets received
 *              by motes
 *
 */

/**
 * @author Nelson Lee
 */


package net.tinyos.sim.plugins;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

/* All plugins must extend the 'Plugin' class. 'SimConst' provides
 * some useful constants.
 */
public class RadioLinkPlugin extends GuiPlugin implements SimConst {
  private static final int BROADCAST_ADDR = 0xffff;

  /* Total number of links to draw at once. */
  private static final int numberLinksToRemember = 10;

  /* Data structure for remembering recently-seen radio links. */
  private LinkHolder holder = new LinkHolder(numberLinksToRemember);

  /* The main event-handling function. Every event handled by TinyViz
   * will be delivered to each plugin through this method. There are
   * a few types of events that can be received - see the 'event' 
   * subdirectory. 
   */
  public void handleEvent(SimEvent event) {

    /* An event indicating that a radio message was sent - what we
     * really care about here. 
     */
    if (event instanceof RadioMsgSentEvent) {
      RadioMsgSentEvent rmEvent = (RadioMsgSentEvent)event;
      /* Get the actual message */
      TOSMsg msg = rmEvent.getMessage();
      /* Look at the mote ID of the sender and receiver, add a link */
      holder.addLink(new RadioLink(rmEvent.getMoteID(), msg.get_addr()));
      /* Refresh the display */
      tv.getMotePanel().refresh();

    } else if (event instanceof SimObjectEvent) {

      /* These events occur when motes are added or removed from the 
       * display. 
       */
      SimObjectEvent simObjectEvent = (SimObjectEvent)event;
      switch (simObjectEvent.getType()) {
	case SimObjectEvent.OBJECT_ADDED:
	  // do nothing
	  break;
	case SimObjectEvent.OBJECT_REMOVED:
	  // remove all links associated with the deleted mote
	  if (simObjectEvent.getSimObject() instanceof MoteSimObject) {
	    MoteSimObject m = (MoteSimObject) simObjectEvent.getSimObject();
	    int moteID = m.getID();
	    Enumeration enum = holder.getLinks();
	    while(enum.hasMoreElements()) {
	      RadioLink radioLink = (RadioLink) enum.nextElement();
	      if (radioLink.getMoteSender() == moteID || radioLink.getMoteReceiver() == moteID) {
		holder.removeLink(radioLink);
	      }
	    }
	  }
	  break;
      }
    } else if (event instanceof AttributeEvent) {
      /* These events occur when an attribute changes -- such as the 
       * location of a mote.
       */
      AttributeEvent attributeEvent = (AttributeEvent)event;
      switch (attributeEvent.getType()) {
	case ATTRIBUTE_CHANGED:
	  if (attributeEvent.getAttribute() instanceof MoteCoordinateAttribute)
	    /* Just redraw the mote panel, so our links appear in the 
	     * right place
	     */
	    motePanel.refresh();
      }
    } 
  }

  /* This method is called when a plugin is "registered", ie., enabled
   * by the user from the plugins menu. Here we create the widgets to appear 
   * in the plugin control panel.
   */
  public void register() {
    /* Nothing interesting here but a little informative message. */
    JTextArea ta = new JTextArea(3,40);
    ta.setFont(tv.defaultFont);
    ta.setEditable(false);
    ta.setBackground(Color.lightGray);
    ta.setLineWrap(true);
    ta.setText("Displays recent radio packets.\nBlue circles denote message broadcast.\nRed lines show direct message sent.");
    pluginPanel.add(ta);
  }

  /* This method is called when a plugin is disabled by the user - here
   * we do nothing.
   */
  public void deregister() {}

  /* This method is called when the simulation state is reset, which 
   * may happen when the simulation stops running, or in between 
   * simulations when using AutoRun files. Here we want to clear out our
   * internal state.
   */
  public void reset() {
    holder = new LinkHolder(numberLinksToRemember);
    motePanel.refresh();
  }

  /* Called when it's time to redraw the mote panel. Here we just redraw
   * the arrows representing radio links.
   */
  public void draw(Graphics graphics) {

    /* Iterate through the links */
    Enumeration enum = holder.getLinks();
    while (enum.hasMoreElements()) {
      RadioLink link = (RadioLink)enum.nextElement();
      int sendaddr = link.getMoteSender();
      int recvaddr = link.getMoteReceiver();

      try {
        /* Look up the location of the sender */
	MoteSimObject moteSender = state.getMoteSimObject(link.getMoteSender());
	MoteCoordinateAttribute moteSenderCoordinate = moteSender.getCoordinate();

        /* If it's a broadcast, draw a circle around the mote. */
      	if (recvaddr == BROADCAST_ADDR) {
          /* We use the CoordinateTransformer methods to translate
	   * between virtual mote coordinates and screen coordinates */
	  graphics.setColor(Color.blue);
	  int x = (int)cT.simXToGUIX(moteSenderCoordinate.getX()) - 12;
	  int y = (int)cT.simYToGUIY(moteSenderCoordinate.getY()) - 12;
	  graphics.drawOval(x, y, 24, 24);

	} else {

	  /* If it's a directed message, look up the receiver position */
	  MoteSimObject moteReceiver = state.getMoteSimObject(link.getMoteReceiver());
	  MoteCoordinateAttribute moteReceiverCoordinate = moteReceiver.getCoordinate();

	  /* Draw an arrow. The Arrow class is found in the parent 
	   * directory.
	   */
	  graphics.setColor(Color.magenta);
	  Arrow.drawArrow(graphics,
	      (int)cT.simXToGUIX(moteSenderCoordinate.getX()),
	      (int)cT.simYToGUIY(moteSenderCoordinate.getY()),
	      (int)cT.simXToGUIX(moteReceiverCoordinate.getX()),
	      (int)cT.simYToGUIY(moteReceiverCoordinate.getY()), 
	      Arrow.SIDE_LEAD);
	}
      } catch (NullPointerException e) {
	/* We may get a NullPointerException if the radio message is sent 
	 * from or to a mote we don't know about yet - just ignore this 
	 * link.
	 */
	continue;
      }
    }
  }

  /* The toString() method is important - it gives the plugin a name in
   * the plugins menu and panel. Use a *short* but descriptive name here.
   */
  public String toString() {
    return "Radio links";
  }

  /* Internal class representing radio links. */
  private class RadioLink {
    private int moteSender;
    private int moteReceiver;

    public RadioLink(int moteSender, int moteReceiver) {
      this.moteSender = moteSender;
      this.moteReceiver = moteReceiver;
    }

    public int getMoteSender() {
      return moteSender;
    }

    public int getMoteReceiver() {
      return moteReceiver;
    }
  }

  private class LinkHolder {
    private Vector holder = new Vector();
    private int numLinks;

    public LinkHolder(int numLinks) {
      this.numLinks = numLinks;
    }

    public Enumeration getLinks() {
      return holder.elements();
    }

    public void addLink(RadioLink link) {
      if (holder.size() == numLinks) {
	holder.remove(0);
      }
      holder.add(link);
    }

    public void removeLink(RadioLink link) {
      holder.remove(link);
    }
  }
}


