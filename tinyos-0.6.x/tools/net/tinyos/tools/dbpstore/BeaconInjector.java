/* @(#)BeaconInjector.java
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

package net.tinyos.tools.dbpstore;

import net.tinyos.util.*;
import java.io.*;

public class BeaconInjector implements Runnable
{
    SerialStub rw;
    byte [] packet = new byte[SerialForwarderStub.PACKET_SIZE];
    public static final char MSG_TYPE = 5;
    public static final short TOS_BCAST_ADDR = (short) 0xffff;
    byte group_id;

    BeaconInjector(SerialStub writer, byte gid) throws IOException{
	rw = writer;
	group_id = gid;
    }

    public void run() {
	packet[0] = (byte) ((TOS_BCAST_ADDR >> 8) & 0xff);
	packet[1] = (byte) (TOS_BCAST_ADDR & 0xff);
	packet[2] = MSG_TYPE;
	packet[3] = group_id;
	packet[4] = 0;
	packet[5] = 1;
	packet[6] = 0;
	for (int i = 0; i < SerialForwarderStub.PACKET_SIZE; i++) {
	    System.out.print(Integer.toHexString(packet[i] & 0xff)+ " ");
	}
	System.out.println();
	while (true) {
	    try {
		rw.Write(packet);
		System.out.print("?");
		Thread.currentThread().sleep(12000);
	    } catch (Exception e) {
	    }
	}
    }
}
