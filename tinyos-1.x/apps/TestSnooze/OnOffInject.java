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
 * $Id: OnOffInject.java,v 1.2 2003/10/07 21:45:22 idgay Exp $
 */

/**
 * This application works with the TestUartRadio in tinyos/apps.
 * The string input on the command line is sent to the remote LCD display.
 *
 * @author Joe Polastre
 */

import net.tinyos.util.*;
import java.io.*;
import net.tinyos.message.*;

public class OnOffInject {

    public static final short TOS_BCAST_ADDR = (short) 0xffff;

    public static void usage() {
	    System.err.println("Usage: OnOffInject"+
			       "<host> <port> <group_id> <mote> <value>");
        System.err.println("\twhere mote = -1 broadcasts to all motes");
        System.err.println();
    }

    public static void main(String[] argv) throws IOException{
        String cmd;
        byte group_id = 0;
        short mote = 0;
        byte function = 0;
        byte value = 0;
        String host = "";
        int port = 0;

        if (argv.length < 5) {
          usage();
          System.exit(-1);
        }

        try {
            group_id = (byte)(Integer.parseInt(argv[2]) & 0xff);
            mote = (short)(Integer.parseInt(argv[3]) & 0xffff);
            value = (byte)(Integer.parseInt(argv[4]) & 0xff);
            port = (Integer.parseInt(argv[1]));
        } catch (NumberFormatException nfe) {
          usage();
          System.exit(-1);
        }

        TOSMsg packet = new TOSMsg(36);
        if (mote == -1)
          packet.set_addr(0xFFFF);
        else
          packet.set_addr(mote);
        packet.set_group(group_id);
        packet.set_type((short)249);
        packet.amTypeSet((short)249);
        packet.setElement_data(0, value);
        packet.setElement_data(1,(byte)0);
        packet.set_length((short)2);


        try {
            System.err.print("Sending payload: ");
            for (int i = 0; i < packet.dataLength(); i++) {
                System.err.print(Integer.toHexString(packet.dataGet()[i] & 0xff)+ " ");
            }
            System.err.println();
            SerialForwarderStub sfs = new SerialForwarderStub (host,port);
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

