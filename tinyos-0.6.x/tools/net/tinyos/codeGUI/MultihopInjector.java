/** Queries and injects code into a mote RF network.
 *  Motes are assumed to have MULTIHOP_PROG component installed
 *   FILE: MultihopInjector.java
 * AUTHOR: Sam Madden, based on CodeInjector.java by Robert Szewczyk, Phil Levis
 * Essentially the same as CodeInjector, except:
 *  - attach a sequence number to each message so that motes know what to forward
 *  - packets include an additional header byte.  The lowermost bit (mask 0x01) 
 *    indicates whether the packet is a basestation request or a mote reply (since the 
 *     MSG_WRITE AM is overloaded to be both write requests by the server and packet responses from motes)
 *  - The seven high bits are the mote's "level", used by the motes to determine which packets to forward,
 *     ignorded by this code.
 */

package net.tinyos.codeGUI;

import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

import net.tinyos.util.*;

public class MultihopInjector implements PacketListenerIF, Runnable{
    public static final byte MSG_NEW_PROG   = 47;
    public static final byte MSG_START = 48;
    public static final byte MSG_WRITE = 49;
    public static final byte MSG_READ  = 50;
    public static final byte MSG_RUN = 8;
    public static final int GENERIC_BASE_ADDR = 0xffff;
    public static final int TOS_BROADCAST_ADDR = 0xffff;
    public static final byte MSG_LENGTH = 36;
    public static int nrepeats = 2;
    public int nretries = 1000;
    public static final int MAX_CODE_SIZE  = 8192;
    public static int longDelay = 200;
    public static int shortDelay = 80;
    public static final int MAX_CAPSULES = MAX_CODE_SIZE / 16;
		
    private static final int debug = 1;
    private static final boolean showReceived = true;
    private int awaitingResponse;
    private int reliableRequest;
    private int requestID;

    private MotePanel motePanel;
    private LogPanel logPanel;

  private static int seqno = GetSeqNo();

    
    byte flash[];
    int length;
    short prog_id = 1;
    byte group_id = 0x7d;
    SerialStub serialStub;
    boolean packets_received[];
  
    public MultihopInjector() {
	packets_received = new boolean[MAX_CAPSULES];
	for (int i = 0; i < 512; i++) {
	    packets_received[i] = true;
	}
	flash = new byte[MAX_CODE_SIZE];
	for (int i=0; i < MAX_CODE_SIZE; i++) {
	    flash[i] = (byte) 0xff;
	}
	reliableRequest = 0;
	requestID = -1;
    }
    
    public MultihopInjector(String commPort) {
	this();
	setStub(new SerialPortStub(commPort));
    }

    public MultihopInjector(String host, int port) {
	this();
	setStub(new SerialForwarderStub(host, port));
    }
    
    public MultihopInjector(MotePanel motes, LogPanel log, String commPort) {
	this(commPort);
	motePanel = motes;
	logPanel = log;
    }

    public MultihopInjector(MotePanel motes, LogPanel log, String host, int port) {
	this(host, port);
	motePanel = motes;
	logPanel = log;
    }

    public void run() {
	try {
	    while (true) {
		serialStub.Read();
	    }
	}
	catch (Exception e) {
	    System.err.println("Reading ERROR");
	    System.err.println(e);
	    e.printStackTrace();
	}
	System.err.print("error");
    }

    public void setStub(SerialStub stub) {
	serialStub = stub;
    }

    public SerialStub getStub() {
	return serialStub;
    }
    
