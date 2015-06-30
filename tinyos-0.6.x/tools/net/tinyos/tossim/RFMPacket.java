/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:		Phil Levis
 * Date:        Aug 3 2001
 * Desc:        A TOSSIM RFM packet datum.
 *
 */

package net.tinyos.tossim;

import java.io.*;

public class RFMPacket {
    private static final int PACKET_LEN = 36;

    private long time;
    private short moteID;
    private byte[] packet;
    
    public RFMPacket(byte[] data) throws IOException {
	DataInputStream stream = new DataInputStream(new ByteArrayInputStream(data));
	packet = new byte[PACKET_LEN];
	
	time = stream.readLong();
	moteID = stream.readShort();
	stream.readFully(packet);
    }

    public long time() {return time;}
    public short moteID() {return moteID;}
    public byte[] data() {return packet;}

    public String toString() {
	String msg = "RFM Packet\n";
	msg += "Time: " + time + "\n";
	msg += "MoteID: " + moteID + "\n";
	msg += "Data:";
	for (int i = 0; i < PACKET_LEN; i++) {
	    if (i % 20 == 0) {
		msg += "\n";
	    }
	    String datum = Integer.toString((int)(packet[i] & 0xff), 16);
	    if (datum.length() == 1) {msg += "0";}
	    msg += datum;
	    msg += " ";
	}
	msg += "\n";
	return msg;
    }
    
}
