/** 
 *
 * Reliable Message Injector for the Drip protocol.
 * 
 * @author Gilman Tolle <get@cs.berkeley.edu>
 * @since  0.1
 */

package net.tinyos.drip;

import net.tinyos.message.*;
import net.tinyos.util.*;

import org.apache.log4j.*;

import java.io.*; 
import java.text.*;
import java.util.*;

public class Drip implements MessageListener {

  public static int SEND_COUNT = 12;
  public static int SEND_RATE = DripConsts.DRIP_TIMER_PERIOD;

  public static int WAKEUP_SEND_COUNT = 25;
  public static int WAKEUP_SEND_RATE = 40;

  private Logger log = Logger.getLogger(Drip.class.getName());

  private static final int IDLE = 0;
  private static final int PROBING = 1;
  private static final int SENDING_SEQNO = 2;
  private static final int SENT_SEQNO = 3;
  private static final int SENDING_NEW = 4;

  private int state = IDLE;

  int id;
  int seqno;
  int sendCount = 0;
  int maxSendCount;

  Timer trickle;
  TimerTask trickleTask;

  MoteIF moteIF;
  DripMsg dripMsg;
  boolean hasMessage = false;
  boolean sentOK = true;

  boolean wakeupMsg = false;

  public Drip(int id) {

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

  public Drip(int id, MoteIF p_moteIF) {

    log.info("Started with own moteIF id=" + id);

    try {
      moteIF = p_moteIF;
      moteIF.registerListener(new DripMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    this.id = id;
  }

  void setupDrip(Message msg, int msgSize) {
    trickle = new Timer();
    trickleTask = new DripSender();
    dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + msgSize);
    dripMsg.dataSet(msg.dataGet(), 0, dripMsg.offset_data(0),
		    msgSize);
    sendCount = 0;
  }

  Message buildAddrMsg(int dest, Message msg, int msgSize) {
    AddressMsg addrMsg = new AddressMsg(AddressMsg.DEFAULT_MESSAGE_SIZE + msgSize);
    String moteid = Env.getenv("MOTEID");
    int source = 0xFFFF;
    
    if (moteid != null) {
      source = Integer.parseInt(moteid);
    }

    addrMsg.dataSet(msg.dataGet(), 0, addrMsg.offset_data(0), msgSize);
    
    addrMsg.set_dest(dest);
    addrMsg.set_source(source);

    return addrMsg;
  }

  public synchronized void send(Message msg, int msgSize) {
    setupDrip(msg, msgSize);

    state = PROBING;
    wakeupMsg = false;
    sendCount = 0;
    maxSendCount = SEND_COUNT;
    trickle.schedule(trickleTask, 0, 500);
    try {
      wait();
    } catch (InterruptedException e) {
      // return
    }
  }

  public synchronized void sendAddressed(int dest, Message msg, int msgSize) {

    AddressMsg addrMsg = (AddressMsg) buildAddrMsg(dest, msg, msgSize);
    send(addrMsg, msgSize + AddressMsg.DEFAULT_MESSAGE_SIZE);
  }

  public synchronized void sendUnreliable(Message msg, int msgSize) {
    setupDrip(msg, msgSize);

    state = SENDING_NEW;
    wakeupMsg = false;
    sendCount = 0;
    maxSendCount = 1;
    trickle.schedule(trickleTask, 0, SEND_RATE);
    try {
      wait();
    } catch (InterruptedException e) {
      // return
    }
  }

  public synchronized void sendAddressedUnreliable(int dest, Message msg, 
						   int msgSize) {
    AddressMsg addrMsg = (AddressMsg) buildAddrMsg(dest, msg, msgSize);
    sendUnreliable(addrMsg, msgSize + AddressMsg.DEFAULT_MESSAGE_SIZE);
  }

  public synchronized void sendWakeup(Message msg, int msgSize) {
    setupDrip(msg, msgSize);

    state = SENDING_NEW;
    wakeupMsg = true;
    sendCount = 0;
    maxSendCount = WAKEUP_SEND_COUNT;
    trickle.schedule(trickleTask, 0, WAKEUP_SEND_RATE);
    try {
      wait();
    } catch (InterruptedException e) {
      // return
    }
  }
    
  private synchronized void sendDone() {
    notifyAll();
    state = IDLE;
  }
    
  class DripSender extends TimerTask {
    
    public void run() {

      boolean stopSending = false;

      log.debug("DripSender.run(state=" + state + " sendCount= " + sendCount + ")");

      dripMsg.set_metadata_id((short)id);
      
      switch (state) {
      case PROBING:
	if (sendCount < maxSendCount) {
	  log.debug("probing");
	  dripMsg.set_metadata_seqno((byte)DripConsts.DRIP_SEQNO_OLDEST);
	} else {
	  log.debug("probing finished");
	  stopSending = true;
	}
	break;
      case SENDING_SEQNO:
	if (sendCount < maxSendCount) {
	  log.debug("sending new seqno "+seqno);
	  dripMsg.set_metadata_seqno((byte)seqno);
	} else {
	  log.debug("sending finished");
	  stopSending = true;
	}
	break;
      case SENDING_NEW:
	if (sendCount < maxSendCount) {
	  log.debug("sending unreliably");
	  dripMsg.set_metadata_seqno((byte)DripConsts.DRIP_SEQNO_NEWEST);
	} else {
	  log.debug("sending unreliably finished");
	  stopSending = true;
	}
	break;
      case SENT_SEQNO:
	log.debug("done sending");
	stopSending = true;
	return;
      default:
      }
      
      if (wakeupMsg == true) {
	dripMsg.set_metadata_seqno((short)((dripMsg.get_metadata_seqno()+1) % 256));
      }

      if (stopSending) {
	trickle.cancel();
	trickleTask.cancel();
	sendDone();
      } else {
	log.info("Sending Msg " + sendCount + ": id=" + id + ",seqno=" + dripMsg.get_metadata_seqno());
	send(dripMsg);
	sendCount++;
      }
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

  public void messageReceived(int to, Message m) {
	
    DripMsg msg = (DripMsg)m;
	
    int newId = msg.get_metadata_id();
    int newSeqno = msg.get_metadata_seqno();

    log.debug("Received Msg: id=" + newId + ",seqno=" + newSeqno);
	
    if (newId != id) {
      log.debug("dropped, not ID " + id);
      return;
    }

    if ((newSeqno & ~DripConsts.DRIP_WAKEUP_BIT) == DripConsts.DRIP_SEQNO_NEWEST) {
      log.debug("dropped, a special seqno " + newSeqno);
      return;
    }

    switch (state) {
    case PROBING:
      seqno = newSeqno;
      log.info("Receive: id=" + id + ",seqno=" + dripMsg.get_metadata_seqno() + " Heard Old Seqno");
      incrementSeqno();
      state = SENDING_SEQNO;
    case SENDING_SEQNO:
      if (seqno == newSeqno) {
	log.info("Receive: id=" + id + ",seqno=" + dripMsg.get_metadata_seqno() + " Heard New Seqno");
	trickle.cancel();
	trickleTask.cancel();
	sendDone();
      }
    default:
    }
  }
    
  private void incrementSeqno() {
    if (wakeupMsg && ((seqno & DripConsts.DRIP_WAKEUP_BIT) == 0)) {
      seqno = (seqno + 1) % 256;      
    }

    if (!wakeupMsg && ((seqno & DripConsts.DRIP_WAKEUP_BIT) == 1)) {
      seqno = (seqno + 1) % 256;
    }

    seqno = (seqno + 1) % 256;
    seqno = (seqno + 1) % 256;

    while ((seqno & ~DripConsts.DRIP_WAKEUP_BIT) == DripConsts.DRIP_SEQNO_OLDEST ||
	   (seqno & ~DripConsts.DRIP_WAKEUP_BIT) == DripConsts.DRIP_SEQNO_NEWEST ||
	   (seqno & ~DripConsts.DRIP_WAKEUP_BIT) == DripConsts.DRIP_SEQNO_UNKNOWN) {

      seqno = (seqno + 1) % 256;
      seqno = (seqno + 1) % 256;
    }
  }

  private static int data = 1000;
  private static int channel = 254;
  private static boolean wakeup = false;

  public static void main(String[] args) {

    parseArgs(args);

    Drip drip = new Drip(channel);
    TestDripMsg msg = new TestDripMsg();
    msg.set_data((short)data);
    
    if (wakeup) {
      drip.sendWakeup(msg, TestDripMsg.DEFAULT_MESSAGE_SIZE);
    } else {
      drip.send(msg, TestDripMsg.DEFAULT_MESSAGE_SIZE);
    }
    System.exit(0);
  }

  private static void parseArgs(String args[]) {

    ArrayList cleanedArgs = new ArrayList();

    for(int i = 0; i < args.length; i++) {
      if (args[i].startsWith("--")) {

        // Parse Long Options
        String longopt = args[i].substring(2);
	
	if (longopt.equals("help")) {
	  usage();
	}

      } else if (args[i].startsWith("-")) {

        // Parse Short Options
	String opt = args[i].substring(1);

	if (opt.equals("d")) {
	  data = Integer.parseInt(args[++i]);
	} else if (opt.equals("w")) {
	  wakeup = true;
	} else if (opt.equals("c")) {
	  channel = Integer.parseInt(args[++i]);
	} else if (opt.equals("h")) {
	  usage();
	}
	
      } else {

        // Place into args string
        cleanedArgs.add(args[i]);
      }
    }
  }

  private static void usage() {
    System.err.println("usage: java net.tinyos.drain.Drip <opts>");
    System.err.println("  -d <data value>");
    System.err.println("  -c <channel id>");
    System.err.println("  -w : send message with wakeup bit set");
    System.err.println("  -h, --help : this information");
    System.exit(1);
  }

}
