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

package Surge.PacketAnalyzers;

import Surge.PacketAnalyzers.Location.*;
import Surge.PacketAnalyzers.Location.StageOne.*;
import Surge.PacketAnalyzers.Location.StageTwo.*;
import Surge.PacketAnalyzers.Location.StageThree.*;
import Surge.PacketAnalyzers.Location.StageFour.*;
import Surge.*;
import Surge.event.*;
import Surge.util.*;
import Surge.Dialog.*;
import java.util.*;
import java.lang.*;
import java.awt.event.*;
import javax.swing.*;
import java.awt.*;
import Surge.Packet.*;
import java.io.*;
import java.util.zip.*;
import Surge.PacketAnalyzers.*;

              //this class performs two functions:
              // 1.  estimate distances between nodes
              // 2.  estimate the locations of the nodes
              //It is currently configured to be able to do these functions
              //using interchangable distance and location estimators
              
              //Basically, it estimates distance every time a new packet is recieved
              //and a seperate thread runs in the background, constantly updating 
              //the location estimates
public class MassSpringsLocationAnalyzer extends Surge.PacketAnalyzers.PacketAnalyzer implements java.lang.Runnable, LocationAnalyzer
{
	Thread estimateLocationThread;
	protected static Hashtable proprietaryNodeInfo;
	protected static TwoKeyHashtable proprietaryEdgeInfo;
	protected MenuManager menuManager;
	
	protected StageOneAnalyzer stage1;
	protected StageTwoAnalyzer stage2;
	protected StageThreeAnalyzer stage3;
	protected StageFourAnalyzer stage4;
	
	          //----------------------------------------------------------------------
	          //*****---CONSTRUCTOR---******//
	public MassSpringsLocationAnalyzer()
	{
		      //define hashtables to hold my proprietary information
		proprietaryNodeInfo = new Hashtable();
		proprietaryEdgeInfo = new TwoKeyHashtable();
		
		      //define which algorithms I am going to use
		stage1 = new StageOnePolynomialRegression();
		stage2 = new StageTwoTimeWindow();
		stage3 = new StageThreeResolutionOfForces();
		stage4 = new StageFourAnalyzer();
		
		      //register to hear new node and edge events
		MainClass.objectMaintainer.AddNodeEventListener(this);
		MainClass.objectMaintainer.AddEdgeEventListener(this);

				//register myself to recieve NodeClickedEvents and EdgeClickedEvents
		MainClass.displayManager.AddNodeDialogContributor(this);
		MainClass.displayManager.AddEdgeDialogContributor(this);

		      //register to be a node and edge painter
		MainClass.displayManager.AddNodePainter(this);
		MainClass.displayManager.AddEdgePainter(this);

		menuManager = new MenuManager();//this creates the menu, adds it to the MainMenuBar, and creates and object to handle all menu events

              //spawn a new thread to do background analysis
		estimateLocationThread = new Thread(this);
		try{
			estimateLocationThread.setPriority(Thread.NORM_PRIORITY);
			estimateLocationThread.start(); //recall that start() calls the run() method defined in this class
		}
		catch(Exception e){e.printStackTrace();}
	}
	          //*****---CONSTRUCTOR---*****//
	          //----------------------------------------------------------------------
	
	
	          //----------------------------------------------------------------------
		      //*****---PACKETRECIEVED EVENT HANDLER---*****//
	public  void PacketRecieved(PacketEvent e)
	{
		      //this function will read the packet and update the lengths
		      //of the edges that correspond to the data in the packet.  
		Packet packet = e.GetPacket();
	//	if(packet.GetSourceNode() == 18)//this is just for calibration
	//	{
        	Vector signalStrengths = packet.CreateSignalStrengthArray();
        	Vector sourceNodes = packet.CreateSignalStrengthSourceArray();
        	Vector destinationNodes = packet.CreateSignalStrengthDestinationArray();
			double distance, signalStrength;
			EdgeInfo edgeInfo;
			Integer sourceNodeNumber, destinationNodeNumber;
	        
        	for(int index = 0; index < signalStrengths.size(); index++)
        	{
        		sourceNodeNumber = (Integer)sourceNodes.elementAt(index);
        		destinationNodeNumber = (Integer)destinationNodes.elementAt(index);
        		signalStrength = ((Double)signalStrengths.elementAt(index)).doubleValue();
        		distance = stage1.EstimateDistance(sourceNodeNumber, destinationNodeNumber, signalStrength);
        		distance = stage2.EstimateDistance(sourceNodeNumber, destinationNodeNumber, distance);
				edgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(sourceNodeNumber, destinationNodeNumber);
				if( (!Double.isNaN(distance)) && (edgeInfo!=null) )
				{	
					edgeInfo.SetDistance(distance);	
				}
        	}
     //   }
	}
		      //*****---PACKETRECIEVED EVENT HANDLER---*****//
	          //----------------------------------------------------------------------
		      
	
	          //----------------------------------------------------------------------
		      //*****---run---*****//
	public void run() 
	{
		      //this function will do all background work for location estimation
		      //in general, this would include mass springs or boltzman machine
		      //type activity
		while(true)
		{	
			try
			{
				estimateLocationThread.sleep(100);
			}
			catch(Exception e){e.printStackTrace();}
			stage3.EstimateLocation();
			stage4.EstimateLocation();
		}
	}
			  //*****---run---*****//
	          //----------------------------------------------------------------------



