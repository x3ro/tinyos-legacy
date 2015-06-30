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

package packet;


public class BLESSPacket extends AMPacket {

    public short packetField_BLESS_dest;
    public short packetField_BLESS_hop_src;
    public short packetField_BLESS_src;
    public byte packetField_BLESS_src_hop_distance;

    public byte[] packetField_BLESS_data;
    
    public BLESSPacket() {super();}

    public int headerLength() {return super.headerLength() + 7;}

    public short blessSource() {return packetField_BLESS_src;}
    public short blessDest() {return packetField_BLESS_dest;}
    public short blessHopSource() {return packetField_BLESS_hop_src;}
    public byte blessSourceHopDistance() {return packetField_BLESS_src_hop_distance;}
    
    
    public void initialize(byte[] packet) {
	super.initialize(packet);
	int offset = super.headerLength();

	packetField_BLESS_dest = ArrayPackerLE.getShort(packet, offset + 0);
	packetField_BLESS_hop_src = ArrayPackerLE.getShort(packet, offset + 2);
	packetField_BLESS_src = ArrayPackerLE.getShort(packet, offset + 4);
	packetField_BLESS_src_hop_distance = ArrayPackerLE.getByte(packet, offset + 6);

	int headerLen = headerLength();

	packetField_BLESS_data = new byte[dataLength()];
	for (int i = 0; i < packetField_BLESS_data.length; i++) {
	    packetField_BLESS_data[i] = packet[headerLen + i];
	}
    }

    public byte[] toByteArray() {
	byte[] packet = super.toByteArray();
	int offset = super.headerLength();

	ArrayPackerLE.putShort(packet, offset + 0, packetField_BLESS_dest);
	ArrayPackerLE.putShort(packet, offset + 2, packetField_BLESS_hop_src);
	ArrayPackerLE.putShort(packet, offset + 4, packetField_BLESS_src);
	ArrayPackerLE.putByte(packet, offset + 6, packetField_BLESS_src_hop_distance);

	if (packetField_BLESS_data != null) {
	    int headerLen = headerLength();
	    for (int i = 0; i < packetField_BLESS_data.length; i++) {
		ArrayPackerLE.putByte(packet, headerLen + i, packetField_BLESS_data[i]); 
	    }
	}
	
	return packet;
    }

    public static void main(String[] args) throws Exception {
	byte[] msg  = {
		
	    (byte)0xfa, (byte)0xce, (byte)0x07, (byte)0x13,
	    (byte)0x01, (byte)0x00, (byte)0x03, (byte)0x00,
	    (byte)0x00, (byte)0x07, (byte)0x0a, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef,
	    (byte)0xde, (byte)0xad, (byte)0x00, (byte)0x00,
	    (byte)0x00, (byte)0x00};

	BLESSPacket packet = new BLESSPacket();
	packet.initialize(msg);

	String[] fields;
	
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
	
	packet.setTwoByteField("BLESS_src", (short)0xe1fe);
	System.out.println("Set bless source to 0xe1fe.");
	System.out.println("Checking: source is 0x" + Integer.toHexString((packet.blessSource()) & 0xffff));

	
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