    public void setGroupID(byte group) { 
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
		if (line == null) { length = j; break; }
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
	int capsule = readings[7] & 0xff;
	capsule += (readings[8] & 0xff)<<8;
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
	    int progid = (readings[13] & 0xff) + ((readings[14] & 0xff) << 8);
	    int proglen = (readings[15] & 0xff) + ((readings[16] & 0xff) <<
						   8);
	    int moteid = (readings[11] & 0xff) + ((readings[12] & 0xff) << 8);
	    if (motePanel != null) {
		motePanel.addMote(new MoteInfo(moteid, progid, proglen));
	    } else {
		System.out.println("Node ID: " + moteid);
		System.out.println("Next Program ID: " + progid);
		System.out.println("Next Program Length: " + proglen);
	    }
	} else if ((capsule >= MAX_CODE_SIZE) && (capsule <
						  (MAX_CODE_SIZE+64))) {
	    short pid = (short)(((readings[6] & 0xff) << 8) + (readings[5] & 0xff));
	    if ((readings[readings.length-1] == (byte) ((crc>>8) & 0xff)) &&
		(readings[readings.length-2] == (byte) (crc & 0xff)) &&
	        (prog_id == pid)) {
		for (int i = 0; i < 16; i++) {
		    int map = readings[i+ 11] & 0xff; 
		    for (int j = 0; j < 8; j++) {
			packets_received[base + (i*8) + j]  &= ((map & 0x01) == 1);
			map >>= 1;
		    }
		}
	    
		//System.out.println("Awaiting responses: "+awaitingResponse);
		awaitingResponse--;
	    } else {
		if (debug> 0) {
		    System.out.println("CRC check failed, expected CRC"+
				       Integer.toHexString(crc)+" "+
				       Integer.toHexString(pid)+" "+
				       Integer.toHexString(prog_id)+" ");
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
	//readings[4] is the first byte of our data
	//if high bit == 0, that means its a response to our write request
	//otherwise, it's just a mote forwarding on a write request
	if (readings[2] == MSG_WRITE && (readings[4]&0x01) == 0) {
	    updatePacketsReceived(readings);
	}
	notify();
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
    
    synchronized void preparePacket(byte [] packet)  throws IOException{
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

    public void sendCapsule(short node, int capsule) throws IOException{
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[4] = 1;  //this is a request
	packet[6] = (byte) ((prog_id >> 8) & 0xff); 
	packet[5] = (byte) (prog_id & 0xff);        
	packet[8] = (byte) ((capsule >> 8) & 0xff);
	packet[7] = (byte) (capsule & 0xff);
	IncSeqNo();
	packet[9] = (byte) (seqno & 0xff);
	packet[10] = (byte) ((seqno >> 8) & 0xff);
	System.arraycopy(flash, capsule, packet, 11, 16);
	preparePacket(packet);
	serialStub.Write(packet);
    }
    
    public void download(short node) throws IOException  {
	for (int i = 0; i < ((length+15) & 0xfff0); i += 16) {
	    if (debug > 0) {
		System.out.print("+");
		System.out.flush();
		if (i % 1280 == 0) {
		    System.out.println();
		}
	    }
	    if (logPanel != null) {
		if (i % 10 == 0) {logPanel.repaint();}
	    }
	    sendCapsule(node, i);
	    try {
		Thread.currentThread().yield();
		if (((i>>4) & 127) == 1) {
		    System.out.print("!");
		    Thread.currentThread().sleep(longDelay);
		} else {
		    Thread.currentThread().sleep(shortDelay);
		}
		logPanel.repaint();
	    }
	    catch (Exception e) {}
	    
	}
	int capsule = MAX_CODE_SIZE +64;
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[4] = 1; //this is a request
	packet[6] = (byte) ((prog_id >> 8) & 0xff); 
	packet[5] = (byte) (prog_id & 0xff);        
	packet[8] = (byte) ((capsule >> 8) & 0xff);
	packet[7] = (byte) (capsule & 0xff);          
	IncSeqNo();
	packet[9] = (byte) (seqno & 0xff);
	packet[10] = (byte) ((seqno >> 8) & 0xff);

	preparePacket(packet);
	serialStub.Write(packet);
    }

    public void verify(short node) throws IOException {
	for (int i = 0; i < ((length+15) & 0xfff0); i+= 16) {
	    if (debug > 0) {
		System.out.print("+");
	    }
	    if (logPanel != null) {
		if (i % 10 == 0) {logPanel.repaint();}
	    }
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

    //dummy packet forces log records to eeprom
    void writeDummyPacket(short node) {
	int capsule = MAX_CODE_SIZE + 64;
	byte [] packet = new byte[MSG_LENGTH];
	
	try {
	    packet[0] = (byte) (node & 0xff);
	    packet[1] = (byte) ((node >> 8) & 0xff);
	    packet[2] = MSG_WRITE;
	    packet[3] = group_id;
	    packet[4] = 1; //this is a request
	    packet[6] = (byte) ((prog_id >> 8) & 0xff); 
	    packet[5] = (byte) (prog_id & 0xff);        
	    packet[8] = (byte) ((capsule >> 8) & 0xff);
	    packet[7] = (byte) (capsule & 0xff);      
	    IncSeqNo();
	    packet[9] = (byte) (seqno & 0xff);
	    packet[10] = (byte) ((seqno >> 8) & 0xff);
    
	    preparePacket(packet);
	    serialStub.Write(packet);

	    try {
		Thread.currentThread().sleep(500);
	    } catch (Exception e) {}

	    capsule = MAX_CODE_SIZE + 2048;

	    packet[0] = (byte) (node & 0xff);
	    packet[1] = (byte) ((node >> 8) & 0xff);
	    packet[2] = MSG_WRITE;
	    packet[3] = group_id;
	    packet[4] = 1; //this is a request
	    packet[6] = (byte) ((prog_id >> 8) & 0xff); 
	    packet[5] = (byte) (prog_id & 0xff);        
	    packet[8] = (byte) ((capsule >> 8) & 0xff);
	    packet[7] = (byte) (capsule & 0xff);      
	    IncSeqNo();
	    packet[9] = (byte) (seqno & 0xff);
	    packet[10] = (byte) ((seqno >> 8) & 0xff);
    
	    preparePacket(packet);
	    serialStub.Write(packet);
	} catch (IOException e) {
	    e.printStackTrace();
	}

    }
    
    public synchronized void check(short node) throws IOException {
	for (int i = 0; i < 64; i+=16) {
	    awaitingResponse = 1;
	    while (awaitingResponse > 0) {
		if (debug > 0)
		    System.out.print("+");
		readCapsule(node, MAX_CODE_SIZE+i);
		try {
		    wait(100);
		} catch (InterruptedException e) {
		    System.err.println("Interrupted wait:"+e);
		    e.printStackTrace();
		}
	    }
	}
		
	if (debug >0) 
	    System.out.print("\nMissing packets:");
	for (int i =0; i < ((length+15)>>4); i++) {
	    if (!packets_received[i]) {
		if (debug >0)
		    System.out.print(i+" ");
		if (logPanel != null) {
		    if (i % 10 == 0) {logPanel.repaint();}
		}
		sendCapsule(node, i * 16);
		try {
		    Thread.currentThread().sleep(500);
		} catch (Exception e){}
	    }
	}
	
	writeDummyPacket(node);
    }


    public synchronized void multicheck(int nnodes) throws IOException {
	boolean redo = false;
	int n;
	for (int i = 0; i < 64; i+=16) {
	    awaitingResponse = nnodes;
	    n = 0;
	    while ((awaitingResponse > 0) && (n < nretries)) {
		if (debug > 0)
		    System.out.print("+");
		n++;
		readCapsule((short)-1, MAX_CODE_SIZE+i, 0);
		try {
		    wait(400);
		} catch (InterruptedException e) {
		    System.err.println("Interrupted wait:"+e);
		    e.printStackTrace();
		}
	    }
	}
		
	if (debug >0) 
	    System.out.print("\nMissing packets:");
	
	for (int q= 0; q < nrepeats; q++) {
	for (int i =0; i < ((length+15)>>4); i++) {
	    if (!packets_received[i]) {
		if (debug >0)
		    System.out.print(i+" ");
		if (logPanel != null) {
		    if (i % 10 == 0) {logPanel.repaint();}
		}
		redo = true;
		sendCapsule((short)-1, i * 16);
		try {
		    Thread.currentThread().sleep(200);
		} catch (Exception e){}
	    }
	}}
		
	writeDummyPacket((short)-1);

	if (redo) {
	    for (int i = 0; i < 512; i++) {
		packets_received[i] = true;
	    }
	    multicheck(nnodes);
	}
    }
	
    public void id(short node) throws IOException {
	readCapsule(node, 32768 - 64);
	if (logPanel == null){
	    try {
		Thread.currentThread().sleep(3000);
	    } catch (Exception e) {}}
    }

    public void setId(short node, short newID) {
	byte [] packet = new byte[MSG_LENGTH];
	int capsule = 32768 - 64;
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[4] = 1; //this is a request
	packet[6] = (byte) ((prog_id >> 8) & 0xff); 
	packet[5] = (byte) (prog_id & 0xff);        
	packet[8] = (byte) ((capsule >> 8) & 0xff);
	packet[7] = (byte) (capsule & 0xff);     
	IncSeqNo();
	packet[9] = (byte) (seqno & 0xff);
	packet[10] = (byte) ((seqno >> 8) & 0xff);
     
	packet[12] = (byte) ((newID >> 8) & 0xff);
	packet[11] = (byte)(newID & 0xff);
	packet[14] = (byte) ((prog_id >> 8) & 0xff); 
	packet[13] = (byte) (prog_id & 0xff);        
	packet[16] = (byte) ((length >> 8) & 0xff); 
	packet[15] = (byte) (length & 0xff);        
	try {
	    preparePacket(packet);
	    serialStub.Write(packet); 
	} catch (Exception e ) {
	    System.err.println("Something bad happened in setID"+e);
	    e.printStackTrace();
	}
    }

    public void startProgram(short node)  throws IOException{
	byte [] packet = new byte[MSG_LENGTH];


	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_START;
	packet[3] = group_id;
	IncSeqNo();
	packet[4] = (byte) (seqno & 0xff);
	packet[5] = (byte) ((seqno >> 8) & 0xff);
	packet[7] = (byte) ((prog_id >> 8) & 0xff); 
	packet[6] = (byte) (prog_id & 0xff);        
	//	packet[6] = (byte) ((i >> 8) & 0xff);
	//	packet[5] = (byte) (i & 0xff);          
	preparePacket(packet);
	serialStub.Write(packet);
    }

    public void fillBitmap(short node) throws IOException{
	byte bitmap[] = new byte[64]; 
	for (int i = 0; i < 64; i++) {
	    bitmap[i] = (byte)0xff;
	}
	for (int i =0; i < ((length+15)>>4); i++) {
	    bitmap[(i >> 3) & 63] &= (byte)(~(1 << (i & 0x7)));
	}
	for (int i = 0; i < 64; i++) {
	    System.out.print(Integer.toHexString(bitmap[i] & 0xff) + " "); 
	}
	System.out.println();
	for (int i = 0; i < 4; i++) {
	    byte [] packet = new byte[MSG_LENGTH];
	    int capsule = 8192 + (i * 16);
	    packet[0] = (byte) (node & 0xff);
	    packet[1] = (byte) ((node >> 8) & 0xff);
	    packet[2] = MSG_WRITE;
	    packet[3] = group_id;
	    packet[4] = 1; //this is a request
	    packet[6] = (byte) ((prog_id >> 8) & 0xff); 
	    packet[5] = (byte) (prog_id & 0xff);        
	    packet[8] = (byte) ((capsule >> 8) & 0xff);
	    packet[7] = (byte) (capsule & 0xff);  
	    IncSeqNo();
	    packet[9] = (byte) (seqno & 0xff);
	    packet[10] = (byte) ((seqno >> 8) & 0xff);
        
	    System.arraycopy(bitmap, i*16, packet, 11, 16);
	    int any = 0;
	    for (int j = 0; j < 16; j++) {
		any |= packet[7+j];
	    }
	    if (any != 0) {
		if (debug > 0)
		    System.out.print("+");
		preparePacket(packet);
		serialStub.Write(packet);
		try {
		    Thread.currentThread().sleep(300);
		} catch (Exception e) {}
	    } else {
		if (debug > 0)
		    System.out.print("?");
	    }
	}
    }

    
    public void newProgram(short node)  throws IOException{
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_NEW_PROG;
	packet[3] = group_id;
	IncSeqNo();
	packet[4] = (byte) (seqno & 0xff);
	packet[5] = (byte) ((seqno >> 8) & 0xff);

	packet[7] = (byte) ((prog_id >> 8) & 0xff); 
	packet[6] = (byte) (prog_id & 0xff);        
	packet[9] = (byte) ((length >> 8) & 0xff);
	packet[8] = (byte) (length & 0xff);          
	preparePacket(packet);
	serialStub.Write(packet);
	fillBitmap(node);
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
    public void readCapsule(short node, int capsule) throws IOException {
	readCapsule(node, capsule, 0);
    }

    public void readCapsule(short node, int capsule, int check) throws IOException {
	
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_READ;
	packet[3] = group_id;
	packet[4] = 1; //this is a request
	packet[6] = (byte) ((prog_id >> 8) & 0xff); 
	packet[5] = (byte) (prog_id & 0xff);        
	packet[8] = (byte) ((capsule >> 8) & 0xff);
	packet[7] = (byte) (capsule & 0xff);          
	packet[10] = (byte) ((GENERIC_BASE_ADDR >> 8) & 0xff);
	packet[9] = (byte) (GENERIC_BASE_ADDR & 0xff);
	packet[11] = (byte) check;
	IncSeqNo();
	packet[12] = (byte) (seqno & 0xff);
	packet[13] = (byte) ((seqno >> 8) & 0xff);

	preparePacket(packet);

	serialStub.Write(packet);
    }

    public static void usage() {
	System.out.println("Usage: java codeGUI.MultihopInjector command args\n");
	System.out.println("where command is one of the following:\n"+
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
	
    public static void main(String[] args) {

	MultihopInjector ic;
	SerialStub r;
	try{
	    try {
		ic = new MultihopInjector("localhost", 9000); 
		r = ic.getStub();
		r.Open();
		r.registerPacketListener(ic);
	    } catch(IOException e) {
		ic = new MultihopInjector("COM1");
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
    }


    /* Sequence number is attached to each packet so that motes know whether they've
       already forwarded a packet or not.
       
       This is pretty seriously ugly as it involves a flush to disk on each call to IncSeqNo.

    */
  static int GetSeqNo() {
    String s;
    try {
      File f = new File("seqno");
      BufferedReader r= new BufferedReader(new InputStreamReader(new FileInputStream(f)));
      s = r.readLine();
      r.close();

    } catch (IOException e ) {
      e.printStackTrace();
      return -1;
    }
    try {
      return Integer.valueOf(s).intValue();
    } catch (NumberFormatException e) {
      e.printStackTrace();
      return -1;
    }
  }

  static int IncSeqNo() {
    int newseqno = ++seqno;
    if (newseqno > 32700) newseqno = 0;
    try {
      File f = new File("seqno");
      BufferedWriter w = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(f)));
      w.write(new Integer(newseqno).toString());
      w.write("\n");
      w.flush();
      w.close();
    } catch (IOException e) {
      e.printStackTrace();
      return -1;
    }
    seqno = newseqno;  //hope this is atomic
    return seqno;
  }
}
