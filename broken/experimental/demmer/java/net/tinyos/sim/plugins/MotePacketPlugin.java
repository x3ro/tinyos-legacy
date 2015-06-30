// $Id: MotePacketPlugin.java,v 1.2 2003/10/20 22:35:57 mikedemmer Exp $

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

public class MotePacketPlugin extends GuiPlugin implements SimConst {
  private static final int MAX_DISPLAY = 22;
  private static final int MAX_MESSAGES = 500;
  private JCheckBox cbSelectedOnly;
  private boolean selectedOnly = false;
  private MoteMessageList msgList;
  private MoteSimObject lastMote = null;
  private Color bgColor = new Color(230,230,230);
  private Color otherColor = Color.white;

  public void handleEvent(SimEvent event) {
    if (event instanceof RadioMsgSentEvent) {
      RadioMsgSentEvent revent = (RadioMsgSentEvent)event;
      TOSMsg msg = revent.getMessage();
      MoteSimObject mote = state.getMoteSimObject(revent.getMoteID());

      if (mote != lastMote) {
	Color tmp = bgColor;
    	bgColor = otherColor;
	otherColor = tmp;
	lastMote = mote;
      }
      msgList.addMessage(msg.toString(), mote, Color.black, bgColor);
    } else if (event instanceof SimObjectsSelectedEvent) {
      SimObjectsSelectedEvent selEvent = (SimObjectsSelectedEvent)event;
      msgList.setSelected(selEvent.getSelectedSimObjects());
    }
  }

  public void register() {
    JPanel selPane = new JPanel();
    cbSelectedOnly = new JCheckBox("Selected motes only", selectedOnly);
    cbSelectedOnly.addItemListener(new cbListener());
    cbSelectedOnly.setFont(tv.labelFont);
    selPane.add(cbSelectedOnly);

    msgList = new MoteMessageList(MAX_DISPLAY, MAX_MESSAGES);
    pluginPanel.setLayout(new BorderLayout());
    pluginPanel.add(selPane, BorderLayout.NORTH);
    pluginPanel.add(msgList, BorderLayout.CENTER);
    pluginPanel.revalidate();
    msgList.revalidate();
  }

  public void deregister() { 
  }

  public void draw(Graphics graphics) {}

  public String toString() {
    return "Sent radio packets";
  }

  class cbListener implements ItemListener {
    public void itemStateChanged(ItemEvent e) {
      selectedOnly = (e.getStateChange() == e.SELECTED);
      msgList.setSelectedOnly(selectedOnly);
    }
  }
}

