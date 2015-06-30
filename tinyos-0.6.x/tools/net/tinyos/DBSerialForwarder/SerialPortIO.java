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
 * $Id: SerialPortIO.java,v 1.2 2002/06/06 01:17:05 ammbot Exp $
 */

/**
 * File: SerialPortIO.java
 *
 * Description:
 * The SerialPortIO handles the collection of packets
 * from a mote connected to the serial port.  The Constructor
 * takes in an already open input stream from which to read
 * data.
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 */

package net.tinyos.DBSerialForwarder;

import java.util.*;
import java.io.*;
import javax.comm.*;
import java.net.*;

public class SerialPortIO extends Thread
{
    private static final String   CLASS_NAME = "SerialPortIO";
    private static SerialPortIO   runningSerialPortIO = null;
    private FileInputStream       m_fis           = null;
    private InputStream           m_is            = null;
    private OutputStream          m_os            = null;
    private Vector                m_vctPSForwarders = new Vector ();
    private boolean               m_bDummyData    = false;
    private boolean               m_bShutdown     = false;
    private boolean               m_bSourceSim    = false;
    private boolean               m_bSourceDB     = false;
    private boolean               m_bTerminated   = false;
    private boolean		  m_bSock	  = false;
    int                           m_nBytes        = 0;
    int                           dmmyDtPrd       = 1000;
    private SerialPort            serialPort      = null;
    private DBReader              m_dbReader      = null;

    /* the following are used if the "serial port" is really a socket */
    private Socket		  m_socket	  = null;

    public synchronized static void InitSerialPortIO ( )
    {
        if ( runningSerialPortIO == null )
        {
            runningSerialPortIO = new SerialPortIO ( );
            runningSerialPortIO.start();
        }
    }

    public static void RegisterPacketForwarder ( ClientServicer cs)
    {
        InitSerialPortIO ( );
        if ( runningSerialPortIO != null )
        {
            runningSerialPortIO.RegisterPSForwarder ( cs );
        }
    }

    public static void UnregisterPacketForwarder ( ClientServicer cs )
    {
        if ( runningSerialPortIO != null )
        {
            runningSerialPortIO.UnregisterPSForwarder ( cs );
        }
    }

    public static void WriteBytes ( byte[] data )
    {
        InitSerialPortIO ( );
        if ( runningSerialPortIO != null )
        {
            runningSerialPortIO.WriteToPort ( data );
        }
    }

    public SerialPortIO ( )
    {
        m_bDummyData = SerialForward.useDummyData;
        m_nBytes = SerialForward.nBytesRead;
        m_bSourceSim  = SerialForward.bSourceSim;
	m_bSourceDB = SerialForward.bSourceDB;
	m_bSock = SerialForward.commPort_is_socket;
    }

    public void run ( )
    {
        SerialForward.VERBOSE ( "SerialPortIO: initializing" );

        SetIOStreams ( );
        ReadData ( );
        Terminate ( );

        SerialForward.VERBOSE ( "SerialPortIO: closing data source" );
    }

    private void SetIOStreams ( )
    {
        if ( m_bSourceSim )
        {
            SerialForward.VERBOSE ( "Reading data from TOS Simulator" );
            ListenForSim ( );
        }
        else if ( m_bDummyData )
        {
            SerialForward.VERBOSE ( "Reading Dummy data" );
            SerialForward.PACKET_DUMMY_DATA = new byte[SerialForward.PACKET_SIZE];
            SerialForward.PACKET_DUMMY_DATA[0] = (byte) 0x7E;
            for (int ii = 1; ii < SerialForward.PACKET_DUMMY_DATA.length; ii++)
            {
                SerialForward.PACKET_DUMMY_DATA[ii] = (byte)ii;
            }
        }
	else if ( m_bSourceDB ) {
	    m_dbReader = new DBReader (SerialForward.strDBUser, SerialForward.strDBPassword, SerialForward.bPostgresql );
	}
        else if ( m_bSock ) {
            // read from socket
            try
            {
                OpenSocket( );
                SerialForward.VERBOSE("Successfully opened " + SerialForward.commHost);
                m_is = m_socket.getInputStream();
                m_os = m_socket.getOutputStream();
            }
            catch ( Exception e )
            {
                SerialForward.VERBOSE ( "Unable to open socket to host [" +
			SerialForward.commHost + ", port " +
			SerialForward.commTCPPort + "] as serial port" );
                m_is = null;
                m_os = null;
            }

	}
	else
        {
            // read from a true serial port
            try
            {
                OpenCommPort ( );
                SerialForward.VERBOSE( "Successfully opened " + SerialForward.commPort );
                m_is = serialPort.getInputStream();
                m_os = serialPort.getOutputStream();
            }
            catch ( Exception e )
            {
                SerialForward.VERBOSE ( "Unable to open serial port" );
                PrintAllPorts ( );
                m_is = null;
                m_os = null;
            }
        }
        return;
    }

