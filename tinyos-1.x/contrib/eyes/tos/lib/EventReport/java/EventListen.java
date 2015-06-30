import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;
import java.util.*;


public class EventListen implements MessageListener {
  private MoteIF moteIF;
  private int messageCount = 0;
  private ReportMsg reportMsg;
  
  public static void printHex(byte b)
  {
    String s = Integer.toHexString(0xFF & b).toUpperCase();
    System.out.print("0x" + ((b & 0xF0) > 0 ? "" : "0") + s + " ");
  }

  public EventListen(PhoenixSource source)
  {
    try {
      moteIF = new MoteIF(source);
      moteIF.registerListener(new ReportMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Can't register at serial forwarder.");
      System.exit(1);
    }
  }

  public void messageReceived(int to, Message m) {
    ReportMsg reportMsg = (ReportMsg) m;
    System.out.println(reportMsg.get_sourceID()+"\t"+reportMsg.get_seqNum()+"\t"+reportMsg.get_eventID()+"\t"+reportMsg.get_delta()+"\t"+reportMsg.get_subscriberID()+"\t"+reportMsg.get_subscriptionID());

    // send ACK
	  try {
	    moteIF.send(MoteIF.TOS_BCAST_ADDR, reportMsg);
	  } catch (IOException ioe) {
	    System.err.println("Warning: Got IOException sending ACK message: "+ioe);
	    ioe.printStackTrace();
	  }
  }

  public static void main(String[] args) {
    String port = "localhost:9001";
    System.out.println("Usage: java EventListen [host:port]");
    if (args.length >= 1)
      port = args[0];
    PacketSource packetSource = BuildSource.makeArgsSF(port);
    new EventListen(BuildSource.makePhoenix(packetSource, null));
    System.out.println("Sender\tSeqNum\tEventID\tDelta\tSubTree\tSubscriptionID");
    System.out.println("--------------------------------------------------");
    while(true);
  }
  
  
}
