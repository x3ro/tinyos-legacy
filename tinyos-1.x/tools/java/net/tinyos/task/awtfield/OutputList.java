package net.tinyos.task.awtfield;

import java.awt.*;
import java.awt.event.*;
import net.tinyos.message.*;
import java.util.*;

class OutputList implements AdjustmentListener {
    Tool parent;
    Vector allOutput = new Vector();
    Output lastActive = null;

    OutputList(Tool parent) {
	this.parent = parent;
	parent.scrollElement.addAdjustmentListener(this);
    }

    synchronized void activate(Output o, boolean first) {
	if (lastActive != null)
	    lastActive.deactivate();
	lastActive = o;
	o.activate(first);
    }

    int current, max = 0;

    synchronized void add(Output o) {
	allOutput.addElement(o);
	if (max >= Tool.maxOutput[0])
	    allOutput.removeElementAt(0);
	else {
	    max++;
	    parent.scrollElement.setMaximum(max);
	}
	parent.scrollElement.setValue(max - 1);
	current = max - 1;
	activate(o, true);
    }

    synchronized public void adjustmentValueChanged(AdjustmentEvent e) {
	if (max == 0)
	    return;

	// getValue() is buggy on Zaurus. Emulate.
	switch (e.getAdjustmentType()) {
	case AdjustmentEvent.TRACK: current = e.getValue(); break;
	case AdjustmentEvent.BLOCK_DECREMENT: case AdjustmentEvent.UNIT_DECREMENT:
	    current--;
	    if (current < 0)
		current = 0;
	    break;
	case AdjustmentEvent.BLOCK_INCREMENT: case AdjustmentEvent.UNIT_INCREMENT:
	    current++;
	    if (current >= max)
		current = max - 1;
	    break;
	default:
	    System.out.println("unknown type " + e.getAdjustmentType());
	    break;
	}
	activate((Output)allOutput.elementAt(current), current == max - 1);
    }
}
