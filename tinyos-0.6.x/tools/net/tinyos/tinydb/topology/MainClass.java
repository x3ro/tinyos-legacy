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
* Authors:   Wei Hong, adapted for tinydb
*/

//***********************************************************************
//***********************************************************************
//this is the main class that holds all global variables
//and from where "main" is run.
//the global variables can be accessed as: MainClass.MainFrame for example.
//***********************************************************************
//***********************************************************************

package net.tinyos.tinydb.topology;

import java.util.*;
import net.tinyos.tinydb.*;
import net.tinyos.tinydb.topology.event.*;
import net.tinyos.tinydb.topology.util.*;
import net.tinyos.tinydb.topology.PacketAnalyzer.*;
import net.tinyos.tinydb.topology.Dialog.*;
import net.tinyos.tinydb.topology.Packet.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;
import java.io.*;
import net.tinyos.amhandler.*;

public class MainClass implements ResultListener
{
	public static MainFrame mainFrame;
	public static DisplayManager displayManager;
	public static ObjectMaintainer objectMaintainer;
	public static SensorAnalyzer sensorAnalyzer;
	public static LocationAnalyzer locationAnalyzer;
	public static Vector packetAnalyzers;
	public static TinyDBQuery topologyQuery;
	public static boolean topologyQueryRunning = false;
	public static short topologyQueryEpochDur = 4096;
    
    TinyDBNetwork nw;

	public MainClass(TinyDBNetwork nw, byte qid) throws IOException
	{
	    this.nw = nw;
	    nw.addResultListener(this, false, qid);

		mainFrame = new MainFrame("Sensor Network Topology", nw);
		displayManager = new DisplayManager(mainFrame);
			
		packetAnalyzers = new Vector();	
		
		objectMaintainer = new ObjectMaintainer();
		objectMaintainer.AddEdgeEventListener(displayManager);
		objectMaintainer.AddNodeEventListener(displayManager);
		
		locationAnalyzer = new LocationAnalyzer();
		sensorAnalyzer = new SensorAnalyzer();

		packetAnalyzers.add(objectMaintainer);
		packetAnalyzers.add(sensorAnalyzer);
			
	    //make the MainFrame visible as the last thing
		mainFrame.setVisible(true);
		topologyQuery = new TinyDBQuery(qid, topologyQueryEpochDur);
		QueryField qf1 = new QueryField("nodeid", QueryField.INTTWO);
		QueryField qf2 = new QueryField("parent", QueryField.INTTWO);
		QueryField qf3 = new QueryField("light", QueryField.INTTWO);
		QueryField qf4 = new QueryField("temp", QueryField.INTTWO);
		QueryField qf5 = new QueryField("voltage", QueryField.INTTWO);
		topologyQuery.addField(qf1);
		topologyQuery.addField(qf2);
		topologyQuery.addField(qf3);
		topologyQuery.addField(qf4);
		topologyQuery.addField(qf5);
		nw.sendQuery(topologyQuery);
		TinyDBMain.notifyAddedQuery(topologyQuery);
		topologyQueryRunning = true;
	}


    public void addResult(QueryResult qr) {
	Packet packet = new Packet(qr);

	try {
	    
	    if (packet.getNodeId().intValue() < 0 || 
		packet.getNodeId().intValue() > 32 ||
		packet.getParent().intValue() < 0 ||
		packet.getParent().intValue() > 32)
		return;
	} catch (ArrayIndexOutOfBoundsException e) {
	    return;
	}
	
	PacketEventListener currentListener;
	for(Enumeration list = packetAnalyzers.elements(); list.hasMoreElements();)
	    {
		currentListener = (PacketEventListener)list.nextElement();
		PacketEvent e = new PacketEvent(nw, packet,
						Calendar.getInstance().getTime());
		currentListener.PacketReceived(e);//send the listener an event
	    }			
    }
}
