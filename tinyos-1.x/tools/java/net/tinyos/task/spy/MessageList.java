package net.tinyos.task.spy;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.text.*;

/* A MessageList is a title + scrollbar + textarea for displaying
   a list of messages */
class MessageList implements AdjustmentListener {
    // GUI elements
    Panel container;
    MyLabel title;
    Scrollbar scroller;
    TextArea output;

    // Messages
    String name;
    Vector messages = new Vector();
    Output lastActive = null;
    int current = -1, max = 0;

    MessageList(String name) {
	this.name = name;

	container = new Panel(new BorderLayout());

	// A title and left, right buttons, and, underneath
	// a text area
	Panel titleArea = new Panel(new GridBagLayout());
	container.add(titleArea, BorderLayout.NORTH);
	output = new TextArea("", 5, 25, TextArea.SCROLLBARS_VERTICAL_ONLY);
	container.add(output);

	// the title and buttons
	title = new MyLabel(name, Color.red);
	GridBagConstraints namec = new GridBagConstraints();
	namec.gridx = 0;
	namec.fill = GridBagConstraints.HORIZONTAL;
	namec.anchor = GridBagConstraints.WEST;
	namec.weightx = 3;
	titleArea.add(title, namec);
	GridBagConstraints scrollc = new GridBagConstraints();
	scrollc.weightx = 1;
	scrollc.gridwidth = GridBagConstraints.REMAINDER;
	scrollc.fill = GridBagConstraints.HORIZONTAL;
	scroller = new MyScrollbar();
	titleArea.add(scroller, scrollc);
	scroller.addAdjustmentListener(this);
    }

    synchronized void activate(Output o, boolean first) {
	if (lastActive != null)
	    lastActive.deactivate();
	lastActive = o;
	o.activate(first);
    }

    synchronized void add(String s) {
	boolean atend = current == max - 1;

	Output o = new Output(this, s);
	messages.addElement(o);
	if (max >= Tool.maxOutput[0])
	    messages.removeElementAt(0);
	else {
	    max++;
	    scroller.setMaximum(max);
	}
	// If we were at end, display new message. Otherwise leave user alone.
	if (atend) {
	    scroller.setValue(max - 1);
	    current = max - 1;
	    activate(o, true);
	}
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
	activate((Output)messages.elementAt(current), current == max - 1);
    }
}


// A horizontal scrollbar w/ increased height
// (work around problem on Zaurus SL6000)
class MyScrollbar extends Scrollbar {
    MyScrollbar() {
	super(Scrollbar.HORIZONTAL, 0, 1, 0, 1);
    }

    public Dimension getPreferredSize() {
	Dimension d = super.getPreferredSize();

	return new Dimension(d.width, d.height + 10);
    }
    
}

class MyLabel extends Component {
    String label;
    Color color;
    final static int XOFFSET = 5;
    final static int YOFFSET = 2;

    public MyLabel(String label, Color color) {
        this.label = label;
	this.color = color;
    }
    
    public Dimension getPreferredSize() {
	Graphics g = getGraphics();

        FontMetrics fm = g.getFontMetrics();
        int width = fm.stringWidth(label);
        int height = fm.getHeight();
        
	return new Dimension(XOFFSET * 2 + width, YOFFSET * 2 + height);
    }
    
    public void paint(Graphics g) {
	super.paint(g);
	g.setColor(color);

        FontMetrics fm = g.getFontMetrics();
        int y = getBounds().height / 2 + fm.getHeight() / 2 - YOFFSET;

	g.drawString(label, XOFFSET, y);
    }
    
    public void update(Graphics g) {
        paint(g);
    }

    void setText(String s) {
	label = s;
	repaint();
    }

    void setColor(Color c) {
	color = c;
	//repaint(); 
    }
}
