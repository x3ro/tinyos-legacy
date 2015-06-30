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
//===   SerialPortStub.java   ==============================================


package net.tinyos.util;

import java.util.*;
import java.io.*;
import javax.comm.*;

/**
 *
 * Init the serial port and reads data from it.
 *
 * @author  <A HREF="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A>
 *		(<A HREF="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @since   1.1.6
 */

/**
 * Modifications:
 * Constructor: set baud rate
 * msgSize : make public so it can be externally changed
 */
public class SerialPortStub implements SerialStub {

    //=========================================================================
    //=   CONSTANTS   =========================================================

    private static final String  CLASS_NAME = "SerialPortStub";

    //size of a message, in bytes
    public int msgSize = 36;

    //=========================================================================
    //=   PRIVATE VARIABLES   =================================================

    CommPortIdentifier portId;
    SerialPort port;
    String portName;
    int baudRate = 0;
    InputStream in;
    OutputStream out;
    public static int debug = 0;
    public static boolean bXGenericBase = false ;   //True if using bXGenericBase
    public static int hdr1 = 0x7e;                 //1st byte expected in pckt
    private Vector listeners = new Vector();


    //=   CONSTRUCTORS   ======================================================
    //=========================================================================

    public SerialPortStub(String portName) {
	this.portName = portName;
    }

    public SerialPortStub(String portName,  long baudRate )
    {
            this.portName = portName;
            this.baudRate = (int)baudRate;
    }
    public SerialPortStub(String portName, int packetSize)
    // set Mote packet size
    // bXGB = true if using XGenericBase
    // if using XGenericBase: then first byte in hdr is 0xaa
    //                        msg size = 38 bytes
    {
	this.portName = portName;
	this.msgSize = packetSize;
       // if (bXGB){
         //   this.hdr1 = (byte)0xaa;
           // this.msgSize = 38;
       // }

    }



    //=========================================================================

    public void Open() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException {
	portId = CommPortIdentifier.getPortIdentifier(portName);
	port = (SerialPort)portId.open(CLASS_NAME, 0);
	in = port.getInputStream();
	out = port.getOutputStream();
	port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);

        if (baudRate == 0) baudRate = 19200;         //defautl
	port.setSerialPortParams((int)baudRate, SerialPort.DATABITS_8,
				 SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);

        printPortStatus();
    }

    public void Close() throws Exception {
	in.close();
	out.close();
	port.close();
    }

    private void printPortStatus() {
	System.out.println("baud rate: " + port.getBaudRate());
	System.out.println("data bits: " + port.getDataBits());
	System.out.println("stop bits: " + port.getStopBits());
	System.out.println("parity:    " + port.getParity());
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

    public synchronized void Read() throws IOException {
	int i;
	int count = 0;
//	byte[] packet = new byte[msgSize];
        byte[] packet = new byte[msgSize+ 2];
	if (debug > 0)
	    System.out.print("!");

	while ((i = in.read()) != -1) {
	    if (debug > 0)
		System.out.print("!");
	    packet[count] = (byte)i;
	    count++;
	    if (count == msgSize) {
		count = 0;
		Enumeration e = listeners.elements();
		while (e.hasMoreElements()) {
		    PacketListenerIF listener = (PacketListenerIF)e.nextElement();
		    listener.packetReceived(packet);
		}
	    }
	    else if(count == 1 && (i != (hdr1 & 0xff))){
		count = 0;
		if (debug > 0)
		    System.out.print("?");
	    }
	}
    }

    public  void Write(byte [] packet ) throws IOException {
	if (debug > 0)
	    System.out.print("-");
	out.write(packet);
	out.flush();
    }
}
