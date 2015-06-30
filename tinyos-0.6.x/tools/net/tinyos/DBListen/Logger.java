/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
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
 * $Id: Logger.java,v 1.3 2002/06/06 16:37:03 ammbot Exp $
 */

package net.tinyos.DBListen;

import java.util.*;
import java.net.*;
import java.io.*;


public class Logger extends Thread {

    // optional gui
    private ClientWindow        clntWndw    = null;
    // received packet from server
    private byte[]              packet        = new byte[InitLogger.PACKET_SIZE];
    // flag to kill client
    private boolean             bShutdown      = false;
    // packet stream from socket
    private InputStream         packetStream   = null;
    private FileOutputStream    fileStream     = null;
    // communications socket
    private Socket              commSocket     = null;
    // packet counter
    private int                 nPackets       = 0;
    private DBLogger	      dbLogger	= null;

    public Logger ( ClientWindow window ) {
	clntWndw = window;
	if ( clntWndw != null ) { clntWndw.UpdatePacketsReceived ( nPackets ); }
    }

    public void run () {
	boolean bStatus;

	// open the log file
	bStatus = OpenLogFile ( );
	if ( !bStatus ) {
	    VERBOSE ( "Unable to write log to file: " + InitLogger.strFileName );
	    PreExit ();
	    return;
	} else {
	    VERBOSE ( "Successfully opened log file: " + InitLogger.strFileName );
	}

	// connect to the serial port forwarding server
	bStatus = Connect ( );
	if ( !bStatus ) {
	    VERBOSE ( "Unable to connect to host: " + InitLogger.server );
	    PreExit ();
	    return;
	} else {
	    VERBOSE ( "Successfully connect to host: " + InitLogger.server );
	}

	dbLogger = new DBLogger();

	// Log incoming packets
	GetIncomingPackets ( );

	PreExit ();
	return;
    }

    private boolean OpenLogFile ( ) {
	try { fileStream = new FileOutputStream ( InitLogger.strFileName ); }
	catch ( FileNotFoundException e )
	    {
		if ( InitLogger.debugMode ) { e.printStackTrace(); }
		return false;
	    }
	return true;
    }

    private void CloseLogFile ( ) {
	try { fileStream.close(); }
	catch ( IOException e ) {
	    if ( InitLogger.debugMode ) { e.printStackTrace(); }
	}
    }

    private boolean Connect ( ) {
	try
	    {
		DEBUG ( "LOGGER: Connecting to host: " + InitLogger.server + " port: " + InitLogger.serverPort );
		commSocket = new Socket ( InitLogger.server, InitLogger.serverPort);
		packetStream = commSocket.getInputStream();
	    } catch ( Exception e )
		{
		    if ( InitLogger.debugMode ) { e.printStackTrace(); }
		    return false;
		}
	return true;
    }

    private synchronized void GetIncomingPackets ( ) {
	int nBytesRead = 0;
	int nBytesReturned = 0;

	try { nBytesReturned = packetStream.read ( packet, nBytesRead, InitLogger.PACKET_SIZE - nBytesRead ); }
	catch ( IOException e ) {
	    VERBOSE ( "Socket closed" );
	    bShutdown = true;
	}

	while ( !bShutdown && (nBytesReturned != -1) )
	{
	    nBytesRead += nBytesReturned;
	    if ( nBytesRead == InitLogger.PACKET_SIZE )
	    {
		PacketReceived ( );
		nBytesRead = 0;
//		if ( clntWndw != null )
//		    clntWndw.AddMessage( toHex ( packet ) + "\n" );
		try { fileStream.write ( packet ); }
		catch ( IOException e ) {
		    VERBOSE ( "Unable to write to file: " + InitLogger.strFileName );
		    break;
		}
	    }
	    try { nBytesReturned = packetStream.read ( packet, nBytesRead, InitLogger.PACKET_SIZE - nBytesRead ); }
	    catch ( IOException e ) {
		VERBOSE ( "Socket closed" );
		bShutdown = true;
	    }
	    dbLogger.logPacket(packet);
	}
	try {
	    packetStream.close();
	    commSocket.close();
	}
	catch ( IOException e ) {
	    if ( InitLogger.debugMode ) {
		e.printStackTrace();
	    }
	}
    }

    private void PacketReceived () {
	nPackets++;
	if ( clntWndw != null ) clntWndw.UpdatePacketsReceived ( nPackets );

    }

    public void Shutdown () {
	bShutdown = true;
	try { commSocket.close(); }
	catch ( IOException e ) {
	    if ( InitLogger.debugMode ) { e.printStackTrace( ); }
	}
	interrupt();
    }

    private void ReportMessage ( String msg ) {
	if ( clntWndw == null ) System.out.println (msg);
	else clntWndw.AddMessage (msg+"\n");
    }

    private void DEBUG ( String msg ) {
	if ( InitLogger.debugMode ) { ReportMessage ( msg ); }
    }

    private void VERBOSE ( String msg ) {
	if ( InitLogger.verboseMode ) { ReportMessage ( msg ); }
    }

    private void PreExit ( ) {
	if ( clntWndw != null )
	{
	    clntWndw.SetClient ( null );
	}
	CloseLogFile ( );
	dbLogger.close();
	ReportMessage ( "Logger shutting down" );
    }
    // from jean-baptiste.nizet@s1.com
    public static String toHex(byte[] b) {
	if (b == null) {
	    return null;
	}
	String hits = "0123456789ABCDEF";
	StringBuffer sb = new StringBuffer();

	for (int i = 0; i < b.length; i++) {
	    int j = ((int) b[i]) & 0xFF;

	    char first = hits.charAt(j / 16);
	    char second = hits.charAt(j % 16);

	    sb.append(first);
	    sb.append(second);
	    sb.append(" ");
	}

	return sb.toString();
    }
}
