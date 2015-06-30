/* ex: set tabstop=2 shiftwidth=2 expandtab:*/

/**
* @author Xin Li, based on code of Rodrigo Fonseca
*/
package net.tinyos.dim;

import net.tinyos.util.*;
import java.io.*;
import java.util.Properties;
import net.tinyos.message.*;
import net.tinyos.tools.*;

public class ConsoleCmdInject implements MessageListener {
  public static final short TOS_BCAST_ADDR = (short) 0xffff;
  public static final short AM_CONSOLEQUERYMSG = 77;
  public static final short AM_CONSOLEREPLYMSG = 78;
  public static final byte CONSOLE_COMMAND = 1; // Consistent with DIM greedy packet.
  public static final byte CONSOLE_QUERY = 2;
  public static final byte CONSOLE_QUERY_REPLY = 3;
  public static final byte CONSOLE_ZONE = 4;
  public static final byte CONSOLE_ZONE_REPLY = 5;
  public static final short MAX_PIRLENGTH = 106;
  
  public static void usage() {
    System.err.println("usage: java net.tinyos.dim.ConsoleCmdInject" +
                       " <group_id> <mote_id> <command> ...");
    /*
    System.err.println("  If <command> is \"create\", the rest is" +
                       " treated as a sequence of <attributes>.");
    */
    System.err.println("  If <command> is \"query\", the rest is" +
                       " treated as a 4" +
                       " (<attributeID> <lower_bound> <upper_bound>).");
    System.err.println("  If <command> is \"zone\", no other arguments is allowed.");
  }

  public static void main(String[] argv) throws IOException {
    byte group_id = 0;
    short mote_id = 0;
    byte attrID = 0;
    //String attr;
    short lower_bound = 0;
    short upper_bound = 0;
                    
    if (argv.length < 3) {
      usage();
      System.exit(-1);
    }

    // group_id
    try {
      if (argv[0].startsWith("0x") || argv[0].startsWith("0X")) {
        group_id = (byte)Integer.parseInt(argv[0].substring(2), 16);
      } else {
        group_id = (byte)Integer.parseInt(argv[0]);
      }
    } catch (NumberFormatException nfe) {
      usage();
      System.exit(-1);
    }

    // mote_id
    if (argv[1].equals("BCAST")) {
      mote_id = TOS_BCAST_ADDR;
    } else {
      try {
        if (argv[1].startsWith("0x") || argv[1].startsWith("0X")) {
          mote_id = (short)Integer.parseInt(argv[1].substring(2), 16);
        } else {
          mote_id = (short)Integer.parseInt(argv[1]);
        }
      } catch (NumberFormatException nfe) {
        usage();
        System.exit(-1);
      }
    }
    
    // command
    if (argv[2].equals("query")) {
      if (argv.length < 15) {
        usage();
        System.exit(-1);
      }
      // Send attrNum messages for a single query command.
      ConsoleQueryMsg queryMsg = new ConsoleQueryMsg();
      ConsoleReplyMsg replyMsg = new ConsoleReplyMsg();

      System.out.println("sizeof(ConsoleQueryMsg) in Java is " + queryMsg.dataLength());
      System.out.println("sizeof(ConsoleReplyMsg) in Java is " + replyMsg.dataLength());
      /*
      System.exit(0);
      */

      //queryMsg.amTypeSet(AM_CONSOLEQUERYMSG);
      queryMsg.set_mode_(CONSOLE_QUERY);

      System.out.print("Querying DIM on attributes "); 
      for (int i = 3; i < argv.length; ) {
        try {
          attrID = (byte)Integer.parseInt(argv[i]);
        } catch (NumberFormatException nfe) {
          System.err.println("Invalide attribute ID " + argv[i]);
          usage();
          System.exit(-1);
        }
        System.out.print("(");
        System.out.print(argv[i]);
        System.out.print(", [");
        queryMsg.setElement_queryField_attrID(i/3 - 1, attrID);
        // lower_bound
        //System.out.print(argv[i + 1]);
        try {
          lower_bound = (short)Integer.parseInt(argv[i + 1]);
        } catch (NumberFormatException nfe) {
          System.err.println("Invalid lower bound for attribute " + argv[i + 1]);
          usage();
          System.exit(-1);
        }
        if (lower_bound < 0 || lower_bound > 1023) {
          System.err.println("lower bound must be in [0..1023]");
          System.exit(-1);
        } 
        queryMsg.setElement_queryField_lowerBound(i/3 - 1, lower_bound);
        System.out.print(lower_bound);
        //System.out.print((short)queryMsg.getElement_queryField_lowerBound(i/3 - 1));
        System.out.print("--");
        // upper_bound
        //System.out.print(argv[i + 2]);
        try {
          upper_bound = (short)Integer.parseInt(argv[i + 2]);
        } catch (NumberFormatException nfe) {
          System.err.println("Invalid upper bound for attribute " + argv[i]);
          usage();
          System.exit(-1);
        }
        if (upper_bound < 0 || upper_bound > 1023) {
          System.err.println("upper bound must be in [0..1023]");
          System.exit(-1);
        }
        queryMsg.setElement_queryField_upperBound(i/3 - 1, upper_bound);
        System.out.print(upper_bound);
        //System.out.print((short)queryMsg.getElement_queryField_lowerBound(i/3 - 1));
        System.out.print("])");
        i += 3;
      }
      System.out.println();

      System.err.print("Sending payload: ");
      for (int j = 0; j < queryMsg.dataLength(); j++) {
        System.err.print(Integer.toHexString(queryMsg.dataGet()[j] & 0xff)+ " ");
      }
      System.err.println();

      replyMsg.amTypeSet(AM_CONSOLEREPLYMSG);
      ConsoleCmdInject receiver = new ConsoleCmdInject(); 
      try {
        //MoteIF mote = new MoteIF("127.0.0.1", 9000, group_id);
        MoteIF mote = new MoteIF(PrintStreamMessenger.err, group_id);
        mote.registerListener(replyMsg, receiver);
        mote.start();
        mote.send(mote_id, queryMsg);
        //System.exit(0);
      } catch (Exception e) {
        e.printStackTrace();
        System.exit(-1);
      }
      // Register query reply listener here.
      /*
      try {
        MoteIF console = new MoteIF(PrintStreamMessenger.err, group_id);
        console.registerListener(replyMsg, receiver);
        console.start();
      } catch (Exception e) {
        e.printStackTrace();
        System.exit(-1);
      }
      */
      //System.exit(0);
    } else if (argv[2].equals("zone")) {
      // Send request for node zone code.
      ConsoleQueryMsg queryMsg = new ConsoleQueryMsg();
      ConsoleReplyMsg replyMsg = new ConsoleReplyMsg();

      /*
      System.exit(0);
      */

      //queryMsg.amTypeSet(AM_CONSOLEQUERYMSG);
      queryMsg.set_mode_(CONSOLE_ZONE);
      queryMsg.setElement_queryField_attrID(0, mote_id);

      System.out.print("Querying DIM node zone code.\n"); 
      // No other arguments are needed.

      System.err.print("Sending payload: ");
      for (int j = 0; j < queryMsg.dataLength(); j++) {
        System.err.print(Integer.toHexString(queryMsg.dataGet()[j] & 0xff)+ " ");
      }
      System.err.println();

      replyMsg.amTypeSet(AM_CONSOLEREPLYMSG);
      ConsoleCmdInject receiver = new ConsoleCmdInject(); 
      try {
        //MoteIF mote = new MoteIF("127.0.0.1", 9000, group_id);
        MoteIF mote = new MoteIF(PrintStreamMessenger.err, group_id);
        mote.registerListener(replyMsg, receiver);
        mote.start();
        System.err.println("Send to " + mote_id);
        //mote.send(mote_id, queryMsg);
        mote.send(TOS_BCAST_ADDR, queryMsg);
        //System.exit(0);
      } catch (Exception e) {
        e.printStackTrace();
        System.exit(-1);
      }
      // Register query reply listener here.
      /*
      try {
        MoteIF console = new MoteIF(PrintStreamMessenger.err, group_id);
        console.registerListener(replyMsg, receiver);
        console.start();
      } catch (Exception e) {
        e.printStackTrace();
        System.exit(-1);
      }
      */
      //System.exit(0);
    } else {
      System.err.println("Unknown command " + argv[2]);
      usage();
      System.exit(-1);
    }
  }

