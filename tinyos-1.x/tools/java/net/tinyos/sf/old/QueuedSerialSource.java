// $Id: QueuedSerialSource.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

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

/** QueuedSerialSource maintains an output queue on top of the uart, and uses
    a slightly modified verison of the uart protocol which includes a simple
    form of acknowledgements to support this.
    
    The basic idea is that for each packet, we now send over the UART:

    <magic code> <idx> <packet>

    Where <magic code> is 0xFE and allows us to (hopefully) synchronize on packet start
      if we miss a byte on the mote side,
      
   <idx> is the index of the packet (0-255 sequentially increaing), which can be used
   on the mote side to reject duplicates in the event that we miss an acknowledgement

   When this data is delivered, we immediately expect an acknowledgement byte to be
   returned, which should be 1.  

   To use this, there is a new getQueued call in SerialForwarder, which sets up the
   serial forwarder using a queued interface.

   You also need to use the QueuedUARTGenericComm or QueuedUARTGenericCommPromiscuous
   versions of GenericComm.

   @author Sam Madden (madden@cs.berkeley.edu)

*/

public class QueuedSerialSource implements DataSource, Runnable
{
    private InputStream      m_is = null;
    private OutputStream     m_os = null;
    private String           CLASS_NAME = "QueuedSerialSource";
    private boolean          m_bInitialized = false;
    private boolean          m_bShutdown = false;
    private SerialPort       serialPort      = null;
    private SerialForward sf;

    private Vector queue = new Vector();
    private byte idx = 0;
    private static final int TIMEOUT = 50; //read timeout, in ms
    private Integer mon = new Integer(0);
    private int missed;

    public QueuedSerialSource(SerialForward SF)
    {

        sf=SF;
    }
    public void setSerialForward(SerialForward SF) { sf = SF; }

    public boolean OpenSource ( )
    {

        m_bShutdown                  = false;
        if ( m_bInitialized == true )
        {
            sf.VERBOSE( "QueuedSerialSource already opened" );
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
	
	
	//start running
	Thread t = new Thread(this);
	t.start();


        return true;
    }

    public byte[] ReadPacket( )
    {
	int     serialByte = 0;
        int     nPacketSize = sf.PACKET_SIZE;
        int     count = 0;
        byte[]  packet = new byte[sf.PACKET_SIZE];
	byte[] retPack = null;

        if ( m_is == null ) {
            // serial port must not have opened correctly
            m_bShutdown = true;
        }
	
	//try {
	//serialPort.enableReceiveTimeout(0);
	//} catch (UnsupportedCommOperationException e) {
	//}
	while (retPack == null && !m_bShutdown){
	  

	  synchronized(mon) {		
		try {
		    while (!m_bShutdown && retPack == null && (missed != -1 || (serialByte = m_is.read()) != -1)) {
			if (missed != -1) {
			    packet[count] = (byte)missed;
			    missed = -1;
			} else
			    packet[count] = (byte) serialByte;

		      //SerialForward.VERBOSE("Got byte: "+Integer.toHexString(serialByte & 0xff));
			//System.out.print(serialByte + ",");
		      count++;
		      sf.nBytesRead++;
		      if (count == nPacketSize) {
			retPack = packet;
		      }
		      else if(count == 1 && serialByte != 0x7e) {
			count = 0;
		      }
		    }
		} catch ( IOException e ) {
		  m_bShutdown = true;
		}
	  }
	}
	// try {
	//serialPort.enableReceiveTimeout(TIMEOUT);
	//} catch (UnsupportedCommOperationException e) {

	System.out.println("returning packet");
	if (retPack == null) System.out.println("is null");
	System.out.println("serialByte = " + serialByte);
        return retPack;
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

    public boolean WritePacket ( byte[] packet )
    {
      //	System.out.println("ENQUEUE");
	enqueue(packet);
	return true;
    }

    
    public void run() {
	int serialByte;

	while (true) {

	    try {


		    byte[] sendPack = peek();
		    int b;

		    synchronized(mon) {
		      //System.out.println("WRITING");
		      if (m_os != null) { 
			m_os.write(sendPack);
		      }
		      
		      //now, look for the ack
		      //System.out.println("READING");
		      
		      b = m_is.read();
		    }
		    if (b == 1) {
		      //System.out.println("ACK");
		      pop(); //acked!
		    } else {
			missed = b; //this wasn't the ack, it was the start of a packet!
			System.out.println("NO ACK");
		    //otherwise, we need to resend
		    }
	    } catch (ArrayIndexOutOfBoundsException e) {
	      
		try {
		    Thread.currentThread().sleep(10);
		} catch (InterruptedException ex_int) {
		}

	    } catch (IOException e) {
		System.out.println( "Unable to write data to mote:" + e );
	    }
	}

    }
    
    private void OpenCommPort() throws
        NoSuchPortException, PortInUseException, IOException,
	UnsupportedCommOperationException
    {
          CommPortIdentifier portId = CommPortIdentifier.getPortIdentifier ( sf.commPort );
          serialPort = (SerialPort) portId.open (CLASS_NAME, CommPortIdentifier.PORT_SERIAL);
          serialPort.setFlowControlMode (SerialPort.FLOWCONTROL_NONE);
	  try {
	      serialPort.enableReceiveTimeout(TIMEOUT);
	  } catch (UnsupportedCommOperationException e) {
	  }

	  if (!serialPort.isReceiveTimeoutEnabled())
	      System.out.println("DANGER! TIMEOUT NOT SUPPORTED!");
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

    public void enqueue(byte[] packet) {
	byte copy[] = new byte[packet.length + 2];
	System.arraycopy(packet, 0, copy, 2 , packet.length);
	copy[0] = (byte)0xFE; //magic code
	copy[1] = idx++; //set the index byte
	queue.addElement(copy);
    }

    public byte[] peek() throws ArrayIndexOutOfBoundsException {
	byte[] el = (byte[])queue.elementAt(0);
	if (el == null)
	    throw new ArrayIndexOutOfBoundsException();
	return el;
    }

    public  void pop() {
	if (queue.size() > 0)
	    queue.removeElementAt(0);
    }

}
