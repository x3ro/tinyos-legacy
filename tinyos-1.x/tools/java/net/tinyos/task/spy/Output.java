package net.tinyos.task.spy;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.text.*;

class Output {
    MessageList parent;
    String now, contents;
    boolean first, displayed;

    Output(MessageList parent, String contents) {
	this.parent = parent;
	this.contents = contents;
	this.now = new SimpleDateFormat("H:mm:ss").format(new Date());
	this.first = this.displayed = false;
    }

    synchronized void activate(boolean first) {
	this.displayed = true;
	this.first = first;
	redisplay();
    }

    synchronized void deactivate() {
	this.displayed = false;
    }

    void redisplay() {
	String actualTitle;

	if (first) {
	    parent.title.setColor(Color.red);
	}
	else {
	    parent.title.setColor(Color.black);
	}
	actualTitle = parent.name + " @ " + now;
	parent.title.setText(actualTitle);
	parent.output.setText(contents);
    }
}
