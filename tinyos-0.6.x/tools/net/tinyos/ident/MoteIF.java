package net.tinyos.ident;

import net.tinyos.util.*;
import java.io.*;

class MoteIF extends Thread implements PacketListenerIF {
    static final int CMD_CLEAR = 10;
    static final int CMD_SET = 11;
    static final int CMD_SEND = 12;

    static final short TOS_BCAST_ADDR = (short) 0xffff;

    IdentityReceiver dispatch;

    byte groupId;
    SerialForwarderStub sfw;
    byte[] packet;

    MoteIF(byte gid, IdentityReceiver d)
    {
	groupId = gid;
	dispatch = d;
	sfw = new SerialForwarderStub("localhost", 9000);
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

    synchronized void sendCommand(int cmd, String id)
    {
	//Generic message header, destination, group id, and message type
	packet[0] = (byte)((TOS_BCAST_ADDR >> 8) & 0xff);
	packet[1] = (byte)(TOS_BCAST_ADDR & 0xff);
	packet[2] = (byte)cmd;
	packet[3] = groupId;

	int idlength = id.length();
	for (int i = 0; i < idlength; i++)
	    packet[i + 4] = (byte)id.charAt(i);
	packet[idlength + 4] = 0;

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

    public void packetReceived(byte[] packet)
    {
	if (packet[2] == CMD_SEND && packet[3] == groupId) {
	    StringBuffer receivedId = new StringBuffer(Ident.MAX_ID_LENGTH);
	    int idlen = 0;

	    while (packet[idlen + 4] != 0 && idlen <= Ident.MAX_ID_LENGTH) {
		receivedId.append((char)(packet[idlen + 4]));
		idlen++;
	    }
	    dispatch.identityReceived(receivedId.toString());
	}
    }
}