              //------------------------------------------------------------------------
	          //*****---Node Created---******//
	          //this function defines what you do when a new node is created
	          //It is called by Surge.PacketAnalyzers.ObjectMainter
    public synchronized void NodeCreated(NodeEvent e)
    {
    	Integer newNodeNumber = e.GetNodeNumber();//you probably want to create a new info pbject to track the data of this new node
    	if(!proprietaryNodeInfo.containsKey(newNodeNumber))//unless it already exists (it might exist if you don't delete it in NodeDeleted()
    	{
    		proprietaryNodeInfo.put(newNodeNumber, new NodeInfo(newNodeNumber));
    	}
    }
	          //*****---Node Created---******//
              //------------------------------------------------------------------------

    
              //------------------------------------------------------------------------
    	          //*****---Node Deleted---******//
	          //this function defines what you do when a new node is deleted
	          //It is called by Surge.PacketAnalyzers.ObjectMainter
    public synchronized void NodeDeleted(NodeEvent e)
    {
//    	Integer deletedNodeNumber = e.GetNodeNumber();//you probably want to delete the info pbject to track the data of this new node
//    	proprietaryNodeInfo.remove(deletedNodeNumber);//but you might also want to leave it there but disable it, unless this node reappears and you want to use the same info
    }
	          //*****---Node Deleted---******//
              //------------------------------------------------------------------------


              //------------------------------------------------------------------------
	          //*****---Edge Created---******//
	          //this function defines what you do when a new edge is created
	          //It is called by Surge.PacketAnalyzers.ObjectMainter
    public synchronized void EdgeCreated(EdgeEvent e)
    {
    	Integer sourceNodeNumber = e.GetSourceNodeNumber();
    	Integer destinationNodeNumber = e.GetDestinationNodeNumber();//you probably want to create a new info pbject to track the data of this new node
    	if(!proprietaryEdgeInfo.containsKey(sourceNodeNumber,destinationNodeNumber))//unless it already exists (it might exist if you don't delete it in EdgeDeleted()
    	{
    		proprietaryEdgeInfo.put(sourceNodeNumber, destinationNodeNumber, new EdgeInfo(sourceNodeNumber, destinationNodeNumber));
    	}
    }
	          //*****---Edge Created---******//
              //------------------------------------------------------------------------


              //------------------------------------------------------------------------
	          //*****---Edge Deleted---******//
	          //this function defines what you do when a new edge is deleted
	          //It is called by Surge.PacketAnalyzers.ObjectMainter
    public synchronized void EdgeDeleted(EdgeEvent e)
    {
    	Integer sourceNodeNumber = e.GetSourceNodeNumber();
    	Integer destinationNodeNumber = e.GetDestinationNodeNumber();//you probably want to create a new info pbject to track the data of this new node
    	proprietaryEdgeInfo.remove(sourceNodeNumber, destinationNodeNumber);//but you might also want to leave it there but disable it, unless this edge reappears and you want to use the same info
    }
	          //*****---EdgeDeleted---******//
              //------------------------------------------------------------------------

    public  void NodeClicked(NodeClickedEvent e)
    {
    }

              //------------------------------------------------------------------------
	          //*****---NODE DRAGGED---******//
	          //this function defines what you do when a node is clicked
	          //It is called by Surge.DisplayManager
    public synchronized void NodeDragged(NodeDraggedEvent e)
    {
    	Integer nodeDragged = e.GetNodeNumber();
		NodeInfo selectedNode = (NodeInfo)proprietaryNodeInfo.get(nodeDragged);
		
		if(selectedNode!=null)
		{     //this function acts on a custom mouse drag, and moves the node with the drag 
			selectedNode.SetX(e.GetDraggedToX());
			selectedNode.SetY(e.GetDraggedToY());
			selectedNode.SetFixed(true);
			MainClass.displayManager.RefreshScreenNow();
		}
    	      //and maybe do some other processing
    }
	          //*****---Node Clicked---******//
              //------------------------------------------------------------------------

