/**
 * File: ServerReceivingThread.java
 *
 * Description:
 * The ServerReceivingThread listens for requests
 * from a connected Aggregator Server.  If a data
 * packet is received, it is sent on to the serial
 * port.
 *
 * Author: Bret Hull
 */

import java.net.*;
import java.io.*;
import java.util.*;

public class ClientServicer extends Thread
{
    // communications with client
    private Socket              m_socket        = null;
    private int                 m_nTimeout      = 5000;
    private InputStream         input           = null;
    private OutputStream        output          = null;
    // host name
    private String              m_strHstNm      = null;
    // listen server to which thread is registered
    private ListenServer        lstnSrvr      = null;
    // shutdown flag
    private boolean             bShutdown     = false;

    private static Vector              vctServicers  = new Vector();

    private ClientServicer ( Socket socket )
    {
        m_socket = socket;
        m_strHstNm = socket.getInetAddress().toString();
        SerialForward.DEBUG ( "ServerReceivingThread created to service host " + m_strHstNm );
        vctServicers.add ( this );
    }

    private void InitConnection ( )
    {
        try
        {
          output = m_socket.getOutputStream();
          input = m_socket.getInputStream();
          SerialPortIO.RegisterPacketForwarder( output );
        }
        catch (IOException e )
        {
          e.printStackTrace();
          bShutdown = true;
          return;
        }
        return;
    }

    public void run()
    {
        //open socket inputstream
        InitConnection ( );
        //read packets from stream
        ReadPackets ( );
        //close socket
        Shutdown ();
        // thread about to die, remove from listen server receiving threads vector
        SerialForward.DEBUG ( "ClientServicer: terminating; host = " + m_strHstNm );
    }

    private synchronized void ReadPackets ( )
    {
        int nBytesRead = 0;
        int nBytesReturned = 0;
        byte[] currentPacket = new byte[SerialForward.PACKET_SIZE];

        try {
            nBytesReturned = input.read ( currentPacket, nBytesRead,
                                          SerialForward.PACKET_SIZE - nBytesRead );

            while ( nBytesReturned != -1 && !bShutdown )
            {
                nBytesRead += nBytesReturned;
                if ( nBytesRead == SerialForward.PACKET_SIZE )
                {
                    SerialForward.DEBUG ( "Packet received from " + m_strHstNm );
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
            SerialForward.DEBUG ( "ClientServicer: connection was closed to host " + m_strHstNm );
        }
    }

    private void HandlePacket (byte[] currentPckt)
    {
        SerialForward.DEBUG ( "Packet received from " + m_strHstNm );
        SerialPortIO.WriteBytes ( currentPckt );
    }

    private void RemovePacketForwarder ( )
    {
        //remove the old data stream
        SerialPortIO.UnregisterPacketForwarder ( output );
    }

    public void Shutdown ( )
    {
        bShutdown = true;
        RemovePacketForwarder ();
        vctServicers.remove ( this );
        SerialForward.DecrementClients ();
        try{ m_socket.close(); }
        catch ( IOException e ) { e.printStackTrace(); }
        this.interrupt();
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
        while ( !vctServicers.isEmpty() )
        {
            crrntServicer = (ClientServicer) vctServicers.firstElement();
            crrntServicer.Shutdown();
            try {  crrntServicer.join(); }
            catch (InterruptedException e) { e.printStackTrace(); };
        }
    }
}