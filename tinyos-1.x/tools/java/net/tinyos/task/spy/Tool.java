package net.tinyos.task.spy;

import java.awt.*;
import java.io.*;
import java.awt.event.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Tool implements WindowListener, ActionListener, Messenger {
    final static int SCHEMA_ERROR = 1;

    static int[] moteTimeout = { 10000 };
    static int[] maxOutput = { 100 };

    Frame f;
    MessageList routing, tinydb;
    TextArea motesElement;

    MoteIF moteIF;

    MoteList motes;
    Settings settings;

    public Tool() {
	routing = new MessageList("Routing");
	tinydb = new MessageList("TinyDB");
	buildWindow();
	moteIF = new MoteIF(BuildSource.makePhoenix(this));
	motes = new MoteList(this);

	registerMhopListener(new QueryResult(), new ResultPrint());
	QueryResult otherResultId = new QueryResult();
	otherResultId.amTypeSet(107);
	registerMhopListener(otherResultId, new ResultPrint2());
	registerMhopListener(new RoutePacket(), new RoutePrint());
	moteIF.registerListener(new QueryRequestMessage(), new RequestPrint());
	moteIF.registerListener(new QueryMessage(), new QueryPrint());
	//moteIF.registerListener(new CommandMsg(), new CommandPrint());
    }

    void registerMhopListener(final Message template, final MhopListener l) {
	MultihopMsg mtemplate = new MultihopMsg();
	mtemplate.amTypeSet(template.amType());
	moteIF.registerListener
	    (mtemplate, new MessageListener() {
		    public void messageReceived(int to, Message m) {
			MultihopMsg mm = (MultihopMsg)m;
			int dataLength = mm.dataLength() - mm.offset_data(0);

			Message data = template.clone(dataLength);
			data.dataSet(mm.dataGet(), mm.offset_data(0), 0,
				     dataLength);
			l.messageReceived(to, mm, data);
		    } });
    }

    String mhopPrint(String kind, int to, MultihopMsg header) {
	String sto = to == 65535 ? "B" : "" + to;

	return kind + ": " + " to " + sto +
	    " org " + header.get_originaddr() +
	    " from " + header.get_sourceaddr() +
	    "\nseq " + header.get_seqno() +
	    " hop " + header.get_hopcount() + "\n";
    }

    static String printMask(int nf, long mask) {
	String msg = "";
	for (int i = 0; i < nf; i++)
	    if ((mask & 1 << i) != 0)
		msg += "1";
	    else
		msg += "0";
	return msg;
    }

    class ResultPrint implements MhopListener {
	public void messageReceived(int to, MultihopMsg header, Message m) {
	    QueryResult qr = (QueryResult)m;

	    String msg = mhopPrint("RES", to, header) +
		"qid " + qr.get_qid() +
		", epoch " + qr.get_epoch();
	    if (qr.get_qrType() == 2) { // non-aggregate
		msg += ", mask " +
		    printMask(qr.get_d_t_numFields(),qr.get_d_t_notNull());
	    }
	    tinydb.add(msg);
	    motes.alive(header.get_sourceaddr());
	}
    }

    class ResultPrint2 implements MhopListener {
	public void messageReceived(int to, MultihopMsg header, Message m) {
	    QueryResult qr = (QueryResult)m;

	    String msg = mhopPrint("RES2", to, header) +
		"qid " + qr.get_qid() +
		", epoch " + qr.get_epoch();
	    if (qr.get_qrType() == 2) { // non-aggregate
		msg += ", mask " +
		    printMask(qr.get_d_t_numFields(),qr.get_d_t_notNull());
	    }
	    tinydb.add(msg);
	    motes.alive(header.get_sourceaddr());
	}
    }

    class RoutePrint implements MhopListener {
	public void messageReceived(int to, MultihopMsg header, Message m) {
	    RoutePacket rp = (RoutePacket)m;

	    String msg = "ROUTE: " + header.get_originaddr() + 
		", seq " + header.get_seqno() +
		"\np " + rp.get_parent() +
		", cost " + rp.get_cost();
		int nf = rp.get_estEntries();
		for (int i = 0; i < nf; i++)
		    msg += ", (id:" + rp.getElement_estList_id(i) +
			", q:" + rp.getElement_estList_receiveEst(i) + ")";
	    routing.add(msg);
	    motes.alive(header.get_sourceaddr());
	}
    }

    class RequestPrint implements MessageListener {
	public void messageReceived(int to, Message m) {
	    QueryRequestMessage qr = (QueryRequestMessage)m;

	    String msg = "QREQ: " + qr.get_reqNode() +
		"  asks " + qr.get_fromNode() +
		" for qid  " + qr.get_qid() +
		"\nmask " + printMask(qr.sizeBits_qmsgMask(),
				      qr.get_qmsgMask());
	    tinydb.add(msg);
	    motes.alive(qr.get_fromNode());
	}
    }

    class QueryPrint implements MessageListener {
	public void messageReceived(int to, Message m) {
	    QueryMessage q = (QueryMessage)m;

	    String msg = "QUERY: " + q.get_fwdNode() +
		" sends qid  " + q.get_qid() +
		"\n" + msgType(q.get_msgType()) +
		", nF " + q.get_numFields() +
		", dur " + q.get_epochDuration() +
		", " + qmsgType(q.get_type()) +
		" (" + q.get_idx() + ")";
	    tinydb.add(msg);
	    motes.alive(q.get_fwdNode());
	}
    }

    static String msgType(int type) {
	switch (type) {
	case 0: return "ADD";
	case 1: return "DEL";
	case 2: return "MOD";
	case 3: return "RATE";
	case 4: return "DROP";
	}
	return "ERR";
    }

    static String qmsgType(int type) {
	switch (type) {
	case 0: return "FIELD";
	case 1: return "EXPR";
	case 2: return "BUF";
	case 3: return "EVENT";
	case 4: return "EPOCH";
	case 5: return "DROP";
	}
	return "ERR";
    }

    // Default size (chosen for a Zaurus SL-5500)
    int width = 235;
    int height = 258;

    public void start() {
	f.pack();
	f.setSize(width, height);
	f.show();
    }

    void buildWindow() {
	try {
	    // abort out if pre 1.3
	    Class.forName("java.awt.GraphicsEnvironment");

	    /* Resize up to a 480x640 screen */
	    GraphicsDevice gd = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice();
	    GraphicsConfiguration gc = gd.getDefaultConfiguration();
	    Rectangle s = gc.getBounds();

	    width = s.width;
	    height = s.height;

	    if (width > 480)
		width = 480;
	    if (height > 640)
		height = 640;
	}
	catch (Exception e) { }

	f = new Frame("TASK Spy");
	f.addWindowListener(this);

	// There's a top half and a bottom half...
	f.setLayout(new GridLayout(2, 1));
	Panel top = new Panel(new BorderLayout());
	f.add(top);
	f.add(tinydb.container);

	// Top is a routing output pane a list of motes
	top.add(routing.container);
	motesElement = new TextArea("", 6, 4, TextArea.SCROLLBARS_VERTICAL_ONLY);
	top.add(motesElement, BorderLayout.EAST);

	MenuBar mb = new MenuBar();
	f.setMenuBar(mb);
	Menu file = new Menu("File");
	mb.add(file);
	MenuItem settingsItem = new MenuItem("Settings");
	file.add(settingsItem);
	settingsItem.addActionListener(this);

	settings = new Settings(f, 2);
	settings.add("Mote Timeout", moteTimeout, 1000, 600000);
	settings.add("Max Output", maxOutput, 10, 1000);
	settings.finishDialog();
    }

    public void actionPerformed(ActionEvent e) {
	// settings menu item
	settings.show();
    }

    public void windowClosing(WindowEvent e) {
	// System.exit is sometimes *very* slow.
	// -> Commit suicide the hard way.
	/* Disabled. Made Qtopia desktop unhappy.
	  try {
	    String[] cmd = { "bash", "-c", "kill -3 $PPID" };
	    Runtime.getRuntime().exec(cmd);
	}
	catch (IOException ee) { }*/
	    
	System.exit(0);
    }

    public void windowClosed(WindowEvent e) { }
    public void windowActivated(WindowEvent e) { }
    public void windowIconified(WindowEvent e) { }
    public void windowDeactivated(WindowEvent e) { }
    public void windowDeiconified(WindowEvent e) { }
    public void windowOpened(WindowEvent e) { }

    public void message(String s) {
	new MessageBox(f, "Warning", s);
    }

    public static void main(String[] args) {
	Tool t = new Tool();
	t.start();
    }
}
