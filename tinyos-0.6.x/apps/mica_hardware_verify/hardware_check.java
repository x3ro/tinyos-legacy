/* 
 * Author: Jason Hill
 *
 * This software is copyrighted by Jason Hill and the Regents of
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
//===   hardware_check.java   ==============================================

//package ;

import java.util.*;
import java.io.*;
import javax.comm.*;


public class hardware_check implements Runnable{

  //===========================================================================
  //===   CONSTANTS   =========================================================
  
private static final String  CLASS_NAME                  = "hardware_check";
private static final String  VERSION     	         = "v0.1";
    private static final int MSG_SIZE = 36;  // 4 header bytes, 30 msg bytes, 2 crc bytes,
    
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

public hardware_check(String portName) {
  this.portName = portName;
}


  //===========================================================================

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


public void run(){
	int val = 0;
  while(1 == 1){
     try{
  byte[] packet = new byte[MSG_SIZE]; 
  short crc;
  packet[0] = (byte)0xff;
  packet[1] = (byte)0xff;
  packet[2] = (byte)32;
  packet[3] = 0x7D;
  packet[4] = (byte)(val & 0xf);
  packet[5] = (byte)(val & 0xf);
  packet[6] = (byte)(val & 0xf);
  packet[7] = 0x0;
  packet[8] = 0x0;
  packet[9] = 0x0;
	val ++;
  crc = (short) calcrc(packet,MSG_SIZE-2);
  packet[MSG_SIZE-2] = (byte) (crc & 0xff);
  packet[MSG_SIZE-1] = (byte) ((crc >> 8) & 0xff);
	int i;
	Thread.sleep(2000);
	out.write(packet);
        System.out.print("Sending: ");
  	for(i = 0; i < packet.length; i++) {
    		System.out.print(Integer.toHexString(packet[i] & 0xff) + " ");
  	}
  	System.out.println();
	rx_time --;
	if(rx_time == 0){
		rx_time = 1;
		System.out.println("Node transmission failure");
	}
    }catch(Exception e){
	e.printStackTrace();
    }
  }
}
  
  //===========================================================================  

  //===========================================================================  

int last_rx_count = 0;
int rx_time = 10;

void check_packet(byte[] packet){
	rx_time = 10;
	//check if the SERIAL_ID was read.
	System.out.println("Node async clock: passed");
	System.out.print("Node Serial ID: ");
	for(int i = 0; i < 8; i ++){
    		System.out.print(Integer.toHexString(packet[4 + i]&0xff) + " ");
	}
	System.out.println();
	System.out.print("SPI rework: ");
	if(packet[15] == 0x5){
		System.out.println("passed");
	}else{
		System.out.println("failed");
	}
	System.out.print("4Mbit flash check: ");
	if(packet[12] == 0x1 && (packet[13] & 0xff) == 0x8f && packet[14] == 0x9){
		System.out.println("passed");
	}else{
		System.out.print("failed ");
		System.out.print(packet[12] + " ");
		System.out.print(packet[13] + " ");
		System.out.println(packet[14] + " ");
	}
	
                packet[0] = (byte)0xff;
                packet[1] = (byte)0xff;
  	short pack_crc = (short)((packet[MSG_SIZE-2]) & 0xff);
  	pack_crc |= packet[MSG_SIZE-1] << 8;
  	short crc = (short) calcrc(packet,MSG_SIZE-2);
	boolean crc_check = true;
	if(packet[19] == 1){
		System.out.println("UART transmissison successful");
	}else{
		System.out.println("RF transmissison successful");
		System.out.print("Packet crc: ");
		if(crc == pack_crc){
			System.out.println("passed");
		}else{
			System.out.print("failed ");
			System.out.print(crc + " ");
			System.out.println(pack_crc + " ");
			crc_check = false;
		}
	}
	
	if(packet[17] > last_rx_count && crc_check){
		last_rx_count = packet[17];
		System.out.println("Packet reception successful: rx_count = " + last_rx_count);
	}	
	
}

public void read() throws IOException {
  int i; 
  int count = 0;
  short crc;
  byte[] packet = new byte[MSG_SIZE]; 
  i = 0;
  while ((i = in.read()) != -1) {
    if(i == 0x7e || count != 0){
    	packet[count] = (byte)i;
    	System.out.print(Integer.toHexString(i&0xff) + " ");
    	//System.out.print(i + " ");
    	count++;
	if (count == MSG_SIZE) {
      		System.out.println();
      		count = 0;
		check_packet(packet);
	}
    }else{
	System.out.println("extra byte " + Integer.toHexString(i&0xff));
    }
  }
}


public int calcrc(byte[] packet, int count) 
{
    int crc=0, index=0;
    int i;
       
    while (count > 0) 
    {
        crc = crc ^ (int) packet[index] << 8;
	index++;
        i = 8;
        do
        {
            if ((crc & 0x8000) == 0x8000)
                crc = crc << 1 ^ 0x1021;
            else
                crc = crc << 1;
        } while(--i != 0);
	count --;
    }
    return (crc);
}

  //===========================================================================
  //===   MAIN    =============================================================

public static void main(String args[]) {
  if (args.length != 1) {
    System.err.println("usage: java hardware_check [port]");
    System.exit(-1);
  }

  System.out.println("\nhardware_check started");
  hardware_check reader = new hardware_check(args[0]);
  
  try {
    reader.printAllPorts();
    reader.open();
  }
  catch (Exception e) {
    e.printStackTrace();
  }

  try {
    Thread t = new Thread(reader);
    t.start();
    reader.read();
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

}
