/** 
 * Simple command line tool listen to incoming status msgs 
 * encapsulated dropped via USB. 
 * @author Jan Hauer
 */

package de.tub.eyes.ps;

import net.tinyos.surge.*;
import net.tinyos.packet.*;
import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;
import java.util.*;


public class StatusMsgListen implements MessageListener {
  private MoteIF moteIF;
  private int messageCount = 0;
  String[] idStrings = {
     "NOTIFICATION_SENT_SUCCESS",   
     "NOTIFICATION_SENT_FAIL",         
   
     "NOTIFICATION_RECEIVED_SUCCESS",         
     "NOTIFICATION_RECEIVED_FAIL",
    
     "SUBSCRIPTION_SENT_SUCCESS",
     "SUBSCRIPTION_SENT_FAIL",
            
     "SUBSCRIPTION_RECEIVED_FAIL",    
     "SUBSCRIPTION_RECEIVED_NEW_SUCCESS",    
     "SUBSCRIPTION_RECEIVED_MODIFY_SUCCESS",    
     "SUBSCRIPTION_RECEIVED_MODIFY_FAIL",    
     "SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_SUCCESS",  
     "SUBSCRIPTION_RECEIVED_UNSUBSCRIBE_FAIL",  
     "PSBROKER_INITIALIZED",
     "SERVICE_DISCOVERY",
  };

  public StatusMsgListen()
  {
    try {
      moteIF = new MoteIF((Messenger)null);
      moteIF.registerListener(new PSStatusMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }
  }
  
  public StatusMsgListen(PhoenixSource source)
  {
    try {
      moteIF = new MoteIF(source);//0x7D);
      //moteIF = new MoteIF((Messenger)this);
      moteIF.registerListener(new PSStatusMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }
  }

  public void messageReceived(int to, Message m) {
    String id = "unknown!";
    PSStatusMsg smsg = (PSStatusMsg) m;
    if (smsg.get_statusID() <= idStrings.length)
      id = idStrings[smsg.get_statusID()];
    System.out.print("Source: "+smsg.get_sourceAddress()+", SeqNum: "+smsg.get_seqNum()+
        " ID: "+id+", Content: '");
    for (int i= 0; i<smsg.get_length(); i++)
      System.out.print((char)smsg.getElement_msg(i));
    System.out.println("'");
  }

  public static void main(String[] args) {
    String port = "localhost:9001";
    System.out.println("Usage: java de.tub.eyes.ps.StatusMsgListen [hostname:port-number]");
    System.out.println("(default is localhost:9001).");
    
    if (args.length == 1)
      port = args[0];
    PacketSource packetSource = BuildSource.makeArgsSF(port);
    new StatusMsgListen(BuildSource.makePhoenix(packetSource, null));
    System.out.println("Listening on "+port+" for PS Status Messages:");
    while(true);
  }
  
  
}
