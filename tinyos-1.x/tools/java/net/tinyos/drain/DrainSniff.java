// $Id: DrainSniff.java,v 1.1 2005/10/31 17:07:20 gtolle Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/** 
 *
 * Packet Sniffer for the Drain protocol.
 * 
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

package net.tinyos.drain;

import net.tinyos.message.*;
import net.tinyos.util.*;

import org.apache.log4j.*;

import java.io.*; 
import java.text.*;
import java.util.*;
import java.net.*;

public class DrainSniff {
  private MoteIF moteIF;

  public DrainSniff() {
    moteIF = new MoteIF();
    moteIF.registerListener(new DrainMsg(), new DrainMsgReceiver());
    moteIF.registerListener(new DrainBeaconMsg(), new DrainBeaconMsgReceiver());
  }

  private class DrainMsgReceiver implements MessageListener {
    synchronized public void messageReceived(int to, Message m) {
      
      DrainMsg mhMsg = (DrainMsg)m;
      
      System.out.println("incoming: " +
			 " source: " + mhMsg.get_source() + 
			 " dest: " + mhMsg.get_dest() + 
			 " local-dest: " + to +
			 " type: " + mhMsg.get_type() +
			 " hops: " + (16 - mhMsg.get_ttl()));
    }
  }

  private class DrainBeaconMsgReceiver implements MessageListener {
    synchronized public void messageReceived(int to, Message m) {
      
      DrainBeaconMsg mhMsg = (DrainBeaconMsg)m;
      System.out.println("beacon: " +
			 " treeInstance: " + mhMsg.get_treeInstance() + 
			 " root: " + mhMsg.get_source() +
			 " node: " + mhMsg.get_linkSource() +
			 " parent: " + mhMsg.get_parent() +
			 " cost: " + mhMsg.get_cost() +
			 " ttl: " + mhMsg.get_ttl());
    }
  }

  public static void main(String args[]) {
    DrainSniff ds = new DrainSniff();
  }
}


