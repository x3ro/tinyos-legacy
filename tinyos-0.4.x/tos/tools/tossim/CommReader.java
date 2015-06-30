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

package tossim;

import java.io.*;
import java.net.*;


public class CommReader {
    public static final short RADIO_PORT = 10577;
    public static final short RADIO_BIT_PORT = 10578;
    public static final short UART_PORT = 22576;
    public static final short PACKET_LEN = 48;
    
    private RadioThread radioThread;
    
    public CommReader() {
	
    }

    public void startRadioSocket(PacketListener listener) throws IOException {
	radioThread = new RadioThread(listener);
	radioThread.start();
    }

    public void startRadioBitSocket(BitListener listener) throws IOException {
	return;
    }

    public void startUARTSocket(UARTListener listener) throws IOException {
	return;
    }


    protected class RadioThread extends Thread {
	private PacketListener listener;
	private ServerSocket socket;

	public RadioThread(PacketListener listener) throws IOException {
	    this.listener = listener;
	    setDaemon(true);
	    setPriority(Thread.MIN_PRIORITY);
	}
	
	public void run() {
	    try {
		socket = new ServerSocket(CommReader.RADIO_PORT);
		Socket client = socket.accept();
		InputStream input = client.getInputStream();
		OutputStream output = client.getOutputStream();
		
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
