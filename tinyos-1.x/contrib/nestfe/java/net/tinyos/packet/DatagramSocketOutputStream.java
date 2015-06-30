// $Id: DatagramSocketOutputStream.java,v 1.2 2005/08/23 19:14:43 shawns Exp $

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

import java.io.*;
import java.net.*;

public class DatagramSocketOutputStream extends OutputStream {


    private DatagramSocket socket;
    private InetAddress remoteAddress;
    private int remotePort;
    private boolean open;


    DatagramSocketOutputStream ( String remoteHost , int remotePort ) throws IOException {
	this.remotePort = remotePort;
	try {
	    remoteAddress = InetAddress.getByName( remoteHost );
	} catch (UnknownHostException e) {
	    throw new IOException("Could not resolve the remote host address");
	}
	try {
	    socket = new DatagramSocket();
	} catch (SocketException e) {
	    throw new IOException("Could not open a socket");
	}
	open = true;
    }


    public void close() {
	if( open ) {
	    socket.close();
	    open = false;
	}
    }


    public void flush() {}
    

    public void write ( byte[] b ) throws IOException {
	write( b , 0 , b.length );
    }


    public void write ( byte[] b , int off , int len ) throws IOException {
	byte[] buf = new byte[len];
	System.arraycopy( b , off , buf , 0 , len );
	DatagramPacket datagramPacket = new DatagramPacket( buf , len , remoteAddress , remotePort );
	socket.send( datagramPacket );
    }


    public void write ( int b ) throws IOException {
	byte[] buf = new byte[1];
	buf[0] = (byte) b;
	write( buf , 0 , 1 );
    }

}