    public  void EdgeClicked(EdgeClickedEvent e)
    {
    }

	public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
	{
		NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
		if(nodeInfo==null) return;
		
		if(nodeInfo.GetDisplayCoords() == true)
		{
			String temp = String.valueOf(nodeInfo.GetX());
			String text = temp.substring(0,Math.min(4, temp.length()));
			text = text.concat(",");
			temp = String.valueOf(nodeInfo.GetY());
			text = text.concat(temp.substring(0,Math.min(4, temp.length())));
			g.setColor(Color.black);
			g.drawString(text,  x1, y1);
		}
	}
	
	public void PaintEdge(Integer pSourceNodeNumber, Integer pDestinationNodeNumber, int screenX1, int screenY1, int screenX2, int screenY2, Graphics g)
	{
		EdgeInfo edgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(pSourceNodeNumber,pDestinationNodeNumber);
		if(edgeInfo == null) return;
		
		if(edgeInfo.GetDisplayLength() == true)
		{
			String temp= String.valueOf(this.GetDistance(pSourceNodeNumber,pDestinationNodeNumber));
			String text = temp.substring(0,Math.min(3, temp.length()));
			text = text.concat(",");
			double x1 = GetX(pSourceNodeNumber);
			double y1 = GetY(pSourceNodeNumber);
			double x2 = GetX(pDestinationNodeNumber);
			double y2 = GetY(pDestinationNodeNumber);
			temp = String.valueOf(Math.sqrt(Math.pow(x1-x2, 2)+ Math.pow(y1-y2, 2)));
			text = text.concat(temp.substring(0,Math.min(3, temp.length())));//put both estimated and real distances
			g.setColor(Color.black);
			g.drawString(text, (screenX2+screenX1)/2, (screenY2+screenY1)/2);
		}
	}
	
