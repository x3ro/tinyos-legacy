/* 
 * Author: Mike Chen <mikechen@cs.berkeley.edu>
 * Inception Date: October 22th, 2000
 *
 * This software is copyrighted by Mike Chen and the Regents of
 * the University of California.  The following terms apply to all
 * files associated with the software unless explicitly disclaimed in
 * individual files.
 * 
 * The authors hereby grant permission to use this software without
 * fee or royalty for any non-commercial purpose.  The authors also
 * grant permission to redistribute this software, provided this
 * copyright and a copy of this license (for reference) are retained
 * in all distributed copies.
 *
 * For commercial use of this software, contact the authors.
 * 
 * IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
 * DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
 * IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
 * NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */

//==============================================================================
//===   SyncedCRCSerialPortStub.java   ==============================================

/*
 * VANDY: added CRC checking on incoming packets
 *        added CRC to outgoing packets
 *        added support for 0xaa55 preamble
 * Janos Sallai, ISIS, Vanderbilt janos.sallai@vanderbilt.edu
 */


package isis.nest.util;

import java.util.*;
import java.io.*;
import javax.comm.*;
import net.tinyos.util.*;

/**
 * 
 * Init the serial port and reads data from it.
 *
 * @author  <A HREF="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A> 
 *		(<A HREF="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @since   1.1.6
 */


public class SyncedCRCSerialPortStub implements SerialStub {

    //=========================================================================
    //=   CONSTANTS   =========================================================
  
    public static int hdr1 = 0xaa;                 //1st byte of preamble
    public static int hdr2 = 0x55;                 //2nd byte of preamble

    private static final String  CLASS_NAME = "SerialPortStub";

    //size of a message, in bytes
    private int msgSize = 36;

    //=========================================================================
    //=   PRIVATE VARIABLES   =================================================

    CommPortIdentifier portId;
    SerialPort port;
    String portName;
	int baudrate = 19200;
    InputStream in;
    OutputStream out;
    public static int debug = 0;
    private Vector listeners = new Vector();


    //=   CONSTRUCTORS   ======================================================
    //=========================================================================

    public SyncedCRCSerialPortStub(String portName) {
	this.portName = portName;
    }


    public SyncedCRCSerialPortStub(String portName, int packetSize)
    {
	this.portName = portName;
	this.msgSize = packetSize;
    }

    public SyncedCRCSerialPortStub(String portName, int packetSize, int baudrate)
    {
	this.portName = portName;
	this.msgSize = packetSize;
	this.baudrate = baudrate;
    }

    //=========================================================================

    public void Open() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException {
	portId = CommPortIdentifier.getPortIdentifier(portName);
	port = (SerialPort)portId.open(CLASS_NAME, 0);
	in = port.getInputStream();
	out = port.getOutputStream();
	port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);

	port.setSerialPortParams(baudrate, SerialPort.DATABITS_8,
				 SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
	printPortStatus();
    }

    public void Close() throws Exception {
	in.close();
	out.close();
	port.close();
    }
    
    private void printPortStatus() {
	System.err.println("baud rate: " + port.getBaudRate());
	System.err.println("data bits: " + port.getDataBits());
	System.err.println("stop bits: " + port.getStopBits());
	System.err.println("parity:    " + port.getParity());
    }

    //=========================================================================

    /*
     *  Get an enumeration of all of the comm ports 
     *  on the machine
     */
  
    public void printAllPorts() {
	Enumeration ports = CommPortIdentifier.getPortIdentifiers();
  
	if (ports == null) {
	    System.out.println("No comm ports found!");
	    return;
	}
  
	// print out all ports
	System.out.println("printing all ports...");
	while (ports.hasMoreElements()) {
	    System.out.println("-  " + ((CommPortIdentifier)ports.nextElement()).getName());
	}
	System.out.println("done.");
    }

  
    //=======================================================================  

    public void registerPacketListener(PacketListenerIF listener) {
        if (debug > 0)
	    System.err.println("SPS: Adding listener: "+listener);
	listeners.add(listener);
    }


    //=======================================================================  
    private short calculateCRC(byte packet[]) {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 2;
	crc = 0;
	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}
	return (crc);
    }
    //=======================================================================  

    public synchronized void Read() throws IOException {
	int i; 
	int count = 0;
	byte[] packet = new byte[msgSize];
	if (debug > 0)
	    System.out.print("!");

	while ((i = in.read()) != -1) {
	    if (debug > 0)
		System.out.print("!");
	    packet[count] = (byte)i;
	    count++;
	    if (count == msgSize) {
		count = 0;

    	// VANDY: CRC Check on incoming packets
	    short crc = calculateCRC(packet);
	    if(packet[packet.length-1] == (byte) ((crc >> 8) & 0xff) && packet[packet.length-2] == (byte) (crc & 0xff))
	    {			

    		Enumeration e = listeners.elements();
	    	while (e.hasMoreElements()) {
		        PacketListenerIF listener = (PacketListenerIF)e.nextElement();
		        listener.packetReceived(packet);
		    }
	    } else {
		    System.err.print("CRC error\n");
	    }
	    }
	    else if(count == 1 && i != 0x7e) {
		count = 0;
		if (debug > 0)
		    System.out.print("?");
	    }
	}
    }

    public  void Write(byte [] packet ) throws IOException {
	if (debug > 0)
	    System.out.print("-");
    // VANDY: adding CRC to the packet
  	short crc = calculateCRC(packet);
	packet[packet.length-1] = (byte) ((crc >> 8) & 0xff);
	packet[packet.length-2] = (byte) (crc & 0xff);

    // VANDY: adding 0xaa55 preamble to the packet
    byte packetWithPreamble[] = new byte[packet.length+2];
    packetWithPreamble[0] = (byte)hdr1;
    packetWithPreamble[1] = (byte)hdr2;
    for(int i=2; i<packetWithPreamble.length; i++) packetWithPreamble[i] = packet[i-2];

	out.write(packetWithPreamble);
	out.flush();
    }
}
