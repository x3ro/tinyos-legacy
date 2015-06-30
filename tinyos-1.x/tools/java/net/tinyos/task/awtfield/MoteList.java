package net.tinyos.task.awtfield;

import java.awt.*;
import java.awt.event.*;
import net.tinyos.message.*;
import java.util.*;

class MoteList extends Thread implements MessageListener {
    Tool parent;
    Vector motes; // sorted list of Mote

    MoteList(Tool parent) {
	parent.motesElement.add("ALL");
	parent.motesElement.select(0);
	this.parent = parent;
	this.motes = new Vector();
	parent.moteIF.registerListener(new FieldReplyMsg(), this);
	start();
    }

    public void messageReceived(int to, Message m) {
	FieldReplyMsg msg = (FieldReplyMsg)m;

	int sender = msg.get_sender();
	updateList(sender);
    }

    public void run() {
	WakeupMsg wmsg = new WakeupMsg();

	wmsg.set_sender(Tool.localId[0]);
	for (;;) {
	    try {
		parent.moteIF.send(MoteIF.TOS_BCAST_ADDR, wmsg);
		synchronized (this) {
		    wait(Tool.wakeupPeriod[0]);
		}
		timeoutList();
	    }
	    catch (InterruptedException e) { }
	    catch (java.io.IOException e) { }
	}
    }

    void updateList(int alive) {
	synchronized (motes) {
	    long now = System.currentTimeMillis();
	    int count = motes.size();

	    for (int i = 0; i < count; i++) {
		Mote m = (Mote)(motes.elementAt(i));

		if (m.id == alive) {
		    m.lastHeard = now;
		    //System.out.println("repeat " + alive);
		    return;
		}
		if (alive < m.id) {
		    addMoteAt(i, alive, now);
		    return;
		}
	    }
	    addMoteAt(count, alive, now);
	}
    }

    int checkSelection() {
	int idx = parent.motesElement.getSelectedIndex();
	if (idx >= 0)
	    return idx;

	parent.motesElement.select(0);
	return 0;
    }

    void timeoutList() {
	synchronized (motes) {
	    long now = System.currentTimeMillis();
	    int count = motes.size();

	    for (int i = 0; i < count; i++) {
		Mote m = (Mote)(motes.elementAt(i));

		if (m.lastHeard + Tool.moteTimeout[0] < now) {
		    //System.out.println("removing " + m.id);
		    motes.removeElementAt(i);
		    parent.motesElement.remove(i + 1);
		    checkSelection();
		    i--; count--;
		}
	    }
	}
    }

    void addMoteAt(int index, int alive, long now) {
	Mote m = new Mote();
	m.id = alive;
	m.lastHeard = now;
	motes.insertElementAt(m, index);
	parent.motesElement.add("" + alive, index + 1);
	//System.out.println("awake " + alive);
    }

    int getMote() {
	synchronized (motes) {
	    int idx = checkSelection();
	    if (idx == 0)
		return MoteIF.TOS_BCAST_ADDR;
	    else
		return ((Mote)motes.elementAt(idx - 1)).id;
	}
    }
}

class Mote {
    Mote() { }
    int id;
    long lastHeard;
}
