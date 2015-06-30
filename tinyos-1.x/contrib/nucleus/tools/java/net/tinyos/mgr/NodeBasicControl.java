import java.io.*;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.powermgmt.*;
import net.tinyos.deluge.NetProgCmdMsg;

public class NodeBasicControl {

  public static int MAX_TTL = 0xff;
  public static int DEFAULT_GROUP = 0x0;
  private static int CC1K_FPL = 0;
  private static int CC1K_LPL = 6;
  
  private MoteIF moteIF;

  public NodeBasicControl() {
    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
    }
  }

  public void wake(int nodeID, int ttl, int delay) {

    System.out.println("Waking " + nodeID + " in " + delay + " ms");

    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)PowerMgmtCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)ttl);
    namingMsg.set_group((short)DEFAULT_GROUP);
    namingMsg.set_addr((short)nodeID);
    
    PowerMgmtCmdMsg pcMsg = 
      new PowerMgmtCmdMsg(namingMsg,
			  namingMsg.offset_data(0),
			  PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);
    
    TOSBaseCmdMsg tbCmdMsg = new TOSBaseCmdMsg();

    tbCmdMsg.set_lplModeChanged((byte)1);
    tbCmdMsg.set_lplMode((short)CC1K_LPL);

    pcMsg.set_powerMode((short)0); 
    pcMsg.set_changeDelay((short)delay);
    
    System.out.println("Setting Base to Long-Preamble Mode...");
    send(tbCmdMsg);
    
    System.out.print("Waking up ");
    send(dripMsg);

    if (nodeID == MoteIF.TOS_BCAST_ADDR) {
      System.out.println("all nodes.");
    } else {
      System.out.println("node " + nodeID + ".");
    }

    System.out.println("Setting Base to Short-Preamble Mode...");
    tbCmdMsg.set_lplModeChanged((byte)1);
    tbCmdMsg.set_lplMode((short)CC1K_FPL);

    send(tbCmdMsg);
  }

  public void sleep(int nodeID, int ttl, int delay) {

    System.out.println("Sleeping " + nodeID + " in " + delay + " ms");

    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)PowerMgmtCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)ttl);
    namingMsg.set_group((short)DEFAULT_GROUP);
    namingMsg.set_addr((short)nodeID);
    
    PowerMgmtCmdMsg pcMsg = 
      new PowerMgmtCmdMsg(namingMsg,
			  namingMsg.offset_data(0),
			  PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);

    TOSBaseCmdMsg tbCmdMsg = new TOSBaseCmdMsg();

    tbCmdMsg.set_lplModeChanged((byte)1);
    tbCmdMsg.set_lplMode((short)CC1K_FPL);	

    pcMsg.set_powerMode((short)2);      
    pcMsg.set_changeDelay((short)delay);

    System.out.println("Setting Base to Short-Preamble Mode...");
    send(tbCmdMsg);
    
    System.out.println(dripMsg);
    System.out.println(namingMsg);
    System.out.println(pcMsg);

    System.out.print("Sleeping ");
    send(dripMsg);

    if (nodeID == MoteIF.TOS_BCAST_ADDR) {
      System.out.println("all nodes.");
    } else {
      System.out.println("node " + nodeID + ".");
    }

    System.out.println("Setting Base to Long-Preamble Mode...");
    tbCmdMsg.set_lplModeChanged((byte)1);
    tbCmdMsg.set_lplMode((short)CC1K_LPL);

    send(tbCmdMsg);
  }

  public void reboot(int nodeID, int ttl, int delay) {

    System.out.println("Rebooting " + nodeID + " in " + delay + " ms");

    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE +
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)NetProgCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);
    
    NamingMsg namingMsg = new NamingMsg(dripMsg, 
					dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)ttl);
    namingMsg.set_group((short)DEFAULT_GROUP);
    namingMsg.set_addr((short)nodeID);

    NetProgCmdMsg dcMsg = 
      new NetProgCmdMsg(namingMsg,
			namingMsg.offset_data(0),
			NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);

    dcMsg.set_rebootNode((byte)1);
    dcMsg.set_rebootDelay((short)delay);

    System.out.println(dripMsg);
    System.out.println(namingMsg);
    System.out.println(dcMsg);
    send(dripMsg);
  }

  public void reprogram(int nodeID, int ttl, int image, int delay) {

    System.out.println("Reprogramming " + nodeID + " to " + image + " in " + delay + " ms");

    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE +
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)NetProgCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);
    
    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)ttl);
    namingMsg.set_group((short)DEFAULT_GROUP);
    namingMsg.set_addr((short)nodeID);

    NetProgCmdMsg dcMsg = 
      new NetProgCmdMsg(namingMsg,
			namingMsg.offset_data(0),
			NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);

    dcMsg.set_runningImgNumChanged((byte)1);
    dcMsg.set_runningImgNum((short)image);
    dcMsg.set_rebootDelay((short)delay);

    send(dripMsg);
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
}
