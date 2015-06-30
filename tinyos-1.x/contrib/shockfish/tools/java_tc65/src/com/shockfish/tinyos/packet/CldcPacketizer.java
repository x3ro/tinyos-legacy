/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
 **/

/* 
 * Java CLDC Port
 * Pierre Metrailler
 * Copyright (c) 2005 Shockfish SA
 * 
 */

package com.shockfish.tinyos.packet;

import net.tinyos.packet.ByteSource;
import com.shockfish.tinyos.util.CldcCrc;

import net.tinyos.util.Messenger;
// import net.tinyos.message.*;
import java.io.*;
import java.util.*;
import net.tinyos.message.Dump;

/**
 * The Packetizer class implements the new mote-PC protocol, using a ByteSource
 * for low-level I/O
 */
public class CldcPacketizer extends CldcAbstractSource implements Runnable {
	/*
	 * Protocol inspired by, but not identical to, RFC 1663. There is currently
	 * no protocol establishment phase, and a single byte ("packet type") to
	 * identify the kind/target/etc of each packet.
	 * 
	 * The protocol is really, really not aiming for high performance.
	 * 
	 * There is however a hook for future extensions: implementations are
	 * required to answer all unknown packet types with a P_UNKNOWN packet.
	 * 
	 * To summarise the protocol: - the two sides (A & B) are connected by a
	 * (potentially unreliable) byte stream - the two sides exchange packets
	 * framed by 0x7e (SYNC_BYTE) bytes - each packet has the form <packet type>
	 * <data bytes 1..n> <16-bit crc> where the crc (see net.tinyos.util.Crc)
	 * covers the packet type and bytes 1..n - bytes can be escaped by preceding
	 * them with 0x7d and their value xored with 0x20; 0x7d and 0x7e bytes must
	 * be escaped, 0x00 - 0x1f and 0x80-0x9f may be optionally escaped - There
	 * are currently 5 packet types: P_PACKET_NO_ACK: A user-packet, with no ack
	 * required P_PACKET_ACK: A user-packet with a prefix byte, ack required.
	 * The receiver must send a P_ACK packet with the prefix byte as its
	 * contents. P_ACK: ack for a previous P_PACKET_ACK packet P_UNKNOWN:
	 * unknown packet type received. On reception of an unknown packet type, the
	 * receicer must send a P_UNKNOWN packet, the first byte must be the unknown
	 * packet type. - Packets that are greater than a (private) MTU are silently
	 * dropped.
	 */
	final static int DEBUG_LEVEL = 0;

	final static int DEBUG_DEBUG = 8;

	final static int DEBUG_INFO = 4;

	final static int DEBUG_SILENT = 0;

	final static int SYNC_BYTE = 0x7e;

	final static int ESCAPE_BYTE = 0x7d;

	final static int MTU = 256;

	final static int ACK_TIMEOUT = 5000; // in milliseconds

	final static int P_ACK = 64; // ->queue 0

	final static int P_PACKET_ACK = 65; // ->queue 1

	final static int P_PACKET_NO_ACK = 66; // ->queue 2

	final static int P_UNKNOWN = 255; // ->queue 3

	private ByteSource io;

	private boolean inSync;

	private byte[] receiveBuffer = new byte[MTU];

	private int seqNo;

	// Packets are received by a separate thread and placed in a
	// per-packet-type queue. If received[x] is null, then x is an
	// unknown protocol (but P_UNKNOWN and P_PACKET_ACK are handled
	// specially)
	private Thread reader;

	private Vector[] received;

	/**
	 * Packetizers are built using the makeXXX methods in BuildSource
	 */
	public CldcPacketizer(String name, ByteSource io, int plat) {
		super(name);
		this.io = io;
		platform = plat;
		inSync = false;
		seqNo = 13;
		reader = new Thread(this);
		received = new Vector[4];
		received[0] = new Vector();
		received[1] = new Vector();
		received[2] = new Vector();
		received[3] = new Vector();
	}

	synchronized public void open(Messenger messages) throws IOException {
		super.open(messages);
		if (!reader.isAlive())
			reader.start();	
	}

	protected void openSource() throws IOException {
		io.open();
	}

	protected void closeSource() {
		io.close();
	}

