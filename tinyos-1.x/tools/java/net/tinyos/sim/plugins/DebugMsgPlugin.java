// $Id: DebugMsgPlugin.java,v 1.11 2004/01/10 00:58:22 mikedemmer Exp $

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

public class DebugMsgPlugin extends GuiPlugin implements SimConst {
  private static final int MAX_DISPLAY = 22;
  private static final int MAX_MESSAGES = 500;
  private boolean selectedOnly = false;
  private boolean showDebugMessages = true;
  private boolean showRadioMessages = true;
  private JTextField debugStringMatch;
  private MessageList msgList;
  private int lastMote = 0;
  private Color bgColor = Color.white;
  private Color otherColor = new Color(230,230,230);
  private Color msgColor = new Color(200,0,50);

  public void handleEvent(SimEvent event) {
    if (event instanceof DebugMsgEvent) {
      if (!showDebugMessages) return;
      
      DebugMsgEvent dmEvent = (DebugMsgEvent)event;
      Integer mote = new Integer(dmEvent.getMoteID());
      boolean selected = false;
      if (!selectedOnly || 
	  state.getSelectedMoteSimObjects().contains(state.getMoteSimObject(dmEvent.getMoteID()))) {
	String match = debugStringMatch.getText();
	String msg = dmEvent.getMessage().toLowerCase();
	if (match == null || msg.indexOf(match.toLowerCase()) != -1) {
	  String s = "["+dmEvent.getMoteID()+"] "+dmEvent.getMessage();
	  if (dmEvent.getMoteID() != lastMote) {
	    Color tmp = bgColor;
	    bgColor = otherColor;
	    otherColor = tmp;
	    lastMote = dmEvent.getMoteID();
	  }
	  msgList.addMessage(s, Color.black, bgColor);
	  msgList.revalidate();
	}
      }

    } else if (event instanceof RadioMsgSentEvent) {
      if (!showRadioMessages) return;
      
      RadioMsgSentEvent revent = (RadioMsgSentEvent)event;
      TOSMsg msg = revent.getMessage();
      MoteSimObject mote = state.getMoteSimObject(revent.getMoteID());
      boolean selected = false;
      if (!selectedOnly || 
	  state.getSelectedMoteSimObjects().contains(mote)) {
	if (revent.getMoteID() != lastMote) {
	  Color tmp = bgColor;
	  bgColor = otherColor;
	  otherColor = tmp;
	  lastMote = revent.getMoteID();
	}
	msgList.addMessage("["+revent.getMoteID()+"] Sent "+msg.toString(), msgColor, bgColor);
	msgList.revalidate();
      }
    }
  }

  public void register() {
    JPanel topPane = new JPanel();
    JPanel msgPane = new JPanel();
    JCheckBox cbDebugMsgs;
    cbDebugMsgs = new JCheckBox("Show Debug Messges", showDebugMessages);
    cbDebugMsgs.setFont(tv.labelFont);
    cbDebugMsgs.addItemListener(new ItemListener() {
	public void itemStateChanged(ItemEvent e) {
	  showDebugMessages = (e.getStateChange() == e.SELECTED);
	}
      });
    msgPane.add(cbDebugMsgs);

    JCheckBox cbRadioMsgs;
    cbRadioMsgs = new JCheckBox("Show Radio Messges", showRadioMessages);
    cbRadioMsgs.setFont(tv.labelFont);
    cbRadioMsgs.addItemListener(new ItemListener() {
	public void itemStateChanged(ItemEvent e) {
	  showRadioMessages = (e.getStateChange() == e.SELECTED);
	}
      });
    msgPane.add(cbRadioMsgs);
    
    JPanel selPane = new JPanel();
    JCheckBox cbSelectedOnly;
    cbSelectedOnly = new JCheckBox("Selected motes only", selectedOnly);
    cbSelectedOnly.setFont(tv.labelFont);
    cbSelectedOnly.addItemListener(new ItemListener() {
	public void itemStateChanged(ItemEvent e) {
	  selectedOnly = (e.getStateChange() == e.SELECTED);
	}
      });
    selPane.add(cbSelectedOnly);

    JLabel jl = new JLabel("Match:");
    jl.setFont(tv.defaultFont);
    debugStringMatch = new JTextField(20);
    debugStringMatch.setFont(tv.smallFont);
    debugStringMatch.setEditable(true);
    selPane.add(jl);
    selPane.add(debugStringMatch);

    msgList = new MessageList(MAX_DISPLAY, MAX_MESSAGES);

    topPane.setLayout(new BorderLayout());
    topPane.add(msgPane, BorderLayout.NORTH);
    topPane.add(selPane, BorderLayout.SOUTH);

    pluginPanel.setLayout(new BorderLayout());
    pluginPanel.add(topPane, BorderLayout.NORTH);
    pluginPanel.add(msgList, BorderLayout.CENTER);
    pluginPanel.revalidate();
    msgList.revalidate();
  }

  public void deregister() { 
  }
  public void reset() {
    if (msgList != null) msgList.clear();
  }

  public void draw(Graphics graphics) {}

  public String toString() {
    return "Debug messages";
  }
}

