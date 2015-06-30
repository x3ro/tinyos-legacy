package net.tinyos.moteview.PacketAnalyzers;

/* @(#)CodeInjector.java
 *
 * "Copyright (c) 2001 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * $\Id$
 */

/**
 *  Queries and injects code into a local mote RF network.
 *
 * @author <a href="mailto:szewczyk@sourceforge.net">Robert Szewczyk</a>
 * @author <a href="mailto:scipio@sourceforge.net">Phil Levis</a>
 */

import net.tinyos.moteview.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.util.*;
import net.tinyos.moteview.Dialog.*;
import net.tinyos.moteview.Packet.*;
import net.tinyos.moteview.PacketSenders.*;

import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

public class CodeInjector implements Runnable
{
    public static final byte MSG_NEW_PROG   = 47;
    public static final byte MSG_START = 48;
    public static final byte MSG_WRITE = 49;
    public static final byte MSG_READ  = 50;
    public static final byte MSG_RUN = 8;
    public static final int GENERIC_BASE_ADDR = 0xfff7;
    public static final int TOS_BROADCAST_ADDR = 0xffff;
    public static final byte MSG_LENGTH = 36;
    public static int nrepeats = 4;
    public int nretries = 1000;
    public static final int MAX_CODE_SIZE  = 16384;
    public static int longDelay = 200;
    public static int shortDelay = 80;
    public static final int MAX_CAPSULES = MAX_CODE_SIZE / 16;

    protected static final int debug = 1;
    protected static final boolean showReceived = true;
    protected int awaitingResponse;
    protected int reliableRequest;
    protected int requestID;

    //private MotePanel motePanel;
    //private LogPanel logPanel;

    byte flash[];
    int length;
    int acked;
    short prog_id = 1;
    byte group_id = 0x7d;
    //SerialStub serialStub;
    boolean packets_received[];

    public CodeInjector() {
	packets_received = new boolean[MAX_CAPSULES];
    }


    /*
    public CodeInjector(String commPort) {
	this();
	//setStub(new SerialPortStub(commPort));
    }

    public CodeInjector(String host, int port) {
	this();
	//setStub(new SerialForwarderStub(host, port));
    }
    */


    /*
    public CodeInjector(MotePanel motes, LogPanel log, String commPort) {
	this(commPort);
	motePanel = motes;
	logPanel = log;
    }

    public CodeInjector(MotePanel motes, LogPanel log, String host, int port) {
	this(host, port);
	motePanel = motes;
	logPanel = log;
    }
    */

    public void run ( )
    {

    }




    /*
    public void setStub(SerialStub stub) {
	serialStub = stub;
    }

    public SerialStub getStub() {
	return serialStub;
    }
    */	 void setGroupID(byte group) {
	group_id = group;
    }

    public byte getGroupID() {
	return group_id;
    }

    public int htoi(char []line, int index) {
	String val = "" + line[index] + line[index + 1];
	return Integer.parseInt(val, 16);
    }

    /** Read and store code from <TT>name</TT> file for later use. */
    public void readCode(String name) {
	int j = 0;
	try {
	    DataInputStream dis = new DataInputStream (new FileInputStream(name));
	    String line;

	    while (true) {
		line = dis.readLine();
		char [] bline = line.toUpperCase().toCharArray();
		if (bline[1] == '1') {
		    int n = htoi(bline, 2)-3;
		    int start = (htoi(bline, 4) << 8) + htoi(bline, 6);
		    int s;
		    for (j = start, s = 8; n > 0; n--, j++, s+=2) {
			flash[j] = (byte) htoi(bline, s);
			//System.out.println("Index: "+j+", Data: "+Integer.toHaexString(flash[j]&0xff));
		    }
		}
	    }
	}
	catch (Exception e) {
	    //	    System.out.println("EOF?: "+e);
	    length = j;
	}
	prog_id = calculateCRC(flash);
	System.out.println("Program ID:" + Integer.toHexString(prog_id).toUpperCase());
    }



