package net.tinyos.powermgmt;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.util.*; 

public class PowerMgmt implements Runnable {

  private MoteIF moteIF;
  private TOSBaseCmdMsg tbCmdMsg;
  
  private static int CC1K_FPL = 0;
  private static int CC1K_LPL = 6;

  private String command = "none";
  private int ttl = 0xff;
  private int nodeID = 0xffff;

  private void usage() {
    System.err.println("Usage: java net.tinyos.powermgmt.PowerMgmt [OPTION]... [COMMAND]...");
    System.err.println("Put nodes to sleep or wake them up");
    System.err.println("COMMAND = wake, sleep, hibernate(warning, must touch node to wake up)");
    System.err.println("Command applies to all nodes by default");
    System.err.println("  --id <node ID> : send command to a specific node");
    System.err.println("  --ttl <hop count> : limit number of hops");
    System.exit(1);
  }

  private void parseArgs(String args[]) {

    ArrayList cleanedArgs = new ArrayList();

    for(int i = 0; i < args.length; i++) {
      if (args[i].startsWith("--")) {
	// Parse Long Options
	String longopt = args[i].substring(2);

	if (longopt.equals("help")) {
	  usage();
	} else if (longopt.equals("id")) {
	  nodeID = Integer.parseInt(args[i+1]);
	  i++;
	} else if (longopt.equals("ttl")) {
	  ttl = Integer.parseInt(args[i+1]);
	  i++;
	}

      } else if (args[i].startsWith("-")) {
	// Parse Short Options
	String opt = args[i].substring(1);

	if (opt.equals("h")) {
	  usage();
	}

      } else {
	// Place into args string
	cleanedArgs.add(args[i]);
      }
    }

    for(int i = 0; i < cleanedArgs.size(); i++) {
      if (((String)cleanedArgs.get(i)).equals("wake")) {
	command = "wake";
      } else if (((String)cleanedArgs.get(i)).equals("sleep")) {
	command = "sleep";
      } else if (((String)cleanedArgs.get(i)).equals("hibernate")) {
	command = "hibernate";
      }
    }
  }

  public PowerMgmt(String args[]) {

    parseArgs(args);

    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)PowerMgmtCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)ttl);
    namingMsg.set_group((short)0xff);
    namingMsg.set_addr((short)nodeID);
    
    PowerMgmtCmdMsg pcMsg = 
      new PowerMgmtCmdMsg(namingMsg,
			  namingMsg.offset_data(0),
			  PowerMgmtCmdMsg.DEFAULT_MESSAGE_SIZE);
    
    tbCmdMsg = new TOSBaseCmdMsg();

    if (command.equals("wake")) {
      tbCmdMsg.set_lplModeChanged((byte)1);
      tbCmdMsg.set_lplMode((short)CC1K_LPL);
      pcMsg.set_powerMode((short)0);

      System.out.println("Setting Base to Long-Preamble Mode...");
      send(tbCmdMsg);

      System.out.print("Waking up ");
      send(dripMsg);

    } else if (command.equals("sleep")) {
      tbCmdMsg.set_lplModeChanged((byte)1);
      tbCmdMsg.set_lplMode((short)CC1K_FPL);	
      pcMsg.set_powerMode((short)2);      

      System.out.println("Setting Base to Short-Preamble Mode...");
      send(tbCmdMsg);

      System.out.print("Sleeping ");
      send(dripMsg);

    } else if (command.equals("hibernate")) {
      tbCmdMsg.set_lplModeChanged((byte)1);
      tbCmdMsg.set_lplMode((short)CC1K_FPL);	
      pcMsg.set_powerMode((short)3);      

      System.out.println("Setting Base to Short-Preamble Mode...");
      send(tbCmdMsg);

      System.out.print("Hibernating ");
      send(dripMsg);

    } else {

      usage();
    }

    if (nodeID == MoteIF.TOS_BCAST_ADDR) {
      System.out.println("all nodes.");
    } else {
      System.out.println("node " + nodeID + ".");
    }

    Thread thread = new Thread(this);
    thread.setDaemon(true);
    thread.start();
  }

  public void run() {
    while(true) {
      try {

	if (command.equals("sleep")) {

	  System.out.println("Waiting 65 seconds for the network to sleep...");
	  Thread.currentThread().sleep(65535);

	  System.out.println("Setting Base to Long-Preamble Mode...");
	  tbCmdMsg.set_lplModeChanged((byte)1);
	  tbCmdMsg.set_lplMode((short)CC1K_LPL);

	} else if (command.equals("wake")) {

	  System.out.println("Waiting 4 seconds for the network to wake...");
	  Thread.currentThread().sleep(4096);

	  System.out.println("Setting Base to Short-Preamble Mode...");
	  tbCmdMsg.set_lplModeChanged((byte)1);
	  tbCmdMsg.set_lplMode((short)CC1K_FPL);
	}

	send(tbCmdMsg);

	Thread.currentThread().sleep(1024);
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
    new PowerMgmt(args);
  }
}