  public void messageReceived(int dest_addr, Message msg) {
    /* 
    System.err.print("Receiving payload: ");
    for (int j = 0; j < msg.dataLength(); j++) {
      System.err.print(Integer.toHexString(msg.dataGet()[j] & 0xff)+ " ");
    }
    System.err.println();
    */
    if (msg instanceof ConsoleReplyMsg) {
      // Display tuple.
      ConsoleReplyMsg reply = (ConsoleReplyMsg)msg;
      if (reply.get_mode_() == CONSOLE_QUERY_REPLY) {
        System.err.print("Received tuple: " + 
                         reply.get_timehi() + ", " +
                         reply.get_moteID() + " " +
                         reply.get_timelo() + " <");
        for (int i = 0; i < 4; i ++) {
          System.err.print(reply.getElement_field_attrID(i) + 
                           ":" +
                           reply.getElement_field_value(i));
          if (i < 3) {
            System.err.print(", ");
          }
        }
        System.err.println(">");
      } else if (reply.get_mode_() == CONSOLE_ZONE_REPLY) {
        // *timelo* -- length, *timehi* -- word
        System.err.print("Received zone code: " +
                         reply.get_moteID() + " "); 
        int length = (int)reply.get_timelo();
        
        //System.err.print("length = " + length);

        byte word = (byte)reply.get_timehi();

        //System.err.print("word = " + word + ", ");

        int mask = 1 << 7;
        System.err.print("[");
        for (int i = 0; i < length; i ++) {
          if (i > 0) {
            System.err.print(" ");
          }
          if ((mask & word) > 0) {
            System.err.print("1");
          } else {
            System.err.print("0");
          }
          mask >>= 1;
        }
        System.err.println("]");
      }
    } else {
      System.err.println("Received unknown message " + msg);
    }
  }
}
