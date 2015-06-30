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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001 
*/

//***********************************************************************
//***********************************************************************
//this is the main class that holds all global variables
//and from where "main" is run.
//the global variables can be accessed as: MainClass.MainFrame for example.
//***********************************************************************
//***********************************************************************

package Surge;

import java.util.*;
import Surge.event.*;
import Surge.util.*;
import Surge.PacketAnalyzer.*;
import Surge.PacketAnalyzer.Location.*;
import Surge.PacketReciever.*;
import Surge.Dialog.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;
import java.io.*;

public class MainClass
{
	          //create static variables like data readers, etc
	          //These variables can then be accessed by anybody via e.g. MainClass.nodes
	public static MainClass mainClass;
	public static MainFrame mainFrame;
	public static DisplayManager displayManager;//these three objects are given
	public static ObjectMaintainer objectMaintainer;//special variable names
	public static LocationAnalyzer locationAnalyzer;//because they are critical to the functioning of the system.  All other PacketAnalyzers should just be added to the PacketAnalyzer list
	public static LightAnalyzer lightAnalyzer;
	public static TemperatureAnalyzer tempAnalyzer;
	public static VoltageAnalyzer voltageAnalyzer;
	public static PacketAnalyzer currentAnalyzer;

	public static Vector packetRecievers;
	public static Vector packetAnalyzers;
    public static Thread injectThread;
	          //*****---MAIN---******//
	public static void main(String[] args) 
	{
	    try {
		mainClass = new MainClass();  //Create new Surge application
	    } catch (Exception e) {
		System.err.println("Failed to instantiate MainClass");
		e.printStackTrace();
		System.exit(-1);
	    }
	  
		      
	} 
	          //*****---MAIN---******//



	          //*****---CONSTRUCTOR---******//
	public MainClass() throws IOException
	{
		//instantiate all the static variables
		        
		PacketReciever pr;
		// pr = new SerialPortPacketReciever("COM1");
		pr = new SerialForwarderReciever("10.212.2.22", 9000);
              //instantiate MainFrame before MouseEvent Generator
		mainFrame = new MainFrame("Surge", pr);
		displayManager = new DisplayManager(mainFrame);
			
		packetRecievers = new Vector();
		packetAnalyzers = new Vector();	
		      
		      //be sure to create all packet recievers first
		//packetRecievers.add(new SerialPortPacketReciever(SerialPortPacketReciever.SERIAL_PORT));

		packetRecievers.add(pr);
		
		injectThread = new Thread(new Inject(pr));
		injectThread.setDaemon(true);
		injectThread.start();
		
		//packetRecievers.add(new MadeUpPackets());
	
			  //then create the object maintainer (which registers with the packetRecievers for new packets)
		objectMaintainer = new ObjectMaintainer();
		
		      //then register the display manager with the objectMaintainer (you can't do this until the object maintainer is intantiated)
		objectMaintainer.AddEdgeEventListener(displayManager);
		objectMaintainer.AddNodeEventListener(displayManager);
		
		  //then create the packet analyzers last (which register with the ObjectMaintainer and the DisplayManager)
		locationAnalyzer = new LocationAnalyzer();
		currentAnalyzer = lightAnalyzer = new LightAnalyzer();
		tempAnalyzer = new TemperatureAnalyzer();
		voltageAnalyzer = new VoltageAnalyzer();

		packetAnalyzers.add(objectMaintainer);
		// packetAnalyzers.add(locationAnalyzer);
		// packetAnalyzers.add(new NetworkRoutingAnalyzer());
		// packetAnalyzers.add(new LightAnalyzer());
		// packetAnalyzers.add(new TemperatureAnalyzer());
		// packetAnalyzers.add(new VoltageAnalyzer());
			
			  //make the MainFrame visible as the last thing
		mainFrame.setVisible(true);
				//this thread ends here.  other threads wait for packets or user events
              
              
              
		//try {
		    // Add the following code if you want the Look and Feel
		    // to be set to the Look and Feel of the native system.
		    /*
		    try {
		        UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		    } 
		    catch (Exception e) { 
		    }
		    */

			//Create a new instance of our application's frame, and make it visible.
		/*	(new MainFrame()).setVisible(true);
		} 
		catch (Throwable t) {
			t.printStackTrace();
			//Ensure the application exits with an error condition.
			System.exit(1);
		}*/
	
		
		
	}
	          //*****---CONSTRUCTOR---******//
	          //--------------------------------------------------------
	
	          //*****---ADD PACKET EVENT LISTENERS---******//
	          //this code could be changed to listen only to specific types of packet events
	          //It currently adds you to listen to all packets from all packetRecievers
	public  static void AddPacketEventListener(Surge.event.PacketEventListener listener)
	{
		PacketReciever currentReciever;
		for (Enumeration recievers = packetRecievers.elements(); recievers.hasMoreElements() ;) 
		{
			currentReciever = (PacketReciever)recievers.nextElement();
			currentReciever.AddPacketEventListener(listener);
		}
	}
	
	          
	public  static void RemovePacketEventListener(Surge.event.PacketEventListener listener)
	{
		PacketReciever currentReciever;
		for (Enumeration recievers = packetRecievers.elements(); recievers.hasMoreElements() ;) 
		{
			currentReciever = (PacketReciever)recievers.nextElement();
			currentReciever.RemovePacketEventListener(listener);
		}
	}
	//*****---ADD PACKET EVENT LISTENERS---******//


	//{{DECLARE_CONTROLS
	//}}
}
