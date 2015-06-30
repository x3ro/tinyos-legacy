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

package net.tinyos.packet;


public class NAMINGPacket extends AMPacket {

    public byte[] packetField_NAMING_source = new byte[4];
    public byte[] packetField_NAMING_destination = new byte[4];
    public short packetField_NAMING_bitmask;
    public short packetField_NAMING_moteID;

    public byte[] packetField_NAMING_data;
    
    public NAMINGPacket() {
	super();
	packetField_NAMING_data = new byte[dataLength()];
	try {
	    setOneByteField("AM_type", (byte)11);
	}
	catch (Exception e) {
	    System.err.println("Failed to initialize AM type of NAMING packet to 0x0b.");
	}
    }

    public int headerLength() {return super.headerLength() + 12;}

    public byte[] namingSource() {return packetField_NAMING_source;}
    public byte[] namingDest() {return packetField_NAMING_destination;}
    public short namingBitmask() {return packetField_NAMING_bitmask;}
    public short namingSourceMoteID() {return packetField_NAMING_moteID;}
    
    
    public void initialize(byte[] packet) {
	super.initialize(packet);
	int offset = super.headerLength();

	packetField_NAMING_source[0] = ArrayPackerLE.getByte(packet, offset);
	packetField_NAMING_source[1] = ArrayPackerLE.getByte(packet, offset+1);
	packetField_NAMING_source[2] = ArrayPackerLE.getByte(packet, offset+2);
	packetField_NAMING_source[3] = ArrayPackerLE.getByte(packet, offset+3);
	    
	packetField_NAMING_destination[0] = ArrayPackerLE.getByte(packet, offset + 4);
	packetField_NAMING_destination[1] = ArrayPackerLE.getByte(packet, offset + 5);
	packetField_NAMING_destination[2] = ArrayPackerLE.getByte(packet, offset + 6);
	packetField_NAMING_destination[3] = ArrayPackerLE.getByte(packet, offset + 7);
	
	packetField_NAMING_bitmask = ArrayPackerLE.getShort(packet, offset + 8);
	packetField_NAMING_moteID = ArrayPackerLE.getShort(packet, offset + 10);

	int headerLen = headerLength();

	packetField_NAMING_data = new byte[dataLength()];
	for (int i = 0; i < packetField_NAMING_data.length; i++) {
	    packetField_NAMING_data[i] = packet[headerLen + i];
	}
    }

    public byte[] toByteArray() {
	byte[] packet = super.toByteArray();
	int offset = super.headerLength();

	for (int i = 0; i < 4; i++) {
	    ArrayPackerLE.putByte(packet, offset + i, packetField_NAMING_source[i]);
	}
	for (int i = 0; i < 4; i++) {
	    ArrayPackerLE.putByte(packet, offset + 4 + i, packetField_NAMING_destination[i]);
	}
	
	ArrayPackerLE.putShort(packet, offset + 8, packetField_NAMING_bitmask);
	ArrayPackerLE.putShort(packet, offset + 10, packetField_NAMING_moteID);

	if (packetField_NAMING_data != null) {
	    int headerLen = headerLength();
	    for (int i = 0; i < packetField_NAMING_data.length; i++) {
		ArrayPackerLE.putByte(packet, headerLen + i, packetField_NAMING_data[i]); 
	    }
	}
	
	return packet;
    }

    public static void main(String[] args) throws Exception {
	byte[] msg  = {
		
	    (byte)0x00, (byte)0x00, (byte)0x00, (byte)0x00,
	    (byte)0x00, (byte)0x00, (byte)0x00, (byte)0x00,
	    (byte)0x00, (byte)0x07, (byte)0x0a, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0x00, (byte)0x00,
	    (byte)0x00, (byte)0x00};

	NAMINGPacket packet = new NAMINGPacket();
	packet.initialize(msg);

	/*	String[] fields;
	
	System.out.println("Byte fields:");
	fields = packet.getByteFieldNames();
	for (int i = 0; i < fields.length; i++) {
	    System.out.print(" o ");
	    System.out.println(fields[i]);
	}

	packet.setOneByteField("AM_group", (byte)0x66);
	System.out.println("Set AM group to 0x66.");
	System.out.println("Checking: group is 0x" + Integer.toHexString(packet.group()));

	System.out.println("Checking: AM dest is 0x" + Integer.toHexString(packet.destination() & 0xffff));
	
	packet.setTwoByteField("NAMING_src", (short)0xe1fe);
	System.out.println("Set naming source to 0xe1fe.");
	System.out.println("Checking: source is 0x" + Integer.toHexString((packet.namingSource()) & 0xffff));

	
	System.out.println("Two byte fields:");
	fields = packet.getTwoByteFieldNames();
	for (int i = 0; i < fields.length; i++) {
	    System.out.print(" o ");
	    System.out.println(fields[i]);
	}


	System.out.println("Checking binary structure of packet.");
	byte[] data = packet.toByteArray();
	System.out.println("Packet:");
	System.out.println(TOSPacket.dataToString(data)); */
    }
}
