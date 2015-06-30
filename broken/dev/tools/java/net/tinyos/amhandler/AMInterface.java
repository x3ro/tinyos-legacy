/*									tab:4
 * AMInterface.java
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 */
package net.tinyos.amhandler;

import java.util.*;
import java.io.*;
import javax.comm.*;


import net.tinyos.schema.*;

/**
 * 
 * Class to interface to the tos active message layer via a desktop
 * computer's serial port.  A generic_base mote must be connected
 * the specified port.
 */


public class AMInterface {
    
    /** expected size of active messgae data field */
    public final static int AM_SIZE = 36;
    /** no of bytes in AM headers */
    public final static int AM_HEADER_SIZE = 5;
  /** no of bytes at end of AM  -- for  CRC -- unsupported */
  public final static int AM_FOOTER_SIZE = 2;

    /** total size of an AM */
    private final static int AM_BUFFER_SIZE = AM_SIZE + AM_HEADER_SIZE + AM_FOOTER_SIZE;
    
    private final static int AM_ADDR_LO_BYTE = 0;
    private final static int AM_ADDR_HI_BYTE = 1;
    private final static int AM_TYPE_BYTE = 2;
    private final static int AM_GROUP_BYTE = 3;
    private final static int AM_LENGTH_BYTE = 4;

    /** local group for the receiver */
    public static byte LOCAL_GROUP = (byte)0x7D; //(byte)0x66;
    /** broadcast address constant */
    public static final byte TOS_BCAST_ADDR_LO = (byte)0xFF;
    public static final byte TOS_BCAST_ADDR_HI = (byte)0xFF;

    public static final short TOS_BCAST_ADDR = (short)0xFFFF;
    
    private static final String  CLASS_NAME                  = "listen";
    
    CommPortIdentifier portId;
    SerialPort port;
    String portName;
    InputStream in;
    OutputStream out;
    
    Hashtable handlers = new Hashtable();
    Thread pollerThread = null;
    boolean isOpen = false;
    boolean send_crc = false;
    boolean rcv_crc = false;

    /** create a new AM listener on a specfic port
	@param portName The port to listen on e.g. "COM1" or "COM2"
	@param crc Compute checksum on outgoing messages 
	           and incoming messages.
    */
    public AMInterface(String portName, boolean crc) {
	this(portName, crc,crc);
    }

    /** create a new AM listener on a specfic port
	@param portName The port to listen on e.g. "COM1" or "COM2"
	@param send_crc Compute CRC on outgoing messages
	@param rcv_crc Compute CRC on incoming messages
    */
    public AMInterface(String portName, boolean send_crc, boolean rcv_crc) {
	this.portName = portName;
	this.send_crc = send_crc;
	this.rcv_crc = rcv_crc;
    }

    /** create a new AM listener on a specfic port
	@param portName The port to listen on e.g. "COM1" or "COM2"
	@param send_crc Compute CRC on outgoing messages
	@param rcv_crc Compute CRC on incoming messages
	@param group_id Group id to use
    */
    public AMInterface(String portName, boolean send_crc, boolean rcv_crc, byte groupId) {
	this.portName = portName;
	this.send_crc = send_crc;
	this.rcv_crc = rcv_crc;
	this.LOCAL_GROUP = groupId;
    }
  

