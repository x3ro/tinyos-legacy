/*
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
 * $Id: GDI2SoftInject.java,v 1.2 2003/10/07 21:45:36 idgay Exp $
 */

/**
 * This application works with the TestUartRadio in tinyos/apps.
 * The string input on the command line is sent to the remote LCD display.
 *
 * @author Joe Polastre
 */
package net.tinyos.gdi;

import net.tinyos.util.*;
import java.io.*;
import net.tinyos.message.*;

public class GDI2SoftInject {
        
    public static final short TOS_BCAST_ADDR = (short) 0xffff;
	
    public static void usage() {
	    System.err.println("Usage: java net.tinyos.tools.GDI2SoftInject"+
			       " <group_id> <mote> <function> [params]");
        System.err.println("\twhere mote = -1 broadcasts to all motes");
        System.err.println("\t      function = -c for calibration data");
        System.err.println("\t      function = -k to kill and reset mote(s)");
        System.err.println("\t      function = -q to query");
	    System.err.println("\t      function = -r <min> <sec> for setting sample rate\n");
    }

    public static void main(String[] argv) throws IOException{
	String cmd;
	byte group_id = 0;
    short mote = 0;
        byte function = 0;
        byte value = 0;

	if (argv.length < 3) {
	  usage();
	  System.exit(-1);
	}

	try {
	  group_id = (byte)(Integer.parseInt(argv[0]) & 0xff);
      mote = (short)(Integer.parseInt(argv[1]) & 0xffff);
	} catch (NumberFormatException nfe) {
	  usage();
	  System.exit(-1);
	}

	//cmd = argv[2];

	TOSMsg packet = new TOSMsg(36);
        if (mote == -1)
          packet.set_addr(0xFFFF);
        else
          packet.set_addr(mote);
        packet.set_group(group_id);

	if (argv[2].equals("-c")) {
          packet.set_type((short)55);
          packet.amTypeSet((short)55);
          // insert command_id here
          packet.setElement_data(0, (byte)0);
    	  packet.set_length((short)1);
    }
    else if (argv[2].equals("-q")) {
        packet.set_type((short)59);
        packet.amTypeSet((short)59);
        // insert command_id here
        packet.setElement_data(0, (byte)0);
        packet.set_length((short)1);
    }
    else if (argv[2].equals("-k")) {
        packet.set_type((short)58);
        packet.amTypeSet((short)58);
        // insert command_id here
        packet.setElement_data(0, (byte)0);
        packet.set_length((short)1);
    }
    else if (argv[2].equals("-r")) {
        byte min=0, sec = 0;
  	    try {
  	      min = (byte)(Integer.parseInt(argv[3]) & 0xff);
          sec = (byte)(Integer.parseInt(argv[4]) & 0xff);
	    } catch (Exception nfe) {
	      usage();
	      System.exit(-1);
  	    }
        packet.set_type((short)57);
        packet.amTypeSet((short)57);
        packet.setElement_data(0, min);
        packet.setElement_data(1, sec);
        // insert command_id here
    	packet.set_length((short)2);
    }
        
	try {
	  System.err.print("Sending payload: ");
	  for (int i = 0; i < packet.dataLength(); i++) {
	    System.err.print(Integer.toHexString(packet.dataGet()[i] & 0xff)+ " ");
	  }
	  System.err.println();
      SerialForwarderStub sfs = new SerialForwarderStub ("127.0.0.1", 9000);
      sfs.Open();
	  // Need to wait for a read_log message to come back
      sfs.Write(packet.dataGet());
      sfs.Close();
	  System.exit(0);

	} catch(Exception e) {
      	  e.printStackTrace();
	}	

    }
}

