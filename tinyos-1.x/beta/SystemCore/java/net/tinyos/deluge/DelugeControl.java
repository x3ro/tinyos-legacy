package net.tinyos.deluge;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.util.*; 

public class DelugeControl implements Runnable {

  private MoteIF moteIF;
  private String command = "none";
  private int nodeID = 0xffff;
  private int group = 0;
  private int ttl = 0xff;
  private int image = 0;

  private static int NETPROG_FACTORY_IMAGE_ID = 0xfe;

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
	} else if (longopt.equals("group")) {
	  group = Integer.parseInt(args[i+1]);
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

    if (cleanedArgs.size() < 1) 
      usage();

    for(int i = 0; i < cleanedArgs.size(); i++) {
      if (((String)cleanedArgs.get(i)).equals("reboot")) {
	command = "reboot";
      } else if (((String)cleanedArgs.get(i)).equals("reprogram")) {
	command = "reprogram";
	if (((String)cleanedArgs.get(i+1)).equals("factory")) {
	  image = NETPROG_FACTORY_IMAGE_ID;
	} else {
	  try {
	    image = Integer.parseInt(args[i+1]); 
	  } catch (Exception e) {
	    usage();
	  }
	}
	i++;
      }
    }
  }

  private void usage() {
      System.out.println("java DelugeControl [OPTIONS]... {reboot, reprogram <id>}");
      System.err.println("  --id <node ID> : send command to a specific node");
      System.err.println("  --ttl <hop count> : limit number of hops");
      System.out.println("  --group <group ID> : send command to specific group");
      System.out.println("NOTE: \"reprogram factory\" will load the factory image");
      System.exit(1);
  }

  public DelugeControl(String args[]) {

    parseArgs(args);

    if (command.equals("none")) {
      usage();
    }

    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }
    
    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE +
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)NetProgCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)ttl);
    namingMsg.set_group((short)group);
    namingMsg.set_addr((short)nodeID);

    NetProgCmdMsg dcMsg = 
      new NetProgCmdMsg(namingMsg,
		       namingMsg.offset_data(0),
		       NetProgCmdMsg.DEFAULT_MESSAGE_SIZE);
    
    if (command.equals("reboot")) {
      dcMsg.set_rebootNode((byte)1);
    } else if (command.equals("reprogram")) {
      dcMsg.set_runningImgNumChanged((byte)1);
      dcMsg.set_runningImgNum((short)image);
    }
  
    System.out.println(dripMsg);
    System.out.println(namingMsg);
    System.out.println(dcMsg);
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
    new DelugeControl(args);
  }
}
