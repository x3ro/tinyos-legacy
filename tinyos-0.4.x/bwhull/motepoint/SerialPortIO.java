/**
 * File: SerialPortReader.java
 *
 * Description:
 * The SerialPortReader handles the collection of packets
 * from a mote connected to the serial port.  The Constructor
 * takes in an already open input stream from which to read
 * data.
 *
 * Author: Bret Hull
 */


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
    boolean                       m_bDummyData    = false;
    boolean                       m_bShutdown     = false;
    boolean                       m_bSourceSim    = false;
    int                           m_nBytes        = 0;
    int                           dmmyDtPrd     = 1000;
    ListenServer                  lstnSrvr      = null;
    private SerialPort            serialPort    = null;

    public synchronized static void InitSerialPortIO ( )
    {
        if ( runningSerialPortIO == null )
        {
            runningSerialPortIO = new SerialPortIO ( );
            runningSerialPortIO.start();
        }
    }

    public static void RegisterPacketForwarder ( OutputStream os)
    {
        InitSerialPortIO ( );
        if ( runningSerialPortIO != null )
        {
            runningSerialPortIO.RegisterPSForwarder ( os );
        }
    }

    public static void UnregisterPacketForwarder ( OutputStream os )
    {
        if ( runningSerialPortIO != null )
        {
            runningSerialPortIO.UnregisterPSForwarder ( os );
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
    }

    public void run ( )
    {
        SerialForward.DEBUG ( "SerialPortIO: initializing" );

        SetIOStreams ( );
        ReadData ( );
        Shutdown ( );

        SerialForward.DEBUG ( "SerialPortIO: terminating" );
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
        }
        else
        {
            // read from the serial port
            try
            {
                OpenCommPort ( );
                m_is = serialPort.getInputStream();
                m_os = serialPort.getOutputStream();
            }
            catch ( Exception e )
            {
                SerialForward.DEBUG ("Unable to open serial port");
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


    private void OpenCommPort() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException
    {
        CommPortIdentifier portId = CommPortIdentifier.getPortIdentifier( SerialForward.commPort );
        serialPort = (SerialPort)portId.open(CLASS_NAME, CommPortIdentifier.PORT_SERIAL);
        serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN);
        serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_OUT);
        serialPort.setSerialPortParams(19200, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    }

    private void ReadData ( )
    {
        if ( m_bSourceSim )
        {
            //ReadSimData ( );
        }
        else if ( m_bDummyData )
        {
            ReadDummyData ( );
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
        m_bShutdown = true;
        this.interrupt();

        if ( m_os != null ) {
            try { m_os.close(); }
            catch (IOException e ) { }
        }
        if ( m_is != null ) {
            try { m_is.close(); }
            catch ( IOException e ) { }
        }
        runningSerialPortIO = null;
    }
    private synchronized void RegisterPSForwarder ( OutputStream os )
    {
        m_vctPSForwarders.addElement ( os );
        SerialForward.IncrementClients();
        SerialForward.DEBUG ( "SerialPortIO: Added listener to position: " + m_vctPSForwarders.size() );
    }



    private synchronized void UnregisterPSForwarder ( OutputStream os )
    {
        SerialForward.DEBUG ( "SerialPortIO: Removing packet stream forwarder" );
        UnregisterForwarder ( os, m_vctPSForwarders );
    }

    private void UnregisterForwarder ( OutputStream os, Vector vct )
    {

        if ( !vct.removeElement( os ) )
        {
          SerialForward.VERBOSE ( "Unable to unregister listener");
          return;
        }
        if ( m_vctPSForwarders.isEmpty() && !m_bSourceSim )
        {
            // no more forwarders, shutdown
            m_bShutdown = true;
        }

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
            while (!m_bShutdown && (serialByte = m_is.read()) != -1 )
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
                  SerialForward.VERBOSE (".");
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
        OutputStream currentOS;

        //SerialForward.VERBOSE( "Forwarding packets with contents: " + packet );
        for ( int i = 0; i < m_vctPSForwarders.size(); i++)
        {
            currentOS = (OutputStream) m_vctPSForwarders.elementAt(i);
            try { currentOS.write( packet ); }
            catch ( IOException e )
            {
                UnregisterPSForwarder ( currentOS );
                i--;
            }
        }
    }

    public void PrintAllPorts( )
    {
        SerialForward.VERBOSE( "--------------------" );
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
        SerialForward.VERBOSE( "--------------------" );
    }


}

