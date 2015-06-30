/**
 * File: ListenServer.java
 *
 * Description:
 * The Listen Server is the heart of the serial forwarder.  Upon
 * instantiation, this class spawns the SerialPortReader and the
 * Multicast threads.  As clients connect, this class spawns
 * ServerReceivingThreads as wells as registers the new connection
 * SerialPortReader.  This class also provides the central
 * point of contact for the GUI, allowing the server to easily
 * be shut down
 *
 * Author: Bret Hull
 */

import java.net.*;
import java.io.*;
import javax.comm.*;
import java.util.*;

public class ListenServer extends Thread {

    private static final String CLASS_NAME    = "Listen Server";
    private int                 m_nPort         = 0;
    private boolean             m_bShutdown     = false;
    private ServerSocket        m_serverSocket  = null;

    public ListenServer ( )
    {
        m_nPort       = SerialForward.serverPort;
    }

    public void run ()
    {
        boolean status;

        // open up our server socket
        try { m_serverSocket = new ServerSocket( m_nPort ); }
        catch (IOException e)
        {
            SerialForward.VERBOSE ( "Could not listen on port: " + m_nPort );
            if ( SerialForward.cntrlWndw != null )
            {
                SerialForward.cntrlWndw.ClearListenServer ( );
            }
            return;
        }
        SerialForward.VERBOSE ( "Listening for connections on port " + m_nPort );
        if ( SerialForward.bSourceSim )
        {
            SerialPortIO.InitSerialPortIO();
        }
        // start listening for connections
        try {
            ClientServicer rcv;
            Socket currentSocket;
            while (!m_bShutdown)
            {
                currentSocket = m_serverSocket.accept();
                ClientServicer.AddClientServicer ( currentSocket );
            }
            m_serverSocket.close();
        }
        catch ( IOException e) {
          SerialForward.VERBOSE ("Server Socket closed");
        }
        finally
        {
            ClientServicer.ShutdownAllClientServicers();
            SerialPortIO.Shutdown();
            if ( SerialForward.cntrlWndw != null )
            {
                SerialForward.cntrlWndw.ClearListenServer ( );
            }
        }
        SerialForward.VERBOSE("--------------------------");
    }

    public void Shutdown ( )
    {
        m_bShutdown = true;
        try { m_serverSocket.close(); }
        catch ( IOException e ) { e.printStackTrace(); }
        this.interrupt();
    }
}