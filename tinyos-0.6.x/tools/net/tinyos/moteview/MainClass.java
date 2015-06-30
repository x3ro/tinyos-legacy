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

package net.tinyos.moteview;

import java.util.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.util.*;
import net.tinyos.moteview.PacketAnalyzers.*;
import net.tinyos.moteview.PacketRecievers.*;
import net.tinyos.moteview.PacketSenders.*;
import net.tinyos.moteview.Dialog.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;

/** The main entry point for the Surge Application.  Call 'java net.tinyos.moteview.MainClass'.
 * @author Joe Polastre
 * @author Kamin Whitehouse
 */
public class MainClass
{
        //create static variables like data readers, etc
        //These variables can then be accessed by anybody via e.g. MainClass.nodes
	public static MainClass mainClass;
	public static MainFrame mainFrame;
	public static DisplayManager displayManager;//these three objects are given
	public static ObjectMaintainer objectMaintainer;//special variable names
	public static LocationAnalyzer locationAnalyzer;//because they are critical to the functioning of the system.  All other PacketAnalyzers should just be added to the PacketAnalyzer list
	public static Reprogramming reprogramming;
        public static GenericSensor genericSensor;
	public static Vector packetRecievers;
        public static Vector packetSenders;
	public static Vector packetAnalyzers;
        public static Configuration configuration;
        public static boolean DEBUG = false;
        public static boolean VERBOSE = false;

        public static final String APP_PATH = "net/tinyos/moteview/apps";
    //public static String host = "localhost";
    public static String host = "192.168.2.21";
    //    public static String host = "10.212.2.81";
        public static int port = 9000;
	protected static Vector optionPanelContributors;


        /** the entry point for surge
         */
	public static void main(String[] args)
	{
	    String configFile = "moteview.conf";
	    if (args.length > 0)
	    {
		if (args[0].equals("--help"))
		{
		    System.out.println("java net.tinyos.moteview.MainClass [configfile]");
		    System.exit(0);
		}
		else
		{
		    configFile = args[0];
		}
            }

            mainClass = new MainClass(configFile);  //Create new Surge application

	}


        /** Default Constructor.  Sets up all readers, analyzers, senders, object maintainers, etc for Surge
         * @param configFile the file name of the Surge configuration file
         */
	public MainClass(String configFile)
	{

	    //instantiate all the static variables
	    packetRecievers = new Vector();
            packetSenders = new Vector();
	    packetAnalyzers = new Vector();
	    optionPanelContributors = new Vector();

            //instantiate MainFrame before MouseEvent Generator
	    mainFrame = new MainFrame("MoteView");
	    displayManager = new DisplayManager(mainFrame);

	    // read the configuration file
	    ConfigFileReader cfr = new ConfigFileReader(configFile);
	    configuration = cfr.getConfiguration();
	    Vector pr = configuration.getPacketReaders();

	    ClassLoader cl = ClassLoader.getSystemClassLoader();

	    // create packet readers
	    MainClass.out("PACKET READERS:");
	    for (int i = 0; i < pr.size(); i++)
	    {
		try {
		    Class cClass = cl.loadClass((String)pr.elementAt(i));
		    packetRecievers.add((PacketReciever)cClass.newInstance());
		    MainClass.out("Packet Reader: " + (String)pr.elementAt(i) + " loaded");
		}
		catch (ClassNotFoundException e)
		{
		    System.err.println("Packet Reader Not Found: " + (String)pr.elementAt(i));
		}
		catch (InstantiationException e)
		{
		    System.err.println("Unable to instantiate Packet Reader: " + (String)pr.elementAt(i));
		}
		catch (Exception e)
		{
		    e.printStackTrace();
		}
	    }

	    // create packet senders
	    pr = configuration.getPacketSenders();
	    System.out.println("\nPACKET SENDERS:");
	    for (int i = 0; i < pr.size(); i++)
	    {
		try {
		    Class cClass = cl.loadClass((String)pr.elementAt(i));
		    packetSenders.add((PacketSender)cClass.newInstance());
		    MainClass.out("Packet Sender: " + (String)pr.elementAt(i) + " loaded");
		}
		catch (ClassNotFoundException e)
		{
		    System.err.println("Packet Sender Not Found: " + (String)pr.elementAt(i));
		}
		catch (InstantiationException e)
		{
		    System.err.println("Unable to instantiate Packet Sender: " + (String)pr.elementAt(i));
		}
		catch (Exception e)
		{
		    e.printStackTrace();
		}
	    }

	    //then create the object maintainer (which registers with the packetRecievers for new packets)
	    objectMaintainer = new ObjectMaintainer();
	    objectMaintainer.AddEdgeEventListener(displayManager);
	    objectMaintainer.AddNodeEventListener(displayManager);

	    // locationAnalyzer = new MassSpringsLocationAnalyzer();
	    reprogramming = new Reprogramming ( );
            genericSensor = new GenericSensor ( );
	    packetAnalyzers.add(objectMaintainer);


	    // create packet analyzers
	    /*
	    pr = configuration.getPacketAnalyzers();
	    System.out.println("\nPACKET ANALYZERS:");
	    for (int i = 0; i < pr.size(); i++)
	    {
		try {
		    Class cClass = cl.loadClass((String)pr.elementAt(i));
		    packetAnalyzers.add((PacketAnalyzer)cClass.newInstance());
		    MainClass.out("Packet Analyzer: " + (String)pr.elementAt(i) + " loaded");
		}
		catch (ClassNotFoundException e)
		{
		    System.err.println("Packet Analyzer Not Found: " + (String)pr.elementAt(i));
		}
		catch (InstantiationException e)
		{
		    System.err.println("Unable to instantiate Packet Analyzer: " + (String)pr.elementAt(i));
		}
		catch (Exception e)
		{
		    e.printStackTrace();
		}
	    }*/

            mainFrame.setVisible(true);
	}

