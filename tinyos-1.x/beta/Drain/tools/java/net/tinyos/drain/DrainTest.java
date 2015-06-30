package net.tinyos.drain;

import java.io.*; 
import java.text.*;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.drain.*;

import org.apache.log4j.*;

public class DrainTest implements MessageListener {

  private Logger log = Logger.getLogger(DrainTest.class.getName());

  private Map nodes = new HashMap();

  private int period;

  public DrainTest(int _period) {
    period = _period;
    DrainConnector mhConnector = new DrainConnector();
    Timer t = new Timer();
    t.schedule(new PrintTask(), 0, period);
    mhConnector.registerListener(254, this);
  }
  
  public void messageReceived(int to, Message m) {
    DrainMsg mhMsg = (DrainMsg) m;
    
    DrainTestMsg dtMsg = 
      new DrainTestMsg(mhMsg, mhMsg.offset_data(0), 
		       mhMsg.dataLength()
		       - mhMsg.offset_data(0));
    
    log.debug("seqno=" + dtMsg.get_seqno() + ", " + 
	      "time=" + (dtMsg.get_time() * 1000 / 65535));

    if (nodes.containsKey(new Integer(mhMsg.get_source()))) {
      NodeRec rec = (NodeRec) nodes.get(new Integer(mhMsg.get_source()));
      if (dtMsg.get_seqno() == rec.lastSeqno) {
	rec.receivedDup++;
      }
      if (dtMsg.get_seqno() > rec.lastSeqno) {
	rec.received++;
	rec.sent += dtMsg.get_seqno() - rec.lastSeqno;
	rec.lastSeqno = dtMsg.get_seqno();
      }
      if (dtMsg.get_seqno() < rec.lastSeqno) {
	rec.lastSeqno = dtMsg.get_seqno();
      }
    } else {
      NodeRec rec = new NodeRec();
      rec.received = rec.sent = 1;
      rec.lastSeqno = dtMsg.get_seqno();
      nodes.put(new Integer(mhMsg.get_source()), rec);
    }
  }

  private class NodeRec {
    int received;
    int receivedDup;
    int lastReceived;
    int lastReceivedDup;
    int sent;
    int lastSeqno;
    int lastReceivedMill;
  }

  private class PrintTask extends TimerTask {
    public void run() {
      System.out.println("Status Report - " + new Date());
      double aggTrafficUnique = 0;
      double aggTraffic = 0;
      int count = 0;
      int activeCount = 0;

      List nodeList = new ArrayList(nodes.keySet());
      Collections.sort(nodeList);
      for(Iterator it = nodeList.iterator();
	  it.hasNext(); ) {
	Integer addr = (Integer) it.next();
	NodeRec rec = (NodeRec) nodes.get(addr);
	count++;

	double receiveRateUnique = (rec.received - rec.lastReceived) / ((double)period / 1000);
	double receiveRate = (rec.received + rec.receivedDup - rec.lastReceivedDup) / ((double)period / 1000);
	aggTrafficUnique += receiveRateUnique;
	aggTraffic += receiveRate;

	rec.lastReceived = rec.received;
	rec.lastReceivedDup = rec.received + rec.receivedDup;

	System.out.println(addr + ": " + "sent= " + rec.sent + " received= " + rec.received + " success=" + 100*((float)rec.received / rec.sent) + " pps=" + receiveRate + " ppsUnique=" + receiveRateUnique);

	if (receiveRateUnique > 0) {
	  activeCount++;
	}

      }
      System.out.println("Node count=" + count);
      System.out.println("Active Nodes=" + activeCount);
      System.out.println("Aggregate pps=" + aggTraffic);
      System.out.println("Aggregate Unique pps=" + aggTrafficUnique);
      System.out.println("---");
    }
  }

  public static void main(String args[]) {
    new DrainTest(Integer.parseInt(args[0]));
  }
}
