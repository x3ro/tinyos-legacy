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

//*********************************************************
//*********************************************************
//This file is a template that shows the conventions on how to write a 
//PacketAnalyzer subclass.  It shows you how to do the following things
// 1. recieve and process a new data packet
// 2. recieve and process new node or edge clicks in the interface 
// 3. recieve and process the creation or deletion of nodes or edges
// 4. Display a panel on the edge or node properties panels when they are clicked
// 5. Add graphical output to the node, edge or the screen
// 6. Display a properties panel to edit parameters of this PacketAnalyzer
// 7. run this process in the background as a seperate thread
//*********************************************************
//*********************************************************
//If you want to write a new class to do packet analysis, you should
//not change any files besides this one, the MainFrame class (where you add menus)
//And the MainClass (where this class is instantiated).  This modularity
//will help maintain future compatibilty with other people's analyzers.
//*********************************************************
//*********************************************************
//The main thing to understand here is that the class is highly multithreaded.
// 1.  It can spawn a thread in the constructor to run in the background (as shown below)
// 2.  It can spawn new threads every time an event is recieved (to free the eventGenerating thread)
// 3.  Every "EventRecieved()" function is initially run on the thread of the object that generated the event
//        In this case, the following functions are initially run on the threads of the following objects
//          a.  PacketRecieved()                             -->  PacketListener
//          b.  NodeCreated/Deleted(), EdgeCreated/Deleted() -->  ObjectMaintainer
//			c.  NodeClicked(), EdgeClicked()				 -->  DisplayManager
//			d.	PaintNode(), PaintEdge(), PaintScreen()		 -->  DisplayManager
//			e.  GetProrietaryNode/EdgeDisplayPanel()		 --> DisplayManager
// 4.  All Get/Set functions may be called by the GUI thread
// 5.  The constructor is called on the main() thread of the entire program
//*********************************************************
//*********************************************************
//As a general rule for avoiding synchronization problems:
// 1.  All functions should be synchronized (except run() and the constructor) to eliminate problems with member 
//      variables (i.e. only one thread can be running functions of this object at a time)
// 2.  All threads in the constructor should be started at the end of the constructor to eliminate problems between that thread and the code in the constructor
// 3.  Be careful about synchronizing over methods that call functions in other classes
//		It could cause problems if, for example, I grab resource A, somebody else grabs resource B, I grab resource B, somebody else wants resource A.  We both end up waiting forever. 
// 4.  Try not to call more than one synchronized method within the same call stack. (don't have one thread synchronized on more than one object at a time)
//*********************************************************
//*********************************************************

package Surge.PacketAnalyzers;//make sure you put this class in the Surge/PacketAnalyzer folder

import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;
import java.lang.*;
import javax.swing.*;
import Surge.Dialog.*;
import Surge.Packet.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.zip.*;
        
public class GridLocationAnalyzer extends PacketAnalyzer implements LocationAnalyzer//, java.io.Serializable
{
	          //Define your member variables (try not to have publics)
	protected Hashtable proprietaryNodeInfo;
	protected TwoKeyHashtable proprietaryEdgeInfo;
	protected Thread thread;
	protected MenuManager menuManager;
	protected boolean persistantLocations;//this variable determines whether NodeInfo objects are deleted when nodes expire
	protected boolean includeManualNodes;//this varuable determines whether a blank space should be left for nodes which were placed by hand.
              //------------------------------------------------------------------------
	          //*****---CONSTRUCTOR---******// 
	          //the constructor should be called by the MainClass constructor when 
	          //it instantiates all the packetAnalyzers that we want
	          //Make sure you edit that constructor to do so
	public GridLocationAnalyzer ()
	{
		persistantLocations = true;//this variable determines whether NodeInfo objects are deleted when nodes expire
		includeManualNodes = true;//this varuable determines whether a blank space should be left for nodes which were placed by hand.

		//create new hashtables for your proprietary data
		proprietaryNodeInfo = new Hashtable();
		proprietaryEdgeInfo = new TwoKeyHashtable();
				      
              //register to be notified of nodes and edges being created or deleted
		MainClass.objectMaintainer.AddNodeEventListener(this);//listen to edge event

              //register myself to be able to contribute to the node/edge properties panel
		MainClass.displayManager.AddNodeDialogContributor(this);

			//register myself to recieve NodeClickedEvents and EdgeClickedEvents
		MainClass.displayManager.AddNodeClickedEventListener(this);

              //register myself to paint nodes and edges and display info panels
		MainClass.displayManager.AddNodePainter(this);//paint the nodes //remember to change the default checkbox setting in the menuManager if you delete this line
		
		menuManager = new MenuManager();//this creates the menu, adds it to the MainMenuBar, and creates and object to handle all menu events
		
	}
	          //*****---CONSTRUCTOR---******//
              //------------------------------------------------------------------------
	
	
           