        //*****---ADD PACKET EVENT LISTENERS---******//
        //this code could be changed to listen only to specific types of packet events
        //It currently adds you to listen to all packets from all packetRecievers
	public  static void AddPacketEventListener(net.tinyos.moteview.event.PacketEventListener listener)
	{
		PacketReciever currentReciever;
		for (Enumeration recievers = packetRecievers.elements(); recievers.hasMoreElements() ;)
		{
			currentReciever = (PacketReciever)recievers.nextElement();
			currentReciever.AddPacketEventListener(listener);
		}
	}


	public static void RemovePacketEventListener(net.tinyos.moteview.event.PacketEventListener listener)
	{
		PacketReciever currentReciever;
		for (Enumeration recievers = packetRecievers.elements(); recievers.hasMoreElements() ;)
		{
			currentReciever = (PacketReciever)recievers.nextElement();
			currentReciever.RemovePacketEventListener(listener);
		}
	}

	public static void AddOptionsPanelContributor(Object pContributor)
	{
		optionPanelContributors.add(pContributor);
	}

	public static void RemoveOptionsPanelContributor(Object pContributor)
	{
		optionPanelContributors.remove(pContributor);
	}

        /** Used to print messages to standard out if the debugging option is on.
         * @param in the string to be printed
         */
        public static void out(String in)
        {
            if (configuration.getDebug())
                System.out.println(in);
        }

        /** Used to print messages to standard out if the verbose option is on.
         * @param in the string to be printed
         */
        public static void outv(String in)
        {
            if (configuration.getVerbose())
                System.out.println(in);
        }


        /** Show Options Dialog.
         * this function displays the dialog showing all node properties
         */
	public static void ShowOptionsDialog()
	{
		TabbedDialog optionsDialog = new TabbedDialog("Surge Options");
		ActivePanel currentPanel;
		PacketReciever reciever;
		PacketAnalyzer analyzer;
		Object contributor;

		for(Enumeration e = optionPanelContributors.elements(); e.hasMoreElements();)
		{
			contributor = e.nextElement();
			if(contributor instanceof DisplayManager)
			{
				currentPanel = ((DisplayManager)contributor).GetOptionsPanel();
				if(currentPanel != null)//if you don't have proprietary info, return a null panel
				{
					optionsDialog.AddActivePanel(currentPanel.GetTabTitle(), currentPanel);
				}
			}
            else if(contributor instanceof PacketReciever)
            {
				currentPanel = ((PacketReciever)contributor).GetOptionsPanel();
				if(currentPanel != null)//if you don't have proprietary info, return a null panel
				{
					optionsDialog.AddActivePanel(currentPanel.GetTabTitle(), currentPanel);
				}
			}
            else if(contributor instanceof PacketAnalyzer)
            {
				currentPanel = ((PacketAnalyzer)contributor).GetOptionsPanel();
				if(currentPanel != null)//if you don't have proprietary info, return a null panel
				{
					optionsDialog.AddActivePanel(currentPanel.GetTabTitle(), currentPanel);
				}
			}
		}
		//optionsDialog.setModal(false);
		optionsDialog.show();
	}

}
