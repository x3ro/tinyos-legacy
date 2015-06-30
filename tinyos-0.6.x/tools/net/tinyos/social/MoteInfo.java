package net.tinyos.social;

class MoteInfo
{
    final int moteId, localId;
    long arrivalTime;

    final PacketAssembler socialPA;
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
	int first_packet_people = (PacketAssembler.BYTES_PER_MESSAGE - MoteIF.SSI_DATA) / 2;
	int people_per_packet = PacketAssembler.BYTES_PER_MESSAGE / 2;
	int npackets = Social.MAX_LOCAL_IDS <= first_packet_people ? 1 :
	    1 + (Social.MAX_LOCAL_IDS - first_packet_people + people_per_packet - 1) / people_per_packet;
	this.socialPA = new PacketAssembler(npackets, MoteIF.SSI_DATA + 2 * Social.MAX_LOCAL_IDS);
	this.lastSocialStartTime = this.lastSocialEndTime = 0;
	this.lastSocialRequestTime = 0;
	this.socialTimes = new int[Social.MAX_LOCAL_IDS];
	this.lastSocialTimes = new int[Social.MAX_LOCAL_IDS];
    }
}
