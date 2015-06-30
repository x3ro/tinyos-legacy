//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/CelestronConnector.java,v 1.1.1.1 2005/05/10 23:37:05 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Radu Stoleru
// Date: 3/26/2005

import java.io.*;
import java.util.Enumeration;
import java.util.Observable;
import java.util.TooManyListenersException;

import javax.comm.CommPortIdentifier;
import javax.comm.PortInUseException;
import javax.comm.SerialPort;
import javax.comm.SerialPortEvent;
import javax.comm.SerialPortEventListener;
import javax.comm.UnsupportedCommOperationException;

public class CelestronConnector extends Observable implements Runnable, 
SerialPortEventListener {
	
	static CommPortIdentifier portId;
	static Enumeration	      portList;
	InputStream		          inputStream;
	static OutputStream       outputStream;
	SerialPort		          serialPort;
	Thread		              readThread;
	PacketListenerIF          listener;
	byte[] tempPacket = new byte[40];
	int previousBytes;
	
	public CelestronConnector(){		
		connectSerial();
	}
	
	/****************************************************************/
	public void sendMessage(byte[] message){		
		try {
			outputStream.write(message);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	/****************************************************************/
	void connectSerial() {
		portList = CommPortIdentifier.getPortIdentifiers();
		
		while (portList.hasMoreElements()) {
			portId = (CommPortIdentifier) portList.nextElement();
			
			if (portId.getPortType() == CommPortIdentifier.PORT_SERIAL) {
				
				if (portId.getName().equals(Constants.CELESTRON_COM_PORT)) {
					
					try {
						serialPort = (SerialPort) portId.open("CelestronConnector",
								2000);
					} catch (PortInUseException e) {
						e.printStackTrace();
					}
					
					try {
						inputStream = serialPort.getInputStream();
					} catch (IOException e) {
						e.printStackTrace();	
					}
					
					try {
						outputStream = serialPort.getOutputStream();
					} catch (IOException e) {
						e.printStackTrace();	
					}
					
					try {
						serialPort.addEventListener(this);
					} catch (TooManyListenersException e) {
						e.printStackTrace();	
					}
					
					serialPort.notifyOnDataAvailable(true);
					
					try {
						serialPort.setSerialPortParams(9600, SerialPort.DATABITS_8, 
								SerialPort.STOPBITS_1, 
								SerialPort.PARITY_NONE);
					} catch (UnsupportedCommOperationException e) {
						e.printStackTrace();
					}
					
					readThread = new Thread(this);
					
					readThread.start();
				}
			}
		}
	}
	
	/****************************************************************/
	void disconnectSerial() {
		try {
			serialPort.close();
		}
		catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	/****************************************************************/
	public void run() {
		try {
			Thread.sleep(20000);
		} catch (InterruptedException e) {
			e.printStackTrace();	
		}
	}
	
	/****************************************************************/
	public void serialEvent(SerialPortEvent event) {
		switch (event.getEventType()) {
		
		case SerialPortEvent.BI:
		case SerialPortEvent.OE:
		case SerialPortEvent.FE:
		case SerialPortEvent.PE:
		case SerialPortEvent.CD:
		case SerialPortEvent.CTS:
		case SerialPortEvent.DSR:
		case SerialPortEvent.RI:
		case SerialPortEvent.OUTPUT_BUFFER_EMPTY:
			break;
		case SerialPortEvent.DATA_AVAILABLE: {
			byte[] readBuffer = new byte[20];
			byte[] packet = null;
			
			int numBytes = 0;
			
			try {
				while (inputStream.available() > 0) {
					numBytes = inputStream.read(readBuffer);
				} 
				
				// debugging		
				System.out.print("[In ]");
				for (int k = 0; k < numBytes; k++) {
					System.out.print((char) readBuffer[k]);
					//packet[k] = readBuffer[k];
					System.out.print(" ");
				}
				System.out.println();
				
				if(readBuffer[numBytes-1] == '#') {
					packet = new byte[previousBytes+numBytes];
					// copy the previous data
					for(int i = 0; i < previousBytes; i++)
						packet[i] = tempPacket[i];
					for(int i = 0; i < numBytes; i++)
						packet[previousBytes+i] = readBuffer[i];
					
					// clean the temp space
					previousBytes = 0;
					for(int i = 0; i < tempPacket.length; i++)
						tempPacket[i] = 0;
					
					// notify
					listener.packetReceived(packet, Constants.CELESTRON);
				} else {
					for(int i = 0; i < numBytes; i++)
						tempPacket[previousBytes++] = readBuffer[i];
				}
				
			} catch (IOException e) {
				e.printStackTrace();
			}
			
			break; }
		}
		
	}
	
	public void registerPacketListener(PacketListenerIF packetListener) {		
		listener = packetListener;
	}
	
}