    private void ListenForSim ( )
    {
        ServerSocket socketSimListen = null;
        Socket socketSimRead = null;
        try {
            SerialForward.VERBOSE( "Listening for TOS Simulator on port " + SerialForward.TOSSIM_LISTENPORT);
            socketSimListen = new ServerSocket ( SerialForward.TOSSIM_LISTENPORT );
            socketSimRead  = socketSimListen.accept();
            m_is = socketSimRead.getInputStream();
            SerialForward.VERBOSE( "Read Connection opened to TOS Simulator" );
        }
        catch ( IOException e )
        {
            SerialForward.VERBOSE( "Cannot listen for TOS Simulator on port " + SerialForward.TOSSIM_LISTENPORT);
            m_bShutdown = true;
            return;
        }


        try {
            Socket socketSimWrite = new Socket ( SerialForward.TOSSIM_ADDRESS, SerialForward.TOSSIM_WRITEPORT );
            m_os = socketSimWrite.getOutputStream();
        }
        catch ( IOException e )
        {
            SerialForward.VERBOSE( "Cannot open write connection to TOS Simulator" );
        }
    }


    private void OpenCommPort() throws
        NoSuchPortException, PortInUseException, IOException,
	UnsupportedCommOperationException
    {
          CommPortIdentifier portId =
	    CommPortIdentifier.getPortIdentifier( SerialForward.commPort );
          serialPort =
	    (SerialPort)portId.open(CLASS_NAME, CommPortIdentifier.PORT_SERIAL);
          serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
          serialPort.setSerialPortParams(19200, SerialPort.DATABITS_8,
	    SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    }

    private void OpenSocket() throws
        UnknownHostException, IOException, NumberFormatException
    {
	    // use a socket as the serial port
	    m_socket = new Socket(
		SerialForward.commHost,
		Integer.parseInt(SerialForward.commTCPPort)
	    );
    }

    private void ReadData ( )
    {
        if ( m_bSourceSim )
        {
            ReadSerialData( );
        }
        else if ( m_bDummyData )
        {
            ReadDummyData ( );
        }
	else if ( m_bSourceDB ) {
	    ReadDBData ( );
	}
        else
        {
            ReadSerialData ( );
        }
    }

    private void WriteToPort ( byte[] data )
    {
        if ( m_bSourceSim )
        {
            WriteSerialData ( data );
        }
        else if ( m_bDummyData )
        {
            // do nothing
        }
        else
        {
            WriteSerialData ( data );
        }
    }

    private void ReadDummyData ()
    {
        SerialForward.DEBUG ( "SerialPortReader: sending dummy data" );

        while ( !m_bShutdown )
        {
            SerialForward.nBytesRead += SerialForward.PACKET_DUMMY_DATA.length;
            UpdatePacketForwarders ( SerialForward.PACKET_DUMMY_DATA );
            try { sleep ( dmmyDtPrd ); }
            catch (Exception e ) { }
        }
    }

    private void ReadDBData ( )
    {
	if ( m_dbReader == null ) {
	    m_bShutdown = true;
	    return;
	}
	java.sql.Timestamp lastTimestamp = null;
	java.sql.Timestamp crrntTimestamp = null;
	m_bShutdown = !(m_dbReader.Connect ());

	byte[] packet = m_dbReader.NextPacket();
	crrntTimestamp = m_dbReader.GetTimestamp ( );
	lastTimestamp = crrntTimestamp;
	while ( !m_bShutdown &&  packet != null ) {
	    if ( crrntTimestamp != null && lastTimestamp != null ) {
		
		//int crrntSec = lastTimestamp.getTime())*1000) + (int)(lastTimestamp.getNanos()/1000000);
		//int crrntMils = ((int)crrntTimestamp.getTime())*1000 + (int)(crrntTimestamp.getNanos()/1000000);
		int sleep = (int)(crrntTimestamp.getTime() - lastTimestamp.getTime());
		if ( sleep > 0 ) {
		    System.out.println ("Sleeping for: " + sleep );
		    try { sleep ( sleep ); }
		    catch (Exception e ) { } 
		}
	    } 
	    //try { sleep ( 500); }
	    //catch (Exception e ) {}
	    UpdatePacketForwarders ( packet );
	    System.out.println ( "Read packet from db ");
	    packet = m_dbReader.NextPacket();
	    lastTimestamp = crrntTimestamp;
	    crrntTimestamp = m_dbReader.GetTimestamp();
	}

	System.out.println ("Done reading packets from db");
    }

    private void ReadFileData ( )
    {
        /*ObjectInputStream ois = (ObjectInputStream) m_is;
        Object currentPckt;
        Object lastPckt = null;

        while ( !m_bShutdown )
        {
            try { currentPckt = ois.readObject(); }
            catch ( Exception e )
            {
                m_bShutdown = true;
                continue;
            }

            if ( currentPckt instanceof DataPckt )
            {
                SerialForward.settings.nBytesRead += ((DataPckt) currentPckt).data.length;
                if ( lastPckt == null )
                {
                  UpdatePacketForwarders ( ( (DataPckt) currentPckt).data );
                }
                else
                {
                  SimulatePcktDelay ( (DataPckt) currentPckt, (DataPckt) lastPckt );
                  UpdatePacketForwarders ( ( (DataPckt) currentPckt).data );
                }
                lastPckt = currentPckt;
            }
        }*/
    }
/*
    private void SimulatePcktDelay ( DataPckt currentPckt, DataPckt lastPckt )
    {
        long timeDelta = currentPckt.time.getTime() - lastPckt.time.getTime();
        if ( timeDelta < 0 ) { return; }
        else
        {
            try { this.sleep( timeDelta ); }
            catch ( InterruptedException e ) { }
        }
    }
*/
    public static void Shutdown ( )
    {
        if ( runningSerialPortIO != null )
        {
            runningSerialPortIO.Terminate();
        }
    }

    private void Terminate ( )
    {
        if ( !m_bTerminated ) {
            m_bTerminated = true;
            m_bShutdown = true;
            this.interrupt();
	    if ( m_dbReader != null ) {
		m_dbReader.Close ();
	    }
            if ( m_os != null ) {
                try { m_os.close(); }
                catch (IOException e ) { }
            }
            if ( m_is != null ) {
                try { m_is.close(); }
                catch ( IOException e ) { }
            }
            if ( serialPort != null )
            {
                serialPort.close();
            }

            runningSerialPortIO = null;
        }
    }
    private synchronized void RegisterPSForwarder ( ClientServicer cs )
    {
        m_vctPSForwarders.addElement ( cs );
        SerialForward.IncrementClients();
        SerialForward.DEBUG ( "SerialPortIO: Added listener to position: " + m_vctPSForwarders.size() );
    }



    private synchronized void UnregisterPSForwarder ( ClientServicer cs )
    {
        SerialForward.DEBUG ( "SerialPortIO: Removing packet stream forwarder" );
        UnregisterForwarder ( cs, m_vctPSForwarders );
    }

    private void UnregisterForwarder ( ClientServicer cs, Vector vct )
    {

        if ( !vct.removeElement( cs ) )
        {
          SerialForward.DEBUG ( "Unable to unregister listener");
          return;
        }
	// we always want to read from port even if we
	// have no clients...cause jason says so
	/*
        if ( m_vctPSForwarders.isEmpty() && !m_bSourceSim )
        {
            // no more forwarders, shutdown
            m_bShutdown = true;
	}*/

    }

    public void ReadSerialData()
    {
        int     serialByte;
        int     nPacketSize = SerialForward.PACKET_SIZE;
        int     count = 0;
        byte[]  packet = new byte[SerialForward.PACKET_SIZE];

        if ( m_is == null ) {
            // serial port must not have opened correctly
            m_bShutdown = true;
        }

        try
        {
            SerialForward.VERBOSE("SerialPortIO: Reading port");
            while (!m_bShutdown && (serialByte = m_is.read()) != -1 )
            //while ((serialByte = m_is.read()) != -1 )
            {
              packet[count] = (byte) serialByte;
              count++;
              SerialForward.nBytesRead++;
              if (count == nPacketSize)
              {
                count = 0;
                // send data to listener threads
                UpdatePacketForwarders ( packet );
                nPacketSize = SerialForward.PACKET_SIZE;
                packet = new byte[nPacketSize];
              }
              else if(count == 1 && serialByte != 0x7e)
              {
                  count = 0;
                  System.out.print (".");
              }
            }
        }
        catch ( IOException e )
        {
            m_bShutdown = true;
        }
    }

    public void WriteSerialData ( byte[] data )
    {
        try
        {
            if ( m_os != null ) { m_os.write( data ); }
        }
        catch ( IOException e )
        {
            SerialForward.VERBOSE( "Unable to write data to mote" );
        }
    }

    private synchronized void UpdatePacketForwarders ( byte[] packet )
    {
        SerialForward.IncrementPacketsRead ();
        ClientServicer currentCS;

        //SerialForward.VERBOSE( "Forwarding packets with contents: " + packet );
        for ( int i = 0; i < m_vctPSForwarders.size(); i++)
        {
            currentCS = (ClientServicer) m_vctPSForwarders.elementAt(i);
            try { currentCS.output.write( packet ); }
            catch ( IOException e )
            {
                currentCS.Shutdown ( );
                i--;
            }
        }
	/*
        if ( m_vctPSForwarders.size() == 0 )
        {
            m_bShutdown = true;
	    }*/
    }

    public void PrintAllPorts( )
    {
        Enumeration ports = CommPortIdentifier.getPortIdentifiers();

        if (ports == null) {
          SerialForward.VERBOSE("No comm ports found!" );
          return;
        }

        // print out all ports
        SerialForward.VERBOSE( "printing all ports..." );
        while ( ports.hasMoreElements() )
        {
          SerialForward.VERBOSE( "-  " + ((CommPortIdentifier)ports.nextElement()).getName() );
        }
    }


}

