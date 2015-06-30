import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

public class inject_code implements PacketListenerIF, Runnable{
    public static final byte MSG_NEW_PROG   = 47;
    public static final byte MSG_START = 48;
    public static final byte MSG_WRITE = 49;
    public static final byte MSG_READ  = 50;
    public static final byte MSG_LENGTH = 38;
    private static final int debug = 1;
    private static final boolean showReceived = true;
    byte flash[];
    int length;
    int acked;
    short prog_id = 1;
    byte group_id =0x13;
    public static final int GENERIC_BASE_ADDR =  0xf7;
    SerialPortReader r;
    private boolean awaitingResponse;
    boolean packets_received[];

    public inject_code() {
	packets_received = new boolean[512];
	for (int i = 0; i < 512; i++) {
	    packets_received[i] = true;
	}
	flash = new byte[8192];
	for (int i=0; i < 8192; i++) {
	    flash[i] = (byte) 0xff;
	}
	acked = 0;
    }

    public void run() {
	try {
	while (acked < length) {
	    r.Read();
	}
	} catch (Exception e) {
	    System.err.println("Something BAD happened when reading responses:"+e);
	    e.printStackTrace();
	}
	System.err.print("e");
    }

    public int htoi(char []line, int index) {
	int ret;
	if (line[index] <= '9') {
	    ret = ((line[index] - '0') << 4) &0xf0;
	} else {
	    ret = ((line[index] - 'A' + 10) << 4) &0xf0;
	}	    
	if (line[index+1] <= '9') {
	    ret += (line[index+1] - '0') & 0x0f;
	} else {
	    ret += (line[index+1] - 'A' + 10) & 0x0f;
	}	    
	return ret;
    }

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
		    //		    System.out.println("Index: "+j+", Data: "+Integer.toHexString(flash[j]&0xff));
		}
	    }
	}
	} catch (Exception e) {
	    //	    System.out.println("EOF?: "+e);
	    length = j;
	}
    }

    public void updatePacketsReceived(byte [] readings) {
	int base = readings[5] & 0xff;
	base += (readings[6] & 0xff)<<8;
	if (base < 8192) 
	    return;
	base -= 8192;
	base *= 8;
	base &= 0x7fff;
	if (debug > 2)
	    System.out.println("Updating range from "+ base+" to " +
			       (base+128));
	if (base == 32256) {
	    int progid = (readings[8] & 0xff) + ((readings[9] & 0xff) << 8);
	    int proglen = (readings[10] & 0xff) + ((readings[11] & 0xff) << 8);
	    System.out.println("Node ID: " + readings[7]);
	    System.out.println("Next Program ID: " + progid);
	    System.out.println("Next Program Length: " + proglen);
	} else {
	
	    for (int i = 0; i < 16; i++) {
		int map = readings[i+ 7] & 0xff; 
		for (int j = 0; j < 8; j++) {
		    packets_received[base + (i*8) + j] &= ((map & 0x01) == 1);
		    map >>= 1;
		    //		    System.out.println("Packet no.: "+(base + (i*8) + j)+" missing: " + packets_received[base + (i*8) + j]);
		}
	    }
	    awaitingResponse = false;
	}
    }

    public synchronized void packetReceived(byte [] readings) {
	if (debug > 0) {
	    System.err.print(".");
	} 
	if (showReceived) {
	    for(int j = 0; j < readings.length; j++)
		System.out.print(Integer.toHexString(readings[j] & 0xff) + " ");
	    System.out.println("\n");
	}
	if (readings[1] == MSG_WRITE) {
	    updatePacketsReceived(readings);
	}
	acked = ((readings[3] &0xff) << 8) + (readings[4] &0xff) +16;
	notify();
    }

    

    short calcrc(byte packet[])
    {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 4;
	crc = 0;
	while (--count >= 0) 
	    {
		crc = (short) (crc ^ ((short) (packet[index++]) << 8));
		i = 8;
		do
		    {
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
	crc = calcrc(packet);
	packet[packet.length-3] = (byte) ((crc>>8) & 0xff);
	packet[packet.length-4] = (byte) (crc & 0xff);
	if (debug > 2) {
	    for(int j = 0; j < packet.length; j++)
		System.out.print(Integer.toHexString(packet[j] & 0xff) + " ");
	    System.out.println("\n");
	}
    }

    public void sendCapsule(byte node, int capsule) throws IOException{
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = node;
	packet[1] = MSG_WRITE;
	packet[2] = group_id;
	packet[4] = (byte) ((prog_id >> 8) & 0xff); 
	packet[3] = (byte) (prog_id & 0xff);        
	packet[6] = (byte) ((capsule >> 8) & 0xff);
	packet[5] = (byte) (capsule & 0xff);          
	System.arraycopy(flash, capsule, packet, 7, 16);
	preparePacket(packet);
	r.Write(packet);
    }

    public void download(byte node) throws IOException  {
	for (int i = 0; i < ((length+15) & 0xfff0); i += 16) {
	    if (debug > 0)
		System.out.print("+");
	    sendCapsule(node, i);
	    try {
		Thread.currentThread().sleep(200);
	    } catch (Exception e) {}
	}
	int capsule = 8192 +64;
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = node;
	packet[1] = MSG_WRITE;
	packet[2] = group_id;
	packet[4] = (byte) ((prog_id >> 8) & 0xff); 
	packet[3] = (byte) (prog_id & 0xff);        
	packet[6] = (byte) ((capsule >> 8) & 0xff);
	packet[5] = (byte) (capsule & 0xff);          
	preparePacket(packet);
	r.Write(packet);
    }

    public void verify(byte node) throws IOException {
	for (int i = 0; i < ((length+15) & 0xfff0); i+= 16) {
	    if (debug > 0)
		System.out.print("+");
	    readCapsule(node, i);
	    try {
		Thread.currentThread().sleep(350);
	    } catch (Exception e) {}
	}
    }
    
    public synchronized void status(byte node) throws IOException {
	for (int i = 0; i < 64; i+=16) {
	    awaitingResponse = true;
	    while (awaitingResponse) {
		if (debug > 0)
		    System.out.print("+");
		readCapsule(node, 8192+i);
		try {
		    wait(150);
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
		sendCapsule(node, i * 16);
		try {
		    Thread.currentThread().sleep(200);
		} catch (InterruptedException e){}
	    }
	}
	int capsule = 8192 +64;
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = node;
	packet[1] = MSG_WRITE;
	packet[2] = group_id;
	packet[4] = (byte) ((prog_id >> 8) & 0xff); 
	packet[3] = (byte) (prog_id & 0xff);        
	packet[6] = (byte) ((capsule >> 8) & 0xff);
	packet[5] = (byte) (capsule & 0xff);          
	preparePacket(packet);
	r.Write(packet);
    }

    public void id(byte node) throws IOException {
	readCapsule(node, 32768 - 64);
	try {
	    Thread.currentThread().sleep(3000);
	} catch (Exception e) {}
    }

    public void startProgram(byte node)  throws IOException{
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = node;
	packet[1] = MSG_START;
	packet[2] = group_id;
	packet[4] = (byte) ((prog_id >> 8) & 0xff); 
	packet[3] = (byte) (prog_id & 0xff);        
	//	packet[6] = (byte) ((i >> 8) & 0xff);
	//	packet[5] = (byte) (i & 0xff);          
	preparePacket(packet);
	r.Write(packet);
    }

    public void newProgram(byte node)  throws IOException{
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = node;
	packet[1] = MSG_NEW_PROG;
	packet[2] = group_id;
	packet[4] = (byte) ((prog_id >> 8) & 0xff); 
	packet[3] = (byte) (prog_id & 0xff);        
	packet[6] = (byte) ((length >> 8) & 0xff);
	packet[5] = (byte) (length & 0xff);          
	preparePacket(packet);
	r.Write(packet);
    }

    public void readCapsule(byte node, int capsule) throws IOException {
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = node;
	packet[1] = MSG_READ;
	packet[2] = group_id;
	packet[4] = (byte) ((prog_id >> 8) & 0xff); 
	packet[3] = (byte) (prog_id & 0xff);        
	packet[6] = (byte) ((capsule >> 8) & 0xff);
	packet[5] = (byte) (capsule & 0xff);          
	packet[8] = (byte) ((GENERIC_BASE_ADDR >> 8) & 0xff);
	packet[7] = (byte) (GENERIC_BASE_ADDR & 0xff);
	preparePacket(packet);
	r.Write(packet);
    }

    public static void main(String[] args) {
	inject_code ic = new inject_code();
	ic.readCode(args[0]);
	if (args.length != 3) {
	    System.out.println("Usage: java inject_code srec_file node_id function");
	    System.out.println("where:\n"+
			       "srec_file = program to be uploaded\n" +
			       "node_id = which node will be affected (broadcast possible)\n"+
	    "function = function to perform; possibilities include\n"+
	    "\tnew -- initialize uploading a new program(erase counters, etc.)\n"+
	    "\tstart -- start reprogramming on a given node\n"+
	    "\twrite -- write capsules to the appropriate nodes\n"+
	    "\tread -- read capsules from the stored nodes\n"+
	    "\tstatus -- find out which capsules have been written\n");
	    System.exit(-1);
	}
	int node = Integer.parseInt(args[1]);

	//SerialForwarderReader r = new SerialForwarderReader("localhost",9000);
	
	SerialPortReader r = new SerialPortReader("COM1");
	ic.r = r;
	try{
	r.Open();
	r.registerPacketListener(ic);
	
	Thread rt = new Thread(ic);
	rt.setDaemon(true);
	rt.start();
	
	if (args[2].equals("new")) {
	    ic.newProgram((byte)node);
	} else if (args[2].equals("start")) {
	    ic.startProgram((byte)node);
	} else if (args[2].equals("write")) {
	    ic.download((byte)node);
	} else if (args[2].equals("read")) {
	    ic.verify((byte)node);
	} else if (args[2].equals("status")) {
	    ic.status((byte) node);
	} else if (args[2].equals("id")) {
	    ic.id((byte) node);
	} else {
	    System.out.println("Unknown command");
	}

	System.out.println("");
	    
	}catch(Exception e){
	    e.printStackTrace();
	}
    }
}
