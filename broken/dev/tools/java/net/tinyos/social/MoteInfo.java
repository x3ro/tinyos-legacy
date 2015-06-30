package net.tinyos.social;

class MoteInfo
{
    final int moteId, localId;
    long arrivalTime;

    final PacketAssembler socialPA;
    final SocialPacket socialPacket;
    static int maxPeople;
    long lastSocialRequestTime;

    // Cumulative social data (upto lastSocialTime), indexed by localId
    int[] socialTimes;
    // last data received, and corresponding start and end times
    int[] lastSocialTimes;
    long lastSocialStartTime, lastSocialEndTime;

    MoteInfo(int moteId, int localId)
    {
	this.moteId = moteId;
	this.localId = localId;

	this.arrivalTime = -1;
	this.lastSocialStartTime = this.lastSocialEndTime = 0;
	this.lastSocialRequestTime = 0;

	this.socialPacket = new SocialPacket();

	/* We find the max number of people from the size of the SocialPacket
	   packet */
	int spLength = socialPacket.dataGet().length;
	maxPeople = (spLength - socialPacket.offsetTimeTogether(0) / 8) / 2;

	this.socialTimes = new int[maxPeople];
	this.lastSocialTimes = new int[maxPeople];

	int maxBytes = net.tinyos.message.MoteIF.maxMessageSize -
	    DataMsg.offsetData(0) / 8;
	int firstPacketPeople = (maxBytes - socialPacket.offsetTimeTogether(0) / 8) / 2;
	int peoplePerPacket = maxBytes / 2;
	int npackets;

	npackets = 1;
	if (maxPeople > firstPacketPeople)
	    npackets += (maxPeople - firstPacketPeople + peoplePerPacket - 1) / peoplePerPacket;

	this.socialPA = new PacketAssembler(npackets, spLength);
    }
}
