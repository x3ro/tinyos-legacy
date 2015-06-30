// $Id: ClientServicer.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
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

package net.tinyos.sf.old;

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
    private SerialForward sf;
    private ListenServer listenServer;

    public ClientServicer ( Socket socket, SerialForward serialForward, ListenServer listenSvr )
    {
        sf=serialForward;
        listenServer=listenSvr;
        m_socket = socket;
        InetAddress addr = m_socket.getInetAddress();
	hostname = addr.getHostName();
	ipaddr = addr.getHostAddress();
        sf.DEBUG ( "ServerReceivingThread created to service host " + hostname);

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
          if(sf.serialPortIO!=null){
	      sf.serialPortIO.RegisterPacketForwarder( this );
	  }
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
        sf.VERBOSE("client connected from "+hostname+" ("+ipaddr+")");
        //open socket inputstream
        InitConnection ();
        //read packets from stream
        ReadPackets ();
        //close socket
        Shutdown ();
        // thread about to die, remove from listen server receiving threads vector
        sf.VERBOSE("client disconnected from "+hostname+" ("+ipaddr+")");
        sf.DEBUG ( "ClientServicer: terminating host = " +hostname);
    }

    private synchronized void ReadPackets ( )
    {
        int nBytesRead = 0;
        int nBytesReturned = 0;
        byte[] currentPacket = new byte[sf.PACKET_SIZE];

        try {
            nBytesReturned = input.read ( currentPacket, nBytesRead,
                                          sf.PACKET_SIZE - nBytesRead );

            while ( nBytesReturned != -1 && (!bShutdown || bFirstTime) )
            {
                bFirstTime = false;
                nBytesRead += nBytesReturned;
                if ( nBytesRead == sf.PACKET_SIZE )
                {
                  // send packet to serial port
                  nBytesRead = 0;
                  HandlePacket ( currentPacket );
                }
                nBytesReturned = input.read ( currentPacket, nBytesRead,
                                              sf.PACKET_SIZE - nBytesRead );
            }
        }
        catch (IOException e)
        {
            sf.DEBUG ( "ClientServicer: connection was closed to host " + hostname);
        }
    }

    private void HandlePacket (byte[] currentPckt)
    {
        sf.DEBUG ( "Packet received from " + hostname);
        sf.IncrementPacketsWritten();
        sf.serialPortIO.WriteBytes ( currentPckt );
    }

    public void Shutdown ( )
    {
        if ( !bShutdown ) {
            //unregister output stream
            bShutdown = true;
            if(sf.serialPortIO!=null)
                sf.serialPortIO.UnregisterPacketForwarder ( this );
            listenServer.RemoveClientServicer( this );
            sf.DecrementClients ();
            try{ m_socket.close(); }
            catch ( IOException e ) { e.printStackTrace(); }
            this.interrupt();
        }
    }


}
