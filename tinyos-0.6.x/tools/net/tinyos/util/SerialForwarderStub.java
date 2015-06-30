/* @(#)SerialForwarderStub.java
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
 * 
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Brett Hull</a>
 */

package net.tinyos.util;

import java.io.*;
import java.net.*;

public class SerialForwarderStub implements SerialStub
{
    private String            host          = null;
    private int               port          = 0;
    private Socket            commSocket    = null;
    private InputStream       packetIStream  = null;
    private OutputStream       packetOStream  = null;
    private PacketListenerIF  listener      = null;
    public final static int   PACKET_SIZE   = 36;

    public SerialForwarderStub ( String host, int port )
    {
	this.host = host;
	this.port = port ;
    }

    public void registerPacketListener ( PacketListenerIF listener )
    {
	this.listener = listener;
    }

    public void Close ( ) throws IOException
    {
	packetOStream.flush();
	commSocket.close();


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

    public void Open ( ) throws IOException
    {
	// connect to server
	commSocket = new Socket(host, port);
	packetIStream = commSocket.getInputStream();
	packetOStream = commSocket.getOutputStream();
    }

    public void Read ( ) throws IOException
    {
	byte[] packet = new byte[PACKET_SIZE];
	int nBytesRead = 0;
	int nBytesReturned = packetIStream.read ( packet, nBytesRead,
						  PACKET_SIZE - nBytesRead );

	while ( nBytesReturned != -1 )
	    {
		nBytesRead += nBytesReturned;
		if ( nBytesRead == PACKET_SIZE )
		    {
			nBytesRead = 0;
			if(listener != null){
			    listener.packetReceived ( packet );
			}
		    }
		nBytesReturned = packetIStream.read ( packet, nBytesRead,
						      PACKET_SIZE - nBytesRead );
	    }
    }
  
    public void Write(byte[] pack) throws IOException {
	short crc = calculateCRC(pack);
	pack[pack.length-1] = (byte) ((crc >> 8) & 0xff);
	pack[pack.length-2] = (byte) (crc & 0xff);
	packetOStream.write(pack);	
    }

}
