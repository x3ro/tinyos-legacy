/** 
 * Simple command line tool listen to incoming notifications 
 * encapsulated in a Drain message. 
 * @author Jan Hauer
 */

package de.tub.eyes.ps;

import net.tinyos.surge.*;
import net.tinyos.drain.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;
import java.util.*;


public class NotificationListen implements MessageListener {
  private MoteIF moteIF;
  private int messageCount = 0;
  private boolean isProtocolDrain;
  private Drain drain;
  
  // initial beacon frequency (before any notifications have been received)
  private int DRIP_INIT_BEACON_FREQUENCY = 3;  
  
  // beacon frequency (one or more notifications have been received, e.g. decrease the frequency)
  private int DRIP_DEFAULT_BEACON_FREQUENCY = 3;  
  
  public static void printHex(byte b)
  {
    String s = Integer.toHexString(0xFF & b).toUpperCase();
    System.out.print("0x" + ((b & 0xF0) > 0 ? "" : "0") + s + " ");
  }

  public NotificationListen(PhoenixSource source, boolean usedrain, int rootID)
  {
    try {
      if (usedrain){
        this.isProtocolDrain = true;
        //DrainConnector dc = new DrainConnector();
        moteIF = DrainLib.startMoteIF();
        moteIF.registerListener(new DrainMsg(), this);
        drain = new Drain(rootID, moteIF);
        drain.forever = true;
        drain.buildTree(DRIP_INIT_BEACON_FREQUENCY);
        drain.maintainTree();
      } else {
        this.isProtocolDrain = false;
        moteIF = new MoteIF(source);
        moteIF.registerListener(new PSMultihopMsg(), this);
      }
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }
  }

  

  public void messageReceived(int to, Message m) {
    PSNotificationMsg msg; 
    if (isProtocolDrain){
      drain.delay = DRIP_DEFAULT_BEACON_FREQUENCY;
      DrainMsg mhmsg = (DrainMsg)m;
      PSNotificationMsg msgTmp = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0));
      msg = new PSNotificationMsg(
        mhmsg, mhmsg.offset_data(0), msgTmp.DEFAULT_MESSAGE_SIZE + msgTmp.get_dataLength());
    } else {     
      PSMultihopMsg mhmsg = (PSMultihopMsg) m;
      PSNotificationMsg msgTmp = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0));
      msg = new PSNotificationMsg(
        mhmsg, mhmsg.offset_data(0), msgTmp.DEFAULT_MESSAGE_SIZE + msgTmp.get_dataLength());
    }
    
    System.out.println("Notification "+ (++messageCount) + " received:");
    System.out.print("  Parent = " + msg.get_parentAddress());
    System.out.print("  Source = " + msg.get_sourceAddress());
    System.out.print("  SubscriberID = " + msg.get_subscriberID());
    System.out.print("  SubscriptionID = " + msg.get_subscriptionID());
    System.out.print("  Flags = " + msg.get_flags());
    System.out.println("  DataLength = " + msg.get_dataLength());
    
    //System.out.println("  AVPairCount = " + msg.getAVPairCount());
    //System.out.println("  RequestCount = " + msg.getRequestCount());
    for(int i = 0; i < msg.getAVPairCount(); i++){
      System.out.print("     AVPair "+i+": {"+
          msg.getAVPairAttributeID(i)+", ");
      Short[] avpairValue = msg.getAVPairValue(i);
      for (int j=0; j<avpairValue.length; j++)
        printHex(avpairValue[j].byteValue());
      System.out.print("}   ");
    }
    System.out.println("");
    for(int i = 0; i < msg.getRequestCount(); i++){
      System.out.print("     Request "+i+": {"+
          msg.getRequestAttributeID(i)+", "+
          msg.getRequestOperationID(i)+", ");
      Short[] requestValue = msg.getRequestValue(i);
      for (int j=0; j<requestValue.length; j++)
        printHex(requestValue[j].byteValue());
      System.out.print("}   ");
    }
    System.out.println("");
  }

  public static void main(String[] args) {
    String port = "localhost:9001";
    String protocol = "Drain";
    boolean drain = true;
    int rootID = 65534;
    System.out.println("Usage: java de.tub.eyes.ps.NotificationListen [host:port] [protocol] [rootID]");
    System.out.println("where protocol is 'Drain' (default) or 'MultihopRSSI', 'host:port' specifies the SerialForwarder (default is localhost:9001) and 'rootID' is the ID of the root node in the tree (default is 65534).");
    if (args.length >= 1)
      port = args[0];
    if (args.length >= 2)
      protocol = args[1];
    if (protocol.compareTo("Drain") != 0 && protocol.compareTo("MultihopRSSI") != 0)
      System.exit(1);
    if (protocol == "MultihopRSSI")
      drain = false;
    if (args.length >= 3)
      rootID = Integer.parseInt(args[2]);
    PacketSource packetSource = BuildSource.makeArgsSF(port);
    new NotificationListen(BuildSource.makePhoenix(packetSource, null), drain, rootID);
    System.out.println("Listening for notifications (protocol "+protocol+"):");
    while(true);
  }
  
  
}
