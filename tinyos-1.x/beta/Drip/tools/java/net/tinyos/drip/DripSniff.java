package net.tinyos.drip;

import net.tinyos.message.*;
import net.tinyos.util.*;

import org.apache.log4j.*;

import java.io.*; 
import java.text.*;
import java.util.*;
import java.net.*;

public class DripSniff {
  private MoteIF moteIF;

  public DripSniff() {
    moteIF = new MoteIF();
    moteIF.registerListener(new DripMsg(), new DripMsgReceiver());
  }

  private class DripMsgReceiver implements MessageListener {
    synchronized public void messageReceived(int to, Message m) {
      
      DripMsg mhMsg = (DripMsg)m;
      
      System.out.print("incoming: " +
		       " id: " + mhMsg.get_metadata_id() + 
		       " seqno: " + mhMsg.get_metadata_seqno());
      if (mhMsg.get_metadata_seqno() == 2) {
	System.out.print(" -- new node -- ");
      }

      System.out.println("");
    }
  }

  public static void main(String args[]) {
    DripSniff ds = new DripSniff();
  }
}
