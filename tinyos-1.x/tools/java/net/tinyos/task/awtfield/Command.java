package net.tinyos.task.awtfield;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import net.tinyos.message.*;

class Command extends Thread implements MessageListener {
    Tool parent;
    int cmdId = (new Random()).nextInt() & 0xffff;
    Hashtable outstanding = new Hashtable();
    Vector queue = new Vector();

    Command(Tool parent) {
	this.parent = parent;
	parent.moteIF.registerListener(new FieldReplyMsg(), this);
	start();
    }

    public void messageReceived(int to, Message m) {
	FieldReplyMsg msg = (FieldReplyMsg)m;

	Integer id = new Integer(msg.get_cmdId());
	
	//System.out.println("received reply for " + id + " from " + msg.get_sender());
	MessageListener handler = (MessageListener)outstanding.get(id);
	if (handler != null)
	    handler.messageReceived(to, msg);
    }

    void sendCommand(int dest, FieldMsg command, MessageListener handler) {
	command.set_cmdId(cmdId);
	command.set_sender(Tool.localId[0]);
	//System.out.println("reg " + cmdId);
	outstanding.put(new Integer(cmdId++), handler);
	if (cmdId >= 0x10000)
	    cmdId = 0;
	synchronized (queue) {
	    for (int i = 0; i < Tool.sendCount[0]; i++)
		queue.addElement(new MessageDest(dest, command));
	    queue.notify();
	}
    }

    public void run() {
	synchronized (queue) {
	    for (;;) try {
		while (!queue.isEmpty()) {
		    MessageDest md = (MessageDest)queue.elementAt(0);
		    queue.removeElementAt(0);

		    try {
			parent.moteIF.send(md.d, md.m);
		    }
		    catch (java.io.IOException e) { }

		    synchronized (this) {
			wait(Tool.sendInterval[0]);
		    }
		}
		queue.wait();
	    }
	    catch (InterruptedException e) { }
	}
    }
}

class MessageDest {
    MessageDest(int d, Message m) {
	this.d = d;
	this.m = m;
    }
    Message m;
    int d;
}
