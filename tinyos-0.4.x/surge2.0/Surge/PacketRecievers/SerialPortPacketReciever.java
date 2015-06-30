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

package Surge.PacketRecievers;

import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;
import java.io.*;
import javax.comm.*;
import Surge.Packet.*;
import java.awt.event.*;
import javax.swing.*;

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
	protected MenuManager menuManager;

	          //*****---CONSTRUCTOR---******//
	          //THe constructor opens the ports and spawns a new thread
	public SerialPortPacketReciever(String portName) 
	{
		menuManager = new MenuManager();
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

	port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN);
	port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_OUT);

	printPortStatus();
	port.setSerialPortParams(19200, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
	printPortStatus();
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
			while(true)
			{
				while ((i = in.read()) != -1) 
				{
    				if( ( (i == SEARCH_BYTE) && (count == 0))
    					|| (count != 0))
    				{
						packet[count] = (byte)i;
//    					System.out.print(Hex.toHex(i) + " ");
    					//System.out.print(i + " ");
    					count++;
						if (count == Packet.NUMBER_OF_BYTES) 
						{
							//System.out.println();
      						TriggerPacketEvent(new PacketEvent(this, new Packet(packet), Calendar.getInstance().getTime()));//for each new packet recieved, trigger a new packetEvent
							System.out.println(Hex.toHex(packet));
							packet = new byte[Packet.NUMBER_OF_BYTES];
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
	
	
	
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //MENU MANAGER
              //This class creates and holds the menu that controls this
              //PacketAnalyzer.  It returns the menu to whoever wants
              //to display it and it also handles all events on the menu
	protected class MenuManager implements /*Serializable,*/ ActionListener, ItemListener
	{
			//{{DECLARE_CONTROLS
		JMenu mainMenu = new JMenu();
		JCheckBoxMenuItem receivePacketsCheckBox = new JCheckBoxMenuItem();
		JSeparator separator1 = new JSeparator();
		JMenuItem propertiesItem = new JMenuItem();
		//}}
	
		public MenuManager()
		{
			//{{INIT_CONTROLS
			mainMenu.setText("Serial Port Packets");
			mainMenu.setActionCommand("Serial Port Packets");
			receivePacketsCheckBox.setSelected(true);
			receivePacketsCheckBox.setText("Receive Packets");
			receivePacketsCheckBox.setActionCommand("Receive Packets");
			mainMenu.add(receivePacketsCheckBox);
			mainMenu.add(separator1);
			propertiesItem.setText("Options");
			propertiesItem.setActionCommand("Options");
			mainMenu.add(propertiesItem);
			MainClass.mainFrame.PacketReadersMenu.add(mainMenu);//this last command adds this entire menu to the main PacketAnalyzers menu
			//}}

			//{{REGISTER_LISTENERS
			receivePacketsCheckBox.addItemListener(this);
			propertiesItem.addActionListener(this);
			//}}
		}

		      //----------------------------------------------------------------------
		      //EVENT HANDLERS
		      //The following two functions handle menu events
		      //The functions following this are the event handling functions
		public void actionPerformed(ActionEvent e)
		{
			Object object = e.getSource();
//			if (object == propertiesItem)
//				ShowOptionsDialog();
		}

		public void itemStateChanged(ItemEvent e)
		{
			Object object = e.getSource();
			if (object == receivePacketsCheckBox)
				ToggleReceivePackets();
		}		
		      //EVENT HANDLERS
		      //----------------------------------------------------------------------

		      //------------------------------------------------------------------------
		      //****---TOGGLE Receive Packets
		      //This function will either start or stop the background thread 
		public void ToggleReceivePackets()
		{
			if(receivePacketsCheckBox.isSelected())
			{ 
				start();
			}
			else
			{
				stop(); 
			}
		}
		      //****---TOGGLE Receive Packets
		      //------------------------------------------------------------------------
				
	}	          
              //MENU MANAGER
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************

	
}