    /** Called when received update packets. */

    public void updatePacketsReceived(byte [] readings) {
	int capsule = readings[6] & 0xff;
	capsule += (readings[7] & 0xff)<<8;
	int base = capsule;
	base -= MAX_CODE_SIZE;
	base *= 8;
	base &= 0x7fff;
	readings[1] = (byte) ((GENERIC_BASE_ADDR >> 8) & 0xff);
	readings[0] = (byte) (GENERIC_BASE_ADDR & 0xff);
	short crc = calculateCRC(readings);

	//if (debug > 2)
	//System.out.println("Updating range from "+ base+" to " +
	//	       (base+128));
	//	System.out.println("Base: "+base);
	if (requestID == capsule) {
	    requestID = -1;
	    reliableRequest--;
	} else if (capsule == 0x7FC0) {
	    int progid = (readings[10] & 0xff) + ((readings[11] & 0xff) << 8);
	    int proglen = (readings[12] & 0xff) + ((readings[13] & 0xff) <<
						   8);
	    int moteid = (readings[8] & 0xff) + ((readings[9] & 0xff) << 8);
	    // if (motePanel != null) {
	    //	motePanel.addMote(new MoteInfo(moteid, progid, proglen));
	    //} else {
		System.out.println("Node ID: " + moteid);
		System.out.println("Next Program ID: " + progid);
		System.out.println("Next Program Length: " + proglen);
		//}
	} else if ((capsule >= MAX_CODE_SIZE) && (capsule <
						  (MAX_CODE_SIZE+(MAX_CAPSULES/8)))) {
	    short pid = (short)(((readings[5] & 0xff) << 8) + (readings[4] & 0xff));
	    if ((readings[readings.length-1] == (byte) ((crc>>8) & 0xff)) &&
		(readings[readings.length-2] == (byte) (crc & 0xff)) &&
	        (prog_id == pid)) {
		for (int i = 0; i < 16; i++) {
		    int map = readings[i+ 8] & 0xff;
		    for (int j = 0; j < 8; j++) {
			packets_received[base + (i*8) + j]  &= ((map & 0x01) == 1);
			map >>= 1;
		    }
		}

		//System.out.println("Awaiting responses: "+awaitingResponse);
		awaitingResponse--;
	    } else {
		if (debug> 0) {
		    System.out.println("CRC check failed, expected CRC "+
				       Integer.toHexString(crc&0xffff)+" "+
				       Integer.toHexString(pid&0xffff)+" "+
				       Integer.toHexString(prog_id&0xffff)+" ");
		}
	    }
	}
    }


    /** Processes a received packet. */
    public synchronized void packetReceived(byte [] readings) {
	if (debug > 0) {
	    System.err.print(".");
	}
	if (showReceived) {
	    for(int j = 0; j < readings.length; j++)
		System.out.print(Integer.toHexString(readings[j] & 0xff) + " ");
	    System.out.println("\n");
	}

    }




