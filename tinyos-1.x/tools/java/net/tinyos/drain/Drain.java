// $Id: Drain.java,v 1.1 2005/10/31 17:07:20 gtolle Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/** 
 *
 * Tree builder for the Drain protocol.
 * 
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

package net.tinyos.drain;

import net.tinyos.message.*;
import net.tinyos.util.*;

import org.apache.log4j.*;

import java.io.*; 
import java.text.*;
import java.util.*;

public class Drain {

  public boolean VERBOSE = true;
  private Logger log = Logger.getLogger(Drain.class.getName());

  private static int DRAIN_MAX_CHILDREN = 8;
  private static int DRAIN_MAX_CHILDREN_LOG2 = 3;

  private MoteIF moteIF;
  private int spAddr;

  private ArrayList children = new ArrayList();

  private static int BEACON_DELAY = 4;

  private TreeMaintainer treeMaintainer = null;

  public short ttl = 15;
  public int delay = 4;
  public int period = 0;
  public int count = 1;
  public boolean forever = false;
  public boolean usingTosBase = true;
  public int treeInstance = (int)((double)Math.random() * (double)255);

  public boolean isCommandLine = false;

  public Drain() {
    spAddr = DrainLib.setSPAddr();
    moteIF = DrainLib.startMoteIF();
  }

  public Drain(int p_spAddr, MoteIF p_moteIF) {
    spAddr = p_spAddr;
    moteIF = p_moteIF;
  }

  public void buildTree() {
    buildTree(BEACON_DELAY);
  }

  public void buildTree(int delay) {

    buildTree(delay, treeInstance, true);
  }

  public void buildTree(int delay, int treeInstance, boolean defaultRoute) {

    DrainBeaconMsg beaconMsg = new DrainBeaconMsg();

    children.clear();
    children.add(new Integer(0));

    beaconMsg.set_treeInstance((byte)treeInstance);
    beaconMsg.set_source(spAddr);
    beaconMsg.set_parent(0xffff);
    if (usingTosBase){
	beaconMsg.set_linkSource(spAddr);
    }
    else {
	beaconMsg.set_linkSource(0x7e);
    }
    beaconMsg.set_cost(0);
    beaconMsg.set_ttl(ttl);
    
    beaconMsg.set_beaconSeqno((short)0);
    beaconMsg.set_beaconDelay((byte)delay);
    beaconMsg.set_beaconOffset((short)0);

    if (defaultRoute) {
      beaconMsg.set_defaultRoute((short)1);
    } else {
      beaconMsg.set_defaultRoute((short)0);
    }

    log.info("buildTree: root_address=" + beaconMsg.get_linkSource() + " instance=" + treeInstance + " delay=" + delay + " defaultRoute=" + defaultRoute);
    
    send(beaconMsg);
  }

  public synchronized void send(Message m) {
    sendTo(MoteIF.TOS_BCAST_ADDR, m);
  }
 
  public synchronized void sendTo(int to, Message m) {
    try {
      moteIF.send(to, m);
    } catch (IOException e) {
      e.printStackTrace();
      System.out.println("ERROR: Can't send message");
      System.exit(1);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private class TreeMaintainer extends Thread {
      
      public void run(){
	  while (count > 0 || forever) {
	      if (VERBOSE) {
		  System.err.println("Sending beacon...");
	      }
	      buildTree(delay, treeInstance, true);
	      try {
		if (period > 0) {
		  Thread.sleep(period * 1000);
		} else {
		  Thread.sleep(delay * 1000);
		}
	      } catch (InterruptedException e) {}
	      count--;
	  }
	  if (isCommandLine) {
	    System.exit(0);
	  }
      }
  }

  public void maintainTree(){
      if (treeMaintainer != null && treeMaintainer.isAlive() ){
	  return;
      }
      treeMaintainer = new TreeMaintainer();
      treeMaintainer.start();
  }

  public void stopTreeMaintenance() {
      if (treeMaintainer != null && treeMaintainer.isAlive() ){
	  treeMaintainer.stop();
      }
  }
  public static void main(String args[]) {
    
    Drain drain = new Drain();
    
    parseArgs(args, drain);
    
    System.out.println("Drain: root_address=" + drain.spAddr + " instance=" + drain.treeInstance + " period=" + drain.period + " delay=" + drain.delay);

    drain.maintainTree();
  }

  private static void parseArgs(String args[], Drain drain) {

    ArrayList cleanedArgs = new ArrayList();

    drain.isCommandLine = true;

    for(int i = 0; i < args.length; i++) {
      if (args[i].startsWith("--")) {

        // Parse Long Options
        String longopt = args[i].substring(2);
	
	if (longopt.equals("help")) {
	  usage();
	}

      } else if (args[i].startsWith("-")) {

        // Parse Short Options
	String opt = args[i].substring(1);

	if (opt.equals("t")) {
	  drain.delay = Integer.parseInt(args[++i]);
	} else if (opt.equals("c")) {
	  drain.count = Integer.parseInt(args[++i]);
	} else if (opt.equals("a")) {
	  drain.spAddr = Integer.parseInt(args[++i]);
	} else if (opt.equals("b")) {
	  drain.usingTosBase = Boolean.valueOf(args[++i]).booleanValue();
	} else if (opt.equals("n")) {
	  drain.forever = true;
	} else if (opt.equals("s")) {
          drain.spAddr = 0xfffe;
	  drain.usingTosBase = false;
	} else if (opt.equals("i")) {
	  drain.treeInstance = Integer.parseInt(args[++i]);
	} else if (opt.equals("p")) {
	  drain.period = Integer.parseInt(args[++i]);
	} else if (opt.equals("h")) {
	  usage();
	}
	
      } else {

        // Place into args string
        cleanedArgs.add(args[i]);
      }
    }
  }

  private static void usage() {
    System.err.println("usage: java net.tinyos.nucleus.Drain <opts>");
    System.err.println("  -i <instance number>");
    System.err.println("  -t <rebroadcast delay in secs>");
    System.err.println("  -p <rebuilding period in secs>");
    System.err.println("  -c <number of beacons to transmit>");
    System.err.println("  -n : Keep rebuilding the tree forever");
    System.err.println("  -b <true|false> : TOSBase is connected or not");
    System.err.println("  -a <spAddress> : the address of the root (default=0)");
    System.err.println("  -s : Using with tossim (equivalent to '-b false -a 0xfffe'");
    System.err.println("  -h, --help : This message.");
    System.exit(1);
  }
}
