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

public class BcastInject {
    static Properties p = new Properties();
    public static final int LED_ON = 1;
    public static final int LED_OFF = 2;
    public static final int RADIO_LOUDER = 3;
    public static final int RADIO_QUIETER = 4;
    public static final int START_SENSING = 5;
    public static final int READ_LOG = 6;
	public static final int DIAG = 7;// sping
    
    public static final int YELLOW_LED = 1;
    public static final int GREEN_LED = 1;
    public static final int RED_LED = 1;

    public static final short TOS_BCAST_ADDR = (short) 0xffff;
    public static final byte MSG_TYPE = 8;
	public static final byte DIAG_TYPE = 90;// sping


    public static void usage() {

	    System.err.println("Usage: java net.tinyos.utils.BcastInject"+
		// sping   " [forwarder_address port] group_id command ");
			       " group_id command + [pattern repeatTimes interval]");
	    System.err.println("\twhere command is one of the following:");
	    System.err.println("\t\tled_on");
	    System.err.println("\t\tled_off");
	    System.err.println("\t\tradio_louder");
	    System.err.println("\t\tradio_quieter");
		System.err.println("\t\tdiag");// sping
		System.err.println("\t\t (pattern, repeatTimes, interval  are for diag command only)");
		
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
	String host = "localhost";
	int port = 9000;
	String cmd = "";
	String pstr = ""; // for holding argument pattern
	byte group_id = 0;
	int cmd_offset = 0;
	short pattern =0;
	short repeatTimes = 0;
	short interval= 1000;

	if (argv.length == 2) {
		cmd = argv[1];
	    if (cmd.equals ("diag")) {
			usage();
			
       	    System.exit(-1);
		}
	    group_id = (byte) Integer.parseInt(argv[0]);	    
	    cmd_offset = 1;
	} else if (argv.length == 5) {
		cmd = argv[1];
		if (cmd.equals ("diag")) {
			group_id = (byte) Integer.parseInt(argv[0]); 
			cmd_offset = 1;
			pattern = (short) Integer.parseInt(argv[2]);
			repeatTimes = (short) Integer.parseInt(argv[3]);
			interval = (short) Integer.parseInt(argv[4]);
			
		/* {
			pstr = argv[2];
			if (pstr.length()!= 6) {

			if ( pstr.startsWith("0x")==false) {
				System.err.println("\t\t pattern is not a 16 bit hexadecimal");
				System.exit(-1);	  
			} }
		}
		
		pattern = toShortInt(pstr);
		*/
		} else {
			usage();
       	    System.exit(-1);
		}
		
	} else {
	    usage();
       	System.exit(-1);
	} 

	SerialForwarderStub rw = new SerialForwarderStub(host, port);
	byte [] packet = new byte[SerialForwarderStub.PACKET_SIZE];
	byte command = 0;
	byte command_args = 0;
	byte sequenceNo = 0;
	if (cmd.equals("led_on")) {
	    command = LED_ON;
	} else if (cmd.equals("led_off")) {
	    command = LED_OFF;
	} else if (cmd.equals("radio_louder")) {
	    command = RADIO_LOUDER;
	} else if (cmd.equals("radio_quieter")) {
	    command = RADIO_QUIETER;
	} else if (cmd.equals("start_sensing")) {
	    command = START_SENSING;
	    int nsamples = Integer.parseInt(argv[cmd_offset + 1]);
	    packet[9] = (byte)(nsamples & 0xff); // number of data points
	    packet[10] = (byte) ((nsamples >> 8) & 0xff);
	    packet[11] = (byte) (Integer.parseInt(argv[cmd_offset + 2]) & 0xff);
	    packet[12] = (byte) (Integer.parseInt(argv[cmd_offset + 3]) & 0xff);
	} else if (cmd.equals("read_log")) {
	    command = READ_LOG;
	    int address = Integer.parseInt(argv[cmd_offset + 1]);
	    int line = Integer.parseInt(argv[cmd_offset + 2]);
	    packet[9] = (byte) (address & 0xff);
	    packet[10] = (byte) ((address>>8) & 0xff);
	    packet[11] = (byte) (line & 0xff);
	    packet[12] = (byte) ((line>>8) & 0xff);
	}  
	else if (cmd.equals("diag")) {
	    command = DIAG;
		
	} 
	else {
	    usage();System.out.println("444");
	    System.exit(-1);
	}
	sequenceNo = restoreSequenceNo();
	
	//Generic message header, destination, group id, and message type
	packet[0] = (byte) (TOS_BCAST_ADDR & 0xff);
	packet[1] = (byte) ((TOS_BCAST_ADDR >>8) & 0xff);
	packet[3] = group_id;
	if (command==DIAG) { 
		packet[2] = DIAG_TYPE;
		// fill in msg data 
		// packet[4] and [5] are source mote ID-- don't know
		packet[4] = 0; packet[5] = 0;
		// 6  and 7 is sequence number 
		packet[6]= sequenceNo++; packet[7]=0;
		// 8 is diag action.  value 0 means packet loss 
		packet[8]= 0;
		// 9 is reserved field  
		packet[9]= 0;  
		// 10 and 11 is diag pattern
		packet[10]= (byte)(pattern &0xff);
		packet[11]= (byte)((pattern >> 8) & 0xff);
		// 12 and 13 is the number of diag response expected 
		packet[12]= (byte)(repeatTimes &0xff);
		packet[13]= (byte)((repeatTimes >> 8 ) & 0xff);
		// 14 and 15 is the response interval in ms. 
		packet[14]= (byte)(interval & 0xff);
		packet[15]= (byte)((interval >>8)& 0xff);
	}
	else {	
	packet[2] = MSG_TYPE;
	// BCast specific information: sequence number.
	packet[4] = sequenceNo++;	
	// Commands to be executed: command and args	
	packet[5] = command;		   
	packet[6] = (byte) 0xff; 
	packet[7] = (byte) 0xfb;
	packet[8] = (byte) 0;
	}
	rw.Open();
	rw.Write(packet);
	for (int i = 0; i < SerialForwarderStub.PACKET_SIZE; i++) {
	    System.out.print(Integer.toHexString(packet[i] & 0xff)+ " ");
	}
	System.out.println();
	saveSequenceNo(sequenceNo);
    }

}
