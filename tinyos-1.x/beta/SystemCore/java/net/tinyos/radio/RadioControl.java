package net.tinyos.radio;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 

public class RadioControl implements Runnable {

  private MoteIF moteIF;

  public RadioControl(String args[]) {

    if (args.length < 2) {
      System.err.println("java RadioControl <node ID> <on/off>");
      System.exit(1);
    }

    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    int nodeID = Integer.parseInt(args[0]);

    DripMsg dripMsg = new DripMsg();

    dripMsg.set_metadata_id((short)RadioControlCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					RadioControlCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)0xff);
    namingMsg.set_group((short)0xff);
    namingMsg.set_addr((short)nodeID);
    
    RadioControlCmdMsg rcMsg = 
      new RadioControlCmdMsg(namingMsg,
			     namingMsg.offset_data(0),
			     RadioControlCmdMsg.DEFAULT_MESSAGE_SIZE);
    
    for(int i = 0; i < args.length; i++) {
      if (args[i].equals("on")) {
	rcMsg.set_active((short)1);
	i++;
      } else if (args[i].equals("off")) {
	rcMsg.set_active((short)0);
	i++;
      }
    }

    System.out.println(dripMsg);
    System.out.println(namingMsg);
    System.out.println(rcMsg);
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
    new RadioControl(args);
  }

}
