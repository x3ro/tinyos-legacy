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
//===   listen.java   ==============================================

//package ;

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


public class listen {

  //===========================================================================
  //===   CONSTANTS   =========================================================
  
private static final String  CLASS_NAME                  = "listen";
private static final String  VERSION     	         = "v0.1";
    private static final int MSG_SIZE = 36;  // 3 header bytes, 31 msg bytes, 2 crc bytes
  //===   CONSTANTS   =========================================================
  //===========================================================================
  
  //===========================================================================
  //===   PRIVATE VARIABLES   =================================================

CommPortIdentifier portId;
SerialPort port;
String portName;
InputStream in;
OutputStream out;

  //===   PRIVATE VARIABLES   =================================================
  //===========================================================================
  
  
  //===========================================================================
  //===   NONLOCAL INSTANCE VARIABLES   =======================================

  //===   NONLOCAL INSTANCE VARIABLES   =======================================
  //===========================================================================
  
  //===========================================================================
  //===   CONSTRUCTORS   ======================================================
  
  /**
   * Default constructor.
   */

  //===   CONSTRUCTORS   ======================================================
  //===========================================================================

  //===========================================================================
  

  /**
   *  .
   */

public listen(String portName) {
  this.portName = portName;
}


  //===========================================================================

public void open() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException {
  portId = CommPortIdentifier.getPortIdentifier(portName);
  port = (SerialPort)portId.open(CLASS_NAME, 0);
  in = port.getInputStream();
  out = port.getOutputStream();

  //port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN);
  port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
  port.disableReceiveFraming();
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

  //===========================================================================

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

  
  //===========================================================================  

  //===========================================================================  

public void read() throws IOException {
  int i; 
  int count = 0;
  byte[] packet = new byte[MSG_SIZE];

  while ((i = in.read()) != -1) {
    if(i == 0x7e || count != 0){
    	packet[count] = (byte)i;
	String val = Integer.toHexString( i &0xff);
	if (val.length() == 1) {
	    val = "0" + val;
	}
    	System.out.print(val + " ");
    	//System.out.print(i + " ");
    	count++;
	if (count == MSG_SIZE) {
      		System.out.println();
      		count = 0;
	}
    }else{
	System.out.println("extra byte " + Integer.toHexString(i&0xff));
    }
  }
}



  //===========================================================================
  //===   MAIN    =============================================================

public static void main(String args[]) {
  if (args.length != 1) {
    System.err.println("usage: java listen [port]");
    System.exit(-1);
  }

  System.out.println("\nlisten started");
  listen reader = new listen(args[0]);
  try {
    reader.printAllPorts();
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
