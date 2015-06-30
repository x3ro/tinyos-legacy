// $Id: DripDaemon.java,v 1.2 2005/10/31 17:04:53 gtolle Exp $

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
 * Daemon-style continual message injector for the Drip protocol.
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

public class DripDaemon implements MessageListener {

  private Logger log = Logger.getLogger(DripDaemon.class.getName());

  MoteIF moteIF;

  int id;
  int seqno;
  Message store;
  int storeSize;
  boolean storeForever;
  boolean newStore;
  boolean doneInjecting;

  Timer trickle = new Timer();
  TimerTask trickleTimer = new DripSender();

  int period;
  int round;


  public DripDaemon(int id) {
    
    log.info("Started id=" + id);

    try {
      moteIF = new MoteIF();
      moteIF.registerListener(new DripMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    this.id = id;
  }

  public void storeOnce(Message m, int size) {
    store(m, size, false);
  }

  public void storeForever(Message m, int size) {
    store(m, size, true);
  }

  private void store(Message m, int size, boolean forever) {
    log.info("id=" + id + ": storing new message");

    doneInjecting = false;

    store = m;
    storeSize = size;
    storeForever = forever;

    newStore = true;
    seqno = DripConsts.DRIP_SEQNO_OLDEST;


    round = 0;
    period = DripConsts.DRIP_TIMER_PERIOD * (1 << round);
    
    trickleTimer.cancel();
    trickleTimer = new DripSender();
    trickle.schedule(trickleTimer, period);
  }

  public void messageReceived(int to, Message m) {
    
    DripMsg msg = (DripMsg)m;
    
    int newId = msg.get_metadata_id();
    int newSeqno = msg.get_metadata_seqno();
    
    log.info("id=" + id + ": received msg id=" + newId + ",seqno=" + newSeqno);
	
    if (newId != id) {
      return;
    }

    if (doneInjecting) {
      return;
    }

    if (newStore) {
      seqno = newSeqno;
      log.info("id=" + id + ": heard packet with old seqno = " + seqno);
      incrementSeqno();
      log.info("id=" + id + ": injecting packet with new seqno = " + seqno);
      newStore = false;
    } else {
      if (storeForever) {
	if (newSeqno > seqno) {
	  seqno = newSeqno;
	  log.info("id=" + id + ": (subsequent) heard packet with old seqno = " + seqno);
	  incrementSeqno();
	  log.info("id=" + id + ": (subsequent) injecting packet with new seqno = " + seqno);
	}
      } else {
	if (seqno == newSeqno) {
	  log.info("id=" + id + ": done injecting");
	  doneInjecting = true;
	  trickleTimer.cancel();
	}
      }
    }

    if (seqno != newSeqno) {
      round = 0;
      period = DripConsts.DRIP_TIMER_PERIOD * (1 << round);
      
      trickleTimer.cancel();
      trickleTimer = new DripSender();
      trickle.schedule(trickleTimer, period);
    }
  }

  class DripSender extends TimerTask {
    public void run() {

      log.info("id=" + id + ": sending msg seqno=" + seqno);

      DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + storeSize);

      dripMsg.set_metadata_id((short)id);
      dripMsg.set_metadata_seqno((short)seqno);
      dripMsg.dataSet(store.dataGet(), 0, dripMsg.offset_data(0),
		      storeSize);
      send(dripMsg);

      if (round < DripConsts.DRIP_MAX_SEND_INTERVAL) {
	round++;
      }
      period = DripConsts.DRIP_TIMER_PERIOD * (1 << round);
      trickleTimer = new DripSender();
      trickle.schedule(trickleTimer, period);
    }
  }

  private void send(Message m) {
    try {
      moteIF.send(MoteIF.TOS_BCAST_ADDR, m);
    } catch (IOException e) {
      e.printStackTrace();
      System.out.println("ERROR: Can't send message");
      System.exit(1);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private void incrementSeqno() {
    seqno = (seqno + 1) % 256;
    seqno = (seqno + 1) % 256;

    while ((seqno & ~DripConsts.DRIP_WAKEUP_BIT) == DripConsts.DRIP_SEQNO_OLDEST ||
	   (seqno & ~DripConsts.DRIP_WAKEUP_BIT) == DripConsts.DRIP_SEQNO_NEWEST ||
	   (seqno & ~DripConsts.DRIP_WAKEUP_BIT) == DripConsts.DRIP_SEQNO_UNKNOWN) {


      seqno = (seqno + 1) % 256;
      seqno = (seqno + 1) % 256;
    }

    seqno &= ~DripConsts.DRIP_WAKEUP_BIT;
  }
}
