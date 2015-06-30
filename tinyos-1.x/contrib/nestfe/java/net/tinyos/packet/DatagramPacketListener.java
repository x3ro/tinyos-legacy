// $Id: DatagramPacketListener.java,v 1.5 2005/08/30 02:47:29 shawns Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 */

package net.tinyos.packet;

import java.net.*;
import java.util.Vector;
import java.io.*;


class DatagramConfig {
    static final int maxDatagramLen = 200;
    static final int datagramBufferLen = 10;
}


public class DatagramPacketListener implements Runnable {


    private DatagramSocket socket;
    private VectorQueue packetBuffer;
    private boolean open;


    DatagramPacketListener( int port ) throws IOException {
	open = false;
	try {
	    socket = new DatagramSocket( port );
	    open = true;
	} catch (SocketException e) {
	    throw new IOException("Could not open local socket for listening");
	}
	packetBuffer = new VectorQueue( DatagramConfig.datagramBufferLen );
    }


    public boolean isOpen() {
	return open;
    }


    public void close() {
	if( open ) {
	    socket.close();
	    open = false;
	}
    }


    public void run() {
	byte[] byteBuffer;
	DatagramPacket packet;
        while( open ) {
            try {
		byteBuffer = new byte[ DatagramConfig.maxDatagramLen ];
		packet = new DatagramPacket( byteBuffer , byteBuffer.length );
		//System.out.println("Run: Trying to receive new packet...");
		socket.receive( packet );
		//System.out.println("Run: Received new packet:");
                //for (int i = packet.getOffset() ; i < packet.getOffset() + packet.getLength() ; i++) {
                    //System.out.print((0xFF & byteBuffer[i]) + " "); 
                //    System.out.print( Integer.toHexString((int) (0xFF & byteBuffer[i])) + " "); 
                //}
		//System.out.println("");
		//System.out.println("Run: Adding new packet to packetBuffer...");
		packetBuffer.add( packet );
		//System.out.println("Run: Done adding new packet to packetBuffer");
            } catch (IOException e) {
		open = false;
            }
        }
    }

    
    public DatagramPacket getPacket() throws EOFException {
	if( open ) {
	    //System.out.println("getPacket: Removing new packet from packetBuffer...");
	    DatagramPacket d = (DatagramPacket) packetBuffer.remove();
	    //System.out.println("getPacket: ...Removed new packet from packetBuffer");
	    return d;
	} else {
	    throw new EOFException("IO has been closed");
	}
    }


    public InputStream getInputStream() {
	return new DatagramSocketInputStream( this );
    }
}




class DatagramSocketInputStream extends InputStream {
    // Semantic: if only a partial packet is read by the user of the input stream;
    // then we are flooded with new packets; the partial bytes of the old packet will
    // be protected


    private byte[] byteBuffer;
    private int len;
    private int offset;
    private DatagramPacketListener inListener;
    private boolean listenerOpen;


    DatagramSocketInputStream( DatagramPacketListener inListener ) {
	byteBuffer = new byte[ DatagramConfig.maxDatagramLen ];
	len = 0;
	offset = 0;
	this.inListener = inListener;
	listenerOpen = true;
    }


    // Fill the buffer if needed
    private void updateBuffer() {

	// If buffer is empty, get a new packet
	if( (listenerOpen) && (len == 0) ) {

	    
	    // Get the bytes of the new packet
	    try {
		DatagramPacket packet = inListener.getPacket();
		offset = 0;
		len = packet.getLength();
		int end = packet.getOffset() + len - 1;
		// This is a big fat hack to get BAT code working
		if( (end > 0) && (packet.getData()[end] == 0x7E) && (packet.getData()[end-1] == 0x00) ) { 
		    System.arraycopy( packet.getData() , packet.getOffset() , byteBuffer , 0 , len - 1 );
		    len--;
		    byteBuffer[len-1] = 0x7E;
		} else {
		    System.arraycopy( packet.getData() , packet.getOffset() , byteBuffer , 0 , packet.getLength() );
		}
	    } catch (EOFException e) {
		listenerOpen = false;
	    }
	}
    }


    public int available() {
	//System.out.println("available: attempting to updateBuffer...");
	updateBuffer();
	//System.out.println("available: attempting to updateBuffer...");
	return len;
    }


    public void close() {
	inListener.close();
	listenerOpen = false;
    }


    public int read() {
	//System.out.println("read: attempting to updateBuffer...");
	updateBuffer();
	//System.out.println("read: ... done: attempting to updateBuffer.");
	if( len == 0 ) {
	    return (int) -1;
	} else {
	    //System.out.print( ">>>" ); 
	    //for (int i = offset ; i < offset + len ; i++) {
	    //	System.out.print( (byte) byteBuffer[i] + " " ); 
	    //}
	    //System.out.print( "" ); 
	    int val = 0xFF & (int) byteBuffer[offset];
	    //System.out.print( "read: outputing new int: " + val ); 
	    offset++;
	    len--;
	    return val;
	}
    }

    public boolean markSupported() { return false; }
    public void mark( int readlimit ) {}
    public void reset() {}
}




class VectorQueue {


    private Vector vector;
    private int size;


    VectorQueue( int size ) {
	this.size = size;
	this.vector = new Vector( this.size );
    }


    public synchronized void add( Object obj ) {
	while( vector.size() >= size ) {
	    vector.remove(0);
	}
	vector.add( obj );
	notifyAll();
    }


    // Implements a blocking read/remove action
    public synchronized Object remove() {
	while( vector.size() == 0 ) {
	    try {
		wait();
	    } catch (InterruptedException e) {}
	}
	Object obj = vector.get(0);
	vector.remove(0);
	return obj;
    } 


    public synchronized int size() {
	return vector.size();
    }

}
