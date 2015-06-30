/* @(#)BcastInject.java
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * $\Id$
 */

/**
 * 
 *
 * @author <a href="mailto:szewczyk@sourceforge.net">Robert Szewczyk</a>
 */
package net.tinyos.tools;

import net.tinyos.util.*;
import java.io.*;
import java.util.Properties;
import net.tinyos.message.*;

public class BcastInject implements MessageListener {
    static Properties p = new Properties();
    public static final byte LED_ON = 1;
    public static final byte LED_OFF = 2;
    public static final byte RADIO_LOUDER = 3;
    public static final byte RADIO_QUIETER = 4;
    public static final byte START_SENSING = 5;
    public static final byte READ_LOG = 6;

    public boolean read_log_done = false; 
    
    public static final short TOS_BCAST_ADDR = (short) 0xffff;
	
    public static void usage() {
	    System.err.println("Usage: java net.tinyos.utils.BcastInject"+
			       " <group_id> <command> [arguments]");
	    System.err.println("\twhere <command> and [arguments] can be one of the following:");
	    System.err.println("\t\tled_on");
	    System.err.println("\t\tled_off");
	    System.err.println("\t\tradio_louder");
	    System.err.println("\t\tradio_quieter");
 	    System.err.println("\t\tstart_sensing [nsamples interval_ms]");
	    System.err.println("\t\tread_log [dest_address]");
    }

    public static void startSensingUsage() {
	System.err.println("Usage: java net.tinyos.tools.BcastInject <group_id>"
		+ " start_sensing [num_samples interval_ms]");
    }
    public static void  readLogUsage() {
	System.err.println("Usage: java net.tinyos.tools.BcastInject <group_id>" +
		" read_log [dest_address]");
    } 

    public static byte restoreSequenceNo() {
	try {
	    FileInputStream fis = new FileInputStream("bcast.properties");
	    p.load(fis);
	    byte i = (byte)Integer.parseInt(p.getProperty("sequenceNo", "1"));
	    fis.close();
	    return i;
	} catch (IOException e) {
	    p.setProperty("sequenceNo", "1");
	    return 1;
	}
    }
    public static void saveSequenceNo(int i) {
	try {
	    FileOutputStream fos = new FileOutputStream("bcast.properties");
	    p.setProperty("sequenceNo", Integer.toString(i));
	    p.store(fos, "#Properties for BcastInject\n");
	} catch (IOException e) {
	    System.err.println("Exception while saving sequence number" +
			       e);
	    e.printStackTrace();
	}
    }

    public static void main(String[] argv) throws IOException{
	String cmd;
	byte group_id = 0;
	byte sequenceNo = 0;
	boolean read_log = false;

	if (argv.length < 2) {
	  usage();
	  System.exit(-1);
	}

	try {
	  group_id = (byte)(Integer.parseInt(argv[0]) & 0xff);
	} catch (NumberFormatException nfe) {
	  usage();
	  System.exit(-1);
	}

	cmd = argv[1];

	if (cmd.equals("start_sensing") && argv.length != 4) {
	  startSensingUsage();
	  System.exit(-1);
	} else if (cmd.equals("read_log") && argv.length != 3) {
	  readLogUsage();
  	  System.exit(-1);
	}
	
	SimpleCmdMsg packet = new SimpleCmdMsg(); 
	sequenceNo = restoreSequenceNo();
	packet.setSeqno(sequenceNo);
	packet.setHop_count((char)0);
	packet.setSource((char)0);

	if (cmd.equals("led_on")) {
	  packet.setAction(LED_ON);
	} else if (cmd.equals("led_off")) {
	  packet.setAction(LED_OFF);
	} else if (cmd.equals("radio_louder")) {
	  packet.setAction(RADIO_LOUDER);
	} else if (cmd.equals("radio_quieter")) {
	  packet.setAction(RADIO_QUIETER);
	} else if (cmd.equals("start_sensing")) {
	  packet.setAction(START_SENSING);
	  short nsamples = (short)Integer.parseInt(argv[2]);
	  long interval_ms = (long)Integer.parseInt(argv[3]);
	  packet.setArgs_ss_args_nsamples(nsamples);
	  packet.setArgs_ss_args_interval(interval_ms);
	} else if (cmd.equals("read_log")) {
	  read_log = true;
	  packet.setAction(READ_LOG);
	  char address = (char)Integer.parseInt(argv[2]);
	  packet.setArgs_rl_args_destaddr(address);
	}  else {
      	  usage();
	  System.exit(-1);
	}

	try {

	  System.err.print("Sending payload: ");
	  for (int i = 0; i < packet.dataLength(); i++) {
	    System.err.print(Integer.toHexString(packet.dataGet()[i] & 0xff)+ " ");
	  }
	  System.err.println();

	  MoteIF mote = new MoteIF("127.0.0.1", 9000, group_id);

	  // Need to wait for a read_log message to come back
	  BcastInject bc = null;
	  if (read_log) {
	    bc = new BcastInject();
	    mote.registerListener(new LogMsg(), bc);
	    mote.start();
	  }

	  mote.send(TOS_BCAST_ADDR, packet);

	  if (read_log) {
	    synchronized (bc) {
	      if (bc.read_log_done == false) {
		System.err.println("Waiting for response to read_log...");
		bc.wait(10000);
	      }
	      if (bc.read_log_done == false) {
		System.err.println("Warning: Timed out waiting for response to read_log command!");
	      }
	    }
	  }

	  saveSequenceNo(sequenceNo+1);
	  System.exit(0);

	} catch(Exception e) {
      	  e.printStackTrace();
	}	

    }

    public void messageReceived(int dest_addr, Message m) {
      LogMsg lm = (LogMsg) m;
      System.err.println("Received log message: "+lm);

      System.err.print("Log values: ");
      for (int i = 0; i < lm.numElementsLog(); i++) {
	char val = lm.getLog(i);
	System.err.print(Integer.toHexString((int)val)+" ");
      }
      System.err.println("");

      synchronized (this) {
	read_log_done = true;
	this.notifyAll();
      }
    }

}

