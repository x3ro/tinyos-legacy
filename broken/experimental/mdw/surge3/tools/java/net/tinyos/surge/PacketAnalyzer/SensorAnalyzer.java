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
* Authors:   Wei Hong, modified for tinydb
*/

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.event.*;
import net.tinyos.surge.util.*;
import java.util.*;
import java.lang.*;
import java.text.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;
import java.awt.*;
        
public class SensorAnalyzer extends PacketAnalyzer {
  protected static Hashtable proprietaryNodeInfo;
  protected static TwoKeyHashtable proprietaryEdgeInfo;

  public SensorAnalyzer() {
    super();
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

  public synchronized void PacketReceived(SurgeMsg msg) {
    if (MainFrame.DEBUG_MODE) System.err.println("MESSAGE RECEIVED: "+msg);
    Integer currentNodeNumber = new Integer(msg.get_originaddr());
    NodeInfo currentNodeInfo;   
    if( (currentNodeInfo = (NodeInfo)proprietaryNodeInfo.get(currentNodeNumber)) != null) {
      currentNodeInfo.update(msg);
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
    if (light == -1) return;
    nodeInfo.centerX = (x1 + x2)/2;
    nodeInfo.centerY = (y1 + y2)/2;

    if (!MainFrame.SENSOR_MODE) {
      int val = Math.max(0,Math.min(light, 255));
      g.setColor(new Color(val, val, val));
      g.fillOval(x1, y1, x2-x1, y2-y1);
    }

    if (nodeInfo.active) {
      g.setColor(Color.red);
      g.drawOval(x1, y1, x2-x1, y2-y1);
      g.drawOval(x1+3, y1+3, x2-x1-6, y2-y1-6);
    }

    if (MainFrame.STATUS_MODE) {
      g.setColor(MainFrame.labelColor);
      g.setFont(MainFrame.bigFont);
      String s = nodeInfo.GetInfoString();
      g.drawString(s, (x1+x2)/2, y2-(y2-y1)/4 + 20);
      Util.drawValueBar((x1+x2)/2, y2-(y2-y1)/4 + 30, 
        (nodeInfo.link_quality / 100.0), true, "Quality", g);
      Util.drawValueBar((x1+x2)/2, y2-(y2-y1)/4 + 40, 
	  nodeInfo.yield, true, "Yield", g);
    }
  }

  //SCREEN PAINTER
  //Put some function here to paint whatever you want over the screen before and after
  //all edges and nodes have been painted.
  public void PaintScreenBefore(Graphics g) 
  {
    Dimension d = MainClass.mainFrame.GetGraphDisplayPanel().getSize();

    if (!MainFrame.SENSOR_MODE) {
      g.setColor(new Color(50, 50, 150));
      g.fillRect(0,0,d.width,d.height);
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

  public NodeInfo GetNodeInfo(Integer nodeNumber){return (NodeInfo)proprietaryNodeInfo.get(nodeNumber);}
  public Enumeration GetNodeInfo(){return proprietaryNodeInfo.elements();}

  public void ShowPropertiesDialog() 
  {
    StandardDialog newDialog = new StandardDialog(new DisplayPropertiesPanel(this));
    newDialog.show();
  }

  // Periodically decay yield for each thread
  private static final long DECAY_THREAD_RATE = 5000;
  class DecayThread implements Runnable {

    public void run() {
      System.err.println("Decay thread running...");
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

  //NODE INFO CLASS
  //this class should hold any special information you hold about the
  //node, for example time created or a history of the number of packets
  //forwarded through this mote or whetever it is you are studying
  public class NodeInfo
  {
      // dchi
    protected ProprietaryNodeInfoPanel panel = null;
    protected Integer nodeNumber;
    protected int value;
    protected int centerY;
    protected int centerX;
    protected String infoString;
    protected long msgCount = 0, lastMsgCount = 0;
    protected long lastTime;
    protected double msgRate = 0;
    protected double yield = 0;
    protected int link_quality;
    protected long AVERAGE_INTERVAL = 2000;
    protected boolean isDirectChild = false;
    protected boolean active = false;

    public NodeInfo(Integer pNodeNumber) {
      lastTime = System.currentTimeMillis();
      nodeNumber = pNodeNumber;
      value = -1;//if it doesn't change from this value nothing will be written
      infoString = "[none]";
    }

    public Integer GetNodeNumber() {
      return nodeNumber;
    }

    public void SetPanel (ProprietaryNodeInfoPanel p) {
      panel = p;
    }

    public void SetNodeNumber(Integer pNodeNumber) {
      nodeNumber = pNodeNumber;
    }

    public int GetSensorValue() { return value; }
    public String GetInfoString() { return infoString; }

    // Decay current estimates if no msgs heard in last cycle
    public void decay() {
      if (active) { active = false; return; }

      long curtime = System.currentTimeMillis();
      if (curtime - lastTime >= AVERAGE_INTERVAL) {
	msgRate = (lastMsgCount * 1.0) / ((curtime - lastTime) * 1.0e-3);
	yield = (msgRate)/(1.0/((MainClass.mainFrame.sampleRate * 1.0) * 1.0e-3));
	lastMsgCount = 0;
	lastTime = curtime;
      }
    }

    public void update(SurgeMsg msg) {
      String info;

      if (msg.get_type() == 0) {

	if (msg.get_parentaddr() == MainFrame.BEACON_BASE_ADDRESS) {
	  isDirectChild = true;
	} else {
	  isDirectChild = false;
	}

	// Update message count and rate
	// Only update if this message is coming to the root from
	// a direct child
	int saddr = msg.get_sourceaddr();
	NodeInfo ni = (NodeInfo)proprietaryNodeInfo.get(new Integer(saddr));
	if (ni != null) {
	  if (ni.isDirectChild) {
	    msgCount++; lastMsgCount++;
	    active = true;
	    long curtime = System.currentTimeMillis();
	    if (curtime - lastTime >= AVERAGE_INTERVAL) {
	      msgRate = (lastMsgCount * 1.0) / ((curtime - lastTime) * 1.0e-3);
	      yield = (msgRate)/(1.0/((MainClass.mainFrame.sampleRate * 1.0) * 1.0e-3));
	      lastMsgCount = 0;
	      lastTime = curtime;
	    }
	  }
	}

	info = msgCount+" msgs ("+Util.format(msgRate)+" msgs/sec)";

    	this.value = msg.get_args_reading_args_reading();
	if (panel != null) {
	  //System.err.println ("setvalue: " + panel.isVisible());
 	  panel.JLabel6.setText(String.valueOf(value));
	}

    	link_quality = msg.get_args_reading_args_parent_link_quality();
	if (link_quality == 255) { // Unknown value
	  link_quality = -1;
	} 
	this.infoString = info;
      }
    }
      
  }                                         
  //NODE INFO

  //PROPRIETARY NODE INFO DISPLAY PANEL
  //This class is an ActivePanel and should have all the information
  //in GUI form that this class stores with respect to nodes
  //It should be returned with GetProprietaryNodeInfoPanel and it will be displayed
  //with all the other packet analyzer proprietary info when a node is clicked.
  public class ProprietaryNodeInfoPanel extends net.tinyos.surge.Dialog.ActivePanel
  {
    NodeInfo nodeInfo;

    public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)
    {
      nodeInfo = pNodeInfo;
      
      nodeInfo.SetPanel(this);

      tabTitle = "Sensor Value";//this will be the title of the tab
      setLayout(null);
      //			Insets ins = getInsets();
      setSize(307,168);
      //JLabel3.setToolTipText("This text will appear with mouse hover over this component");
      JLabel3.setText("Node Number:");
      add(JLabel3);
      //JLabel3.setBounds(12,36,108,24);
      JLabel3.setBounds(12,6,108,24);

      // JLabel4.setToolTipText("This is the value of NodeNumber");
      JLabel4.setText("text");
      add(JLabel4);
      //JLabel4.setBounds(12,60,108,24);
      JLabel4.setBounds(12,26,108,24);

      //      JLabel5.setToolTipText("This text will appear with mouse hover over this component");
      JLabel5.setText("Sensor Reading:");
      add(JLabel5);
      //JLabel5.setBounds(12,84,108,24); 
      JLabel5.setBounds(12,54,108,24);

      //      JLabel6.setToolTipText("This is the value of Sensor Reading");
      JLabel6.setText("text");
      add(JLabel6);
      //JLabel6.setBounds(12,108,108,24);
      JLabel6.setBounds(12,74,108,24);
    }

      public void panelClosing() {
	  System.err.println ("SensorAnalyzer: updating panel = null");
	  nodeInfo.SetPanel(null);
      }
      
    javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
    javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
    javax.swing.JLabel JLabel5 = new javax.swing.JLabel();
    javax.swing.JLabel JLabel6 = new javax.swing.JLabel();

    public void ApplyChanges()//this function will be called when the apply button is hit
    {
      nodeInfo.SetNodeNumber(Integer.getInteger(JLabel4.getText()));
    }

    public void InitializeDisplayValues()//this function will be called when the panel is first shown
    {
      JLabel4.setText(String.valueOf(nodeInfo.GetNodeNumber()));
      JLabel6.setText(String.valueOf(nodeInfo.GetSensorValue()));
    }
  }

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