	public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber)
	{
		return new ProprietaryNodeInfoPanel((NodeInfo)proprietaryNodeInfo.get(pNodeNumber));
	}

	public ActivePanel GetProprietaryEdgeInfoPanel(Integer pSourceNodeNumber, Integer pDestinationNodeNumber)
	{
		return new ProprietaryEdgeInfoPanel((EdgeInfo)proprietaryEdgeInfo.get(pSourceNodeNumber,pDestinationNodeNumber));
	}


	          //------------------------------------------------------------------------
	          //*****---FIND NEAREST NODE---******//
	public Integer FindNearestNode(double x, double y)
	{
		NodeInfo selectedNode = null;
		NodeInfo tempNode = null;
		double dist = Double.MAX_VALUE;
		double bestdist = Double.MAX_VALUE;
		double xDist, yDist;
		for(Enumeration nodes = proprietaryNodeInfo.elements(); nodes.hasMoreElements();) 
		{
			tempNode = (NodeInfo)nodes.nextElement();
			xDist = Math.pow(tempNode.GetX() - x,2.0);
			yDist = Math.pow(tempNode.GetY() - y,2.0);
			dist = Math.sqrt(xDist + yDist);
			if (dist < bestdist) {
				selectedNode = tempNode;
				bestdist = dist;
			}
		}
		if(selectedNode == null)
		{
			return null;
		}
		else
		{
	    	return selectedNode.GetNodeNumber();
	    }
	}
	          //*****---FIND NEAREST NODE---******//
	          //------------------------------------------------------------------------


	          //------------------------------------------------------------------------
	          //*****---FIND NEAREST EDGE---******//
	public Vector FindNearestEdge(double x, double y)
	{
		EdgeInfo selectedEdge = null;
		EdgeInfo tempEdge = null;
		double dist = Double.MAX_VALUE;
		double bestdist = Double.MAX_VALUE;
		for(Enumeration edges = proprietaryEdgeInfo.elements(); edges.hasMoreElements();) 
		{
			double x1, y1, x2, y2, xCenter, yCenter;
			tempEdge = (EdgeInfo)edges.nextElement();
			Integer sourceNodeNumber = tempEdge.GetSourceNodeNumber();
			Integer destinationNodeNumber = tempEdge.GetDestinationNodeNumber();
			x1=MainClass.locationAnalyzer.GetX(sourceNodeNumber);
			y1=MainClass.locationAnalyzer.GetY(sourceNodeNumber);
			x2=MainClass.locationAnalyzer.GetX(destinationNodeNumber);
			y2=MainClass.locationAnalyzer.GetY(destinationNodeNumber);
			xCenter= (x1 + x2)/2;
			yCenter= (y1 + y2)/2;
			dist = Math.sqrt(Math.pow(xCenter-x,2) + Math.pow(yCenter-y,2));
			if (dist < bestdist) 
			{
				selectedEdge = tempEdge;
				bestdist = dist;
			}
		}
		if(selectedEdge == null)
		{
			return null;
		}
		else
		{	
			Vector edgeID = new Vector();
			edgeID.add(selectedEdge.GetSourceNodeNumber());
			edgeID.add(selectedEdge.GetDestinationNodeNumber());
			return edgeID;
		}
	}
	          //*****---FIND NEAREST EDGE---******//
	          //------------------------------------------------------------------------

              //----------------------------------------------------------------
              //GET/SET
    public double GetDistance(Integer sourceNodeNumber, Integer destinationNodeNumber )
    {
    	EdgeInfo edgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(sourceNodeNumber, destinationNodeNumber);
    	if(edgeInfo != null)
    	{
    		return edgeInfo.GetDistance();
    	}
    	else
    	{
    		return Double.NaN;
    	}
    }
    
    public double GetX(Integer nodeNumber )
    {
    	NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(nodeNumber);
    	if(nodeInfo !=null)
    	{
    		return nodeInfo.GetX();
    	}
    	else
    	{
    		return Double.NaN;
    	}
    }
    public double GetY(Integer nodeNumber)
    {
    	NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(nodeNumber);
    	if(nodeInfo !=null)
    	{
    		return nodeInfo.GetY();
    	}
    	else
    	{
    		return -1;
    	}
    }
	public NodeInfo GetNodeInfo(Integer nodeNumber){return (NodeInfo)proprietaryNodeInfo.get(nodeNumber);}
	public EdgeInfo GetEdgeInfo(Integer sourceNumber, Integer destinationNumber){return (EdgeInfo)proprietaryEdgeInfo.get(sourceNumber,destinationNumber);}
	public Enumeration GetNodeInfo(){return proprietaryNodeInfo.elements();}
	public Enumeration GetEdgeInfo(){return proprietaryEdgeInfo.elements();}
              //GET/SET
              //----------------------------------------------------------------
              
              //----------------------------------------------------------------
		          //*****---Thread commands---******//
    public void start(){ try{ estimateLocationThread=new Thread(this);estimateLocationThread.start();} catch(Exception e){e.printStackTrace();}}
    public void stop(){ try{ estimateLocationThread.stop();} catch(Exception e){e.printStackTrace();}}
    public void sleep(long p){ try{ estimateLocationThread.sleep(p);} catch(Exception e){e.printStackTrace();}}
    public void setPriority(int p) { try{estimateLocationThread.setPriority(p);} catch(Exception e){e.printStackTrace();}}    
			//*****---Thread commands---******//
            //----------------------------------------------------------------

              //------------------------------------------------------------------------
	          //*****---SHOW PROPERTIES DIALOG---******//
	          //this function can be called by MainFrame (by the menus, in particular)
	          //and should simply show the dialog as shown here.
	          //You need to define the class "LocationAnalyzerPropertiesPanel"
	          //in order for this to do anything.  it is useful for setting parameters
	          //on your analyzer.
	public void ShowOptionsDialog() 
	{
//		StandardDialog newDialog = new StandardDialog(new OptionsPanel(this));
//		newDialog.show();
	}

