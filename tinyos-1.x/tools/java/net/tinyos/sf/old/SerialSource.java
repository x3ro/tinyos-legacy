// $Id: SerialSource.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

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


package net.tinyos.sf.old;

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

    private int sync_count = 0;

    private static final int SYNC_BYTE  = 0x6E;
    private static final int SYNC_LEN   = 10;

    private static final byte[] sync_array = { SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE };

    public SerialSource(SerialForward SF)
    {
        sf=SF;
    }
    public void setSerialForward(SerialForward SF) { sf = SF; }

    public boolean OpenSource ( ) {
	
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

		if (sf.sync_uart) {
		    if (serialByte == SYNC_BYTE) {
			sync_count++;
			if (sync_count == SYNC_LEN) {
			    count = 0;
			}
		    }
		    else {
			sync_count = 0;
		    }
		}

                if (count == nPacketSize)
                {
                    return packet;
                } 
		else if ((count == 1 && serialByte != 0x7e) && (!sf.sync_uart))
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
	sf.VERBOSE("Closing serial port.\n");
	
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

    public boolean WritePacket ( byte[] packet )
    {
        try
        {
            if ( m_os != null )
            {
		if (sf.sync_uart)
		    m_os.write( sync_array );
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
	  System.err.println(sf.commPort+" "+sf.BAUD_RATE+" bps");
          serialPort.setSerialPortParams (sf.BAUD_RATE, SerialPort.DATABITS_8,SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);

	  // Try & run external program to setup serial port correctly
	  // (necessary on Linux, IBM's javax.comm leaves port in cooked mode)
	  try {
	    Runtime.getRuntime().exec("tinyos-serial-configure " + sf.commPort);
	  }
	  catch (IOException e) { }
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
