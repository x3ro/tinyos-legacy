package net.tinyos.task.spy;

import java.awt.*;
import java.awt.event.*;
import java.util.*;

class MoteList extends Thread {
    Tool parent;
    Vector motes; // sorted list of Mote

    MoteList(Tool parent) {
	this.parent = parent;
	this.motes = new Vector();
	start();
    }

    public void run() {
	for (;;) {
	    try {
		synchronized (this) {
		    wait(1000);
		}
		timeoutList();
	    }
	    catch (InterruptedException e) { }
	}
    }

    void alive(int who) {
	synchronized (motes) {
	    long now = System.currentTimeMillis();
	    int count = motes.size();

	    for (int i = 0; i < count; i++) {
		Mote m = (Mote)(motes.elementAt(i));

		if (m.id == who) {
		    m.lastHeard = now;
		    //System.out.println("repeat " + who);
		    return;
		}
		if (who < m.id) {
		    addMoteAt(i, who, now);
		    return;
		}
	    }
	    addMoteAt(count, who, now);
	}
    }

    void timeoutList() {
	synchronized (motes) {
	    long now = System.currentTimeMillis();
	    int count = motes.size();
	    boolean change = false;

	    for (int i = 0; i < count; i++) {
		Mote m = (Mote)(motes.elementAt(i));

		if (m.lastHeard + Tool.moteTimeout[0] < now) {
		    //System.out.println("removing " + m.id);
		    motes.removeElementAt(i);
		    i--; count--;
		    change = true;
		}
	    }
	    if (change)
		updateWidget();
	}
    }

    void addMoteAt(int index, int alive, long now) {
	Mote m = new Mote();
	m.id = alive;
	m.lastHeard = now;
	motes.insertElementAt(m, index);
	updateWidget();
	//System.out.println("awake " + alive);
    }

    void updateWidget() {
	String l = "";
	int count = motes.size();

	for (int i = 0; i < count; i++) {
	    Mote m = (Mote)(motes.elementAt(i));
	    l += m.id + "\n";
	}
	parent.motesElement.setText(l);
    }
}

class Mote {
    Mote() { }
    int id;
    long lastHeard;
}
