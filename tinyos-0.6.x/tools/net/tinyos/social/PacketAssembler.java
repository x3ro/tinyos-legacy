package net.tinyos.social;

import net.tinyos.util.*;

class PacketAssembler {

    /* As written, this code will handle only packets built out of a maximum
       of 127 messages */

    final static int PACKET_NUMBER_OFFSET = 6;
    final static int MESSAGE_NUMBER_OFFSET = PACKET_NUMBER_OFFSET + 1;
    final static int DATA_STARTS = MESSAGE_NUMBER_OFFSET + 1;
    final static int BYTES_PER_MESSAGE = SerialForwarderStub.PACKET_SIZE - 2 -
	DATA_STARTS;

    byte[] packet;
    int nMessagesPerPacket, packetSize;

    /* current state */
    int currentPacketNumber;
    boolean[] receivedMessages;
    int remainingMessages;

    PacketAssembler(int nMessagesPerPacket, int packetSize)
    {
	if (nMessagesPerPacket < 1 || nMessagesPerPacket > 127)
	    throw new Error("less than 1 or more than 127 messages per packet");

	this.packetSize = packetSize;
	this.nMessagesPerPacket = nMessagesPerPacket;
	this.packet = new byte[packetSize];
	this.receivedMessages = new boolean[nMessagesPerPacket];
	
	noPacket();
    }

    private void noPacket()
    {
	currentPacketNumber = -256; /* Any illegal byte value will do */
	remainingMessages = nMessagesPerPacket;
	for (int i = 0; i < nMessagesPerPacket; i++)
	    receivedMessages[i] = false;
    }

    boolean messageReceived(byte[] message)
    {
	if (currentPacketNumber != message[PACKET_NUMBER_OFFSET])
	    noPacket();
	currentPacketNumber = message[PACKET_NUMBER_OFFSET];

	int messageNumber = message[MESSAGE_NUMBER_OFFSET];
	if (messageNumber < 0 || messageNumber >= nMessagesPerPacket ||
	    receivedMessages[messageNumber])
	    /* Bogus or redundant message */
	    return false;
	receivedMessages[messageNumber] = true;
	remainingMessages--;

	int offset = messageNumber * BYTES_PER_MESSAGE;
	int nBytes = offset + BYTES_PER_MESSAGE > packetSize ?
	    packetSize - offset : BYTES_PER_MESSAGE;
	for (int i = 0; i < nBytes; i++)
	    packet[offset + i] = message[DATA_STARTS + i];

	return remainingMessages == 0;
    }

    byte[] getPacket()
    {
	return packet;
    }

    int getPacketNumber()
    {
	return currentPacketNumber;
    }
}
