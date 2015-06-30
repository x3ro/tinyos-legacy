// $Id: NetworkUdpByteSource.java,v 1.3 2005/09/22 03:56:21 kaminw Exp $

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

import java.util.*;
import java.io.*;
import java.net.*;

/**
 * A udp byte-source
 */
public class NetworkUdpByteSource extends StreamByteSource {


    private DatagramPacketListener inListener;
    private String remoteHost;
    private int remotePort;
    private int localPort;


    public NetworkUdpByteSource( int localPort , String remoteHost, int remotePort ) {
	this.remoteHost = remoteHost;
	this.remotePort = remotePort;
	this.localPort = localPort;
    }


    protected void openStreams() throws IOException {
	try {
	    os = new DatagramSocketOutputStream( remoteHost , remotePort );
	    inListener = new DatagramPacketListener( localPort );
	    new Thread( inListener ).start(); //FIXME: how do we stop/interrupt a thread?
	    is = inListener.getInputStream();
	} catch (SocketException e) {
	    throw new IOException("Could not open in/out sockets");
	}
    }


    protected void closeStreams() throws IOException {
        inListener.close();
        os.close();
    }

}
