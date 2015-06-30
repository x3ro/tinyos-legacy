// $Id: SensorAnalyzer.java,v 1.10 2004/05/15 23:16:37 jlhill Exp $

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


/**
 * @author Wei Hong
 */

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.messages.*;
import net.tinyos.surge.event.*;
import net.tinyos.message.*;
import net.tinyos.surge.util.*;
import java.util.*;
import java.lang.*;
import java.text.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;
import java.awt.*;


class LinkAnalyzer extends PacketAnalyzer{
    SensorAnalyzer s;
    public LinkAnalyzer(SensorAnalyzer s) {
	super();
	AnalyzerDisplayEnable();
	this.s = s;
    }
    public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber) {
    	return s.getLinkPanel(pNodeNumber);
   }
}
        
public class SensorAnalyzer extends PacketAnalyzer {
    protected static Hashtable proprietaryNodeInfo;
    protected static TwoKeyHashtable proprietaryEdgeInfo;

    public SensorAnalyzer() {
	super();
	new LinkAnalyzer(this);
	if(MainClass.getMoteIF() != null)MainClass.getMoteIF().registerListener(new DebugPacket(), this);
	//create new hashtables for your proprietary data
	proprietaryNodeInfo = new Hashtable();
	proprietaryEdgeInfo = new TwoKeyHashtable();

	//register to be notified of nodes and edges being created or deleted
	MainClass.objectMaintainer.AddEdgeEventListener(this);//listen to node events
	MainClass.objectMaintainer.AddNodeEventListener(this);//listen to edge event
	AnalyzerDisplayEnable();

	// Start decay thread
	new Thread(new DecayThread()).start();


    }

    public void messageReceived(int addr, Message m) {
	if(m.amType() == 17){
         MultihopMsg msg = new MultihopMsg(m.dataGet());
         this.PacketReceived(msg);
	}else{
          MultihopMsg msg = new MultihopMsg(m.dataGet());
          this.DebugPacketReceived(msg);
	}

    }

    public synchronized void PacketReceived(MultihopMsg msg) {
	if (MainFrame.DEBUG_MODE) System.err.println("MESSAGE RECEIVED: "+msg);
	Integer currentNodeNumber = new Integer(msg.get_originaddr());
	NodeInfo currentNodeInfo;   
	if( (currentNodeInfo = (NodeInfo)proprietaryNodeInfo.get(currentNodeNumber)) != null) {
	    currentNodeInfo.update(msg);
	}
    }	

    public synchronized void DebugPacketReceived(MultihopMsg msg) {
	Integer currentNodeNumber = new Integer(msg.get_originaddr());
	NodeInfo currentNodeInfo;   
	if( (currentNodeInfo = (NodeInfo)proprietaryNodeInfo.get(currentNodeNumber)) != null) {
	    currentNodeInfo.updateDebug(msg);
	}
    }	

    public synchronized void NodeCreated(NodeEvent e) {
	Integer newNodeNumber = e.GetNodeNumber();//you probably want to create a new info pbject to track the data of this new node
	proprietaryNodeInfo.put(newNodeNumber, new NodeInfo(newNodeNumber));
    }

    public synchronized void NodeDeleted(NodeEvent e) {
	Integer deletedNodeNumber = e.GetNodeNumber();//you probably want to delete the info pbject to track the data of this new node
	proprietaryNodeInfo.remove(deletedNodeNumber);
    }

    public ActivePanel getLinkPanel(Integer pNodeNumber) {
	NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
	if(nodeInfo==null) 
	    return null;
	ProprietaryLinkInfoPanel panel = new ProprietaryLinkInfoPanel(nodeInfo);
	return (ActivePanel)panel;
    }

