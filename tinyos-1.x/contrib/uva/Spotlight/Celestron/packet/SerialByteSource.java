// $Id: SerialByteSource.java,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

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


package packet;

import java.util.*;
import java.io.*;
import javax.comm.*;

/**
 * A serial port byte source, with extra special hack to deal with
 * broken javax.comm implementations (IBM's javax.comm does not set the
 * port to raw mode, on Linux, at least in some implementations - call
 * an external program (tinyos-serial-configure) to "fix" this)
 */
public class SerialByteSource extends StreamByteSource implements SerialPortEventListener
{
    private SerialPort serialPort;
    private String portName;
    private int baudRate;
    java.util.HashSet listenerList = new java.util.HashSet() ;
	 private long seqNo= 0;	
	 	  
   	 
    public SerialByteSource(String portName, int baudRate) {
		this.portName = portName;
		this.baudRate = baudRate;
    }

    public SerialPort getSerialPort(){    
    	return serialPort;    
    }

    public void openStreams() throws IOException {
	CommPortIdentifier portId;
	try {
	    portId = CommPortIdentifier.getPortIdentifier(portName);
	}
	catch (NoSuchPortException e) {
	    throw new IOException("Invalid port. " + allPorts());
	}
	try {
	    serialPort = (SerialPort)portId.open("SerialByteSource",
						 CommPortIdentifier.PORT_SERIAL);
	}
	catch (PortInUseException e) {
	    throw new IOException("Port " + portName + " busy");
	}

	try {
	    serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
	    serialPort.setSerialPortParams(baudRate,
					   SerialPort.DATABITS_8,
					   SerialPort.STOPBITS_1,
					   SerialPort.PARITY_NONE);

	    serialPort.addEventListener(this);
	    serialPort.notifyOnDataAvailable(true);
	    serialPort.notifyOnCTS(true);
	    serialPort.notifyOnCarrierDetect(true);
	    serialPort.notifyOnDSR(true);



	}
	catch (Exception e) {
	    serialPort.close();
	    throw new IOException("Couldn't configure " + portName);
	}

	// Try & run external program to setup serial port correctly
	// (necessary on Linux, IBM's javax.comm leaves port in cooked mode)
	try {
	    Runtime.getRuntime().exec("tinyos-serial-configure " + portName);
	}
	catch (IOException e) { }

	is = serialPort.getInputStream();
	os = serialPort.getOutputStream();
    }

    public void closeStreams() throws IOException {
	serialPort.close();
    }

    public String allPorts() {
	Enumeration ports = CommPortIdentifier.getPortIdentifiers();
	if (ports == null)
	    return "No comm ports found!";

	boolean  noPorts = true;
	String portList = "Known serial ports:\n";
	while (ports.hasMoreElements()) {
	    CommPortIdentifier port = (CommPortIdentifier)ports.nextElement();

	    if (port.getPortType() == CommPortIdentifier.PORT_SERIAL) {
		portList += "- " + port.getName() + "\n";
		noPorts = false;
	    }
	}
	if (noPorts)
	    return "No comm ports found!";
	else
	    return portList;
    }

    Object sync = new Object();

    public byte readByte() throws IOException {
	// On Linux at least, javax.comm input streams are not interruptible.
	// Make them so, relying on the DATA_AVAILABLE serial event.
	synchronized (sync) {
	    while (is.available() == 0) {
		try {
		    sync.wait();
		}
		catch (InterruptedException e) {
		    close();
		    throw new IOException("interrupted");
		}
	    }
	}
   
   byte retval = super.readByte();
   /*
   PrintHexByte(retval);   
   */ 
	return retval;
    }

    public void serialEvent(SerialPortEvent ev) {
    	
      int EventType = 	ev.getEventType();
            
      switch(EventType){
		   case SerialPortEvent.DATA_AVAILABLE: 			   
				synchronized (sync) {
				    sync.notify();
				}
				
				java.util.Iterator notifyListIterator =  listenerList.iterator();
				while(notifyListIterator.hasNext()){
					((SerialPortEventListener)notifyListIterator.next()).serialEvent(ev);						                						                						              						                
				}
								
		   break;
		   default:

		   break;
		}	
    }
    
	public void registerSerialEventListener(SerialPortEventListener Listener){						
		listenerList.add(Listener);		
	}
	    
	public void removeSerialEventListener(SerialPortEventListener Listener){						
		listenerList.remove(Listener);		
	}

	private void PrintHexByte(byte b) {
		int i = (int) b;
		i = (i >= 0) ? i : (i + 256);
		System.out.print("["+Integer.toHexString(i / 16));
		System.out.print(Integer.toHexString(i % 16)+"]");
	}
				
}
