package net.tinyos.social.names;

class MoteInfo
{
    final int moteId;
    String name;

    MoteInfo(int moteId)
    {
	this.moteId = moteId;
	this.name = "A" + moteId;
    }

    MoteInfo(int moteId, String name)
    {
	this.moteId = moteId;
	this.name = name;
    }

    public String toString() {
	return "" + moteId + ":" + name;
    }
}
