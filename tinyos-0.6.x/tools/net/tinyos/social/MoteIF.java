package net.tinyos.social;

import net.tinyos.util.*;
import java.io.*;
import java.util.Date;

class MoteIF extends Thread implements PacketListenerIF {
    static final int CMD_REGISTER = 20;
    static final int CMD_SEND_ID = 21;
    static final int CMD_REQ_DATA = 22;
    static final int CMD_SEND_SOCIAL_INFO = 23;

    /* Packet fields offsets */
    static final int SSI_DATA = 10;

    static final short TOS_BCAST_ADDR = (short) 0xffff;

    SocialReceiver socialListener;

    int id; /* For identifying base stations */
    byte groupId;
    SerialForwarderStub sfw;
    byte[] packet;

    MoteIF(int id, String host, int port, byte gid, SocialReceiver s)
    {
	this.id = id;
	groupId = gid;
	socialListener = s;
	sfw = new SerialForwarderStub(host, port);
	try { sfw.Open(); }
	catch (IOException e) {
	    e.printStackTrace();
	    System.exit(2);
	}
	sfw.registerPacketListener(this);
	packet = new byte[SerialForwarderStub.PACKET_SIZE];
    }

    public void run()
    {
	try { sfw.Read(); }
	catch (IOException e) {
	    e.printStackTrace();
	    System.exit(2);
	}
    }

    void writeShort(int i, int offset)
    {
	packet[offset] = (byte)(i & 0xff);
	packet[offset + 1] = (byte)((i >> 8) & 0xff);
    }

    void writeInt(long i, int offset)
    {
	writeShort((int)i, offset);
	packet[offset + 2] = (byte)((i >> 16) & 0xff);
	packet[offset + 3] = (byte)((i >> 24) & 0xff);
    }

    static int readShort(byte[] packet, int offset)
    {
	return (packet[offset] & 0xff) + ((packet[offset + 1] & 0xff) << 8);
    }

    static long readInt(byte[] packet, int offset)
    {
	return readShort(packet, offset) +
	    ((packet[offset + 2] & 0xff) << 16) +
	    ((packet[offset + 3] & 0xff) << 24);
    }

    private void send(int moteId)
    {
	//Generic message header, destination, group id, and message type
	writeShort(moteId, 0);
	packet[3] = groupId;

	try { sfw.Write(packet); }
	catch (IOException e) {
	    e.printStackTrace();
	    System.exit(2);
	}
	for (int i = 0; i < SerialForwarderStub.PACKET_SIZE; i++) {
	    System.out.print(Integer.toHexString(packet[i] & 0xff)+ " ");
	}
	System.out.println();
    }

    synchronized void sendRegister(int moteId, int localId)
    {
	packet[2] = (byte)CMD_REGISTER;
	writeShort(localId, 4);
	send(moteId);
    }

    synchronized void sendReqData(int moteId, long lastDataTime)
    {
	packet[2] = (byte)CMD_REQ_DATA;
	writeInt(new Date().getTime() / 1000, 4);
	writeInt(lastDataTime, 8);
	send(moteId);
    }

    public void packetReceived(byte[] packet)
    {
	if (packet[3] == groupId)
	    switch (packet[2]) {
	    case CMD_SEND_ID:
		socialListener.identityReceived(this,
						readShort(packet, 8),
						readShort(packet, 10),
						readShort(packet, 4),
						readShort(packet, 6),
						readInt(packet, 12));
		break;
	    case CMD_SEND_SOCIAL_INFO:
		socialListener.socialDataReceived(this, packet);
		break;
	    }
    }
}