	public void dumpQueues() {
		System.out.println(name + " *** Queues: ACK=" + received[0].size()
				+ ",P_PACKET_ACK=" + received[1].size() + ",P_PACKET_NO_ACK="
				+ received[2].size() + ",P_UNKNOWN=" + received[3].size());
	}

	public int getQueueSize() {
		return received[2].size();
	}

	private int getQueueId(int packetType) {
		switch (packetType) {

		case P_ACK:
			return 0;
		case P_PACKET_ACK:
			return 1;
		case P_PACKET_NO_ACK:
			return 2;
		case P_UNKNOWN:
			return 3;
		}
		// TODO throw exc
		return 0;
	}

	protected byte[] readProtocolPacket(int packetType, long deadline)
			throws IOException {
		Vector inPackets = received[getQueueId(packetType)];
		synchronized (inPackets) {
			while (inPackets.isEmpty()) {
				long now = System.currentTimeMillis();
				if (deadline != 0 && now >= deadline) {
					if (DEBUG_LEVEL >= DEBUG_INFO)
						System.out.println(name + " Queue expired");
					return null;
				}
				try {
					inPackets.wait(deadline != 0 ? deadline - now : 0);
				} catch (InterruptedException e) {
					throw new IOException(name + " Queue interrupted");
				}
			}
			// CLDC hack : we replace removefirst
			byte[] topPacket = (byte[]) inPackets.firstElement();
			inPackets.removeElementAt(0);

			return topPacket;
		}
	}

	// Place a packet in its packet queue, or reject unknown packet
	// types (which don't have a queue)
	protected void pushProtocolPacket(int packetType, byte[] packet) {
		Vector inPackets = received[getQueueId(packetType)];
		if (inPackets != null) {
			synchronized (inPackets) {
				inPackets.addElement(packet);
				inPackets.notify();
			}
		} else if (packetType != P_UNKNOWN) {
			System.out.println("WARNING : NOT IMPLEMENTED");
			try {
				writeFramedPacket(P_UNKNOWN, packetType, ackPacket, 0);
			} catch (IOException e) {
				e.printStackTrace();
			}
			message(name + ": ignoring unknown packet type "
					+ Integer.toHexString(packetType));
		}
	}

	protected byte[] readSourcePacket() throws IOException {
		if (DEBUG_LEVEL >= DEBUG_INFO) {
			dumpQueues();
		}
		// Packetizer packet format is identical to PacketSource's
		return readProtocolPacket(P_PACKET_NO_ACK, 0);
	}

	// Write an ack-ed packet
	protected boolean writeSourcePacket(byte[] packet) throws IOException {
		if (DEBUG_LEVEL >= DEBUG_INFO) {
			dumpQueues();
		}
		seqNo++;

		writeFramedPacket(P_PACKET_ACK, seqNo, packet, packet.length);

		long deadline = System.currentTimeMillis() + ACK_TIMEOUT;
		for (;;) {
			byte[] ack = readProtocolPacket(P_ACK, deadline);
			if (ack == null) {
				if (DEBUG_LEVEL >= DEBUG_INFO) {
					message(name + ": ACK timed out");
				}
				return false;
			}
			if (ack[0] == (byte) seqNo) {
				if (DEBUG_LEVEL >= DEBUG_INFO) {
					message(name + ": Rcvd ACK");
				}
				return true;
			}
		}
	}

	static private byte ackPacket[] = new byte[0];

	public void run() {
		try {
			for (;;) {
				byte[] packet = readFramedPacket();
				int packetType = packet[0] & 0xff;
				int pdataOffset = 1;
				//System.out
				//		.println(name + " received packet type " + packetType);
				if (packetType == P_PACKET_ACK) {
					// send ack
					message(name + " ack req->ack send");
					writeFramedPacket(P_ACK, packet[1], ackPacket, 0);
					// And merge with un-acked packets
					packetType = P_PACKET_NO_ACK;
					pdataOffset = 2;
				}
				int dataLength = packet.length - pdataOffset;
				byte[] dataPacket = new byte[dataLength];
				System
						.arraycopy(packet, pdataOffset, dataPacket, 0,
								dataLength);
				pushProtocolPacket(packetType, dataPacket);
				dataPacket = null;
			}
		} catch (IOException e) {
			//System.out.println("--- IOE");
			e.printStackTrace();
		}
	}

