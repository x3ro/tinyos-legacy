package net.tinyos.drain;

import net.tinyos.message.*;
import net.tinyos.util.*;

import org.apache.log4j.*;

import java.io.*; 
import java.text.*;
import java.util.*;
import java.net.*;

public class DrainSniff {
  private MoteIF moteIF;

  public DrainSniff() {
    moteIF = new MoteIF();
    moteIF.registerListener(new DrainMsg(), new DrainMsgReceiver());
    moteIF.registerListener(new DrainBeaconMsg(), new DrainBeaconMsgReceiver());
  }

  private class DrainMsgReceiver implements MessageListener {
    synchronized public void messageReceived(int to, Message m) {
      
      DrainMsg mhMsg = (DrainMsg)m;
      
      System.out.println("incoming: " +
			 " source: " + mhMsg.get_source() + 
			 " dest: " + mhMsg.get_dest() + 
			 " local-dest: " + to +
			 " type: " + mhMsg.get_type() +
			 " hops: " + (16 - mhMsg.get_ttl()));
    }
  }

  private class DrainBeaconMsgReceiver implements MessageListener {
    synchronized public void messageReceived(int to, Message m) {
      
      DrainBeaconMsg mhMsg = (DrainBeaconMsg)m;
      System.out.println("beacon: " +
			 " treeInstance: " + mhMsg.get_treeInstance() + 
			 " root: " + mhMsg.get_source() +
			 " node: " + mhMsg.get_linkSource() +
			 " parent: " + mhMsg.get_parent() +
			 " cost: " + mhMsg.get_cost() +
			 " ttl: " + mhMsg.get_ttl());
    }
  }

  public static void main(String args[]) {
    DrainSniff ds = new DrainSniff();
  }
}


