/*
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
 * File: ServerReceivingThread.java
 *
 * Description:
 * The ServerReceivingThread listens for requests
 * from a connected Aggregator Server.  If a data
 * packet is received, it is sent on to the serial
 * port.
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 *
 */

package net.tinyos.sf;

import java.net.*;
import java.io.*;
import java.util.*;

public class ClientServicer extends Thread {
    // communications with client
    private static final boolean DEBUG = true;
    private Socket              m_socket        = null;
    private int                 m_nTimeout      = 5000;
    private InputStream         input           = null;
    public OutputStream        output          = null;
    // listen server to which thread is registered
    private ListenServer        lstnSrvr      = null;
    // shutdown flag
    private boolean             bShutdown     = false;
    private boolean             bFirstTime    = true;
    private String hostname, ipaddr;

    private static Vector              vctServicers  = new Vector();

    private ClientServicer ( Socket socket )
    {
        m_socket = socket;
        InetAddress addr = m_socket.getInetAddress();
	hostname = addr.getHostName();
	ipaddr = addr.getHostAddress();
        SerialForward.DEBUG ( "ServerReceivingThread created to service host " + hostname);

    }

    public String toString() {
      return "Client "+hostname+" ("+ipaddr+")";
    }

    private void InitConnection ( )
    {
        try
        {
          output = m_socket.getOutputStream();
          input = m_socket.getInputStream();
          SerialPortIO.RegisterPacketForwarder( this );
        }
        catch (Exception e )
        {
          e.printStackTrace();
          bShutdown = true;
          return;
        }
        return;
    }

    public void run()
    {
        SerialForward.VERBOSE("client connected from "+hostname+" ("+ipaddr+")");
        //open socket inputstream
        InitConnection ();
        //read packets from stream
        ReadPackets ();
        //close socket
        Shutdown ();
        // thread about to die, remove from listen server receiving threads vector
        SerialForward.VERBOSE("client disconnected from "+hostname+" ("+ipaddr+")");
        SerialForward.DEBUG ( "ClientServicer: terminating host = " +hostname);
    }

    private synchronized void ReadPackets ( )
    {
        int nBytesRead = 0;
        int nBytesReturned = 0;
        byte[] currentPacket = new byte[SerialForward.PACKET_SIZE];

        try {
            nBytesReturned = input.read ( currentPacket, nBytesRead,
                                          SerialForward.PACKET_SIZE - nBytesRead );

            while ( nBytesReturned != -1 && (!bShutdown || bFirstTime) )
            {
                bFirstTime = false;
                nBytesRead += nBytesReturned;
                if ( nBytesRead == SerialForward.PACKET_SIZE )
                {
                  // send packet to serial port
                  nBytesRead = 0;
                  HandlePacket ( currentPacket );
                }
                nBytesReturned = input.read ( currentPacket, nBytesRead,
                                              SerialForward.PACKET_SIZE - nBytesRead );
            }
        }
        catch (IOException e)
        {
            SerialForward.DEBUG ( "ClientServicer: connection was closed to host " + hostname);
        }
    }

    private void HandlePacket (byte[] currentPckt)
    {
        SerialForward.DEBUG ( "Packet received from " + hostname);
        SerialForward.IncrementPacketsWritten();
        SerialPortIO.WriteBytes ( currentPckt );
    }

    public void Shutdown ( )
    {
        if ( !bShutdown ) {
            //unregister output stream
            bShutdown = true;
            SerialPortIO.UnregisterPacketForwarder ( this );
            vctServicers.remove ( this );
            SerialForward.DecrementClients ();
            try{ m_socket.close(); }
            catch ( IOException e ) { e.printStackTrace(); }
            this.interrupt();
        }
    }

    public static ClientServicer AddClientServicer (Socket clntSocket)
    {
        ClientServicer newServicer = new ClientServicer ( clntSocket );
        vctServicers.add ( newServicer );
        newServicer.start();
        return newServicer;
    }

    public static void ShutdownAllClientServicers ( )
    {
        SerialForward.VERBOSE( "CLIENTSERVICER: Shutting down all client connections" );
        ClientServicer crrntServicer;
        while ( vctServicers.size() != 0 )
        {
            crrntServicer = (ClientServicer) vctServicers.firstElement();
            crrntServicer.Shutdown();
            try {  crrntServicer.join(1000); }
            catch (InterruptedException e) { e.printStackTrace(); };
        }
    }
}