	// Read system-level packet. If inSync is false, we currently don't
	// have sync
	private byte[] readFramedPacket() throws IOException {
		int count = 0;
		boolean escaped = false;

		for (;;) {
			if (!inSync) {
				message(name + ": resynchronising");
				// re-synchronise
				while (io.readByte() != SYNC_BYTE) {
					// message(name+": garbage");
				}
				inSync = true;
				count = 0;
				escaped = false;
			}

			if (count >= MTU) {
				// Packet too long, give up and try to resync
				message(name + ": packet too long");
				inSync = false;
				continue;
			}

			byte b = io.readByte();

			if (escaped) {
				if (b == SYNC_BYTE) {
					// sync byte following escape is an error, resync
					message(name + ": unexpected sync byte");
					inSync = false;
					continue;
				}
				b ^= 0x20;
				escaped = false;
			} else if (b == ESCAPE_BYTE) {
				escaped = true;
				continue;
			} else if (b == SYNC_BYTE) {
				if (count < 4) {
					// too-small frames are ignored
					count = 0;
					continue;
				}
				byte[] packet = new byte[count - 2];
				System.arraycopy(receiveBuffer, 0, packet, 0, count - 2);

				int readCrc = (receiveBuffer[count - 2] & 0xff)
						| (receiveBuffer[count - 1] & 0xff) << 8;
				int computedCrc = CldcCrc.calc(packet, packet.length);

				if (DEBUG_LEVEL >= DEBUG_INFO) {
					// message(name+" R:");
					// Dump.printPacket(System.err, packet);
					// message(" rcrc: " + Integer.toHexString(readCrc) +
					// " ccrc: " + Integer.toHexString(computedCrc));
				}

				if (readCrc == computedCrc) {
					return packet;
				} else {
					message(name + ": bad packet");
					/*
					 * We don't lose sync here. If we did, garbage on the line
					 * at startup will cause loss of the first packet.
					 */
					count = 0;
					continue;
				}
			}

			receiveBuffer[count++] = b;
		}
	}

	// Class to build a framed, escaped and crced packet byte stream
	static class Escaper {
		byte[] escaped;

		int escapePtr;

		int crc;

		// We're building a length-byte packet
		Escaper(int length) {
			escaped = new byte[2 * length];
			escapePtr = 0;
			crc = 0;
			escaped[escapePtr++] = SYNC_BYTE;
		}

		static private boolean needsEscape(int b) {
			return b == SYNC_BYTE || b == ESCAPE_BYTE;
		}

		void nextByte(int b) {
			b = b & 0xff;
			crc = CldcCrc.calcByte(crc, b);
			if (needsEscape(b)) {
				escaped[escapePtr++] = ESCAPE_BYTE;
				escaped[escapePtr++] = (byte) (b ^ 0x20);
			} else {
				escaped[escapePtr++] = (byte) b;
			}
		}

		void terminate() {
			escaped[escapePtr++] = SYNC_BYTE;
		}
	}

	// Write a packet of type 'packetType', first byte 'firstByte'
	// and bytes 2..'count'+1 in 'packet'
	private synchronized void writeFramedPacket(int packetType, int firstByte,
			byte[] packet, int count) throws IOException {
		if (DEBUG_LEVEL >= DEBUG_INFO) {
			System.err.println(name + " sent packet type " + packetType);
		}

		Escaper buffer = new Escaper(count + 6);

		buffer.nextByte(packetType);
		buffer.nextByte(firstByte);
		for (int i = 0; i < count; i++) {
			buffer.nextByte(packet[i]);
		}

		int crc = buffer.crc;
		buffer.nextByte(crc & 0xff);
		buffer.nextByte(crc >> 8);

		buffer.terminate();

		byte[] realPacket = new byte[buffer.escapePtr];
		System.arraycopy(buffer.escaped, 0, realPacket, 0, buffer.escapePtr);

		if (DEBUG_LEVEL >= DEBUG_INFO) {
			// Dump.dump("encoded", realPacket);
		}
		io.writeBytes(realPacket);
		buffer = null;
	}

}
