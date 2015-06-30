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
        
public class PacketAnalyzerTemplate extends PacketAnalyzer implements java.lang.Runnable 
{
	          //Define your member variables (try not to have publics)
	protected int variableName;
	protected Hashtable proprietaryNodeInfo;
	protected TwoKeyHashtable proprietaryEdgeInfo;
	protected Thread thread;
	protected MenuManager menuManager;
              //------------------------------------------------------------------------
	          //*****---CONSTRUCTOR---******// 
	          //the constructor should be called by the MainClass constructor when 
	          //it instantiates all the packetAnalyzers that we want
	          //Make sure you edit that constructor to do so
	public PacketAnalyzerTemplate ()
	{
            //initialize your variables
        variableName = 0;

		//create new hashtables for your proprietary data
		proprietaryNodeInfo = new Hashtable();
		proprietaryEdgeInfo = new TwoKeyHashtable();
				      
              //register to be notified of nodes and edges being created or deleted
		MainClass.objectMaintainer.AddEdgeEventListener(this);//listen to node events
		MainClass.objectMaintainer.AddNodeEventListener(this);//listen to edge event

              //register myself to be able to contribute to the node/edge properties panel
		MainClass.displayManager.AddNodeDialogContributor(this);
		MainClass.displayManager.AddEdgeDialogContributor(this);

			//register myself to recieve NodeClickedEvents and EdgeClickedEvents
		MainClass.displayManager.AddNodeClickedEventListener(this);
		MainClass.displayManager.AddEdgeClickedEventListener(this);

              //register myself to paint nodes and edges and display info panels
		MainClass.displayManager.AddNodePainter(this);//paint the nodes //remember to change the default checkbox setting in the menuManager if you delete this line
		MainClass.displayManager.AddEdgePainter(this);//paint the edges //remember to change the default checkbox setting in the menuManager if you delete this line
		MainClass.displayManager.AddScreenPainter(this);//paint on the screen over the edges and nodes //remember to change the default checkbox setting in the menuManager if you delete this line
		
		menuManager = new MenuManager();//this creates the menu, adds it to the MainMenuBar, and creates and object to handle all menu events
		
		//instantiate and start the thread you will use if you want to run the run() function of this analyzer in the background on a seperate thread.  Otherwise, delete these lines.
		thread = new Thread(this);
		try{
			thread.setPriority(Thread.MIN_PRIORITY);
			thread.start(); //recall that start() calls the run() method defined in this class
		}
		catch(Exception e){e.printStackTrace();}
	}
	          //*****---CONSTRUCTOR---******//
              //------------------------------------------------------------------------
	
	
              //------------------------------------------------------------------------
              //EXAMPLE FUNCTION
	          //*****---An example function with example code---******//
	          //naming convention is as shown here.
	          //Be sure to synchronize this function if it is being called from more than
	          //one of the following threads
	          // 1.  your own thread (the run() function)
	          // 2.  PacketReciever threads (packetRecieved() function)
	          // 3.  ObjectMaintainer thread (NodeCreated/Deleted() or EdgeCreated/Deleted() functions)
	          // 4.  GUI thread (Node/Edge Clicked(), GetNode/EdgePanel(), PaintNode/Edge/Screen() functions)
	          // 5.  Any Get/Set function or other function called by the GUI thread
	          //If you do not want to synchronize the entire method (or any method in this class), 
	          //you have to figure out which parts may need to be synchronized over which 
	          //variables, and do it manually
	public synchronized void DummyFunction(Integer pNodeNumber)
	{
		NodeInfo currentNodeInfo;

		//Always synchronize over MainClass.nodes or MainClass.edges if you care that somebody else might add or delete nodes/edges
		if(proprietaryNodeInfo.contains(pNodeNumber)==true)             //e.g the node exists for the if() statement but is deleted and you get a null pointer exception when you try to paint it (In this case you should just use: currentNode = MainClass.nodes.get(Number) and afterward check if currentNode == null.  Remember to synchronize over currentNode).
		{
			currentNodeInfo = ((NodeInfo)proprietaryNodeInfo.get(pNodeNumber));	    	
		}
		else 
		{
			currentNodeInfo = new NodeInfo(pNodeNumber);
		}
	}
			  //*****---An example function with example code---******//
              //------------------------------------------------------------------------
	 
	          
              //------------------------------------------------------------------------
	          //*****---Packet Recieved event handler---******//
	          //this function will be called by the thread running the packetReciever
	          //everytime a new packet is recieved
	          //make sure it is synchronized if it modifies any of your data
    public synchronized void PacketRecieved(PacketEvent e)
    {
                //this function defines what you do when a new packet is heard by the system (recall that the parent class (PacketAnalyzer) already registered you to listen for new packets automatically)
                //if this is a long function, you should call it in a seperate thread to allow the PacketReciever thread to continue recieving packets
                        
    	Packet packet = e.GetPacket();//you might want to get the packet out of the event
		Date eventTime = e.GetTime(); //you might want to get the time the packet was recieved
		
    	Integer currentNodeNumber; //you might want to define a few local variables
    	NodeInfo currentNodeInfo;   //this can hold the proprietary info of some node
    	EdgeInfo currentEdgeInfo;   //this can hold the proprietary info os some edge

		
		//you might want to get some data out of the packet, e.g. the routePath vector
		Vector routePath = packet.CreateRoutePathArray();

              //here is an example of how to process the packet
		for(Enumeration nodeNumbers = routePath.elements(); nodeNumbers.hasMoreElements();)
		{
			currentNodeNumber = (Integer)nodeNumbers.nextElement();
			currentNodeInfo = (NodeInfo)proprietaryNodeInfo.get(currentNodeNumber);//update the timelastSeen
		}     
	}	
	          //*****---Packet Recieved event handler---******//
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
    }
	          //*****---Node Created---******//
              //------------------------------------------------------------------------

    
              //------------------------------------------------------------------------
    	          //*****---Node Deleted---******//
	          //this function defines what you do when a new node is deleted
	          //It is called by Surge.PacketAnalyzers.ObjectMainter
    public synchronized void NodeDeleted(NodeEvent e)
    {
    	Integer deletedNodeNumber = e.GetNodeNumber();//you probably want to delete the info pbject to track the data of this new node
    	proprietaryNodeInfo.remove(deletedNodeNumber);//but you might also want to leave it there but disable it, unless this node reappears and you want to use the same info
    	      //if so, build in a disable boolean into your NodeInfo Class
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
    	      //if so, build in a disable boolean into your EdgeInfo Class
    }
	          //*****---EdgeDeleted---******//
              //------------------------------------------------------------------------


              //************************************************************************
              //************************************************************************
              //the following two functions correspond to the 
              //NodeClickedEventListener, EdgeClickedEventListener interfaces and will
              //only work if you register as a listener for these events
              //************************************************************************
              //************************************************************************

              
              //------------------------------------------------------------------------
	          //*****---NODE Clicked---******//
	          //this function defines what you do when a node is clicked
	          //It is called by Surge.DisplayManager
    public synchronized void NodeClicked(NodeClickedEvent e)
    {
    	Integer nodeClicked = e.GetNodeNumber();
    	      //and maybe do some other processing
    }
	          //*****---Node Clicked---******//
              //------------------------------------------------------------------------

	          
              //------------------------------------------------------------------------
	          //*****---NODE DRAGGED---******//
	          //this function defines what you do when a node is clicked
	          //It is called by Surge.DisplayManager
    public synchronized void NodeDragged(NodeDraggedEvent e)
    {
    	Integer nodeDragged = e.GetNodeNumber();
    	      //and maybe do some other processing
    }
	          //*****---Node Clicked---******//
              //------------------------------------------------------------------------

	          
              //------------------------------------------------------------------------
	          //*****---Edge Clicked---******//
	          //this function defines what you do when an edge is clicked
	          //It is called by Surge.DisplayManager
    public synchronized void EdgeClicked(EdgeClickedEvent e)
    {
		Integer sourceClicked = e.GetSourceNodeNumber();    	      
		Integer destinationClicked = e.GetDestinationNodeNumber();    	      
    	      //and maybe do some other processing
    }
	          //*****---Edge Clicked---******//
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


              //------------------------------------------------------------------------
	          //GET PROPRIETARY EDGE INFO PANEL
	          //This function returns the Panel that you define it to retunr
	          //which will then automatically appear ina dialog when an edge is clicked.
	          //this function is called by DisplayManager
	public ActivePanel GetProprietaryEdgeInfoPanel(Integer pSourceNodeNumber, Integer pDestinationNodeNumber) 
	{
		EdgeInfo edgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(pSourceNodeNumber, pDestinationNodeNumber);
		if(edgeInfo==null)
			return null;
		ProprietaryEdgeInfoPanel panel = new ProprietaryEdgeInfoPanel(edgeInfo);
		return (ActivePanel)panel;
	}
	          //GET PROPRIETARY EDGE INFO PANEL
              //------------------------------------------------------------------------

              //------------------------------------------------------------------------
	          //*****---SHOW PROPERTIES DIALOG---******//
	          //this function can be called by MainFrame (by the menus, in particular)
	          //and should simply show the dialog as shown here.
	          //You need to define the class "PacketAnalyzerTemplatePropertiesPanel"
	          //in order for this to do anything.  it is useful for setting parameters
	          //on your analyzer.
	public void ShowOptionsDialog() 
	{
		StandardDialog newDialog = new StandardDialog(new OptionsPanel());
		newDialog.show();
	}
				//*****---SHOW PROPERTIES DIALOG---******//
              //------------------------------------------------------------------------


              //------------------------------------------------------------------------
				//*****---GET PROPERTIES Panel---******//
			  //this function is used to get the options panel to display in
			  //the general options dialog.  return null if you don't have an options panel
	public ActivePanel GetOptionsPanel() 
	{
		return new OptionsPanel();
	}
				//*****---GET PROPERTIES Panel---******//
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
		if(nodeInfo==null)
			return;
			  //now use the info in your NodeInfo object to paint something
	}
	          //NODE PAINTER
              //------------------------------------------------------------------------
              
              
              //------------------------------------------------------------------------
	          //EDGE PAINTER
	          //Put some function here to paint whatever you want over the edge.
	          //The x1,y1 coordinates are the source of the edge
	          //The x2,y2 coordinates are the destination
	          //Paint everything on the graphics object
	          //this function is called by DisplayManager
	public void PaintEdge(Integer pSourceNodeNumber, Integer pDestinationNodeNumber, int x1, int y1, int x2, int y2, Graphics g) 
	{
		EdgeInfo edgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(pSourceNodeNumber,pDestinationNodeNumber);
		if(edgeInfo==null)
			return;
			  //now use the info in your edgeInfo object to paint something
	}
	          //EDGE PAINTER
              //------------------------------------------------------------------------
              
              
              //------------------------------------------------------------------------
	          //SCREEN PAINTER
	          //Put some function here to paint whatever you want over the screen before and after
	          //all edges and nodes have been painted.
	public void PaintScreenBefore(Graphics g) 
	{
		      //paint something on the graphics object
	}

	public void PaintScreenAfter(Graphics g) 
	{
		      //paint something on the graphics object
	}
	          //SCREEN PAINTER
              //------------------------------------------------------------------------

              
              //************************************************************************
              //************************************************************************
              //the following functions correspond to the thread instantiated in the
              //constructor and will only work if you actually instantiate it.
              //The Run function is what the thread does.  The functions following
              //it are wrappers of the thread function to let us control the thread.
              //************************************************************************
              //************************************************************************
         
              
              //------------------------------------------------------------------------
	          //*****---Run---******//
              //this function runs in a seperate thread whenever you call the two lines: 
              //   thread = new Thread(this); 
              //   thread.start();
    public void run()
    {
		while(true)
    	{
    		//do something here which will run in the background
    		//then sleep for a while
    		try
			{
	    			thread.sleep(1000);//time is in milliseconds
	    	}
			catch(Exception e){e.printStackTrace();}
		}
		
    }
	          //*****---Run---******//
              //------------------------------------------------------------------------
    

              //------------------------------------------------------------------------
	          //*****---Thread commands---******//
	          //you might want to add these thread commands 
    public void start(){ try{ thread=new Thread(this);thread.start();} catch(Exception e){e.printStackTrace();}}
    public void stop(){ try{ thread.stop();} catch(Exception e){e.printStackTrace();}}
    public void sleep(long p){ try{ thread.sleep(p);} catch(Exception e){e.printStackTrace();}}
    public void setPriority(int p) { try{thread.setPriority(p);} catch(Exception e){e.printStackTrace();}}    
			//*****---Thread commands---******//
              //------------------------------------------------------------------------

              //------------------------------------------------------------------------
              //INTERFACE TO PROPRIETARY DATA
              //write some functions here that will let other Analyzers find and user your data
	public NodeInfo GetNodeInfo(Integer nodeNumber){return (NodeInfo)proprietaryNodeInfo.get(nodeNumber);}
	public EdgeInfo GetEdgeInfo(Integer sourceNumber, Integer destinationNumber){return (EdgeInfo)proprietaryEdgeInfo.get(sourceNumber,destinationNumber);}
	public Enumeration GetNodeInfo(){return proprietaryNodeInfo.elements();}
	public Enumeration GetEdgeInfo(){return proprietaryEdgeInfo.elements();}
              //INTERFACE TO PROPRIETARY DATA
              //------------------------------------------------------------------------




              //------------------------------------------------------------------------
	          //*****---GET/SET COMMANDS---******//
	public synchronized int GetVariableName(){ return variableName;}
	public synchronized void SetVariableName(int pVariableName){variableName = pVariableName;}
			  //*****---GET/SET COMMANDS---******//
              //------------------------------------------------------------------------






	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //NODE INFO CLASS
              //this class should hold any special information you hold about the
              //node, for example time created or a history of the number of packets
              //forwarded through this mote or whetever it is you are studying.
              //Make sure this class is static because inner classes try to serialize
              //their enclosing class if they are not static.  If you need to make
              //references to the private PacketAnalyzer functions from the NodeInfo
              //class, however, this class cannot be static.  In that case, you
              //either need to write a custom serialize function or you cannot
              //serialize these NodeInfo objects
	public static class NodeInfo implements Serializable
	{
		protected Integer nodeNumber;
		
		public NodeInfo(Integer pNodeNumber)
		{
			nodeNumber = pNodeNumber;
		}
		
		public Integer GetNodeNumber()
		{
			return nodeNumber;
		}
	}
	          //NODE INFO
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
	
	
	
	        
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
	          //EDGEINFO
              //this class should hold any special information you hold about the
              //edge, for example time created or a history of the number of packets
              //forwarded over this edge or whetever it is you are studying
              //Make sure this class is static because inner classes try to serialize
              //their enclosing class if they are not static.  If you need to make
              //references to the private PacketAnalyzer functions from the EdgeInfo
              //class, however, this class cannot be static.  In that case, you
              //either need to write a custom serialize function or you cannot
              //serialize these EdgeInfo objects
	public static class EdgeInfo implements Serializable
	{
		protected Integer sourceNodeNumber;
		protected Integer destinationNodeNumber;
		
		public EdgeInfo(Integer pSourceNodeNumber, Integer pDestinationNodeNumber)
		{
			sourceNodeNumber = pSourceNodeNumber;
			destinationNodeNumber = pDestinationNodeNumber;
		}
		
		public Integer GetSourceNodeNumber()
		{
			return sourceNodeNumber;
		}
		
		public Integer GetDestinationNodeNumber()
		{
			return sourceNodeNumber;
		}
	}
	          //EDGE INFO
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************



	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //PROPRIETARY NODE INFO DISPLAY PANEL
              //This class is an ActivePanel and should have all the information
              //in GUI form that this class stores with respect to nodes
              //It should be returned with GetProprietaryNodeInfoPanel and it will be displayed
              //with all the other packet analyzer proprietary info when a node is clicked.
	public class ProprietaryNodeInfoPanel extends Surge.Dialog.ActivePanel
	{
		NodeInfo nodeInfo;
		
		public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)
		{
			nodeInfo = pNodeInfo;
			tabTitle = "Packet Analyzer Template";//this will be the title of the tab
			//{{INIT_CONTROLS
			setLayout(null);
//			Insets ins = getInsets();
			setSize(307,168);
			JLabel3.setToolTipText("This text will appear with mouse hover over this component");
			JLabel3.setText("Node NUmber:");
			add(JLabel3);
			JLabel3.setBounds(12,36,108,24);
			JLabel4.setToolTipText("This is the value of NodeNumber");
			JLabel4.setText("text");
			add(JLabel4);
			JLabel4.setBounds(12,60,108,24);
			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
		//}}
		
		public void ApplyChanges()//this function will be called when the apply button is hit
		{
//			nodeInfo.SetNodeNumber(Integer.getInteger(JLabel4.getText()));
		}
		
		public void InitializeDisplayValues()//this function will be called when the panel is first shown
		{
			JLabel4.setText(String.valueOf(nodeInfo.GetNodeNumber()));
		}
	}	          
              //PROPRIETARY NODE INFO DISPLAY PANEL
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************


	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //PROPRIETARY EDGE INFO DISPLAY PANEL
              //This class is an ActivePanel and should have all the information
              //in GUI form that this class stores with respect to EDGES
              //It should be return with GetProprietaryEdgeInfoPanel and it will be displayed
              //with all the other packet analyzer proprietary info when a edgeis clicked.
	public class ProprietaryEdgeInfoPanel extends Surge.Dialog.ActivePanel
	{
		EdgeInfo edgeInfo;
		
		public ProprietaryEdgeInfoPanel(EdgeInfo pEdgeInfo)
		{
			edgeInfo = pEdgeInfo;
			tabTitle = "Packet Analyzer Template";//this will be the title of the tab
			//{{INIT_CONTROLS
			setLayout(null);
//			Insets ins = getInsets();
			setSize(307,168);
			JLabel3.setToolTipText("This text will appear with mouse hover over this component");
			JLabel3.setText("Source Node NUmber:");
			add(JLabel3);
			JLabel3.setBounds(12,36,108,24);
			JLabel4.setToolTipText("This is the value of SOURCENodeNumber");
			JLabel4.setText("text");
			add(JLabel4);
			JLabel4.setBounds(12,60,108,24);
			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
		//}}
		
		public void ApplyChanges()//this function will be called when the apply button is hit
		{
//			edgeInfo.SetSourceNodeNumber(Integer.getInteger(JLabel4.getText()));
		}
		
		public void InitializeDisplayValues()//this function will be called when the panel is first shown
		{
			JLabel4.setText(String.valueOf(edgeInfo .GetSourceNodeNumber()));
		}
	}	          
              //PROPRIETARY NODE INFO DISPLAY PANEL
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************


	        
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //PacketAnalyzerTemplatePropertiesPanel
              //This class is an ActivePanel and should have all the information
              //in GUI form that this class stores with respect to EDGES
              //It will be displayed automatically with ShowOptionsDialog
	public class OptionsPanel extends Surge.Dialog.ActivePanel
	{		
		public OptionsPanel()
		{
			tabTitle = "Packet Analyzer Template";//this will be the title of the tab
			//{{INIT_CONTROLS
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
			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
		//}}
		
		public void ApplyChanges()//this function will be called when the apply button is hit
		{
			SetVariableName(Integer.getInteger(JLabel4.getText()).intValue());
		}
		
		public void InitializeDisplayValues()//this function will be called when the panel is first shown
		{
			JLabel4.setText(String.valueOf(GetVariableName()));
		}
	}	          
              //PacketAnalyzerTemplatePropertiesPanel
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
              //Some features are already built in for you.  If you do not want
              //them, just delete them.
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
			mainMenu.setText("Packet Analyzer Template");
			mainMenu.setActionCommand("Packet Analyzer Template");
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
			saveNodesItem.setText("Save Nodes");
			saveNodesItem.setActionCommand("Save Nodes");
			serializeMenu.add(saveNodesItem);
			loadNodesItem.setText("Load Nodes");
			loadNodesItem.setActionCommand("Load Nodes");
			serializeMenu.add(loadNodesItem);
			saveEdgesItem.setText("Save Edges");
			saveEdgesItem.setActionCommand("Save Edges");
			serializeMenu.add(saveEdgesItem);
			loadEdgesItem.setText("Load Edges");
			loadEdgesItem.setActionCommand("Load Edges");
			serializeMenu.add(loadEdgesItem);
			mainMenu.add(serializeMenu);
			mainMenu.add(separator3);
			paintMenu.setText("Painting");
			paintMenu.setActionCommand("Painting");
			paintNodesItem.setSelected(true);
			paintNodesItem.setText("Paint on Nodes");
			paintNodesItem.setActionCommand("Paint on Nodes");
			paintMenu.add(paintNodesItem);
			paintEdgesItem.setSelected(true);
			paintEdgesItem.setText("Paint on Edges");
			paintEdgesItem.setActionCommand("Paint on Edges");
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
			{ //Note:  the following syntax "PacketAnalyzerTemplate.this" allows an inner class to refer to its enclosing class
				MainClass.AddPacketEventListener(PacketAnalyzerTemplate.this);//start the background thread of the enclosing packetAnalyzer
			}
			else
			{
				MainClass.RemovePacketEventListener(PacketAnalyzerTemplate.this);//stop the background thread of the enclosing packetAnalyzer
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
			{ //Note:  the following syntax "PacketAnalyzerTemplate.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddNodePainter(PacketAnalyzerTemplate.this);//paint the nodes
			}
			else
			{
				MainClass.displayManager.RemoveNodePainter(PacketAnalyzerTemplate.this);//paint the nodes
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
			{ //Note:  the following syntax "PacketAnalyzerTemplate.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddEdgePainter(PacketAnalyzerTemplate.this);//paint the edges
			}
			else
			{
				MainClass.displayManager.RemoveEdgePainter(PacketAnalyzerTemplate.this);//paint the edges
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
			{ //Note:  the following syntax "PacketAnalyzerTemplate.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddScreenPainter(PacketAnalyzerTemplate.this);//
			}
			else
			{
				MainClass.displayManager.RemoveScreenPainter(PacketAnalyzerTemplate.this);//
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
              //End of Packet Analyzer
	        //*********************************************************
