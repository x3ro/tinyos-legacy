package net.tinyos.cc1000;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 

public class CC1000Interface implements Runnable {

  private MoteIF moteIF;

  TOSBaseCmdMsg tbCmdMsg;

  public CC1000Interface(String args[]) {

    if (args.length < 1) {
      System.out.println("java CC1000Interface <dest ID> [rf <n> lpl <n>]");
      System.exit(1);
    }
      
    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }
    
    int nodeID = Integer.parseInt(args[0]);

    DripMsg dripMsg = new DripMsg(2+NamingMsg.DEFAULT_MESSAGE_SIZE+
				  CC1000InterfaceDripMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)CC1000InterfaceDripMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					CC1000InterfaceDripMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)0xff);
    namingMsg.set_group((short)0xff);
    namingMsg.set_addr((short)nodeID);

    CC1000InterfaceDripMsg ccMsg = 
      new CC1000InterfaceDripMsg(namingMsg,
				 namingMsg.offset_data(0),
				 CC1000InterfaceDripMsg.DEFAULT_MESSAGE_SIZE);

    tbCmdMsg = new TOSBaseCmdMsg();

    for(int i = 0; i < args.length; i++) {
      if (args[i].equals("rf") && args.length > i+1) {
	int rfPower = Integer.parseInt(args[i+1]);
	ccMsg.set_rfPowerChanged((byte)1);
	ccMsg.set_rfPower((short)rfPower);
	tbCmdMsg.set_rfPowerChanged((byte)1);
	tbCmdMsg.set_rfPower((short)rfPower);
	i++;
      } else if (args[i].equals("lpl") && args.length > i+1) {
	int lplPower = Integer.parseInt(args[i+1]);
	ccMsg.set_lplPowerChanged((byte)1);
	ccMsg.set_lplPower((short)lplPower);
	tbCmdMsg.set_lplModeChanged((byte)1);
	tbCmdMsg.set_lplMode((short)lplPower);
	i++;
      }
    }

    System.out.println(dripMsg);
    System.out.println(ccMsg);
    send(dripMsg);

    Thread thread = new Thread(this);
    thread.setDaemon(true);
    thread.start();
  }

  public void run() {
    while(true) {
      try {
	Thread.currentThread().sleep(2048);
	System.out.println(tbCmdMsg);
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
    new CC1000Interface(args);
  }

}