              //************************************************************************
              //************************************************************************
              //the following four functions correspond with the 
              //NodeEventListener and EdgeEventListener interfaces and only work if you 
              //register as a listener for these events as show in the constructor.
              //Note that becuase of the order the packetAnalyzers were created
              //in the MainClass cosntructor, the ObjectMaintainer will always get
              //a packet before all other PacketAnalyzers. 
              //************************************************************************
              //************************************************************************
              
              
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
    	LocalizeNodes();
    }
	          //*****---Node Created---******//
              //------------------------------------------------------------------------

    
              //------------------------------------------------------------------------
    	          //*****---Node Deleted---******//
	          //this function defines what you do when a new node is deleted
	          //It is called by Surge.PacketAnalyzers.ObjectMainter
    public synchronized void NodeDeleted(NodeEvent e)
    {
    	if(persistantLocations==false)//if we don't delete the NodeInfo objects, they will be stored and used again when the node appears again.  Otherwise, all old data will be thrown away
    	{
	    	Integer deletedNodeNumber = e.GetNodeNumber();//you probably want to delete the info pbject to track the data of this new node
		   	proprietaryNodeInfo.remove(deletedNodeNumber);//but you might also want to leave it there but disable it, unless this node reappears and you want to use the same info
    	}
    	LocalizeNodes();
    }
	          //*****---Node Deleted---******//
              //------------------------------------------------------------------------


              //************************************************************************
              //************************************************************************
              //the following two functions correspond to the 
              //NodeClickedEventListener, EdgeClickedEventListener interfaces and will
              //only work if you register as a listener for these events
              //************************************************************************
              //************************************************************************

              
              //------------------------------------------------------------------------
	          //*****---Edge Clicked---******//
	          //this function defines what you do when a node is clicked
	          //It is called by Surge.DisplayManager
