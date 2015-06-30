/* 
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
 *
 * Authors: Mike Chen, Philip Levis
 * Last Modified: 7/1/02 (transition to nesC)
 *
 */


package net.tinyos.tools;

import java.util.*;
import java.io.*;
import javax.comm.*;

import net.tinyos.util.*;

public class ListenRaw {

    private static String CLASS_NAME = "net.tinyos.tools.ListenRaw";
    private static final int MAX_MSG_SIZE = 36;
    private static final int PORT_SPEED = 19200;
    private static final int LENGTH_OFFSET = 4;
    private int packetLength;

    // Toggle with -e flag
    private static boolean showEntireMessage = false;
    
    private CommPortIdentifier portId;
    private SerialPort port;
    private String portName;
    private InputStream in;
    private OutputStream out;

    public ListenRaw(String portName) {
	this.portName = portName;
    }


    public void open() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException {
	System.out.println("Opening port " + portName);
	portId = CommPortIdentifier.getPortIdentifier(portName);
	port = (SerialPort)portId.open(CLASS_NAME, 0);
	in = port.getInputStream();
	out = port.getOutputStream();
	
	port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
	port.disableReceiveFraming();
	//printPortStatus();
	// These are the mote UART parameters
	port.setSerialPortParams(PORT_SPEED,
				 SerialPort.DATABITS_8,
				 SerialPort.STOPBITS_1,
				 SerialPort.PARITY_NONE);
	printPortStatus();
	System.out.println();
    }
    
    private void printPortStatus() {
	System.out.println(" baud rate: " + port.getBaudRate());
	System.out.println(" data bits: " + port.getDataBits());
	System.out.println(" stop bits: " + port.getStopBits());
	System.out.println(" parity:    " + port.getParity());
    }

    private static void printAllPorts() {
	Enumeration ports = CommPortIdentifier.getPortIdentifiers();
	
	if (ports == null) {
	    System.out.println("No comm ports found!");
	    return;
	}
	
	// print out all ports
	System.out.println("printing all ports...");
	while (ports.hasMoreElements()) {
	    System.out.println("  " + ((CommPortIdentifier)ports.nextElement()).getName());
	}
    }

    
    
    public void read() throws IOException {
	int i; 
	int count = 0;
	byte[] packet = new byte[MAX_MSG_SIZE];
	
	while ((i = in.read()) != -1) {
	    String val = Integer.toHexString( i &0xff);
	    if (val.length() == 1) {
		val = "0" + val;
	    }
	    if(i == 0x7e || count != 0){
		packet[count] = (byte)i;
		if (count == LENGTH_OFFSET) { // Figure out length of packet
		    System.out.print(val + " ");
		    packetLength = i + count;
		    if (packetLength > MAX_MSG_SIZE - LENGTH_OFFSET) {
			System.err.print("!"); // If too long, print a !
			packetLength = MAX_MSG_SIZE;
		    }
		}
		// Don't print data after the packet
		else if (!showEntireMessage && (count > packetLength) && (count < MAX_MSG_SIZE)) {}
		else {
		    System.out.print(val + " "); // Packet data
		}
		count++;

		if (count >= MAX_MSG_SIZE) {
		    System.out.println();
		    count = 0;
		    packetLength = MAX_MSG_SIZE;
		}
	    }
	    else{
		System.out.println("extra byte: " + val);
	    }
	}
    }

    private static void printUsage() {
	System.err.println("usage: java listen [options] <port>");
	System.err.println("options are:");
	System.err.println("  -h, --help:    usage help");
	System.err.println("  -p:            print available ports");
	System.err.println("  -e:            display entire message");
	System.exit(-1);
    }


    public static void main(String args[]) {

      if ((args.length < 1) || (args.length > 2)) {
	printUsage();
      }
	
	for (int i = 0; i < args.length; i++) {
	    if (args[i].equals("-h") || args[i].equals("--help")) {
		printUsage();
	    }
	    if (args[i].equals("-p")) {
		printAllPorts();
	    }
	    if (args[i].equals("-e")) {
		showEntireMessage = true;
	    }
	}

	if (args[args.length - 1].charAt(0) == '-') {
	    return; // No port specified
	}
	
	ListenRaw reader = new ListenRaw(args[args.length - 1]);
	try {
	    reader.open();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
	
	try {
	    reader.read();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }
}
