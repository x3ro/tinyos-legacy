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

package net.tinyos.SerialForwarder;

import java.util.*;
import java.io.*;


public class SerialPortIO extends Thread
{
    private static SerialPortIO   runningSerialPortIO = null;
    private Vector                m_vctPSForwarders = new Vector ();
    private boolean               m_bShutdown     = false;
    private boolean               m_bTerminated   = false;
    int                           m_nBytes        = 0;
    private DataSource            m_dataSource    = null;


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
            runningSerialPortIO.WriteToSource ( data );
        }
    }

    public SerialPortIO ( )
    {

    }

    public void run ( )
    {
        SerialForward.VERBOSE ( "SerialPortIO: initializing" );
	m_dataSource = SerialForward.dataSource;
	if ( m_dataSource != null )
	{
	    boolean bStatus;
	    byte[] packet;

	    bStatus = m_dataSource.OpenSource ( );
            if ( !bStatus && !m_bShutdown ) { SerialForward.VERBOSE( "Unable to open data source" ); }

	    while ( !m_bShutdown && bStatus )
	    {
		packet = m_dataSource.ReadPacket ( );
		if ( packet != null )
		{
		    UpdatePacketForwarders ( packet );
		}
		else
		{
                    m_dataSource.CloseSource();
                    m_bShutdown = true;
		}
	    }
	}
	else
	{
            SerialForward.VERBOSE ( "SerialPortIO: no data source selected" );
	}

        SerialForward.VERBOSE ( "SerialPortIO: closing data source" );
        runningSerialPortIO = null;
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
            //m_dataSource.CloseSource();
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

    private boolean WriteToSource ( byte[] packet )
    {
        if ( m_dataSource != null )
        {
            m_dataSource.WritePacket( packet );
        }
        return true;
    }

}

