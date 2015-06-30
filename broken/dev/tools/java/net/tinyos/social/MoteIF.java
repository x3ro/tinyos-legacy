package net.tinyos.social;

import net.tinyos.message.*;
import java.io.*;
import java.util.Date;

class MoteIF {
    SocialReceiver socialListener;

    net.tinyos.message.MoteIF intf;

    int id; /* For identifying base stations */

    MoteIF(int id, String host, int port, byte gid, SocialReceiver s) {
	this.id = id;
	socialListener = s;

	try {
	    intf = new net.tinyos.message.MoteIF(host, port, gid);
	    intf.registerListener(new IdentMsg(),
	        new MessageListener() {
			public void messageReceived(int to, Message m) {
			    IdentMsg msg = (IdentMsg)m;

			    socialListener.identityReceived
				(MoteIF.this,
				 msg.getIdentity_moteId(),
				 msg.getIdentity_localId(),
				 msg.getSeqno(),
				 msg.getBroadcastPeriod(),
				 msg.getIdentity_timeInfoStarts());
			} });
	    intf.registerListener(new DataMsg(),
	        new MessageListener() {
			public void messageReceived(int to, Message m) {
			    socialListener.socialDataReceived
				(MoteIF.this, (DataMsg)m);
			} });
	}
	catch (IOException e) {
	    fail("couldn't contact serial forwarder");
	}
    }

    void start() {
	intf.start();
    }

    void mysend(int moteId, Message m) {
	try {
	    intf.send(moteId, m);
	}
	catch (IOException e) {
	    fail("couldn't send message");
	}
    }

    static void fail(String s) {
	System.err.println(s);
	System.exit(2);
    }
    
    synchronized void sendRegister(int moteId, int localId) {
	RegisterMsg msg = new RegisterMsg();

	msg.setLocalId((char)localId);
	mysend(moteId, msg);
    }

    synchronized void sendReqData(int moteId, long lastDataTime) {
	ReqDataMsg msg = new ReqDataMsg();

	msg.setCurrentTime(new Date().getTime() / 1000);
	msg.setLastDataTime(lastDataTime);
	mysend(moteId, msg);
    }
}
