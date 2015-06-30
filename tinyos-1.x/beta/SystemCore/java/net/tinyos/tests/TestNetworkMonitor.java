package net.tinyos.tests;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;
import java.util.*;

public class TestNetworkMonitor implements Runnable, MessageListener {

  private MoteIF moteIF;
  private int spAddr;
  private HashMap moteTable = new HashMap();

  public TestNetworkMonitor(int spAddr) {

    this.spAddr = spAddr;
    try {
      moteIF = new MoteIF((Messenger)null);
      moteIF.registerListener(new MultihopLayerMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    moteIF.start();
  }

  public void run() {
    while(true) {
      try {

	int count = 0;

	Iterator it = moteTable.values().iterator();
	while (it.hasNext()) {
	  MoteInfo mi = (MoteInfo)it.next();
	  if (System.currentTimeMillis() - mi.lastTime < 32768) {
	    count++;
	  }
	}

	System.out.println("Total: " + moteTable.size() + " Count: " + count);

	Thread.currentThread().sleep(10000);
      } catch (Exception e) {
	e.printStackTrace();
      }
    }
  }

  synchronized public void messageReceived(int to, Message m) {

    MultihopLayerMsg mhMsg = (MultihopLayerMsg)m;
    
    if (mhMsg.get_type() == TestNetworkReportMsg.AM_TYPE &&
	to == spAddr) {

      TestNetworkReportMsg tnrMsg = new TestNetworkReportMsg(mhMsg.dataGet(), 
							     mhMsg.offset_data(0));

      MoteInfo mi = (MoteInfo) moteTable.get(new Integer(mhMsg.get_originaddr()));
      
      if (mi == null) {
	mi = new MoteInfo(new Integer(mhMsg.get_originaddr()));
	
	moteTable.put(new Integer(mhMsg.get_originaddr()), mi);
      }

      mi.lastTime = System.currentTimeMillis();

      System.out.println(mi + ":" + tnrMsg.get_value());
    }
  }

  public static void main(String args[]) {

    Thread thread = new Thread(new TestNetworkMonitor(Integer.parseInt(args[0])));
    thread.setDaemon(true);
    thread.start();
    try {
      thread.join();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private class MoteInfo {
    public Integer addr;
    public long lastTime;

    public MoteInfo(Integer addr) {
      this.addr = addr;
    }

    public String toString() {
      return ""+addr;
    }
  }
}
