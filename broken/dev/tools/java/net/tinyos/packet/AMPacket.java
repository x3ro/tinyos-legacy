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


public class AMPacket extends TOSPacket {

    public short packetField_AM_dest;
    public byte packetField_AM_group;
    public byte packetField_AM_type;
    public byte packetField_AM_length;
    public short packetField_AM_crc;
    public byte[] packetField_AM_data;
    
    
    public AMPacket() {
	super();
	packetField_AM_data = new byte[dataLength()];
	packetField_AM_dest = (short)0xffff;
	packetField_AM_group = (byte)0x7D;
    }

    
    public AMPacket(short moteID, byte group, byte type) throws IllegalArgumentException {
	super();

	packetField_AM_dest = moteID;
	packetField_AM_group = group;
	packetField_AM_type = type;
    	packetField_AM_data = new byte[dataLength()];
    }

    public AMPacket(short moteID, byte group, byte type, byte length) throws IllegalArgumentException {
	super();

	packetField_AM_dest = moteID;
	packetField_AM_group = group;
	packetField_AM_type = type;
	packetField_AM_length = length;
    	packetField_AM_data = new byte[dataLength()];
    }

    public AMPacket(short moteID, byte group, byte type, byte[] data) throws IllegalArgumentException {
	super();
	
	packetField_AM_dest = moteID;
	packetField_AM_group = group;
	packetField_AM_type = type;
	packetField_AM_data = new byte[dataLength()];
	
	setData(data);
    }
    
    public AMPacket(short moteID, byte group, byte type, byte length, byte[] data) throws IllegalArgumentException {
	super();
	
	packetField_AM_dest = moteID;
	packetField_AM_group = group;
	packetField_AM_type = type;
	packetField_AM_length = length;
	packetField_AM_data = new byte[dataLength()];
		
	setData(data);
    }
    
    public int headerLength() {return super.headerLength() + 5;}
    public int footerLength() {return super.footerLength() + 2;}

    public short destination() {return packetField_AM_dest;}
    public byte type() {return packetField_AM_type;}
    public byte group() {return packetField_AM_group;}
    public byte length() {return packetField_AM_length;}
    
    public byte[] getDataSection() {return packetField_AM_data;}

    public void setData(byte[] data) throws IllegalArgumentException {
	int dataLen = dataLength();
	if (data.length != dataLen) {throw new IllegalArgumentException("AM data is " + data.length + " bytes long, expecting " + dataLen);}

	packetField_AM_data = data;
    }

    public void calculateCRC() {
	byte[] packet = toByteArray();
	int i;
	int index = 0;
	int count = packet.length - 4;
	short crc = 0;

	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}

	packetField_AM_crc = crc;
    }
    
    public void initialize(byte[] packet) throws IllegalArgumentException {
	if (packet.length != packetLength()) {
	    throw new IllegalArgumentException("Packet isn't length " + packetLength() + ": it's " + packet.length);
	}

	packetField_AM_dest = ArrayPackerLE.getShort(packet, 0);
	packetField_AM_type = ArrayPackerLE.getByte(packet, 2);
	packetField_AM_group = ArrayPackerLE.getByte(packet, 3);
	packetField_AM_length = ArrayPackerLE.getByte(packet, 4);
	
	int dataLen = dataLength();
	packetField_AM_data = new byte[dataLen];
	for (int i = 0; i < dataLen; i++) {
	    packetField_AM_data[i] = packet[i + headerLength()];
	}

	packetField_AM_crc = ArrayPackerLE.getShort(packet, 34);
    }

    
    public byte[] toByteArray() {
	byte[] packet = new byte[packetLength()];
	int offset = super.headerLength();
	
	ArrayPackerLE.putShort(packet, offset + 0, packetField_AM_dest);
	ArrayPackerLE.putByte(packet, offset + 2, packetField_AM_type);
	ArrayPackerLE.putByte(packet, offset + 3, packetField_AM_group);
	ArrayPackerLE.putByte(packet, offset + 4, packetField_AM_length);
	
	int dataLen = dataLength();
	int headerLen = headerLength();
	
	if (packetField_AM_data != null) {
	    for (int i = 0; i < dataLen; i++) {
		ArrayPackerLE.putByte(packet, i + headerLen, packetField_AM_data[i]);
	    }
	}

	int i;
	int index = 0;
	int count = packet.length - footerLength();
	short crc = 0;
	
	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}
	packetField_AM_crc = crc;
	System.out.println("Calculating CRC for " + ( packet.length - footerLength()) + " bytes: " + crc + "\n");
	
	ArrayPackerLE.putShort(packet, offset + 34, packetField_AM_crc);

	return packet;
    }

    public String toString() {
      String s= "AMPacket [dest=0x"+Integer.toHexString(packetField_AM_dest)+" type=0x"+Integer.toHexString(packetField_AM_type)+" group=0x"+Integer.toHexString(packetField_AM_group)+" len="+packetField_AM_length+" crc=0x"+Integer.toHexString(packetField_AM_crc)+"]";
      int dataLen = dataLength();
      for (int i = 0; i < dataLen; i++) {
        s += " "+Integer.toHexString(packetField_AM_data[i] & 0xff);
      }
      return s;
    }

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
	    (byte)0xde, (byte)0xad, (byte)0x00, (byte)0x00};

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
