package net.tinyos.grouper;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 

public class GrouperControl implements Runnable {

  private MoteIF moteIF;

  public GrouperControl(String args[]) {

    if (args.length < 2) {
      System.err.println("java GrouperControl --groupid <group id> --treeid <tree id> --newgroupid <group id>");
      System.exit(1);
    }

    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  GrouperCmdMsg.DEFAULT_MESSAGE_SIZE);
    
    dripMsg.set_metadata_id((short)GrouperCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					GrouperCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)0xff);
    namingMsg.set_group((short)0xff);
    namingMsg.set_addr((short)0xffff);
    
    GrouperCmdMsg gcMsg = 
	new GrouperCmdMsg(namingMsg, namingMsg.offset_data(0),
			  GrouperCmdMsg.DEFAULT_MESSAGE_SIZE);
    
    TOSBaseCmdMsg cmdMsg = new TOSBaseCmdMsg();
    
    for(int i = 0; i < args.length; i++) {
      if (args[i].equals("--treeid")) {
	int treeID = Integer.parseInt(args[i+1]);
	gcMsg.set_treeIDChanged((byte)1);
	gcMsg.set_treeID((short)treeID);
	i++;
      } else if (args[i].equals("--newgroupid")) {
	int groupID = Integer.parseInt(args[i+1]);
	gcMsg.set_newGroupIDChanged((byte)1);
	gcMsg.set_newGroupID((short)groupID);
	i++;
      } else if (args[i].equals("--groupid")) {
	int groupID = Integer.parseInt(args[i+1]);
	cmdMsg.set_groupChanged((byte)1);
	cmdMsg.set_group((short)groupID);	
	i++;
      }
    }


    
    System.out.println(cmdMsg);
    send(cmdMsg);

    System.out.println(dripMsg);
    System.out.println(namingMsg);
    System.out.println(gcMsg);
    send(dripMsg);

    Thread thread = new Thread(this);
    thread.setDaemon(true);
    thread.start();
  }

  public void run() {
    while(true) {
      try {
	Thread.currentThread().sleep(2048);
	System.exit(0);
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
    new GrouperControl(args);
  }
}
