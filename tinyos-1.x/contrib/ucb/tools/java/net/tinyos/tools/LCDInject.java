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
 * $Id: LCDInject.java,v 1.2 2003/10/07 21:45:38 idgay Exp $
 */

/**
 * This application works with the TestUartRadio in tinyos/apps.
 * The string input on the command line is sent to the remote LCD display.
 *
 * @author Joe Polastre
 */
package net.tinyos.tools;

import net.tinyos.util.*;
import java.io.*;
import net.tinyos.message.*;

public class LCDInject {
        
    public static final short TOS_BCAST_ADDR = (short) 0xffff;
	
    public static void usage() {
	    System.err.println("Usage: java net.tinyos.tools.LCDInject"+
			       " <group_id> <function> \"string\"");
            System.err.println("\twhere function = -s for sending a message");
	    System.err.println("\t      function = -b [0,1] for backlight [off,on]\n");
    }

    public static void main(String[] argv) throws IOException{
	String cmd;
	byte group_id = 0;
        byte function = 0;
        byte value = 0;

	if (argv.length < 3) {
	  usage();
	  System.exit(-1);
	}

	try {
	  group_id = (byte)(Integer.parseInt(argv[0]) & 0xff);
	} catch (NumberFormatException nfe) {
	  usage();
	  System.exit(-1);
	}

	cmd = argv[2];

	TOSMsg packet = new TOSMsg(36);
        packet.set_addr(0xFFFF);
        packet.set_group(group_id);

	if (argv[1].equals("-s")) {
          packet.set_type((short)100);
          packet.amTypeSet((short)100);
          packet.setString_data(cmd);
    	  packet.set_length((short)cmd.length());
        }
        else {
  	  try {
	    value = (byte)(Integer.parseInt(argv[2]) & 0xff);
	  } catch (NumberFormatException nfe) {
	    usage();
	    System.exit(-1);
  	  }
          packet.set_type((short)101);
          packet.amTypeSet((short)101);
          packet.setElement_data(0, value);
    	  packet.set_length((short)1);
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