    private short calculateCRC(byte packet[]) {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 2;
	crc = 0;
	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}
	return (crc);
    }

    synchronized void preparePacket(byte [] packet)  {
	short crc;
	crc = calculateCRC(packet);
	packet[packet.length-1] = (byte) ((crc>>8) & 0xff);
	packet[packet.length-2] = (byte) (crc & 0xff);
	if (debug > 2) {
	    for(int j = 0; j < packet.length; j++)
		System.out.print(Integer.toHexString(packet[j] & 0xff) + " ");
	    System.out.println("\n");
	}
    }



    public void verify(short node) throws IOException {
	for (int i = 0; i < ((length+15) & 0xfff0); i+= 16) {
	    if (debug > 0) {
		System.out.print("+");
	    }
	    //if (logPanel != null) {
	    //	if (i % 10 == 0) {logPanel.repaint();}
	    //}
	    readCapsule(node, i);
	    try {
		//	Thread.currentThread().sleep(350);
	    } catch (Exception e) {}
	}
    }

    public synchronized void reliableDownload(short node, int start, int end)
     throws IOException {
	for (int i = start; i < end; i+= 16) {
	    reliableRequest = 1;
	    requestID = (i - 64) & 0x7ff0;
	    while (reliableRequest > 0) {
		try {
		    //		    Thread.currentThread().sleep(100);
		    if (debug > 0)
			System.out.print("+");
		    //		    System.out.println("Reading: " + ( 1024*16-64+i));
		    readCapsule(node, ((i - 64) & 0x7ff0));
		    wait(350);
		} catch (InterruptedException e) {
		    System.err.println("Interrupted wait:"+e);
		    e.printStackTrace();
		}
	    }
	    if ((i & 63) == 48) {
		try {
		    Thread.currentThread().sleep(500);
		} catch (Exception e) {}
	    }

	}
    }


    public void id(short node) throws IOException {
	readCapsule(node, 32768 - 64);
	//if (logPanel == null){
	    try {
		Thread.currentThread().sleep(3000);
	    } catch (Exception e) {}
	    //}
    }


    public void setId(short node, short newID) {
	byte [] packet = new byte[MSG_LENGTH];
	int capsule = 32768 - 64;
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((capsule >> 8) & 0xff);
	packet[6] = (byte) (capsule & 0xff);

	packet[9] = (byte) ((newID >> 8) & 0xff);
	packet[8] = (byte)(newID & 0xff);
	packet[11] = (byte) ((prog_id >> 8) & 0xff);
	packet[10] = (byte) (prog_id & 0xff);
	packet[13] = (byte) ((length >> 8) & 0xff);
	packet[12] = (byte) (length & 0xff);
	try {
	    preparePacket(packet);
	    IPPortPacketSender.sendPackettoAll ( packet );
	} catch (Exception e ) {
	    System.err.println("Something bad happened in setID"+e);
	    e.printStackTrace();
	}
    }

    public void runOption(byte groupID,
			  short moteID,
			  short src,
			  byte type,
			  short prob,
			  byte pot) {

	byte [] packet = new byte[MSG_LENGTH];
	int capsule = 32768 - 64;

	packet[0] = (byte) (moteID & 0xff);        //mote ID
	packet[1] = (byte) ((moteID & 0xff00) >> 8); //mote ID
	packet[2] = MSG_RUN;                                   //AM type
	packet[3] = group_id;                                  //group ID
	packet[4] = (byte) (src & 0xff);                       //src
	packet[5] = (byte) ((src >> 8) & 0xff);                //src
	packet[6] = 1;                                         //hop-count
	packet[7] = 55;                                        //exp_id
	packet[8] = (byte) (prob & 0xff);                      //prob
	packet[9] = (byte) ((prob >> 8) & 0xff);               //prob
	packet[10] = pot;                                      //pot
	packet[11] = type;                                     //comm

	try {
	    preparePacket(packet);
	    for(int i=0;i<14;i++){
		String datum = Integer.toString((int)(packet[i] & 0xff), 16);
		if (datum.length() == 1) {datum = "0" + datum;}
		datum += " ";
		System.out.print(datum);
	    }
	    //serialStub.Write(packet);
            IPPortPacketSender.sendPackettoAll ( packet );
	} catch (Exception e ) {
	    System.err.println("Something bad happened in setID"+e);
	    e.printStackTrace();
	}
    }

    public void startProgram(short node) {
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_START;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	//	packet[6] = (byte) ((i >> 8) & 0xff);
	//	packet[5] = (byte) (i & 0xff);
	preparePacket(packet);
        IPPortPacketSender.sendPackettoAll ( packet );
	//serialStub.Write(packet);
    }



    public void turnOn(short node) throws IOException {
	System.out.println("Turning on " + node);
	runOption(group_id, node, (short)0, (byte)1, (short)100, (byte)10);

    }

    public void turnOff(short node) throws IOException {
	System.out.println("Turning off " + node);
	runOption(group_id, node, (short)0, (byte)2, (short)100, (byte)10);
    }

    public void turnAllOn() throws IOException {
	System.out.println("Turning all motes in group " + getGroupID() + " on.");
	runOption(group_id, (short)0xffff, (short)0, (byte)1, (short)100, (byte)10);
    }

    public void turnAllOff() throws IOException {
	System.out.println("Turning all motes in group " + getGroupID() + " off.");
	runOption(group_id, (short)0xffff, (short)0, (byte)2, (short)100, (byte)10);
    }

    public void newProgram(short node)  {
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_NEW_PROG;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((length >> 8) & 0xff);
	packet[6] = (byte) (length & 0xff);
	preparePacket(packet);
	//serialStub.Write(packet);
	IPPortPacketSender.sendPackettoAll ( packet );
	fillBitmap(node);
    }

    protected void fillBitmap ( short node )
    {
        System.out.println ("newProgram not impelmented");
    }

    private void printPacket(byte[] packet) {
	System.out.print("Packet:");
	for (int i = 0; i < packet.length; i++) {
	    if (i % 16 == 0) {System.out.println();}
	    String val = Integer.toHexString((int)(packet[i] & 0xff));
	    for (int j = 0; j < (3 - val.length()); j++) {
		System.out.print(" ");
	    }

	    System.out.print(val);
	}
	System.out.println();
    }
    public void readCapsule(short node, int capsule) {
	readCapsule(node, capsule, 0);
    }

    public void readCapsule(short node, int capsule, int check) {

	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_READ;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((capsule >> 8) & 0xff);
	packet[6] = (byte) (capsule & 0xff);
	packet[9] = (byte) ((GENERIC_BASE_ADDR >> 8) & 0xff);
	packet[8] = (byte) (GENERIC_BASE_ADDR & 0xff);
	packet[10] = (byte) check;
	preparePacket(packet);
	IPPortPacketSender.sendPackettoAll ( packet );
	//serialStub.Write(packet);
    }

    public static void usage() {
	System.out.println("Usage: java codeGUI.CodeInjector command args\n");
	System.out.println("where command is one of the following:\n"+
			   "\trun <group-id> <src> <command-type> <probability of forwarding> <pot> \n" +
			   "\tnew srec dest-- initialize uploading a new program(erase counters, etc.). \n"+
			   "\tstart srec dest -- start reprogramming on a given node\n"+
			   "\twrite srec dest -- write capsules to the appropriate nodes\n"+
			   "\tread srec dest -- read capsules from the stored nodes\n"+
			   "\tcheck srec dest -- resend unreceived packets\n"+
			   "\tid [dest] -- find an id of a node. "+
			   "dest defaults to broadcast\n" +
			   "\tsetid [oldid] newid -- set ID of a mote (requires power cycling). oldid defaults to broadcast\n"+
			   "\tmultiprog srec nnodes -- reliably download code to nnodes.\n"+
			   "srec file in the above usage refers to the program"+
" to download. It is best specified with absolute paths.\n");
	    System.exit(-1);
	}
    /*
    public static void main(String[] args) {

	CodeInjector ic;
	//SerialStub r;
	try{
	    try {
		ic = new CodeInjector("localhost", 9000);
		r = ic.getStub();
		r.Open();
		r.registerPacketListener(ic);
	    } catch(IOException e) {
		ic = new CodeInjector("COM1");
		r = ic.getStub();
		r.Open();
		r.registerPacketListener(ic);
	    }

	    Thread rt = new Thread(ic);
	    rt.setDaemon(true);
	    rt.start();
	    if (args.length == 0) {
		usage();
	    }
	    if (args[0].equals("help")) {
		usage();
	    } else if (args[0].equals("new")) {
		if (args.length != 3)
		    usage();
		ic.readCode(args[1]);
		int node = Integer.parseInt(args[2]);
		ic.newProgram((short)node);
	    } else if (args[0].equals("start")) {
		if (args.length != 3)
		    usage();
		ic.readCode(args[1]);
		int node = Integer.parseInt(args[2]);
		ic.startProgram((short)node);
	    } else if (args[0].equals("write")) {
		if (args.length < 3)
		    usage();
		else if (args.length > 3){
		    shortDelay = Integer.parseInt(args[3]);
		    longDelay = Integer.parseInt(args[4]);
		}
		ic.readCode(args[1]);
		int node = Integer.parseInt(args[2]);

		ic.download((short)node);
	    } else if (args[0].equals("read")) {
		if (args.length != 3)
		    usage();
		ic.readCode(args[1]);
		int node = Integer.parseInt(args[2]);
		ic.verify((short)node);
	    } else if (args[0].equals("check")) {
		if (args.length != 3)
		    usage();
		ic.readCode(args[1]);
		int node = Integer.parseInt(args[2]);
		ic.check((short) node);
	    } else if (args[0].equals("id")) {
		int node = -1;
		if (args.length > 2 )
		    usage();
		if (args.length > 1)
		    node = Integer.parseInt(args[1]);
		ic.id((short) node);
	    } else if (args[0].equals("run")) {
		short src, prob;
		byte type, pot, groupID;

		if (args.length != 6)
		    usage();
		groupID = Byte.parseByte(args[1]);
		src = Short.parseShort(args[2]);
		type = Byte.parseByte(args[3]);
		prob = Short.parseShort(args[4]);
		pot = Byte.parseByte(args[5]);
		ic.runOption(groupID,(short)0xffff, src,type,prob,pot);
	    } else if (args[0].equals("setid")) {
		int node = -1;
		int nid = -1;
		if (args.length == 3) {
		    node = Integer.parseInt(args[1]);
		    nid = Integer.parseInt(args[2]);
		} else if (args.length == 2) {
		    nid = Integer.parseInt(args[1]);
		} else {
		    usage();
		}
		for (int i = 0; i < 3; i++) {
		    ic.newProgram((short) node);
		    try {
			Thread.currentThread().sleep(500);
		    } catch (Exception e) {}
		}
		for (int i = 0; i < 3; i++) {
		    ic.setId((short) node, (short) nid);
		    try {
			Thread.currentThread().sleep(500);
		    } catch (Exception e) {}
		}
	    } else if (args[0].equals("multiprog")) {
		if (args.length < 3)
		    usage();
		if (args.length > 3)
		    ic.nrepeats = Integer.parseInt(args[3]);
		if (args.length > 4)
		    ic.nretries = Integer.parseInt(args[4]);
		ic.readCode(args[1]);
		int nnodes = Integer.parseInt(args[2]);
		for (int i = 0; i < nrepeats; i++) {
		    ic.newProgram((short)-1);
		    try {
			Thread.currentThread().sleep(200);
		    } catch (Exception e) {}
		}
		for (int i = 0; i < nrepeats; i++) {
		    ic.download((short) -1);
		}
		ic.multicheck(nnodes);
	    }else if (args[0].equals("multicheck")) {
		if (args.length < 3)
		    usage();
		if (args.length > 3)
		    ic.nrepeats = Integer.parseInt(args[3]);
		if (args.length > 4)
		    ic.nretries = Integer.parseInt(args[4]);
		System.out.println("Will resend "+ic.nrepeats+" times, wait for" +
				   " response "+ic.nretries+" packets");
		ic.readCode(args[1]);
		int nnodes = Integer.parseInt(args[2]);
		ic.multicheck(nnodes);
	    } else if (args[0].equals("download") ){
		ic.reliableDownload((short)Integer.parseInt(args[1]),
				 Integer.parseInt(args[2]),
				 Integer.parseInt(args[3]));
	    } else {
		System.out.println("Unknown command");
		usage();
	    }

	    System.out.println("");

	}
	catch(Exception e){
	    e.printStackTrace();
	}
	}*/


}