/*    public synchronized void NodeClicked(NodeClickedEvent e)
    {
    	Integer nodeClicked = e.GetNodeNumber();
    	      //and maybe do some other processing
    }*/
	          //*****---Node Clicked---******//
              //------------------------------------------------------------------------

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


    
              //************************************************************************
              //************************************************************************
              //the following two functions correspond to the 
              //NodeDialogContributor, EdgeDialogContributor interfaces and will
              //only work if you register as a contributor as shown in the constructor.
              //You must define the ProprietaryNodeInfoPanel and ProprietaryEdgeInfoPanel
              //classes and they will automaticallyshow up when a node/edge is clicked
              //by using the following two functions.
              //************************************************************************
              //************************************************************************

    
              //------------------------------------------------------------------------
	          //GET PROPRIETARY NODE INFO PANEL
	          //This function returns the Panel that you define it to retunr
	          //which will then automatically appear ina dialog when a node is clicked.
	          //this function is called by DisplayManager
	public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber)
	{
		NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
		if(nodeInfo==null) 
			return null;
		ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel(nodeInfo);
		return (ActivePanel)panel;
	}
	          //GET PROPRIETARY NODE INFO PANEL
              //------------------------------------------------------------------------

    
    
    
              //************************************************************************
              //************************************************************************
              //the following three functions correspond to the 
              //NodePainter, EdgePainter, and ScreenPainter interfaces and will
              //only work if you register as a Painter as shown in the constructor.
              //Whatever  painting function you implement here will be called every
              //time a node or edge is painted, and after all the nodes/edges are painted
              //the paintScreen functions are called.  You are called in the order that
              //you register as a painter.
              //************************************************************************
              //************************************************************************

              
              //------------------------------------------------------------------------
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
	          //NODE PAINTER
              //------------------------------------------------------------------------

              
              
              //------------------------------------------------------------------------
	          //*****---LOCALIZE NODES---******//
	 public void LocalizeNodes()
	 {
		Enumeration nodes = proprietaryNodeInfo.elements();
		NodeInfo currentNodeInfo;

		int numNodes = proprietaryNodeInfo.size();
		if(includeManualNodes == false)//
		{
			int numFixed = 0;
			for(;nodes.hasMoreElements();)//if we are not including the fixed nodes then subtract them from the total
			{
				currentNodeInfo = (NodeInfo)nodes.nextElement();
				if(currentNodeInfo.GetFixed()) numFixed++;
			}
			numNodes -= numFixed;
		}
			
		double heightD = Math.sqrt(numNodes);
		int heightI = (int)Math.ceil(heightD);
		for(int r = 1; r <= heightI; r++)
		{
			for(int c = 1; c <= heightI; c++) 
			{
				if(nodes.hasMoreElements())
				{	
					currentNodeInfo = (NodeInfo)nodes.nextElement();
					while(currentNodeInfo.GetFixed() == true)//if we are not including the fixed nodes, then keep going until we find one that is not
					{
						currentNodeInfo = (NodeInfo)nodes.nextElement();
					}
					currentNodeInfo.SetX(c/heightI);
					currentNodeInfo.SetY(r/heightI);
				}
			}
		}
	 }
	          //*****---LOCALIZE NODES---******//
              //------------------------------------------------------------------------

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
			if((x1==Double.NaN) || (y1==Double.NaN) || (x2==Double.NaN) || (y2==Double.NaN)) continue;
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


              //------------------------------------------------------------------------
              //INTERFACE TO PROPRIETARY DATA
              //write some functions here that will let other Analyzers find and user your data
	public NodeInfo GetNodeInfo(Integer nodeNumber){return (NodeInfo)proprietaryNodeInfo.get(nodeNumber);}
	public EdgeInfo GetEdgeInfo(Integer sourceNumber, Integer destinationNumber){return (EdgeInfo)proprietaryEdgeInfo.get(sourceNumber,destinationNumber);}
	public Enumeration GetNodeInfo(){return proprietaryNodeInfo.elements();}
	public Enumeration GetEdgeInfo(){return proprietaryEdgeInfo.elements();}
    public double GetDistance(Integer sourceNodeNumber, Integer destinationNodeNumber )
    {
/*    	EdgeInfo edgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(sourceNodeNumber, destinationNodeNumber);
    	if(edgeInfo != null)
    	{
    		return edgeInfo.GetDistance();
    	}
    	else
    	{*/
    		return Double.NaN;
//    	}
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
              //INTERFACE TO PROPRIETARY DATA
              //------------------------------------------------------------------------





              //------------------------------------------------------------------------
	          //*****---SHOW PROPERTIES DIALOG---******//
	          //this function can be called by MainFrame (by the menus, in particular)
	          //and should simply show the dialog as shown here.
	          //You need to define the class "GridLocationAnalyzerPropertiesPanel"
	          //in order for this to do anything.  it is useful for setting parameters
	          //on your analyzer.
	public void ShowOptionsDialog() 
	{
		StandardDialog newDialog = new StandardDialog(new OptionsPanel());
		newDialog.show();
	}

	public ActivePanel GetOptionsPanel() 
	{
		return new OptionsPanel();
	}
//*****---SHOW PROPERTIES DIALOG---******//
              //------------------------------------------------------------------------
	          


	public static class NodeInfo implements java.io.Serializable
	{
		protected double x;
		protected double y;
		protected Integer nodeNumber;
		protected boolean fixed;//determines if the node can move around automatically or not
		protected boolean displayCoords;//determines if the XY Coords should be drawn
		
		public NodeInfo(){}
		
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

	public static class EdgeInfo implements java.io.Serializable
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
			displayLength = false;
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
              //GridLocationAnalyzerPropertiesPanel
              //This class is an ActivePanel and should have all the information
              //in GUI form that this class stores with respect to EDGES
              //It will be displayed automatically with ShowOptionsDialog
	public class OptionsPanel extends Surge.Dialog.ActivePanel
	{		
		public OptionsPanel()
		{
			tabTitle = "Grid Location Analyzer";//this will be the title of the tab
			//{{INIT_CONTROLS
			setLayout(null);
//			Insets ins = getInsets();
			setSize(307,168);
			JCheckBox1.setToolTipText("Check this is you want to remember the positions of the nodes even after they expire (in case they reappear)");
			JCheckBox1.setText("Persistant Locations");
			add(JCheckBox1);
			JCheckBox1.setBounds(36,20,168,24);
			JCheckBox2.setToolTipText("Check this is you want a blank space in the grid for all nodes which you placed by hand");
			JCheckBox2.setText("Include Manual Nodes");
			add(JCheckBox2);
			JCheckBox2.setBounds(36,50,168,24);

			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
		javax.swing.JCheckBox JCheckBox2 = new javax.swing.JCheckBox();
		//}}
		
		public void ApplyChanges()//this function will be called when the apply button is hit
		{
			persistantLocations = JCheckBox1.isSelected();
			includeManualNodes = JCheckBox2.isSelected();
		}
		
		public void InitializeDisplayValues()//this function will be called when the panel is first shown
		{
			JCheckBox1.setSelected(persistantLocations);
			JCheckBox2.setSelected(includeManualNodes);
		}
	}	          
              //GridLocationAnalyzerPropertiesPanel
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************

	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //MENU MANAGER
              //This class creates and holds the menu that controls this
              //PacketAnalyzer.  It returns the menu to whoever wants
              //to display it and it also handles all events on the menu
	protected class MenuManager implements Serializable, ActionListener, ItemListener
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
			mainMenu.setText("Grid Location Analyzer");
			mainMenu.setActionCommand("Grid Location Analyzer");
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
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Load Nodes", FileDialog.LOAD );
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
			{ //Note:  the following syntax "GridLocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.AddPacketEventListener(GridLocationAnalyzer.this);//start the background thread of the enclosing packetAnalyzer
			}
			else
			{
				MainClass.RemovePacketEventListener(GridLocationAnalyzer.this);//stop the background thread of the enclosing packetAnalyzer
			}
		}
		      //****---TOGGLE PACKET PROCESSING
		      //------------------------------------------------------------------------
		
		      //------------------------------------------------------------------------
		      //****---TOGGLE BACKGROUND PROCESSING
		public void ToggleBackgroundProcessing()
		{
/*			if(backgroundProcessingCheckBox.isSelected())
			{
				start();//start the background thread of the enclosing packetAnalyzer
			}
			else
			{
				stop();//stop the background thread of the enclosing packetAnalyzer
			}*/
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
			{ //Note:  the following syntax "GridLocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddNodePainter(GridLocationAnalyzer.this);//paint the nodes
			}
			else
			{
				MainClass.displayManager.RemoveNodePainter(GridLocationAnalyzer.this);//paint the nodes
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
			{ //Note:  the following syntax "GridLocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddEdgePainter(GridLocationAnalyzer.this);//paint the edges
			}
			else
			{
				MainClass.displayManager.RemoveEdgePainter(GridLocationAnalyzer.this);//paint the edges
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
			{ //Note:  the following syntax "GridLocationAnalyzer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddScreenPainter(GridLocationAnalyzer.this);//
			}
			else
			{
				MainClass.displayManager.RemoveScreenPainter(GridLocationAnalyzer.this);//
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
