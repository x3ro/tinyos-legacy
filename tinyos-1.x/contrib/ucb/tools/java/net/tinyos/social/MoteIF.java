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
				 msg.get_identity_moteId(),
				 msg.get_identity_localId(),
				 msg.get_seqno(),
				 msg.get_broadcastPeriod(),
				 msg.get_identity_timeInfoStarts());
			} });
	    intf.registerListener(new DataMsg(),
	        new MessageListener() {
			public void messageReceived(int to, Message m) {
			    socialListener.socialDataReceived
				(MoteIF.this, (DataMsg)m);
			} });
	}
	catch (Exception e) {
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

	msg.set_localId((char)localId);
	mysend(moteId, msg);
    }

    synchronized void sendReqData(int moteId, long lastDataTime) {
	ReqDataMsg msg = new ReqDataMsg();

	msg.set_currentTime(new Date().getTime() / 1000);
	msg.set_lastDataTime(lastDataTime);
	mysend(moteId, msg);
    }
}
