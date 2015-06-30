package net.tinyos.social;


interface SocialReceiver {
    public void identityReceived(MoteIF from,
				 int moteId, int localId,
				 int seqNo,
				 int broadcastPeriod,
				 long timeInfoStarts);

    public void socialDataReceived(MoteIF from, DataMsg packet);
}
