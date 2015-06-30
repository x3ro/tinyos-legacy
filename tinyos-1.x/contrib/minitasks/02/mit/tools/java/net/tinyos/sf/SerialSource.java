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

package net.tinyos.sf;

import java.util.*;
import java.io.*;
import javax.comm.*;
import java.net.*;

public class SerialSource implements DataSource
{
    private InputStream      m_is = null;
    private OutputStream     m_os = null;
    private String           CLASS_NAME = "SerialSource";
    private boolean          m_bInitialized = false;
    private boolean          m_bShutdown = false;
    private SerialPort       serialPort      = null;
    private SerialForward sf;

    public boolean xGenericBaseMode = true;

    public SerialSource(SerialForward SF)
    {
        sf=SF;
    }

    public boolean OpenSource ( )
    {
        m_bShutdown                  = false;
        if ( m_bInitialized == true )
        {
            sf.VERBOSE( "SerialSource already opened" );
            return true;
        }

        try
        {
            OpenCommPort ( );
            sf.VERBOSE( "Successfully opened " + sf.commPort );
            m_is = serialPort.getInputStream();
            m_os = serialPort.getOutputStream();
            m_bInitialized = true;
        }
        catch ( Exception e )
        {
            sf.VERBOSE ( "Unable to open serial port" );
            PrintAllPorts ( );
            m_is = null;
            m_os = null;
            return false;
        }


        return true;
    }

    public byte[] ReadPacket( )
    {
         int     serialByte;
        int     nPacketSize = sf.PACKET_SIZE;
        int     count = 0;
        byte[]  packet = new byte[sf.PACKET_SIZE];

        if ( m_is == null ) {
            // serial port must not have opened correctly
            m_bShutdown = true;
        }

        try
        {
            while (!m_bShutdown && (serialByte = m_is.read()) != -1 )
            //while ((serialByte = m_is.read()) != -1 )
            {
                packet[count] = (byte) serialByte;
		//SerialForward.VERBOSE("Got byte: "+Integer.toHexString(serialByte & 0xff));
                count++;
                sf.nBytesRead++;

                if (count == nPacketSize)
                {
                    return packet;
                }
                else if(count == 1 && serialByte != 0x7e)
                {
                    count = 0;
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

        if ( serialPort != null )
        {
            serialPort.close();
        }

        m_bInitialized = false;
        m_bShutdown    = true;
        m_is           = null;
        m_os           = null;
        serialPort     = null;

	return true;
    }

    // ACS hack in Xbow framing helpers
    private static final int XGB_HDR1 = 0xAA;     //1st header byte
    private static final int XGB_HDR2 = 0x55;     //2nd header byte

    public boolean WritePacket ( byte[] packet )
    {
        try
        {
            if ( m_os != null )
            {

		// ACS hack in Xbow framing helpers
		if(xGenericBaseMode)
		{
		    m_os.write( XGB_HDR1 );
		    m_os.write( XGB_HDR2 );
		}

                m_os.write( packet );
                return true;
            }
        }
        catch ( IOException e )
        {
            sf.VERBOSE( "Unable to write data to mote" );
        }

	return false;
    }

    private void OpenCommPort() throws
        NoSuchPortException, PortInUseException, IOException,
	UnsupportedCommOperationException
    {
          CommPortIdentifier portId = CommPortIdentifier.getPortIdentifier ( sf.commPort );
          serialPort = (SerialPort) portId.open (CLASS_NAME, CommPortIdentifier.PORT_SERIAL);
          serialPort.setFlowControlMode (SerialPort.FLOWCONTROL_NONE);
          serialPort.setSerialPortParams (sf.BAUD_RATE, SerialPort.DATABITS_8,SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    }

    public void PrintAllPorts( )
    {
        Enumeration ports = CommPortIdentifier.getPortIdentifiers();

        if (ports == null) {
          sf.VERBOSE("No comm ports found!" );
          return;
        }

        // print out all ports
        sf.VERBOSE( "printing all ports..." );
        while ( ports.hasMoreElements() )
        {
          sf.VERBOSE( "-  " + ((CommPortIdentifier)ports.nextElement()).getName() );
        }
    }
}
