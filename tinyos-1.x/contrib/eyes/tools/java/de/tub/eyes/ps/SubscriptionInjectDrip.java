/** 
 * Simple command line tool to inject a Subscription 
 * encapsulated in a Drip message. 
 * @author Jan Hauer
 */

package de.tub.eyes.ps;

import net.tinyos.drip.*;
import net.tinyos.message.*;

import java.io.*; 
import java.text.*;
import java.util.*;


public class SubscriptionInjectDrip {
  private static boolean reliable = false;
  private static int dripMessageID = 1; // = subscriptionID
  private static int subscriberID = 0;
  private static short subscriptionID = 1;
  private static short modCount = 0;
  private static boolean unsubscribe = false;
  private static Constraint constraint[];
  private static int numConstraints = 0;
  private static AVPair avpair[];
  private static int numAvpair = 0;

  public static class Constraint {
    public int attibuteID;
    public short operationID;
    public long value;
    public int size;
  }
    
  public static class AVPair {
    public int attibuteID;
    public long value;
    public int size;
  }
  
  public static void printHex(byte b)
  {
    String s = Integer.toHexString(0xFF & b).toUpperCase();
    System.out.print("0x" + ((b & 0xF0) > 0 ? "" : "0") + s + " ");
  }

  public static void main(String[] args) {
    constraint = new Constraint[50]; // enough
    avpair = new AVPair[50];         // enough
    parseArgs(args);
    showMessageContent();
    
    Drip drip = new Drip(dripMessageID);
    PSSubscriptionMsg msg = new PSSubscriptionMsg();
    
    msg.set_subscriberID((short) subscriberID);
    msg.set_subscriptionID((short) subscriptionID);
    msg.set_modificationCounter((short) modCount);
    if (unsubscribe)
      msg.set_flags((short) 1);
    else
      msg.set_flags((short) 0);
    for (int i=0; i<numConstraints; i++)
      if (!msg.addConstraint(
            constraint[i].attibuteID, 
            constraint[i].operationID, 
            constraint[i].value,
            constraint[i].size))
          {
            System.err.println("Error: Too many constraints/instructions !");
            System.exit(1);
          }
         
    for (int i=0; i<numAvpair; i++)
      if (!msg.addAVPair(
            avpair[i].attibuteID, 
            avpair[i].value,
            avpair[i].size))
          {
            System.err.println("Error: Too many constraints/instructions !");
            System.exit(1);
          }

    System.out.print("Sending ...");
    if (reliable)
      drip.send(msg, msg.getTotalMessageSizeBytes());
    else
      drip.sendUnreliable(msg, msg.getTotalMessageSizeBytes());
    System.out.println("done!");
    System.exit(0);
  }
  
  private static void showMessageContent() {
    System.out.println("Message content (subscription encapsulated in a DripMsg): ");
    System.out.println("  -dripID: " + dripMessageID);
    System.out.println("  -subscriberID: " + subscriberID);
    System.out.println("  -subscriptionID: " + subscriptionID);
    System.out.println("  -modCount: " + modCount);
    if (unsubscribe)
      System.out.println("  -unsubscribe");
    else
      System.out.println("  -subscribe");
    System.out.println("  -number of constraints " + numConstraints);
    for(int i = 0; i < numConstraints; i++){
      System.out.println("     constraint "+i+": { AttribID: "+
          constraint[i].attibuteID+", OperationID: "+
          constraint[i].operationID+", Value: "+
          constraint[i].value+", ValueSize: "+
          constraint[i].size+" (byte)} ");
    }
    System.out.println("  -number of instructions " + numAvpair);
    for(int i = 0; i < numAvpair; i++){
      System.out.println("     instruction "+i+": { AttribID: "+
          avpair[i].attibuteID+", Value: "+
          avpair[i].value+" ValueSize: "+
          avpair[i].size+" (byte)} ");
    }
    /*
    if (reliable)
      System.out.println("  -reliable injection");
    else
      System.out.println("  -unreliable injection");
    System.out.println("");
    */
  }
    

    
    
  private static void parseArgs(String args[]) {
    if (args.length == 0)
      usage();
    for(int i = 0; i < args.length; i++) {
      if (args[i].startsWith("--")) {
        String longopt = args[i].substring(2);
    	  if (longopt.equals("help")) {
	        usage();
	      }
      } else if (args[i].startsWith("-")) {
        // Options
	      String opt = args[i].substring(1);
      	if (opt.equals("subscriberID")) {
	        subscriberID =  Integer.parseInt(args[++i]);
      	} else if (opt.equals("subscriptionID")) {
	        dripMessageID = subscriptionID = Short.parseShort(args[++i]);
          if (dripMessageID < 1 || dripMessageID > 10){
            System.out.println(" ERROR: Currently subscriptionID must be [1..10] !");
            System.exit(1);
          }
      	} else if (opt.equals("modCount")) {
	        modCount = Short.parseShort(args[++i]);
      	} else if (opt.equals("unsubscribe")) {
	        unsubscribe = true;
      	} else if (opt.equals("reliable")) {
	        reliable = true;
      	} else if (opt.equals("constraint")) {
          constraint[numConstraints] = new Constraint();
          constraint[numConstraints].attibuteID = Integer.parseInt(args[++i]);
          constraint[numConstraints].operationID = Short.parseShort(args[++i]);
          constraint[numConstraints].value = Long.parseLong(args[++i]);
          constraint[numConstraints].size = Integer.parseInt(args[++i]);
          numConstraints++;
      	} else if (opt.equals("instruction")) {
          avpair[numAvpair] = new AVPair();
          avpair[numAvpair].attibuteID = Integer.parseInt(args[++i]);
          avpair[numAvpair].value = Long.parseLong(args[++i]);
          avpair[numAvpair].size = Integer.parseInt(args[++i]);
          numAvpair++;
        }
      }
    }
  }

  private static void usage() {
    System.err.println("This tool injects a suscription in the network using the Drip protocol.");
    System.err.println("");
    System.err.println("usage: java de.tub.eyes.ps.SubscriptionInjectDrip <opts>");
    System.err.println("  -subscriberID <subscriber id>");
    System.err.println("  -subscriptionID <subscription id>");
    System.err.println("    note: <subscription id> is used as Drip ID and must be [1..10]");
    System.err.println("  -modCount <modification counter>");
    System.err.println("  -unsubscribe or -subscribe");
    System.err.println("  -constraint <attribute ID> <operation ID> <value> <valueSize>");
    System.err.println("    note: valueSize specifies the size of value in byte, e.g. 2 for a uint16_t");
    System.err.println("    default = none ");
    System.err.println("  -instruction <attribute ID> <value> <valueSize>");
    System.err.println("    note: valueSize specifies the size of value in byte, e.g. 2 for a uint16_t");
    System.err.println("    default = none ");
    //System.err.println("  -reliable : inject message reliable (TOSBase must use Drip!)");
    //System.err.println("    default = unreliable (send once)");
    System.err.println("  -h, --help : this information");
    System.err.println("Example (subscribe to Light with a rate of 1s):");
    System.err.println(" 'java de.tub.eyes.ps.SubscriptionInjectDrip -subscriberID 1 -subscriptionID 1'");
    System.err.println("  -modCount 1 -subscribe -constraint 2 5 0 2 -instruction 100 1000 4'");
    System.err.println("Note: Drip requires TOSBase to be installed on the base station node.");
    System.exit(1);
  }
  
}
