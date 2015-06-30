// $Id: PacketLoggerPlugin.java,v 1.5 2003/11/24 23:02:59 scipio Exp $

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
 * Authors:	Philip Levis
 * Date:        November 20 2003
 * Desc:        Logs all packets sent
 *
 */

/**
 * @author Philip Levis
 */


package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class PacketLoggerPlugin extends Plugin implements SimConst {
  private static SimDebug debug = SimDebug.get("packetlog");
  private Vector packetsByTime;
  private Hashtable packetsByMote;

  private Hashtable types;

  public void handleEvent(SimEvent event) {
    if (event instanceof RadioMsgSentEvent) {
      RadioMsgSentEvent rmse = (RadioMsgSentEvent)event;
      
      PacketLogEntry entry = new PacketLogEntry(rmse.getTime(), rmse.getMoteID(), rmse.getMessage());
      packetsByTime.addElement(entry);
      
      Vector moteVector;
      if (packetsByMote.containsKey(new Integer(rmse.getMoteID()))) {
        moteVector = (Vector)packetsByMote.get(new Integer(rmse.getMoteID()));
      }
      else {
        moteVector = new Vector();
        packetsByMote.put(new Integer(rmse.getMoteID()), moteVector);
      }
      moteVector.addElement(entry);
    }
  }

  public void register() {
    debug.out.println("PACKETLOGGERPLUGIN: registering packet logger plugin");
    packetsByTime = new Vector();
    packetsByMote = new Hashtable();
    types = new Hashtable();
  }

  public void deregister() {}
  
  public String toString() {
    return "Packet Logger (non-gui)";
  }

  public Vector getPackets() {
    return packetsByTime;
  }

  public int numTransmitters() {
    return packetsByMote.size();
  }
  public Enumeration getTransmittingMotes() {
    return packetsByMote.keys();
  }
	
  public Vector getPackets(int moteID) {
    if (packetsByMote.containsKey(new Integer(moteID))) {
      Vector v = (Vector)packetsByMote.get(new Integer(moteID));
      v = (Vector)v.clone();
      return v;
    }
    else {
      return new Vector();
    }
  }

}
