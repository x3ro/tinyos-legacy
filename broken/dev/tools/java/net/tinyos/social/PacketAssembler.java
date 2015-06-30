package net.tinyos.social;

import net.tinyos.util.*;

class PacketAssembler {

    /* As written, this code will handle only packets built out of a maximum
       of 127 messages */

    byte[] packet;
    int nMessagesPerPacket, packetSize;

    /* current state */
    int currentPacketNumber;
    DataMsg[] receivedMessages;
    int remainingMessages;

    PacketAssembler(int nMessagesPerPacket, int packetSize) {
	if (nMessagesPerPacket < 1 || nMessagesPerPacket > 127)
	    throw new Error("less than 1 or more than 127 messages per packet");

	this.packetSize = packetSize;
	this.nMessagesPerPacket = nMessagesPerPacket;
	this.packet = new byte[packetSize];
	this.receivedMessages = new DataMsg[nMessagesPerPacket];
	
	noPacket();
    }

    private void noPacket() {
	currentPacketNumber = -256; /* Any illegal byte value will do */
	remainingMessages = nMessagesPerPacket;
	for (int i = 0; i < nMessagesPerPacket; i++)
	    receivedMessages[i] = null;
    }

    boolean messageReceived(DataMsg message) {
	int seqno = message.getSeqno();

	if (currentPacketNumber != seqno)
	    noPacket();
	currentPacketNumber = seqno;

	int messageNumber = message.getMessageno();
	if (messageNumber < 0 || messageNumber >= nMessagesPerPacket ||
	    receivedMessages[messageNumber] != null)
	    /* Bogus or redundant message */
	    return false;
	receivedMessages[messageNumber] = message;
	remainingMessages--;

	return remainingMessages == 0;
    }

    byte[] getPacket() {
	try {
	    int offset = 0;

	    // Extract the bytes from each message
	    for (int i = 0; i < nMessagesPerPacket; i++) {
		DataMsg msg = receivedMessages[i];
		byte[] msgData = msg.dataGet();
		int dataStart = msg.offsetData(0) / 8;
		int length = msgData.length - dataStart;

		for (int j = 0; j < length; j++)
		    packet[offset++] = msgData[dataStart + j];
	    }
	    if (offset == packetSize)
		return packet;
	}
	catch (ArrayIndexOutOfBoundsException e) { }

	// Bad packet.
	return null;
    }

    int getPacketNumber() {
	return currentPacketNumber;
    }
}
