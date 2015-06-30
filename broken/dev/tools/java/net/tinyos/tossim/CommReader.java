/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:		Phil Levis
 * Date:        Aug 6 2001
 * Desc:        Class that maintains sockets and reads in comm data.
 *
 * This class controls the spawning of threads for reading in data from the
 * different sources the simulator provides. It also allows for a
 * coarse-grained pause on the simulation at the radio packet level. This
 * pausing is obtained by the communication model; after a packet is sent
 * over the socket to this GUI, the simulator issues a blocking read for
 * the single byte reply. Through use of synchonization primitives this
 * reply can be withheld while the GUI is paused, causing the simulator to
 * pause as well.
 */

package net.tinyos.tossim;

import java.io.*;
import java.net.*;


public class CommReader {
    public static short RADIO_PORT = 10584;
    public static short RADIO_BIT_PORT = 10578;
    public static short UART_PORT = 22576;
    public static short PACKET_LEN = 52;
    
    private short inputPort;
    private RadioThread radioThread;
    
    public CommReader(int inputPort) {
	this.inputPort = (short)inputPort;
    }

    public RadioThread startRadioSocket(PacketListener listener) throws IOException {
	radioThread = new RadioThread(listener,inputPort);
	radioThread.start();
	return radioThread;
    }

    public void startRadioBitSocket(BitListener listener) throws IOException {
	return;
    }

    public void startUARTSocket(UARTListener listener) throws IOException {
	return;
    }


    protected class RadioThread extends Thread {
	private PacketListener listener;
	private Socket socket;
	private int inputPort;

	public RadioThread(PacketListener listener, int inputPort) throws IOException {
	    this.listener = listener;
	    setDaemon(true);
	    setPriority(Thread.MIN_PRIORITY);
	    this.inputPort = inputPort;
	}
	
	public void run() {

	    if (inputPort != -1) {
		System.out.println("Connecting to port " + inputPort);
		try {
		    socket = new Socket("127.0.0.1", inputPort);
		}
		catch (Exception e) {
		    System.out.println("Connection to port " + inputPort + " failed");
		    System.err.println(e);
		    e.printStackTrace();
		    return;
		}
	    }
	    
	    else {
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
	    }
	    try {
		InputStream input = socket.getInputStream();
		OutputStream output = socket.getOutputStream();
		
		while(true) {
		    byte[] data = new byte[CommReader.PACKET_LEN];
		    byte ack = 0x00;
		    int len = 0;
		    //Read in an entire packet
		    while (len < CommReader.PACKET_LEN) {
			int readLen = input.read(data, len, CommReader.PACKET_LEN - len);
			if (readLen < 0) {
			    return;
			}
			else {
			    len += readLen;
			}
		    }
		    listener.receivePacket(data);
		    synchronized(listener) {
			if (listener.isPaused()) {
			    listener.wait();
			}
		    }
		    output.write((int)ack);
		}
	    }
	    catch (Exception exception) {
		System.err.println("Exception thrown by RadioReader thread. Thread ending.");
		System.err.println(exception);
		exception.printStackTrace();
	    }
	    return;
	}
    }
    
}









