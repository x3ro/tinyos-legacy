/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Author: Jason Hill
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
  //System.out.println("done.");
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
  packet[4] = 29;
  packet[5] = (byte)(val & 0xf);
  packet[6] = (byte)(val & 0xf);
  packet[7] = (byte)(val & 0xf);
  packet[8] = 0x0;
  packet[9] = 0x0;
  packet[10] = 0x0;
	val ++;
  crc = (short) calcrc(packet,MSG_SIZE-2);
  packet[MSG_SIZE-2] = (byte) (crc & 0xff);
  packet[MSG_SIZE-1] = (byte) ((crc >> 8) & 0xff);
	int i;
	Thread.sleep(2000);
	out.write(packet);
        //System.out.print("Sending: ");
  	//for(i = 0; i < packet.length; i++) {
    		//System.out.print(Integer.toHexString(packet[i] & 0xff) + " ");
  	//}
  	//System.out.println();
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
	//System.out.println("Node async clock: passed");
	System.out.print("Node Serial ID: ");
	for(int i = 0; i < 8; i ++){
    		System.out.print(Integer.toHexString(packet[5 + i]&0xff) + " ");
	}
	System.out.println();
	//System.out.print("SPI rework: ");
	if(packet[16] == 0x5){
		//System.out.println("passed");
	}else{
		System.out.println("SPI rework failed");
	}
	//System.out.print("4Mbit flash check: ");
	if(packet[13] == 0x1 && (packet[14] & 0xff) == 0x8f && packet[15] == 0x9){
		//System.out.println("passed");
	}else{
		System.out.print("4Mbit flash check failed ");
		System.out.print(packet[13] + " ");
		System.out.print(packet[14] + " ");
		System.out.println(packet[15] + " ");
	}
	
                packet[0] = (byte)0xff;
                packet[1] = (byte)0xff;
  	short pack_crc = (short)((packet[MSG_SIZE-2]) & 0xff);
  	pack_crc |= packet[MSG_SIZE-1] << 8;
  	short crc = (short) calcrc(packet,MSG_SIZE-2);
	boolean crc_check = true;
	if(packet[20] == 1){
		//System.out.println("UART transmissison successful");
	}else{
		//System.out.println("RF transmissison successful");
		//System.out.print("Packet crc: ");
		if(crc == pack_crc){
			//System.out.println("passed");
		}else{
			//System.out.print("failed ");
			//System.out.print(crc + " ");
			//System.out.println(pack_crc + " ");
			crc_check = false;
		}
	}
	
	if(packet[18] > last_rx_count && crc_check){
		last_rx_count = packet[18];
		System.out.println("Hardware verification successful.");
                // : rx_count = " + last_rx_count);
		if (last_rx_count>0) System.exit(0);
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
    	//System.out.print(Integer.toHexString(i&0xff) + " ");
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
