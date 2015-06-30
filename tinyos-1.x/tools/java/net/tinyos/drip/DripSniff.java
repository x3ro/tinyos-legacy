// $Id: DripSniff.java,v 1.2 2005/10/31 17:04:53 gtolle Exp $

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
 * Packet Sniffer for the Drip protocol
 * 
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

package net.tinyos.drip;

import net.tinyos.message.*;
import net.tinyos.util.*;

import org.apache.log4j.*;

import java.io.*; 
import java.text.*;
import java.util.*;
import java.net.*;

public class DripSniff {
  private MoteIF moteIF;

  public DripSniff() {
    moteIF = new MoteIF();
    moteIF.registerListener(new DripMsg(), new DripMsgReceiver());
  }

  private class DripMsgReceiver implements MessageListener {
    synchronized public void messageReceived(int to, Message m) {
      
      DripMsg mhMsg = (DripMsg)m;
      
      System.out.print("incoming: " +
		       " id: " + mhMsg.get_metadata_id() + 
		       " seqno: " + mhMsg.get_metadata_seqno());
      if (mhMsg.get_metadata_seqno() == 2) {
	System.out.print(" -- new node -- ");
      }

      System.out.println("");
    }
  }

  public static void main(String args[]) {
    DripSniff ds = new DripSniff();
  }
}
