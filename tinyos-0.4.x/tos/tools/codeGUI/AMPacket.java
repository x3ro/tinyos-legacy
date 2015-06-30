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
 *
 *
 */

package codeGUI;


public class AMPacket extends TOSPacket {

    public short packetField_AM_dest;
    public byte packetField_AM_group;
    public byte packetField_AM_type;
    public byte[] packetField_AM_data;
    
    public AMPacket() {super();}

    
    public AMPacket(short moteID, byte group, byte type) throws IllegalArgumentException {
	packetField_AM_dest = moteID;
	packetField_AM_group = group;
	packetField_AM_type = type;
    }
    
    public AMPacket(short moteID, byte group, byte type, byte[] data) throws IllegalArgumentException {
	packetField_AM_dest = moteID;
	packetField_AM_group = group;
	packetField_AM_type = type;
	
	setData(data);
    }

    public short destination() {return packetField_AM_dest;}
    public byte type() {return packetField_AM_type;}
    public byte group() {return packetField_AM_group;}

    public byte[] getDataSection() {return packetField_AM_data;}

    public void setData(byte[] data) throws IllegalArgumentException {
	if (data.length != 34) {throw new IllegalArgumentException("AM data is 34 bytes long, not " + data.length);}

	packetField_AM_data = data;
    }

    public void initialize(byte[] packet) throws IllegalArgumentException {
	if (packet.length != 38) {
	    throw new IllegalArgumentException("Packet isn't length 38: " + packet.length);
	}

	packetField_AM_dest = (short)(((packet[1] & 0xff) << 8) | (packet[0] & 0xff));
	packetField_AM_type = packet[2];
	packetField_AM_group = packet[3];
	packetField_AM_data = new byte[34];
	
	for (int i = 0; i < 34; i++) {
	    packetField_AM_data[i] = packet[i + 4];
	}

	
    }
    
    public byte[] toByteArray() {
	byte[] packet = new byte[38];
	packet[0] = (byte)((packetField_AM_dest) & 0xff);
	packet[1] = (byte)((packetField_AM_dest >> 8) & 0xff);
	packet[2] = packetField_AM_type;
	packet[3] = packetField_AM_group;

	if (packetField_AM_data != null) {
	    for (int i = 0; i < 34; i++) {
		packet[i + 4] = packetField_AM_data[i];
	    }
	}

	return packet;
    }

    public int headerLength() {return 4;}

    public static void main(String[] args) throws Exception {
	byte[] msg  = {
		
	    (byte)0xfa, (byte)0xce, (byte)0x07, (byte)0x13,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0x00, (byte)0x00,
	    (byte)0x00, (byte)0x00};

	AMPacket packet = new AMPacket();
	packet.initialize(msg);

	String[] fields;
	
	System.out.println("Byte fields:");
	fields = packet.getByteFieldNames();
	for (int i = 0; i < fields.length; i++) {
	    System.out.print(" o ");
	    System.out.println(fields[i]);
	}

	packet.setOneByteField("AM_group", (byte)0x66);
	System.out.println("Set group to 0x66.");
	System.out.println("Checking: group is 0x" + Integer.toHexString(packet.group()));

	
	System.out.println("Two byte fields:");
	fields = packet.getTwoByteFieldNames();
	for (int i = 0; i < fields.length; i++) {
	    System.out.print(" o ");
	    System.out.println(fields[i]);
	}


	System.out.println("Checking binary structure of packet.");
	byte[] data = packet.toByteArray();
	
	System.out.println("Packet:");
	System.out.println(TOSPacket.dataToString(data));
    }
}
