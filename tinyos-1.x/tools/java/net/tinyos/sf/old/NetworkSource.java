// $Id: NetworkSource.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

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

public class NetworkSource implements DataSource {
    private InputStream      m_is = null;
    private OutputStream     m_os = null;
    private Socket           m_socket = null;
    private String           CLASS_NAME = "SerialSource";
    private boolean          m_bInitialized = false;
    private boolean          m_bShutdown = false;
    private SerialPort       serialPort      = null;
    private SerialForward sf;
    public NetworkSource(SerialForward SF) {sf =SF;}
    public void setSerialForward(SerialForward SF) {sf =SF;}

    private int sync_count = 0;

    private static final int SYNC_BYTE  = 0x6E;
    private static final int SYNC_LEN   = 10;

    private static final byte[] sync_array = { SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE,
					       SYNC_BYTE, SYNC_BYTE };

    public boolean OpenSource() {
        m_bShutdown                  = false;
        m_bInitialized               = false;

        try {
            OpenSocket();
            sf.VERBOSE("Successfully opened " + sf.commHost);
            m_is = m_socket.getInputStream();
            m_os = m_socket.getOutputStream();
            m_bInitialized = true;
        }
        catch (Exception e) {
            sf.VERBOSE ("Unable to open socket to host [" +
                    sf.commHost + ", port " +
                    sf.commTCPPort + "] as serial port");
            m_is = null;
            m_os = null;
            return false;
        }

        return true;
    }

    public byte[] ReadPacket() {
        int     serialByte;
        int     nPacketSize = sf.PACKET_SIZE;
        int     count = 0;
        byte[]  packet = new byte[sf.PACKET_SIZE];

        if (m_is == null) {
            // serial port must not have opened correctly
            m_bShutdown = true;
        }

        try {
            sf.VERBOSE("SerialPortIO: Reading port");
            while (!m_bShutdown && (serialByte = m_is.read()) != -1) {
            //while ((serialByte = m_is.read()) != -1) {
                packet[count] = (byte) serialByte;
                count++;
                sf.nBytesRead++;

                if (count == nPacketSize) {
                  return packet;
                }
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
		/*                else if(count == 1 && serialByte != 0x7e) {
                    count = 0;
		
		    }*/
            }
        }
        catch(IOException e) {
            m_bShutdown = true;
        }

        return null;
    }

    public boolean CloseSource() {
        if (m_os != null) {
            try {m_os.close();}
            catch (IOException e) {}
        }
        if (m_is != null) {
            try {m_is.close();}
            catch (IOException e) {}
        }

        m_bInitialized = false;
        m_bShutdown    = true;
        m_is           = null;
        m_os           = null;

	return true;
    }

    public boolean WritePacket (byte[] packet) {
        try {
            if (m_os != null) {
		if (sf.sync_uart)
		    m_os.write( sync_array );
                m_os.write(packet);
                return true;
            }
        }
        catch (IOException e) {
            sf.VERBOSE("Unable to write data to mote");
        }

	return false;
    }

    private void OpenSocket() throws UnknownHostException, IOException, NumberFormatException {
	// use a socket as the serial port
	m_socket = new Socket(sf.commHost,
			      Integer.parseInt(sf.commTCPPort));
    }

}
