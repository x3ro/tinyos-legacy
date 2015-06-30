/* "Copyright (c) 2001 and The Regents of the University  
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
* 
* Authors:   Mike Chen
*			 Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created as listen October 22, 2000
*			 Modified by Kamin to work with Surge 2.0 7/22/2001 
*/

//*********************************************************
//*********************************************************
//this class reads the data packets directly out of the serial port
//and generates packet events for each packet recieved.
//it runs in the background on its own thread.
//*********************************************************
//*********************************************************

package Surge.PacketReciever;

import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;
import java.io.*;
import javax.comm.*;
import Surge.Packet.*;

public class SerialPortPacketReciever extends PacketReciever 
{
	protected static final String  CLASS_NAME                  = "listen";
	protected static final String  VERSION     	         = "v0.1";
	public static final String SERIAL_PORT = "COM1";
	protected static final int SEARCH_BYTE = 0x7e;
	
	protected CommPortIdentifier portId;
	protected SerialPort port;
	protected String portName;
	protected InputStream in;
	protected OutputStream out;
	DataSender d;

	          //*****---CONSTRUCTOR---******//
	          //THe constructor opens the ports and spawns a new thread
	public SerialPortPacketReciever(String portName) 
	{
		this.portName = portName;
		System.out.println("\nlisten started");
		try {
    		printAllPorts();
    		open();
			}
		catch (Exception e) 
		{
    		e.printStackTrace();
		}
		recievePacketsThread = new Thread(this);
		try{
			recievePacketsThread.setPriority(Thread.NORM_PRIORITY);
			recievePacketsThread.start(); //recall that start() calls the run() method defined in this class
		}
		catch(Exception e){e.printStackTrace();}
	}
	          //*****---CONSTRUCTOR---******//


	          //*****---OPEN---******//
	public void open() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException 
	{
	portId = CommPortIdentifier.getPortIdentifier(portName);
	port = (SerialPort)portId.open(CLASS_NAME, 0);
	in = port.getInputStream();
	out = port.getOutputStream();

	//	port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN);
	//	port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_OUT);
  port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);

	printPortStatus();
	port.setSerialPortParams(19200, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
	printPortStatus();
	//System.out.write('4');
	//out.write('4');
	printPortStatus();
	//	d = new DataSender(out);
	//d.sendPacket();
	}
	          //*****---OPEN---******//

	          //*****---PRINTPORTSTATUS---******//
	private void printPortStatus() {
	System.out.println("baud rate: " + port.getBaudRate());
	System.out.println("data bits: " + port.getDataBits());
	System.out.println("stop bits: " + port.getStopBits());
	System.out.println("parity:    " + port.getParity());
	}
	          //*****---Print Port STATUS---******//


	          //*****---PRINT ALL PORTS---******//

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
	          //*****---PRINT ALL PORTS---******//

	          //*****---RUN---******//
	public void run() //throws IOException
	{
		int i; 
		int count = 0;
		byte[] packet = new byte[Packet.NUMBER_OF_BYTES];

		try
		{
		    //	Thread t = new Thread(d);
		    //			t.setPriority(Thread.MAX_PRIORITY);
		    //			t.start();
			while(true)
			{
				while ((i = in.read()) != -1) 
				{
    				if( ( (i == SEARCH_BYTE) && (count == 0))
    					|| (count != 0))
    				{
    					packet[count] = (byte)i;
    					//System.out.print(Hex.toHex(i) + " ");
    					System.out.print(i + " ");
    					count++;
						if (count == Packet.NUMBER_OF_BYTES) 
						{
      						System.out.println();//here is where we trigger a new packetEvent
						Packet p  = new Packet(packet);
						if(p.isValid()){
      							TriggerPacketEvent(new PacketEvent(this, p, Calendar.getInstance().getTime()));//for each new packet recieved, trigger a new packetEvent
						}else{
							System.out.println("invalid packet");
						}
							count = 0;
						}
    				}
    				else
    				{
						System.out.println("extra byte " + Hex.toHex(i));
    				}
				}
				i = 1;
			}
		}
		catch(Exception e){e.printStackTrace();}
	}
          //*****---RUN---******//
	
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

    public synchronized void write(byte [] pack) throws IOException{
	short crc = calculateCRC(pack);
	pack[pack.length-1] = (byte) ((crc >> 8) & 0xff);
	pack[pack.length-2] = (byte) (crc & 0xff);
	out.write(pack);
    }
	
	
}