    /** start listening for messages on the port passed into the constructor
     @throws NoSuchPortException if javax.comm doesn't know about this port
     @throws PortInUseException if the port is busy or the user doesn't have
     permissions to access it.
     @throws IOException if the port can't be parameterized properly
    */
    public void open() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException {
	portId = CommPortIdentifier.getPortIdentifier(portName);
	port = (SerialPort)portId.open(CLASS_NAME, 0);
	in = port.getInputStream();
	out = port.getOutputStream();
	
	port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
	port.disableReceiveFraming();
	//port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_OUT);
	//port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN);
	
	printPortStatus();
	port.setSerialPortParams(19200, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
	printPortStatus();

	isOpen = true;
    }
  
    private void printPortStatus() {
	System.out.println("baud rate: " + port.getBaudRate());
	System.out.println("data bits: " + port.getDataBits());
	System.out.println("stop bits: " + port.getStopBits());
	System.out.println("parity:    " + port.getParity());
    }

  
    /**
     *  Print to stdout all ports on the machine. 
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
  
  
    /** Add an AMHandler to this AMInterface.  This handler will be
	called whenever an active message of type id arrives.
	@param handler The handler to invoke
	@param id The type of active message this handler applies to
    */
    public void registerHandler(AMHandler handler, byte id) {
	Vector handlerList = (Vector)handlers.get(new Byte(id));
	if (handlerList == null) {
	    handlerList = new Vector();
	    handlers.put(new Byte(id), handlerList);
	} 
	handlerList.addElement(handler);    
    
	if (pollerThread == null && isOpen) {
	    AMPoller poller = new AMPoller();
	    pollerThread = new Thread(poller);
	    pollerThread.start();
	}
    }
  
    /** Output an active message of the specified type (id), sending
	to the specified address.
	@param data The bytes to send
	@param id The type of the active message
	@param addr The address of the recipient of the message
    */
    public void sendAM(byte[] data, byte id, short addr) throws IOException {
	byte packet[] = new byte[AM_BUFFER_SIZE];
    
	if (data.length > AM_SIZE) {
	    throw new IOException("Message too long.");
	}
    
	packet[AM_ADDR_LO_BYTE] = (byte)(addr & 0x00FF);
	packet[AM_ADDR_HI_BYTE] = (byte)((addr >> 8) & 0x00FF);
	packet[AM_TYPE_BYTE] = id;
	packet[AM_GROUP_BYTE] = LOCAL_GROUP;
	packet[AM_LENGTH_BYTE] = AM_SIZE;
	for (int i = 0; i  < data.length ; i++) {
	    packet[AM_LENGTH_BYTE + i + 1] = data[i];
	}
    
	writePacket(packet);
    
    }
  
    private byte[] readPacket() throws IOException {
	int i; 
	int count = 0;
	byte[] packet = new byte[AM_BUFFER_SIZE];
    
	while ((i = in.read()) != -1) {
	    if(i == 0x7e || count != 0){
		//System.out.println("start of packet.");
		packet[count] = (byte)i;
		count++;
		if (count == AM_BUFFER_SIZE) return packet;
		
	    }
	    //	    System.out.print(i + ",");
	}
	throw new IOException("Unexpected end of stream.");
    }
  
  
    private void writePacket(byte[] packet) throws IOException {
	//	System.out.print("Writing:");
	if (send_crc) preparePacket(packet);
	for (int i = 0; i < AM_BUFFER_SIZE; i++) {
	    out.write(packet[i]);
	    //  System.out.print(packet[i] + ",");
	}
	//System.out.println("");
	out.flush();

    }

 
    short calcrc(byte packet[])
    {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 2;
	crc = 0;
	while (--count >= 0) 
	    {
		crc = (short) (crc ^ ((short) (packet[index++]) << 8));
		i = 8;
		do
		    {
			if ((crc & 0x8000) != 0)
			    crc = (short)(crc << 1 ^ ((short)0x1021));
			else
			    crc = (short)(crc << 1);
		    } while(--i>0);
	    }
	return (crc);
    }

    synchronized void preparePacket(byte [] packet)  throws IOException{
	short crc;
	crc = calcrc(packet);
	packet[packet.length-1] = (byte) ((crc>>8) & 0xff);
	packet[packet.length-2] = (byte) (crc & 0xff);
    }

  
    class AMPoller implements Runnable {
	public AMPoller() {
      
	}
    
	public void run() {
	    while (true) {
		try {
		    byte[] bytes = readPacket();
		    if (rcv_crc) {
			bytes[0] = -1;
			bytes[1] = -1;
			short crc = calcrc(bytes);

			//			System.out.println("crc 0 = " + (byte)(crc & 0xFF) + ", crc 1 = " + (byte)((crc >> 8) & 0xFF) + ", byte 0 = " +  bytes[bytes.length-2] + ", byte 1 = " 
				//	   + bytes[bytes.length-1]);
			if ((byte)(crc>>8 & 0xFF)  != bytes[bytes.length-1]
			  || (byte)(crc & 0xFF) != bytes[bytes.length-2]) { //crc failure 
			    System.out.print('-');
			    continue;
			}
		    }
		    byte data[] = new byte[bytes[AM_LENGTH_BYTE]];
		    
		    byte type = bytes[AM_TYPE_BYTE];
		    short addr = (short)(((((short)bytes[AM_ADDR_HI_BYTE]) << 8) & 0xFF00) + (short)bytes[AM_ADDR_LO_BYTE]);
		    for (int i = 0 ; i < bytes[AM_LENGTH_BYTE]; i ++) {
			data[i] = bytes[i + AM_LENGTH_BYTE + 1];
		    }
		    Vector handlerList = (Vector)handlers.get(new Byte(type));
		    if (handlerList != null) {
			Enumeration e = handlerList.elements();
			AMHandler handler;
			while (e.hasMoreElements()) {
			    handler = (AMHandler)e.nextElement();
			    handler.handleAM(data, addr , bytes[AM_TYPE_BYTE], bytes[AM_GROUP_BYTE]);
			}
		    }
		} catch (Exception e) {

		    System.out.println("Read failed; trying again:" + e);
		    e.printStackTrace();
		}
	    }
	}   

    }


}