    public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber) {
	NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
	if(nodeInfo==null) 
	    return null;
	ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel(nodeInfo);
	return (ActivePanel)panel;
    }

    //NODE PAINTER
    //Put some function here to paint whatever you want over the node.
    //The x1,y1 coordinates are the top left corner within which the node will be drawn
    //The x2,y2 coordinates are the bottom right corner
    //Paint everything on the graphics object
    //this function is called by DisplayManager
    public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g) 
    {

	NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
	if(nodeInfo==null) return;
	int light = nodeInfo.GetSensorValue();
	nodeInfo.centerX = (x1 + x2)/2;
	nodeInfo.centerY = (y1 + y2)/2;

	/*if (!MainFrame.SENSOR_MODE && light != -1) {
	    int val = Math.max(0,Math.min(light, 255));
	    g.setColor(new Color(val, val, val));
	    g.fillOval(x1, y1, x2-x1, y2-y1);
	}*/

	if (nodeInfo.active) {
	    g.setColor(Color.red);
	    g.drawOval(x1, y1, x2-x1, y2-y1);
	    g.drawOval(x1+3, y1+3, x2-x1-6, y2-y1-6);
	}

	if (MainFrame.STATUS_MODE && nodeInfo.GetNodeNumber().intValue() != 0 && nodeInfo.GetNodeNumber().intValue() != 0x7e) {
	    g.setColor(MainFrame.labelColor);
	    g.setFont(MainFrame.bigFont);
	    String s = nodeInfo.GetInfoString();
	    g.drawString(s, (x1+x2)/2, y2-(y2-y1)/4 + 20);
	    if(nodeInfo.neighbors[0] != null)
	    Util.drawValueBar((x1+x2)/2, y2-(y2-y1)/4 + 30, 
			      nodeInfo.link_quality, true, "Quality", g);
	    Util.drawValueBar((x1+x2)/2, y2-(y2-y1)/4 + 40, 
			      nodeInfo.yield(), true, "Yield", g);
	    Util.drawValueBar((x1+x2)/2, y2-(y2-y1)/4 + 50, 
			      nodeInfo.expected_yield(0), true, "Prediction", g);
	}
    }

    //SCREEN PAINTER
    //Put some function here to paint whatever you want over the screen before and after
    //all edges and nodes have been painted.

    Image img;

    public void PaintScreenBefore(Graphics g) 
    {
	Dimension d = MainClass.mainFrame.GetGraphDisplayPanel().getSize();


	//place the background image.

	if (!MainFrame.SENSOR_MODE) {
		if(img == null){
			try{
			img = new ImageIcon(getClass().getResource("../images/Surge_background.jpg")).getImage();
			}catch (Exception e){}
		}
		if(img == null){
			try{
			img = new ImageIcon("images/Surge_background.jpg").getImage();
			}catch (Exception e){}
		}
		
		if(img != null){
	    		g.drawImage(img, 0, 0, d.width, d.height, null);
		}
	    	return;
	}

	NodeInfo nodeInfo;
	int x = 0;
	int y = 0;
	int step = 10;	

	for(;x < d.width; x += step){
	    for(y = 0;y < d.height; y += step){
		double val = 0;
		double sum = 0;
		double total = 0;
		double min = 10000000;
		for(Enumeration nodes = proprietaryNodeInfo.elements();nodes.hasMoreElements();){
		    nodeInfo = (NodeInfo) nodes.nextElement();
		    double dist = distance(x, y, nodeInfo.centerX, nodeInfo.centerY);	
		    if(nodeInfo.value != -1 && nodeInfo.nodeNumber.intValue() != 1){ //121
			if(dist < min) min = dist;
			val += ((double)nodeInfo.value)  / dist /dist;
			sum += (1/dist/dist);
		    }
		}
		int reading = (int)(val / sum);
		reading = reading >> 2;
		if (reading > 255)
		    reading = 255;
		g.setColor(new Color(reading, reading, reading));
		g.fillRect(x, y, step, step);
	    }
	}
    }
    public double distance(int x, int y, int x1, int y1){
	return Math.sqrt( (x-x1)*(x-x1)+(y-y1)*(y-y1));
    }
    public void PaintScreenAfter(Graphics g) {
	//paint something on the graphics object
    }


    public NodeInfo GetNodeInfoByOrder(int n){
	Enumeration e = GetNodeInfo();
	while (e.hasMoreElements()) {
    		NodeInfo ni = (NodeInfo)e.nextElement();
    		if(n == 0) return ni;
		n --;
	}	
	return null;

    }
	
    public int GetNodeCount(){
	return proprietaryNodeInfo.size();
    }

    public NodeInfo GetNodeInfo(Integer nodeNumber){return (NodeInfo)proprietaryNodeInfo.get(nodeNumber);}
    public Enumeration GetNodeInfo(){return proprietaryNodeInfo.elements();}

    public void ShowPropertiesDialog() 
    {
	StandardDialog newDialog = new StandardDialog(new DisplayPropertiesPanel(this));
	newDialog.show();
    }

    // Periodically decay eield for each thread
    public static final long DECAY_THREAD_RATE = 5000;
    public static final int YIELD_HISTORY_LENGTH = 2000;
    public static final int YIELD_INTERVAL = 12;
    public static final int HISTORY_LENGTH = 50;
    class DecayThread implements Runnable {

	public void run() {
	    while (true) {
		try {
		    Thread.currentThread().sleep(DECAY_THREAD_RATE);
		    Enumeration e = GetNodeInfo();
		    while (e.hasMoreElements()) {
			NodeInfo ni = (NodeInfo)e.nextElement();
			ni.decay();
		    }
		} catch (Exception e) {
		    // Ignore
		}
	    }
	}
    }


    //PROPRIETARY NODE INFO DISPLAY PANEL
    //This class is an ActivePanel and should have all the information
    //in GUI form that this class stores with respect to nodes
    //It should be returned with GetProprietaryNodeInfoPanel and it will be displayed
    //with all the other packet analyzer proprietary info when a node is clicked.



    //PacketAnalyzerTemplatePropertiesPanel
    //This class is an ActivePanel and should have all the information
    //in GUI form that this class stores with respect to EDGES
    //It will be displayed automatically with ShowPropertiesDialog
    public class DisplayPropertiesPanel extends net.tinyos.surge.Dialog.ActivePanel
    {
	SensorAnalyzer analyzer;

	public DisplayPropertiesPanel(SensorAnalyzer pAnalyzer)
	{
	    analyzer = pAnalyzer;
	    tabTitle = "Light";//this will be the title of the tab
	    setLayout(null);
	    //			Insets ins = getInsets();
	    setSize(307,168);
	    JLabel3.setToolTipText("This text will appear with mouse hover over this component");
	    JLabel3.setText("Variable Name:");
	    add(JLabel3);
	    JLabel3.setBounds(12,36,108,24);
	    JLabel4.setToolTipText("This is the value of Variable Name");
	    JLabel4.setText("text");
	    add(JLabel4);
	    JLabel4.setBounds(12,60,108,24);
	}

	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();

	public void ApplyChanges()//this function will be called when the apply button is hit
	{
	    //			analyzer.SetVariableName(Integer.getInteger(JLabel4.getText()).intValue());
	}

	public void InitializeDisplayValues()//this function will be called when the panel is first shown
	{
	    //			JLabel4.setText(String.valueOf(analyzer.GetVariableName()));
	}
    }	          

}
