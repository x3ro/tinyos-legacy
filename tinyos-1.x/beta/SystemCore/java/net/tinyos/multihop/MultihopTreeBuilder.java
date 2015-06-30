package net.tinyos.multihop;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;
import java.util.*;

public class MultihopTreeBuilder implements Runnable {

  private MoteIF moteIF;

  private static final int BEACON_PERIOD = 8*1024;
  private int beaconPeriod;
  private int spAddr;
  private int beaconSeqno = 1;
  MultihopBeaconMsg beaconMsg = new MultihopBeaconMsg();
  
  MultihopTreeBuilder(int period) {
    beaconPeriod = period;

    String moteid = Env.getenv("MOTEID");
    if (moteid == null) {
      this.spAddr = MultihopConnector.DEFAULT_MOTE_ID;
    } else {
      this.spAddr = Integer.parseInt(moteid);
    }

    beaconSeqno = 0;
    beaconMsg.set_beaconPeriod(beaconPeriod);
    beaconMsg.set_parent(0xffff);
    beaconMsg.set_sourceAddr(spAddr);
    beaconMsg.set_treeID(spAddr);
    beaconMsg.set_cost(0);
    beaconMsg.set_timestamp(System.currentTimeMillis());

    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    System.out.println(beaconMsg);
    send(beaconMsg);

    moteIF.start();
    Thread thread = new Thread(this);
    thread.setDaemon(true);
    thread.start();
  }

  public void run() {
    while(true) {
      try {

	//	beaconMsg.set_beaconSeqno((short)beaconSeqno++);    
	beaconMsg.set_timestamp(System.currentTimeMillis());

//	System.out.println(beaconMsg);
	send(beaconMsg);
	Thread.sleep(beaconPeriod);

      } catch (Exception e) {
	e.printStackTrace();
      }
    }
  }

  public synchronized void send(Message m) {
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

  public static void main(String args[]) {
    
    int period = BEACON_PERIOD;

    if (args.length < 0) {
      System.err.println("usage: java net.tinyos.multihop.MultihopTreeBuilder [beacon period (ms)]");
      System.exit(1);
    }

    if (args.length == 1) {
      period = Integer.parseInt(args[0]);
    }
    MultihopTreeBuilder mtb = new MultihopTreeBuilder(period);
  }
}
