/* 
 * Author: Phil Levis <pal@cs.berkeley.edu>
 * Inception Date: Jun 15th, 2002
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

/*
 * AgCommand is a simple command-line utility for controlling the
 * pursue_net_2 application. Using it, one can enable or disable
 * magnetometer sensing and TOF ranging, change the radio
 * potentiometer setting, adjust the magnetometer cutoff setting and
 * set the radio time of flight minimum distance cutoff.
 *
 * By default, when invoked, AgCommand disables magnetometer sensing,
 * TOF ranging, and does not change any settings. It usage is:
 *
 * java AgCommand <port> [options...]
 *
 * Where options are:
 *   mag=on           Turn on magnetometer sensing
 *   mag=off          Turn off magnetometer sensing
 *   snd=on           Turn on sounder TOF ranging
 *   snd=off          Turn off sounder TOF ranging
 *   pot=<val>        Set potentiometer to <val> (should be 0...100)
 *   dis=<val>        Set TOF min valid distance to <val>
 *   magcutoff=<val>  Set magnetometer diff cutoff to <val>
 */

import java.util.*;
import java.io.*;
import javax.comm.*;



public class AgCommand {
    
    
    private static final String  CLASS_NAME                  = "AgCommand";
    private static final String  VERSION     	         = "v0.1";
    private static final int MSG_SIZE = 36;  // 4 header bytes, 30 msg bytes, 2 crc bytes,
    
    CommPortIdentifier portId;
    SerialPort port;
    String portName;
    InputStream in;
    OutputStream out;
    
    public AgCommand(String portName) {
	this.portName = portName;
    }
    
    
    public void open() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException {
	portId = CommPortIdentifier.getPortIdentifier(portName);
	port = (SerialPort)portId.open(CLASS_NAME, 0);
	in = port.getInputStream();
	out = port.getOutputStream();
	
	port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
	
	printPortStatus();
	port.setSerialPortParams(19200, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
	printPortStatus();
    }
    
    private void printPortStatus() {
	System.out.println("baud rate: " + port.getBaudRate());
	System.out.println("data bits: " + port.getDataBits());
	System.out.println("stop bits: " + port.getStopBits());
	System.out.println("parity:    " + port.getParity());
    }
    
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

  
  //===========================================================================  

  //===========================================================================  
    
    public void write(boolean magOn, boolean sounderOn, byte pot, int minValidDistance, int magCutoff) throws IOException {
	int i; 
	int count = 0;
	short crc;
	byte[] packet = new byte[MSG_SIZE];
	
	packet[0] = (byte)0xff;
	packet[1] = (byte)0xff;
	packet[2] = (byte)12;
	packet[3] = (byte)(0x86 & 0xff);
	packet[4] = 29; // Length
	
	packet[5] = (byte)((magOn)? 1:0);
	packet[6] = (byte)((sounderOn)? 1:0);
	packet[7] = pot;
	packet[8] = 0;
	packet[9] = 0;
	packet[10] = 0;
	packet[11] = (byte)(minValidDistance & 0xff);
	packet[12] = (byte)((minValidDistance >> 8) & 0xff);
	packet[13] = (byte)(magCutoff & 0xff);
	packet[14] = (byte)((magCutoff >> 8) & 0xff);
	packet[MSG_SIZE - 2] = 0x11;
	packet[MSG_SIZE - 1] = 0x11;

	System.out.println("Sending packet:\n");
	out.write(packet);
	for(i = 0; i < packet.length; i++) {
	    System.out.print(Integer.toHexString(packet[i] & 0xff) + " ");
	}
	System.out.println("\n ... send done");

	while ((i = in.read()) != -1) {
	    if(i == 0x7e || count != 0){
		packet[count] = (byte)i;
		System.out.print(Integer.toHexString(i&0xff) + " ");
		//System.out.print(i + " ");
		count++;
		if (count == MSG_SIZE) {
		    System.out.println();
		    count = 0;
		}
	    }
	}
    }
   
    public static void usage() {
 System.err.println("usage: java AgCommand <port> [commands...]");
 System.err.println("   mag=on           Turn on magnetometer sensing");
 System.err.println("   mag=off          Turn off magnetometer sensing (default)");
 System.err.println("   snd=on           Turn on sounder TOF ranging");
 System.err.println("   snd=off          Turn off sounder TOF ranging (default)");
 System.err.println("   pot=<val>        Set potentiometer to <val> (should be 0...100)");
 System.err.println("   dis=<val>        Set TOF min valid distance to <val>");
 System.err.println("   magcutoff=<val>  Set magnetometer diff cutoff to <val>");

} 
    
    public static void main(String args[]) {
	boolean mag = false;
	boolean sounder = false;
	byte pot = (byte)0xff;
	int minValidDistance = 0;
	int magCutoff = 0;
	if (args.length == 0) {
	    System.err.println("usage: java AgCommand [port] ...");
	    System.exit(-1);
	}
        if (args[0].equals("-h")) {
		usage();
		return;
        }	
	System.out.println("\nAgCommand started");
	AgCommand command = new AgCommand(args[0]);
	try {
	    command.printAllPorts();
	    command.open();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}

	for (int i = 1; i < args.length; i++) {
	    if (args[i].equals("mag=on")) {mag = true;}
	    if (args[i].equals("mag=off")) {mag = false;}
	    if (args[i].equals("snd=on")) {sounder = true;}
	    if (args[i].equals("snd=off")) {sounder = false;}
	    if (args[i].substring(0,4).equals("pot=")) {
		System.err.println("pot set");
		String val = args[i].substring(4);
		pot = Byte.parseByte(val);
	    }
	    if (args[i].substring(0,4).equals("dis=")) {
		String val = args[i].substring(4);
		minValidDistance = Integer.parseInt(val);
	    }
	    if (args[i].length() >= 10 &&
		args[i].substring(0,10).equals("magcutoff=")) {
		String val = args[i].substring(10);
		magCutoff = Integer.parseInt(val);
	    }
	}
	
	try {
	    command.write(mag, sounder, pot, minValidDistance, magCutoff);
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }
    
}
