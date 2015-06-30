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
import Surge.PacketAnalyzers.*;
//import Surge.PacketAnalyzers.Location.*;
import Surge.PacketRecievers.*;
import Surge.Dialog.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;


public class MainClass
{
	          //create static variables like data readers, etc
	          //These variables can then be accessed by anybody via e.g. MainClass.nodes
	public static MainClass mainClass;
	public static MainFrame mainFrame;
	public static DisplayManager displayManager;//these three objects are given
	public static ObjectMaintainer objectMaintainer;//special variable names
	public static LocationAnalyzer locationAnalyzer;//because they are critical to the functioning of the system.  All other PacketAnalyzers should just be added to the PacketAnalyzer list
	public static Vector packetRecievers;
	public static Vector packetAnalyzers;
	                                             
	          //*****---MAIN---******//
	public static void main(String[] args) 
	{
		      mainClass = new MainClass();  //Create new Surge application
		      
	} 
	          //*****---MAIN---******//



	          //*****---CONSTRUCTOR---******//
	public MainClass()
	{
		//instantiate all the static variables
		        
              //instantiate MainFrame before MouseEvent Generator
		mainFrame = new MainFrame("Surge");
		displayManager = new DisplayManager(mainFrame);
			
		packetRecievers = new Vector();
		packetAnalyzers = new Vector();	
		      
		      //be sure to create all packet recievers first
		packetRecievers.add(new SerialPortPacketReciever(SerialPortPacketReciever.SERIAL_PORT));
		packetRecievers.add(new HistoryPacketReciever());//make sure to put the history reciever last
	
			  //then create the object maintainer (which registers with the packetRecievers for new packets)
		objectMaintainer = new ObjectMaintainer();
		
		      //then register the display manager with the objectMaintainer (you can't do this until the object maintainer is intantiated)
		objectMaintainer.AddEdgeEventListener(displayManager);
		objectMaintainer.AddNodeEventListener(displayManager);
		
		  //then create the packet analyzers last (which register with the ObjectMaintainer and the DisplayManager)
		locationAnalyzer = new GridLocationAnalyzer();

		packetAnalyzers.add(objectMaintainer);
		packetAnalyzers.add(locationAnalyzer);
		      //add your PacketAnalyzers here:
		packetAnalyzers.add(new LightAnalyzer());
			
			  //make the MainFrame visible as the last thing
		mainFrame.setVisible(true);
				//this thread ends here.  other threads have just been created to wait for packets or user events
              
              
              
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


				//------------------------------------------------------------------------
			  //*****---SHOW OPTIONS DIALOG---******//
//this function displays the dialog showing all node properties
	public static void ShowOptionsDialog()
	{
		TabbedDialog optionsDialog = new TabbedDialog("Surge Options");		
		ActivePanel currentPanel;
		PacketReciever reciever;
		PacketAnalyzer analyzer;

		currentPanel = displayManager.GetOptionsPanel();
		if(currentPanel != null)//if you don't have proprietary info, return a null panel
		{
			optionsDialog.AddActivePanel(currentPanel.GetTabTitle(), currentPanel);
		}
		for(Enumeration e = packetRecievers.elements(); e.hasMoreElements();)
		{
			reciever = ((PacketReciever)e.nextElement());
			currentPanel = reciever.GetOptionsPanel();
			if(currentPanel != null)//if you don't have proprietary info, return a null panel
			{
				optionsDialog.AddActivePanel(currentPanel.GetTabTitle(), currentPanel);
			}
		}
		for(Enumeration e = packetAnalyzers.elements(); e.hasMoreElements();)
		{
			analyzer = ((PacketAnalyzer)e.nextElement());
			currentPanel = analyzer.GetOptionsPanel();
			if(currentPanel != null)//if you don't have proprietary info, return a null panel
			{
				optionsDialog.AddActivePanel(currentPanel.GetTabTitle(), currentPanel);
			}
		}
		optionsDialog.setModal(false);
		optionsDialog.show();
	}
			  //*****---SHOW OPTIONS DIALOG---******//
	          //------------------------------------------------------------------------


	//{{DECLARE_CONTROLS
	//}}
}