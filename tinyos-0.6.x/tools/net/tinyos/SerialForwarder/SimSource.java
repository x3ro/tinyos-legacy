package net.tinyos.SerialForwarder;

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

import java.net.*;
import java.util.*;
import java.io.*;

public class SimSource implements DataSource
{
    // size in bytes
    public static final int PACKET_TIME_SIZE      = 8;
    public static final int PACKET_TIME_OFFSET    = 0;
    public static final int PACKET_ID_SIZE        = 2;
    public static final int PACKET_ID_OFFSET      = PACKET_TIME_SIZE + PACKET_TIME_OFFSET;
    public static final int PACKET_PAYLOAD_SIZE   = 36;
    public static final int PACKET_PAYLOAD_OFFSET = PACKET_ID_OFFSET + PACKET_ID_SIZE;
    public static final int PACKET_HEADER_SIZE    = 10;
    public static final int TOSSIM_RFREADPORT     = 10577;
    public static final int TOSSIM_RFWRITEPORT    = 10579;
    public static final int TOSSIM_WRITEBACK_SIZE = 128;


    public Socket           m_socketSimRead   = null;
    public Socket           m_socketSimWrite  = null;
    public ServerSocket     m_socketSimListen = null;
    public InputStream      m_is              = null;
    public OutputStream     m_os              = null;
    public OutputStream     m_osWriteBack     = null;
    public boolean          m_bInitialized    = false;
    public boolean          m_bShutdown       = false;
    public boolean          m_bRespawn        = true;
    public int              m_nPacketsRead    = 0;

    public SimSource()
    {

    }

    public boolean OpenSource ( )
    {
        m_bShutdown                  = false;
        m_bInitialized               = false;

        SerialForward.VERBOSE( "Opening TOS Simulator data source" );
        try
	{
            SerialForward.VERBOSE( "Listening for TOS Simulator on port " + TOSSIM_RFREADPORT);
	    m_socketSimListen  = new ServerSocket ( TOSSIM_RFREADPORT );
            m_socketSimRead   = m_socketSimListen.accept();
            m_is              = m_socketSimRead.getInputStream();
            m_osWriteBack     = m_socketSimRead.getOutputStream();
            SerialForward.VERBOSE( "Read Connection opened to TOS Simulator" );

            m_socketSimListen.close();
            m_socketSimListen = null;



            m_bInitialized = true;
        }
        catch ( IOException e )
        {
            if ( !m_bShutdown )SerialForward.VERBOSE( "Cannot listen for TOS Simulator on port");
            return false;
        }

        /*try
        {
            Socket socketSimWrite = new Socket ( SerialForward.TOSSIM_ADDRESS, SerialForward.TOSSIM_WRITEPORT );
            m_os                  = socketSimWrite.getOutputStream();
        }
        catch ( IOException e )
        {
            SerialForward.VERBOSE( "Cannot open write connection to TOS Simulator" );
            return false;
        }*/


        return true;
    }

    public byte[] ReadPacket( )
    {
        byte[] packet = ReadPacketHelper ( );

        if ( m_bRespawn && !m_bShutdown && packet == null )
        {
            boolean bStatus = CloseSource ( );
            bStatus = OpenSource ( );
            packet = ReadPacket  ( );
        }

        return packet;
    }


    private byte[] ReadPacketHelper ( )
    {
        int     serialByte;
        int     nPacketSize = SerialForward.PACKET_SIZE + PACKET_TIME_SIZE + PACKET_ID_SIZE;
        int     count = 0;
        byte[]  packet = new byte[ SerialForward.PACKET_SIZE ];

        if ( m_is == null ) {
            // must connect to simulator first
	    SerialForward.VERBOSE ("SIMSOURCE: call OpenSource() first" );
            return null;
        }

        try
        {
            if ( m_nPacketsRead % TOSSIM_WRITEBACK_SIZE == 0 )
            {
                m_osWriteBack.write( new byte[TOSSIM_WRITEBACK_SIZE] );
            }

            while (!m_bShutdown && (serialByte = m_is.read()) != -1 )
            {
                if ( count >= PACKET_HEADER_SIZE )
                {
                    packet[ count - PACKET_HEADER_SIZE ] = (byte) serialByte;
                }

                count++;
                SerialForward.nBytesRead++;

                if (count == nPacketSize)
                {
                    m_nPacketsRead++;
                    return packet;
                }
            }
        }
        catch ( IOException e )
        {
            m_bShutdown = true;
        }
	return null;
    }

    public boolean CloseSource ( )
    {
        SerialForward.VERBOSE( "Closing TOS Simulator data source" );

        m_bInitialized = false;
        m_bShutdown    = true;

        if ( m_os != null )
        {
            try { m_os.close(); }
            catch (IOException e ) { }
        }
        if ( m_is != null )
        {
            try { m_is.close(); }
            catch ( IOException e ) { }
        }
        if ( m_socketSimRead != null )
        {
            try { m_socketSimRead.close(); }
            catch (IOException e ) { }
        }
        if ( m_socketSimWrite != null )
        {
            try { m_socketSimWrite.close(); }
            catch (IOException e ) { }
        }
        if ( m_socketSimListen != null )
        {
            try { m_socketSimListen.close(); }
            catch (IOException e ) { }
        }

        m_is           = null;
        m_os           = null;
        m_socketSimWrite = null;
        m_socketSimRead  = null;
        m_socketSimListen = null;

	return true;
    }

    public boolean WritePacket ( byte[] packet )
    {
        try
        {
            if ( m_is == null ) { return false; }
            SerialForward.VERBOSE( "Writing to TOSSIM on port " + TOSSIM_RFWRITEPORT);
            m_socketSimWrite   = new Socket ( "127.0.0.1", TOSSIM_RFWRITEPORT );
            m_os               = m_socketSimWrite.getOutputStream();

            if ( m_os != null )
            {
                byte[] tossimpacket = new byte[ SerialForward.PACKET_SIZE + PACKET_TIME_SIZE + PACKET_ID_SIZE ];
                tossimpacket[PACKET_ID_OFFSET] = 0;
                tossimpacket[PACKET_ID_OFFSET+1] = 0x7e;
                for ( int i = 0; i < SerialForward.PACKET_SIZE; i++ ) 
		{ 
		    tossimpacket[PACKET_PAYLOAD_OFFSET + i] = packet[i]; 
		}

                m_os.write( tossimpacket );

                return true;
            }

            m_socketSimWrite.close();
        }
        catch ( IOException e )
        {
            SerialForward.VERBOSE( "SIMSOURCE: Unable to write data to mote" );
	    e.printStackTrace();
            return false;
        }

	return false;
    }
}
