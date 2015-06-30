package net.tinyos.nucleus;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.drip.*;

import java.io.*; 
import java.text.*;
import java.util.*;

public class GroupSet {
  
  static int HARDWAREID_LEN = 8;
  
  MoteIF moteIF;
  Drip drip;

  String hardwareID;
  int groupID;

  String sendMode = "local";
  
  String op = "join";

  public static void main(String args[]) {
    new GroupSet(args);
  }
  
  private void usage() {
    System.err.println("java GroupSet [opts] <hardware id> <group id>");
    System.err.println("  <hardware id> : XX:XX:XX:XX:XX:XX:XX:XX");
    System.err.println("  -s <source> : how to send the msg (serial, local, remote)");
    System.exit(1);
  }

  public GroupSet(String args[]) {

    parseArgs(args);

    moteIF = new MoteIF();

    String idBytes[] = hardwareID.split(":",HARDWAREID_LEN);
    if (idBytes.length < 8) {
      usage();
    }

    GrouperCmdMsg cmdMsg;

    cmdMsg = new GrouperCmdMsg();

    for (int i = 0; i < HARDWAREID_LEN; i++) {
      cmdMsg.setElement_serialID(i, (byte)Integer.parseInt(idBytes[i],16));
    }
    cmdMsg.set_groupID((short)groupID);

    if (op.equals("join")) {
      cmdMsg.set_op((byte)GrouperConsts.GROUPER_JOIN);
    } else if (op.equals("leave")) {
      cmdMsg.set_op((byte)GrouperConsts.GROUPER_LEAVE);
    }

    System.out.println(cmdMsg);

    if (sendMode.equals("local") || sendMode.equals("serial")) {
      
      moteIF = new MoteIF();	    
      send(cmdMsg);      

    } else if (sendMode.equals("remote")) {
      
      drip = new Drip(GrouperCmdMsg.AM_TYPE);
      drip.send(cmdMsg, cmdMsg.dataGet().length);
      
    } else {
      usage();
    }

    System.exit(0);
  }

  private void send(Message m) {
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

  private void parseArgs(String args[]) {

    ArrayList cleanedArgs = new ArrayList();

    for(int i = 0; i < args.length; i++) {
      if (args[i].startsWith("--")) {

        // Parse Long Options
        String longopt = args[i].substring(2);

      } else if (args[i].startsWith("-")) {

        // Parse Short Options
	String opt = args[i].substring(1);

	if (opt.equals("s")) {
	  sendMode = args[++i];
	} else if (opt.equals("j")) {
	  op = "join";
	} else if (opt.equals("l")) {
	  op = "leave";
	}
	
      } else {

        // Place into args string
        cleanedArgs.add(args[i]);

      }
    }

    if (cleanedArgs.size() < 2) {
      usage();
    }

    hardwareID = (String)cleanedArgs.get(0);
    groupID = Integer.parseInt((String)cleanedArgs.get(1));
  }
}
