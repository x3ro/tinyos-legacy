/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Dennis Chi
 * Date:        October 16 2002
 * Desc:        
 *
 */

package net.tinyos.gui;

import java.awt.*;
import java.io.*;
import java.util.*;
import java.lang.*;
import java.net.*;
import javax.swing.*;

import net.tinyos.gui.event.*;

/**
 * This class creates the thread to read data from the packet and passes the packets to the
 * SimEventBus for transmission to all registered GUI plugins.
 */

public class SimComm {
    public static short PACKET_LEN = 46;

    //private ButtonPanel buttons;
    //private MotePanel motes;
    //private CommReader reader;
    private Thread packetThread = null; 
    //private PacketPanel packets;
    private static int portToUsePacketReading = -1;
    private boolean paused;
    public Socket socket;
    
    public SimEventBus eventBus;

    public SimComm(SimEventBus eventBus) {
	//motes = new MotePanel();
	paused = false;	
	this.eventBus = eventBus;
    }
    
    public void start() {
	try {
	    packetThread = new PacketThread(this);
	    packetThread.start();
	}
	catch (Exception exception) {
	    System.err.println(exception);
	    System.exit(-1);
	}
    }
    
    public void receivePacket(byte[] packet) {
	if (packet.length != SimComm.PACKET_LEN) {
	    System.err.println("Received packet of unexpected length. Expected length: " + SimComm.PACKET_LEN + ", received length: " + packet.length);
	    return;
	}

	try {
	    RFMPacket rfm = new RFMPacket(packet);
	    eventBus.push (new SimPacketReceivedEvent(rfm));
	}
	catch (IOException exception) {
	    System.err.println("Exception thrown when adding packet.");
	    exception.printStackTrace();
	}
    }
    
    protected class PacketThread extends Thread {
	SimComm comm;
	
	boolean pause;

	public PacketThread(SimComm comm) throws IOException {
	    this.comm = comm;
	    setDaemon(true);
	    setPriority(Thread.MIN_PRIORITY);
	    pause = false;
	}
	
	public void pauseThread() {
	    pause = true;

	}

	public void resumeThread() {
	    pause = false;
	}

	public void run() {
	    System.out.println("Connecting to port 10577");
	    try {
		socket = new Socket("127.0.0.1", 10577);
	    }
	    catch (Exception e) {
		System.out.println("Connection to port 10577 failed");
		
	    }
	    
	    if (socket == null) {
		System.out.println("Connecting to port 10584");
		try {
		    socket = new Socket("127.0.0.1", 10584);
		}
		catch (Exception e) {
		    System.out.println("Connection to port 10584 failed");
		    System.err.println(e);
		    e.printStackTrace();
		    return;
		}
	    }
	    
	    try {
		InputStream input = socket.getInputStream();
		OutputStream output = socket.getOutputStream();
		
		while(true) {
		    byte[] data = new byte[SimComm.PACKET_LEN];
		    byte ack = 0x00;
		    int len = 0;
		    //Read in an entire packet
		    //System.err.println ("before while");
		    while (len < SimComm.PACKET_LEN) {
			//System.err.println ("trying to read");
			int readLen = input.read(data, len, SimComm.PACKET_LEN - len);
			//System.err.println ("readLen is: " + readLen);
			if (readLen < 0) {
			    //  System.err.println ("returning");
			    return;
			}
			else {
			    len += readLen;
			}
			//System.err.println ("len is: " + len + "  needs to be: " + CommReader.PACKET_LEN);
		    }
		    //		    System.err.println ("after while");
		    comm.receivePacket(data);
		    
		    while (pause) {
			//this.sleep(500);
		    }
		    this.sleep(500);
		    output.write((int)ack);
		}
	    }
	    catch (Exception exception) {
		System.err.println("Exception thrown by SimComm.PacketThread. Thread ending.");
		System.err.println(exception);
		exception.printStackTrace();
	    }
	    return;
	}
    }
}
