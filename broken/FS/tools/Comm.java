package tools;

import net.tinyos.message.*;
import java.io.*;
import java.util.Date;

class Comm implements MessageListener {
    MoteIF intf;

    Comm() {
	try {
	    intf = new MoteIF("localhost", 9000, 0x7d);
	    intf.registerListener(new FSReplyMsg(), this);
	}
	catch (Exception e) {
	    fail("couldn't contact serial forwarder");
	}
    }

    void start() {
	intf.start();
    }

    protected FSReplyMsg reply;

    synchronized FSReplyMsg send(FSOpMsg m) {
	try {
	    intf.send(MoteIF.TOS_BCAST_ADDR, m);
	    wait();
	}
	catch (IOException e) {
	    fail("couldn't send message");
	}
	catch (InterruptedException e) {
	    fail("interrupted!?");
	}
	return reply;
    }

    synchronized public void messageReceived(int to, Message m) {
	reply = (FSReplyMsg)m;
	notify();
    }

    static void fail(String s) {
	System.err.println(s);
	System.exit(2);
    }
    
    static String fsErrors[] = {
	"ok",
	"no more files",
	"no space",
	"bad data",
	"file open",
	"not found",
	"bad crc",
	"hardware problem"
    };

    static String remErrors[] = {
	"unknown command",
	"bad command arguments",
	"file system request failed"
    };

    static String fsErrorString(FSReplyMsg m) {
	int error = m.get_result();
	String msg;

	if (error < fsErrors.length)
	    return fsErrors[error];
	else if (error >= 0x80 && error - 0x80 < remErrors.length)
	    return remErrors[error - 0x80];
	else
	    return "unknown error " + error;
    }

    static void fsError(FSReplyMsg m) {
	System.err.println("error: " + fsErrorString(m));
    }

    static void check(FSReplyMsg m) {
	if (m.get_result() != FS.FS_OK) {
	    fsError(m);
	    System.exit(1);
	}
    }

    FSReplyMsg checkedSend(FSOpMsg m) {
	FSReplyMsg reply = send(m);
	check(reply);
	return reply;
    }
}