/*	public ActivePanel GetOptionsPanel() 
	{
		return new OptionsPanel(this);
	}*/
			  //*****---SHOW PROPERTIES DIALOG---******//
              //------------------------------------------------------------------------
	          

		      
	public static class NodeInfo// implements java.io.Serializable
	{
		protected double x;
		protected double y;
		protected Integer nodeNumber;
		protected boolean fixed;//determines if the node can move around automatically or not
		protected boolean displayCoords;//determines if the XY Coords should be drawn
		
		public NodeInfo(Integer pNodeNumber)
		{
			nodeNumber = pNodeNumber;
			x = Math.random();
			y = Math.random();
			fixed = false;
			displayCoords = true;
		}
		
		public Integer GetNodeNumber(){return nodeNumber;}
		public double GetX(){return x;}
		public double GetY(){return y;}
		public boolean GetFixed(){return fixed;}
		public boolean GetDisplayCoords(){return displayCoords;}

		public void SetX(double pX){x=pX;}
		public void SetY(double pY){y=pY;}
		public void SetFixed(boolean pFixed){fixed = pFixed;}
		public void SetDisplayCoords(boolean pDisplayCoords){displayCoords= pDisplayCoords;}
	}

	public static class EdgeInfo //implements java.io.Serializable
	{
		protected double distance;
		protected Integer sourceNodeNumber;
		protected Integer destinationNodeNumber;
		protected boolean displayLength;//determines if the length should be drawn
		
		EdgeInfo(Integer pSource, Integer pDestination)
		{
			sourceNodeNumber = pSource;
			destinationNodeNumber = pDestination; 
			distance = .5;
			displayLength = true;
		}
		
		public Integer GetSourceNodeNumber(){return sourceNodeNumber;}
		public Integer GetDestinationNodeNumber(){return destinationNodeNumber;}
		public double GetDistance(){return distance;}
		public void SetDistance(double pDistance){distance = pDistance;}
		public boolean GetDisplayLength(){return displayLength;}
		public void SetDisplayLength(boolean pDisplayLength){displayLength = pDisplayLength;}
	}
	
	
	public class ProprietaryNodeInfoPanel extends Surge.Dialog.ActivePanel
	{
		NodeInfo nodeInfo;
		
		public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)
		{
			tabTitle = "Location";
			nodeInfo = pNodeInfo;
			//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(247,168);
		JLabel3.setText("X Coordinate");
		add(JLabel3);
		JLabel3.setBounds(36,48,84,24);
		JLabel4.setText("Y Coordinate");
		add(JLabel4);
		JLabel4.setBounds(36,72,75,24);
		JTextField1.setNextFocusableComponent(JTextField2);
		JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField1.setText("1.5");
		add(JTextField1);
		JTextField1.setBounds(120,48,87,18);
		JTextField2.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField2.setText("3.2");
		add(JTextField2);
		JTextField2.setBounds(120,72,87,18);
		JCheckBox1.setToolTipText("Check this is you don\'t want the node to move around");
		JCheckBox1.setText("Fixed x/y Coordinates");
		add(JCheckBox1);
		JCheckBox1.setBounds(36,96,168,24);
		JCheckBox2.setToolTipText("Check this is you want the coordinates to be displayed on the screen");
		JCheckBox2.setText("Display x/y Coordinates");
		add(JCheckBox2);
		JCheckBox2.setBounds(36,120,168,24);
			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
	javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
	javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
	javax.swing.JCheckBox JCheckBox2 = new javax.swing.JCheckBox();
		//}}

		public void ApplyChanges()
		{
			nodeInfo.SetX(Double.valueOf(JTextField1.getText()).doubleValue());
			nodeInfo.SetY(Double.valueOf(JTextField2.getText()).doubleValue());
			nodeInfo.SetFixed(JCheckBox1.isSelected());
			nodeInfo.SetDisplayCoords(JCheckBox2.isSelected());
		}

		public void InitializeDisplayValues()
		{
			JTextField1.setText(String.valueOf(nodeInfo.GetX()));
			JTextField2.setText(String.valueOf(nodeInfo.GetY()));
			JCheckBox1.setSelected(nodeInfo.GetFixed());
			JCheckBox2.setSelected(nodeInfo.GetDisplayCoords());
		}
	}
	
	public class ProprietaryEdgeInfoPanel extends Surge.Dialog.ActivePanel
	{
		EdgeInfo edgeInfo;
		
		public ProprietaryEdgeInfoPanel(EdgeInfo pEdgeInfo)
		{
			tabTitle = "Location";
			edgeInfo = pEdgeInfo;
			//{{INIT_CONTROLS
			setLayout(null);
			Insets ins = getInsets();
			setSize(247,168);
			JLabel3.setText("Distance");
			add(JLabel3);
			JLabel3.setBounds(36,48,84,24);
			JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
			JTextField1.setText("1.5");
			add(JTextField1);
			JTextField1.setBounds(120,48,87,18);
			JCheckBox1.setToolTipText("Check this is you want the length of the edge to be displayed");
			JCheckBox1.setText("Display Length");
			add(JCheckBox1);
			JCheckBox1.setBounds(36,66,168,24);
			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
		javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
		javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
		//}}

		public void ApplyChanges()
		{
			edgeInfo.SetDistance(Double.parseDouble(JTextField1.getText()));
			edgeInfo.SetDisplayLength(JCheckBox1.isSelected());
		}

		public void InitializeDisplayValues()
		{
			JTextField1.setText(String.valueOf(edgeInfo.GetDistance()));
			JCheckBox1.setSelected(edgeInfo.GetDisplayLength());
		}

	}
	
	
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
		JCheckBoxMenuItem packetProcessingCheckBox = new JCheckBoxMenuItem();
		JCheckBoxMenuItem backgroundProcessingCheckBox = new JCheckBoxMenuItem();
		JSeparator separator1 = new JSeparator();
		JMenuItem propertiesItem = new JMenuItem();
		JSeparator separator2 = new JSeparator();
		JMenu serializeMenu = new JMenu();
		JMenuItem saveNodesItem = new JMenuItem();
		JMenuItem loadNodesItem = new JMenuItem();
		JMenuItem saveEdgesItem = new JMenuItem();
		JMenuItem loadEdgesItem = new JMenuItem();
		JSeparator separator3 = new JSeparator();
		JMenu paintMenu = new JMenu();
		JCheckBoxMenuItem paintNodesItem = new JCheckBoxMenuItem();
		JCheckBoxMenuItem paintEdgesItem = new JCheckBoxMenuItem();
		JCheckBoxMenuItem paintScreenItem = new JCheckBoxMenuItem();
		//}}
	
		public MenuManager()
		{
			//{{INIT_CONTROLS
			mainMenu.setText("Location Analyzer");
			mainMenu.setActionCommand("Location Analyzer");
			packetProcessingCheckBox.setSelected(true);
			packetProcessingCheckBox.setText("Packet Processing");
			packetProcessingCheckBox.setActionCommand("Packet Processing");
			mainMenu.add(packetProcessingCheckBox);
			backgroundProcessingCheckBox.setSelected(true);
			backgroundProcessingCheckBox.setText("Background Processing");
			backgroundProcessingCheckBox.setActionCommand("Background Processing");
			mainMenu.add(backgroundProcessingCheckBox);
			mainMenu.add(separator1);
			propertiesItem.setText("Options");
			propertiesItem.setActionCommand("Options");
			mainMenu.add(propertiesItem);
			mainMenu.add(separator2);
			serializeMenu.setText("Serialize");
			serializeMenu.setActionCommand("Serialize");
			saveNodesItem.setText("Save Node Locations");
			saveNodesItem.setActionCommand("Save Node Locations");
			serializeMenu.add(saveNodesItem);
			loadNodesItem.setText("Load Node Locations");
			loadNodesItem.setActionCommand("Load Node Locations");
			serializeMenu.add(loadNodesItem);
			saveEdgesItem.setText("Save Edge Lengths");
			saveEdgesItem.setActionCommand("Save Edge Lengths");
			serializeMenu.add(saveEdgesItem);
			loadEdgesItem.setText("Load Edge Lengths");
			loadEdgesItem.setActionCommand("Load Edge Lengths");
			serializeMenu.add(loadEdgesItem);
			mainMenu.add(serializeMenu);
			mainMenu.add(separator3);
			paintMenu.setText("Painting");
			paintMenu.setActionCommand("Painting");
			paintNodesItem.setSelected(true);
			paintNodesItem.setText("Show Node Location Info");
			paintNodesItem.setActionCommand("Show Node Location Info");
			paintMenu.add(paintNodesItem);
			paintEdgesItem.setSelected(true);
			paintEdgesItem.setText("Show Edge Location Info");
			paintEdgesItem.setActionCommand("Show Edge Location Info");
			paintMenu.add(paintEdgesItem);
			paintScreenItem.setSelected(true);
			paintScreenItem.setText("Paint on Screen");
			paintScreenItem.setActionCommand("Paint on Screen");
			paintMenu.add(paintScreenItem);
			mainMenu.add(paintMenu);
			MainClass.mainFrame.PacketAnalyzersMenu.add(mainMenu);//this last command adds this entire menu to the main PacketAnalyzers menu
			//}}

			//{{REGISTER_LISTENERS
			packetProcessingCheckBox.addItemListener(this);
			backgroundProcessingCheckBox.addItemListener(this);
			propertiesItem.addActionListener(this);
			saveNodesItem.addActionListener(this);
			loadNodesItem.addActionListener(this);
			saveEdgesItem.addActionListener(this);
			loadEdgesItem.addActionListener(this);
			paintNodesItem.addItemListener(this);
			paintEdgesItem.addItemListener(this);
			paintScreenItem.addItemListener(this);
			//}}
		}

		      //----------------------------------------------------------------------
		      //EVENT HANDLERS
		      //The following two functions handle menu events
		      //The functions following this are the event handling functions
		public void actionPerformed(ActionEvent e)
		{
			Object object = e.getSource();
			if (object == saveNodesItem)
				SaveNodes();
			else if (object == loadNodesItem)
				LoadNodes();
			else if (object == saveEdgesItem)
				SaveEdges();
			else if (object == loadEdgesItem)
				LoadEdges();
			else if (object == propertiesItem)
				ShowOptionsDialog();
		}

		public void itemStateChanged(ItemEvent e)
		{
			Object object = e.getSource();
			if (object == packetProcessingCheckBox)
				TogglePacketProcessing();
			else if (object == backgroundProcessingCheckBox)
				ToggleBackgroundProcessing();
			else if (object == paintNodesItem)
				ToggleNodePainting();
			else if (object == paintEdgesItem)
				ToggleEdgePainting();
			else if (object == paintScreenItem)
				ToggleScreenPainting();
		}		
		      //EVENT HANDLERS
		      //----------------------------------------------------------------------

	        	//------------------------------------------------------------------------
	        	//****---SAVE NODES---****
	        	//takes the node hashtable and saves it to a file
		public void SaveNodes()
		{
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Save Nodes", FileDialog.SAVE);
			dialog.show();
			String filename = dialog.getFile();
			if( (filename != null) && (proprietaryNodeInfo!=null))
			{
				try
				{
					FileOutputStream fos = new FileOutputStream(filename);
					GZIPOutputStream gos = new GZIPOutputStream(fos);
					ObjectOutputStream out = new ObjectOutputStream(gos);
					out.writeObject(proprietaryNodeInfo);
					out.flush();
					out.close();
				}
				catch(Exception e){e.printStackTrace();}
			}
		}
	        	//****---SAVE NODES---****
	        	//------------------------------------------------------------------------
		 

	        	//------------------------------------------------------------------------
	        	//****---LOAD NODES---****
	        	//takes a file and loads the nodes into proprietaryNodeInfo hashtable
		public void LoadNodes()
		{        //in the future, it should prompt the user for which node should be kept
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Save Nodes", FileDialog.SAVE);
			dialog.show();
			String filename = dialog.getFile();
			if(filename != null)
			{
				NodeInfo currentNodeInfo;
				Hashtable newNodes;
				try
				{
					FileInputStream fis = new FileInputStream(filename);
					GZIPInputStream gis = new GZIPInputStream(fis);
					ObjectInputStream in = new ObjectInputStream(gis);
					newNodes = (Hashtable)in.readObject();
					in.close();
				}
				catch(Exception e){e.printStackTrace(); return;}
				
				if((proprietaryNodeInfo == null) || (proprietaryNodeInfo.isEmpty()))//if there are no nodes yet, just assign the new nodes to the entire vector
				{
					proprietaryNodeInfo = newNodes;
				}
				else//otherwise take the new nodes and add them to the vector (first eliminating repeat nodes)  ...in the future, we should ask the user which node to keep, in the case of repeat nodes
				{
					for(Enumeration e = newNodes.elements();e.hasMoreElements();)
					{
						currentNodeInfo = (NodeInfo)e.nextElement();
						proprietaryNodeInfo.remove(currentNodeInfo.GetNodeNumber());
						proprietaryNodeInfo.put(currentNodeInfo.GetNodeNumber(), currentNodeInfo);
					}
				}
					
			}
		}
	        	//****---LOAD NODES---****
	        	//------------------------------------------------------------------------
	 

	        	//------------------------------------------------------------------------
	        	//****---SAVE EDGES---****
	        	//takes the node hashtable and saves it to a file
		public void SaveEdges()
		{
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Save Nodes", FileDialog.SAVE);
			dialog.show();
			String filename = dialog.getFile();
			if( (filename != null) && (proprietaryEdgeInfo!=null))
			{
				try
				{
					FileOutputStream fos = new FileOutputStream(filename);
					GZIPOutputStream gos = new GZIPOutputStream(fos);
					ObjectOutputStream out = new ObjectOutputStream(gos);
					out.writeObject(proprietaryEdgeInfo);
					out.flush();
					out.close();
				}
				catch(Exception e){e.printStackTrace();}
			}
		}
	        	//****---SAVE EDGES---****
	        	//------------------------------------------------------------------------
		 

	        	//------------------------------------------------------------------------
	        	//****---LOAD EDGES---****
	        	//takes a file and loads the nodes into proprietaryNodeInfo hashtable
		public void LoadEdges()
		{        //in the future, it should prompt the user for which node should be kept
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Save Nodes", FileDialog.SAVE);
			dialog.show();
			String filename = dialog.getFile();
			if(filename != null)
			{
				EdgeInfo currentEdgeInfo;
				TwoKeyHashtable newEdges;
				try
				{
					FileInputStream fis = new FileInputStream(filename);
					GZIPInputStream gis = new GZIPInputStream(fis);
					ObjectInputStream in = new ObjectInputStream(gis);
					newEdges = (TwoKeyHashtable)in.readObject();
					in.close();
				}
				catch(Exception e){e.printStackTrace(); return;}
				
				if((proprietaryEdgeInfo == null) || (proprietaryEdgeInfo.isEmpty()))//if there are no Edges yet, just assign the new Edges to the entire vector
				{
					proprietaryEdgeInfo = newEdges;
				}
				else//otherwise take the new Edges and add them to the vector (first eliminating repeat Edges)  ...in the future, we should ask the user which node to keep, in the case of repeat Edges
				{
					for(Enumeration e = newEdges.elements();e.hasMoreElements();)
					{
						currentEdgeInfo = (EdgeInfo)e.nextElement();
						proprietaryEdgeInfo.remove(currentEdgeInfo.GetSourceNodeNumber(),currentEdgeInfo.GetDestinationNodeNumber());
						proprietaryEdgeInfo.put(currentEdgeInfo.GetSourceNodeNumber(),currentEdgeInfo.GetDestinationNodeNumber(), currentEdgeInfo);
					}
				}
					
			}
		}
	        	//****---LOAD EDGES---****
	        	//------------------------------------------------------------------------

		      
		      //------------------------------------------------------------------------
		      //****---TOGGLE PACKET PROCESSING
		      //This function will either register or de-register this PacketAnalyzer
		      //as a PacketEventListener.  
		public void TogglePacketProcessing()
		{
			if(packetProcessingCheckBox.isSelected())
			{ //Note:  the following syntax "LocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.AddPacketEventListener(MassSpringsLocationAnalyzer.this);//start the background thread of the enclosing packetAnalyzer
			}
			else
			{
				MainClass.RemovePacketEventListener(MassSpringsLocationAnalyzer.this);//stop the background thread of the enclosing packetAnalyzer
			}
		}
		      //****---TOGGLE PACKET PROCESSING
		      //------------------------------------------------------------------------
		
		      //------------------------------------------------------------------------
		      //****---TOGGLE BACKGROUND PROCESSING
		public void ToggleBackgroundProcessing()
		{
			if(backgroundProcessingCheckBox.isSelected())
			{
				start();//start the background thread of the enclosing packetAnalyzer
			}
			else
			{
				stop();//stop the background thread of the enclosing packetAnalyzer
			}
		}
		      //****---TOGGLE BACKGROUND PROCESSING
		      //------------------------------------------------------------------------
		
		      //------------------------------------------------------------------------
		      //****---TOGGLE NODE PAINTING
		      //This function will either register or de-register this PacketAnalyzer
		      //as a NodePainter.  
		public void ToggleNodePainting()
		{
			if(paintNodesItem.isSelected())
			{ //Note:  the following syntax "LocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddNodePainter(MassSpringsLocationAnalyzer.this);//paint the nodes
			}
			else
			{
				MainClass.displayManager.RemoveNodePainter(MassSpringsLocationAnalyzer.this);//paint the nodes
			}
		}
		      //****---TOGGLE NODE PAINTING
		      //------------------------------------------------------------------------
		
		
		      //------------------------------------------------------------------------
		      //****---TOGGLE EDGE PAINTING
		      //This function will either register or de-register this PacketAnalyzer
		      //as an EdgePainter.  
		public void ToggleEdgePainting()
		{
			if(paintEdgesItem.isSelected())
			{ //Note:  the following syntax "LocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddEdgePainter(MassSpringsLocationAnalyzer.this);//paint the edges
			}
			else
			{
				MainClass.displayManager.RemoveEdgePainter(MassSpringsLocationAnalyzer.this);//paint the edges
			}
		}
		      //****---TOGGLE EDGE PAINTING
		      //------------------------------------------------------------------------
		
		      //------------------------------------------------------------------------
		      //****---TOGGLE SCREEN PAINTING
		      //This function will either register or de-register this PacketAnalyzer
		      //as a Screen Painter.  
		public void ToggleScreenPainting()
		{
			if(paintScreenItem.isSelected())
			{ //Note:  the following syntax "LocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddScreenPainter(MassSpringsLocationAnalyzer.this);//
			}
			else
			{
				MainClass.displayManager.RemoveScreenPainter(MassSpringsLocationAnalyzer.this);//
			}
		}
		      //****---TOGGLE SCREEN PAINTING
		      //------------------------------------------------------------------------
		
		
	}	          
              //MENU MANAGER
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************

}