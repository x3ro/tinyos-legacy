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

//**************************************************************************
//**************************************************************************
//this class reads packets and updates all nodes and paths
//that are in each packet with timestamps, creating
//those nodes or paths that do not exist.
//It also runs the "run" method as a seperate thread,
//which constantly checks the nodes and paths for having expired.
//**************************************************************************
//**************************************************************************

package Surge.PacketAnalyzers;

import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;
import java.lang.*;
import java.io.*;
import java.util.zip.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import Surge.Dialog.*;
import Surge.Packet.*;

 
public class ObjectMaintainer extends PacketAnalyzer implements Runnable
{
	          //these variables define when to eliminate nodes that are no longer in the network
	protected static long nodeExpireTime;
	protected static long edgeExpireTime;
	protected static long nodeInitialPersistance;
	protected static long edgeInitialPersistance;
	protected static long nodeInitialDormancy;
	protected static long edgeInitialDormancy;
//	protected static long edgeStability;
	//protected static long networkSpeed;
	protected static long expirationCheckRate;
	public static Hashtable proprietaryNodeInfo;
	public static TwoKeyHashtable proprietaryEdgeInfo;
	protected static Thread oldObjectDeleterThread;
	protected static Vector nodeListeners;
	protected static Vector edgeListeners;
	protected MenuManager menuManager;

              //-----------------------------------------------------------------------
	          //*****---CONSTRUCTOR---******//
	public ObjectMaintainer()
	{
				//register myself to recieve NodeClickedEvents and EdgeClickedEvents
		MainClass.displayManager.AddNodeDialogContributor(this);
		MainClass.displayManager.AddEdgeDialogContributor(this);
		
		      //all values are in milliseconds
		nodeExpireTime = 2500;
		edgeExpireTime = 2500;
		nodeInitialPersistance = 2500;
		edgeInitialPersistance = 2500;
		nodeInitialDormancy = 2500;
		edgeInitialDormancy = 2500;
		expirationCheckRate = 1500;//in milliseconds
		
		proprietaryNodeInfo = new Hashtable();
		proprietaryEdgeInfo = new TwoKeyHashtable();
		nodeListeners = new Vector();
		edgeListeners = new Vector();
		oldObjectDeleterThread = new Thread(this);

		menuManager = new MenuManager();//this creates the menu, adds it to the MainMenuBar, and creates and object to handle all menu events
		try{
			oldObjectDeleterThread.setPriority(Thread.MIN_PRIORITY);
			oldObjectDeleterThread.start(); //recall that start() calls the run() method defined in this class
		}
		catch(Exception e){e.printStackTrace();}
	}
	          //*****---CONSTRUCTOR---******//
              //-----------------------------------------------------------------------
	
	
              //-----------------------------------------------------------------------
	          //*****---Packet Recieved event handler---******//
    	      //when a new packet is recieved
    	      //look at the list and order of nodes in the hop-path
    	      //update the node times, create nodes that do not exist
    	      //update the edge times, create edges that do not exist
    public  void PacketRecieved(PacketEvent e)
    {
    	Integer currentNodeNumber;
    	Integer previousNodeNumber=new Integer(-1);
    	NodeInfo currentNodeInfo;
    	NodeInfo previousNodeInfo=null;
    	EdgeInfo currentEdgeInfo;
    	Packet packet = e.GetPacket();

		Date eventTime = e.GetTime();
		Vector routePath = packet.CreateRoutePathArray();//vector of "Integer" objects
		
    	      //look at the list and order of nodes in the hop-path
		for(int count=0; count < routePath.size(); count++)
		{
			currentNodeNumber = (Integer)routePath.elementAt(count);
			if((currentNodeInfo = (NodeInfo)proprietaryNodeInfo.get(currentNodeNumber)) !=null)//if node already exists
			{
				if( (currentNodeInfo.GetCreated()==false) && NodeHasBeenSeenRecently(currentNodeInfo.GetTimeLastSeen(), eventTime))//if the node has been seen recently and we haven't told everybody else about him yet
				{
					currentNodeInfo.SetCreated(true);
					currentNodeInfo.SetTimeLastSeen(eventTime);
					TriggerNodeCreatedEvent(new NodeEvent(this, currentNodeNumber, Calendar.getInstance().getTime()));
                }
                else//if it has already been created, but not seen recently
                {
                	currentNodeInfo.SetTimeLastSeen(eventTime);
				}
            }
			else//if it has never been seen before
			{
				proprietaryNodeInfo.put(currentNodeNumber, new NodeInfo(currentNodeNumber, eventTime));//and create new maintenace info
            }

			if(count != 0)//if this isn't the first node, handle the edge between this and the previous node
			{
				//TwoKeyHashtable.Tuple edgeKey = MainClass.edges.new Tuple(currentNodeNumber,previousNodeNumber);
			//and check for existance of edge with previous node in the list
				if( (currentEdgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(currentNodeNumber,previousNodeNumber)) != null)//if the edge between this and previous node exists
				{
					currentEdgeInfo.SetTimeLastSeen(eventTime);
				}
				else if((currentNodeInfo!=null) && (previousNodeInfo!=null)&&(currentNodeInfo.GetCreated() && previousNodeInfo.GetCreated()))//if the edge doesn't but has been seen and both it's parents have been created
				{
					proprietaryEdgeInfo.put(previousNodeNumber, currentNodeNumber, new EdgeInfo(previousNodeNumber, currentNodeNumber, eventTime));//and create new maintenace info)
					TriggerEdgeCreatedEvent(new EdgeEvent(this, previousNodeNumber, currentNodeNumber, Calendar.getInstance().getTime()));
				}
			}
			previousNodeNumber = currentNodeNumber;
			previousNodeInfo = currentNodeInfo;
		}     //end for loop through hop-list
	}
					
	          //*****---Packet Recieved event handler---******//
              //-----------------------------------------------------------------------
    
    
              //-----------------------------------------------------------------------
	          //*****---Run---******//
              //this function constantly deletes old nodes and edges
    public void run()
    {
		while(true)
    	{
    		EliminateExpiredNodes();
    		EliminateExpiredEdges();
			try
			{
	    		oldObjectDeleterThread.sleep(expirationCheckRate);
	    	}
			catch(Exception e){e.printStackTrace();}
		}
		
    }
	          //*****---Run---******//
              //-----------------------------------------------------------------------
    

              //-----------------------------------------------------------------------
	          //*****---NodeHasBeenSeenRecently---******//
    public boolean NodeHasBeenSeenRecently(Date TimeLastSeen, Date currentTime)
    {
		if((currentTime.getTime() - nodeInitialDormancy)  <= TimeLastSeen.getTime())//if it has been seen in time less than nodeInitialDormancy
		{
			return true;
		}
		return false;
    }
	          //*****---Run---******//
              //-----------------------------------------------------------------------

    
              //-----------------------------------------------------------------------
	          //*****---Eliminiate Nodes---******//
     void EliminateExpiredNodes()
    {
		Integer currentNodeNumber;
		NodeInfo currentNodeInfo;
		
		      //for all nodes in the network
		long currentTime;
		for(Enumeration nodes = proprietaryNodeInfo.elements();nodes.hasMoreElements();) 
		{
			currentNodeInfo = (NodeInfo)nodes.nextElement();
			currentNodeNumber = currentNodeInfo.GetNodeNumber();
			
						 //if node has expired, eliminate it
			currentTime = Calendar.getInstance().getTime().getTime();//milliseconds since January 1, 1970
			if( (currentTime - currentNodeInfo.GetTimeLastSeen().getTime() > nodeExpireTime) &&
				(currentTime - currentNodeInfo.GetTimeCreated().getTime() > nodeInitialPersistance))
			{
				proprietaryNodeInfo.remove(currentNodeNumber);
				TriggerNodeDeletedEvent(new NodeEvent(this, currentNodeNumber, Calendar.getInstance().getTime()));
			}
		}
    }
	          //*****---Eliminiate Nodes---******//
              //-----------------------------------------------------------------------
    
    
              //-----------------------------------------------------------------------
	          //*****---Eliminiate Edges---******//
     void EliminateExpiredEdges()
    {
		
		Integer sourceNumber;
		Integer destinationNumber;
		Integer currentEdgeNumber;
		EdgeInfo currentEdgeInfo;
		
		      //for all edges in the network
		long currentTime; 
		for(Enumeration edges = proprietaryEdgeInfo.elements();edges.hasMoreElements();) 
		{
			currentEdgeInfo = (EdgeInfo)edges.nextElement();
			sourceNumber = currentEdgeInfo.GetSourceNodeNumber();//final vairables that don't need to be synchronized
			destinationNumber = currentEdgeInfo.GetDestinationNodeNumber();//final vairables that don't need to be synchronized

						 //if edge has expired, eliminate it
			currentTime = Calendar.getInstance().getTime().getTime();//milliseconds since January 1, 1970
			if( (currentTime - currentEdgeInfo.GetTimeLastSeen().getTime() > edgeExpireTime) &&
				(currentTime - currentEdgeInfo.GetTimeCreated().getTime() > edgeInitialPersistance) )
			{
				proprietaryEdgeInfo.remove(sourceNumber, destinationNumber);
				TriggerEdgeDeletedEvent(new EdgeEvent(this, sourceNumber, destinationNumber, Calendar.getInstance().getTime()));
			}
		}
    }
	          //*****---Eliminiate Edges---******//
              //-----------------------------------------------------------------------
    
    
              //-----------------------------------------------------------------------
	          //*****---ADD EVENT LISTENER---******//
	public static void AddNodeEventListener(NodeEventListener pListener)
	{
		nodeListeners.add(pListener);
	}
	
	public static void RemoveNodeEventListener(NodeEventListener pListener)
	{
		nodeListeners.remove(pListener);
	}
	
	public static void AddEdgeEventListener(EdgeEventListener pListener)
	{
		edgeListeners.add(pListener);
	}

	public static void RemoveEdgeEventListener(EdgeEventListener pListener)
	{
		edgeListeners.remove(pListener);
	}
	          //*****---ADD EVENT LISTENER---******//
              //-----------------------------------------------------------------------

	
              //-----------------------------------------------------------------------
	          //*****---TRIGGER EVENTS---******//
	protected void TriggerNodeCreatedEvent(NodeEvent e)
	{
		      //for each listener
		NodeEventListener currentListener;
		for(Enumeration list = nodeListeners.elements(); list.hasMoreElements();)
		{
			currentListener = (NodeEventListener)list.nextElement();
			currentListener.NodeCreated(e);//send the listener an event
        }			
	}

	protected void TriggerNodeDeletedEvent(NodeEvent e)
	{
		      //for each listener
		NodeEventListener currentListener;
		for(Enumeration list = nodeListeners.elements(); list.hasMoreElements();)
		{
			currentListener = (NodeEventListener)list.nextElement();
			currentListener.NodeDeleted(e);//send the listener an event
        }			
	}

	protected void TriggerEdgeCreatedEvent(EdgeEvent e)
	{
		      //for each listener
		EdgeEventListener currentListener;
		for(Enumeration list = edgeListeners.elements(); list.hasMoreElements();)
		{
			currentListener = (EdgeEventListener)list.nextElement();
			currentListener.EdgeCreated(e);//send the listener an event
        }			
	}

	protected void TriggerEdgeDeletedEvent(EdgeEvent e)
	{
		      //for each listener
		EdgeEventListener currentListener;
		for(Enumeration list = edgeListeners.elements(); list.hasMoreElements();)
		{
			currentListener = (EdgeEventListener)list.nextElement();
			currentListener.EdgeDeleted(e);//send the listener an event
        }			
	}
	          //*****---TRIGGER EVENTS---******//
              //-----------------------------------------------------------------------


              //-----------------------------------------------------------------------
	          //*****---SHOW PROPERTIES DIALOG---******//
	public void ShowOptionsDialog()
	{
		StandardDialog newDialog = new StandardDialog(new ObjectMaintainerPropertiesPanel(this));
		newDialog.show();
    }

	public ActivePanel GetOptionsPanel()
	{
		return new ObjectMaintainerPropertiesPanel(this);
    }
//*****---SHOW PROPERTIES DIALOG---******//
              //-----------------------------------------------------------------------
    
    
	public void EdgeClicked(EdgeClickedEvent e){}
	public void NodeClicked(NodeClickedEvent e){}

	
              //-----------------------------------------------------------------------
			//*****---Thread commands---******//
    public void start(){ try{ oldObjectDeleterThread=new Thread(this);oldObjectDeleterThread.start();} catch(Exception e){e.printStackTrace();}}
    public void stop(){ try{ oldObjectDeleterThread.stop();} catch(Exception e){e.printStackTrace();}}
    public void sleep(long p){ try{ oldObjectDeleterThread.sleep(p);} catch(Exception e){e.printStackTrace();}}
    public void setPriority(int p) { try{oldObjectDeleterThread.setPriority(p);} catch(Exception e){e.printStackTrace();}}    
			//*****---Thread commands---******//
              //-----------------------------------------------------------------------

			
              //-----------------------------------------------------------------------
			//*****---GET/SET commands---******//
    public long GetNodeExpireTime() { return nodeExpireTime;}    
    public long GetEdgeExpireTime() { return edgeExpireTime;}    
    public long GetEdgeInitialPersisistance() { return edgeInitialPersistance;}    
    public long GetNodeInitialPersisistance() { return nodeInitialPersistance;}    
    public long GetExpirationCheckRate() { return expirationCheckRate;}  
    
    public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber)
    {
    	return new ProprietaryNodeInfoPanel((NodeInfo)proprietaryNodeInfo.get(pNodeNumber));
    }

    public ActivePanel GetProprietaryEdgeInfoPanel(Integer pSourceNodeNumber, Integer pDestinationNodeNumber)
    {
    	EdgeInfo info = (EdgeInfo)proprietaryEdgeInfo.get(pSourceNodeNumber, pDestinationNodeNumber);
    	if(info==null) return null;
    	return new ProprietaryEdgeInfoPanel(info);
    }

	public void SetNodeExpireTime(long p) { nodeExpireTime = p;}    
    public void SetEdgeExpireTime(long p) { edgeExpireTime = p;}    
    public void SetEdgeInitialPersisistance(long p) { edgeInitialPersistance = p;}    
    public void SetNodeInitialPersisistance(long p) { nodeInitialPersistance = p;}    
    public void SetExpirationCheckRate(long p) { expirationCheckRate = p;}    
//*****---GET/SET commands---******//
              //-----------------------------------------------------------------------





              //***************************************************************************
              //***************************************************************************
              //NODE MAINTANCE INFO CLASS
	public static class NodeInfo// implements java.io.Serializable
	{
		protected Integer nodeNumber;
		protected Date timeCreated;
		protected Date timeLastSeen;
		protected Date secondToLastTimeSeen;
		protected Vector motesConnectedTo;
		protected boolean created;//this indicates whether everybody else has already been notified that this node exists (allows us to wait until we hear it more than once before creating it)
		
		public NodeInfo(Integer pNodeNumber, Date time)
		{
			nodeNumber = pNodeNumber;
			timeCreated = time;
			timeLastSeen = time;
			secondToLastTimeSeen = time;
			created = false;
		}
		
		public Integer GetNodeNumber(){return nodeNumber;}
		public Date GetTimeCreated()
		{
			return timeCreated;
		}
		
		public void SetTimeCreated(Date time)
		{
			timeCreated = time;
		}
		
		public Date GetTimeLastSeen()
		{
			return timeLastSeen;
		}
		
		public Date GetSecondToLastTimeSeen()
		{
			return secondToLastTimeSeen;
		}
 
 		public void SetTimeLastSeen(Date time)
		{
			secondToLastTimeSeen = timeLastSeen;
			timeLastSeen = time;
		}
		public boolean GetCreated(){return created;}
		public void SetCreated(boolean pCreated){created = pCreated;}
	}
              //NODE MAINTANCE INFO CLASS
              //***************************************************************************
              //***************************************************************************
	
	
              //***************************************************************************
              //***************************************************************************
	          //EDGEMAINTAINECE INFO
	public static class EdgeInfo// implements java.io.Serializable
	{
		protected Integer sourceNodeNumber;
		protected Integer destinationNodeNumber;
		protected Date timeCreated;
		protected Date timeLastSeen;
		
		public EdgeInfo(Integer pSourceNodeNumber, Integer pDestinationNodeNumber, Date time)
		{
			sourceNodeNumber = pSourceNodeNumber;
			destinationNodeNumber = pDestinationNodeNumber;
			timeCreated = time;
			timeLastSeen = time;
		}
		
		public Integer GetSourceNodeNumber(){return sourceNodeNumber;}
		public Integer GetDestinationNodeNumber(){return destinationNodeNumber;}
		public Date GetTimeCreated()
		{
			return timeCreated;
		}
		
		public void SetTimeCreated(Date time)
		{
			timeCreated = time;
		}
		
		public Date GetTimeLastSeen()
		{
			return timeLastSeen;
		}
		
		public void SetTimeLastSeen(Date time)
		{
			timeLastSeen = time;
		}
	}
	          //EDGEMAINTAINECE INFO
              //***************************************************************************
              //***************************************************************************
	          
	          
              //***************************************************************************
              //***************************************************************************
	          //NODE INFO PANEL
	public class ProprietaryNodeInfoPanel extends Surge.Dialog.ActivePanel
	{
		NodeInfo nodeInfo;
		
		public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)
		{
			tabTitle = "Creation";
			nodeInfo = pNodeInfo;
			//{{INIT_CONTROLS
			setLayout(null);
//			Insets ins = getInsets();
			setSize(307,168);
			JLabel3.setToolTipText("The time in milliseconds that this node was first seen");
			JLabel3.setText("Time Created:");
			add(JLabel3);
			JLabel3.setBounds(12,36,108,24);
			JLabel4.setToolTipText("The time in milliseconds that this node was last seen");
			JLabel4.setText("Time Last Seen");
			add(JLabel4);
			JLabel4.setBounds(12,60,108,24);
			JTextField1.setNextFocusableComponent(JTextField2);
			JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
			JTextField1.setText("1.5");
			add(JTextField1);
			JTextField1.setBounds(108,36,180,18);
			JTextField2.setNextFocusableComponent(JTextField3);
			JTextField2.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
			JTextField2.setText("3.2");
			add(JTextField2);
			JTextField2.setBounds(108,60,180,18);
			JLabel1.setToolTipText("The second to last time seen");
			JLabel1.setText("Time Before");
			add(JLabel1);
			JLabel1.setBounds(12,84,90,18);
			JTextField3.setNextFocusableComponent(JTextField1);
			JTextField3.setToolTipText("The second to last time seen");
			JTextField3.setText("4.5");
			add(JTextField3);
			JTextField3.setBounds(108,84,180,18);
			JLabel2.setText("Node Number:");
			add(JLabel2);
			JLabel2.setFont(new Font("Dialog", Font.BOLD, 16));
			JLabel2.setBounds(48,0,120,39);
			JLabel5.setToolTipText("The number used to identify this node");
			JLabel5.setText("jlabel");
			add(JLabel5);
			JLabel5.setForeground(java.awt.Color.blue);
			JLabel5.setFont(new Font("Dialog", Font.BOLD, 16));
			JLabel5.setBounds(180,0,48,33);
			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
		javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
		javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
		javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
		javax.swing.JTextField JTextField3 = new javax.swing.JTextField();
		javax.swing.JLabel JLabel2 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel5 = new javax.swing.JLabel();
		//}}
		
		public void ApplyChanges()
		{
//			nodeInfo.SetTimeCreated(new Date(JTextField1.getText()));
//			nodeInfo.SetTimeLastSeen(new Date(JTextField2.getText()));
		}
		
		public void InitializeDisplayValues()
		{
			JTextField1.setText(String.valueOf(nodeInfo.GetTimeCreated()));
			JTextField2.setText(String.valueOf(nodeInfo.GetTimeLastSeen()));
			JTextField3.setText(String.valueOf(nodeInfo.GetSecondToLastTimeSeen()));
			JLabel5.setText(String.valueOf(nodeInfo.GetNodeNumber()));
		}
	}	          
	          //NODE INFO PANEL
              //***************************************************************************
              //***************************************************************************
	
              //***************************************************************************
              //***************************************************************************
	          //EDGE INFO PANEL
	public class ProprietaryEdgeInfoPanel extends Surge.Dialog.ActivePanel
	{
		EdgeInfo edgeInfo;
		
		public ProprietaryEdgeInfoPanel(EdgeInfo pedgeInfo)
		{
			tabTitle = "Creation";
			edgeInfo = pedgeInfo;
			//{{INIT_CONTROLS
			setLayout(null);
//			Insets ins = getInsets();
			setSize(307,168);
			JLabel3.setToolTipText("The time in milliseconds that this node was first seen");
			JLabel3.setText("Time Created:");
			add(JLabel3);
			JLabel3.setBounds(24,60,108,24);
			JLabel4.setToolTipText("The time in milliseconds that this node was last seen");
			JLabel4.setText("Time Last Seen");
			add(JLabel4);
			JLabel4.setBounds(24,84,108,24);
			JTextField1.setNextFocusableComponent(JTextField2);
			JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
			JTextField1.setText("1.5");
			add(JTextField1);
			JTextField1.setBounds(120,60,180,18);
			JTextField2.setNextFocusableComponent(JTextField1);
			JTextField2.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
			JTextField2.setText("3.2");
			add(JTextField2);
			JTextField2.setBounds(120,84,180,18);
			JLabel2.setText("Source Node Number:");
			add(JLabel2);
			JLabel2.setBounds(24,12,156,12);
			JLabel1.setText("Destination Node Number");
			add(JLabel1);
			JLabel1.setBounds(24,36,150,15);
			JLabel5.setText("jlabel");
			add(JLabel5);
			JLabel5.setBounds(192,12,36,12);
			JLabel6.setText("jlabel");
			add(JLabel6);
			JLabel6.setBounds(192,36,36,18);
			//}}

			//{{REGISTER_LISTENERS
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
		javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
		javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
		javax.swing.JLabel JLabel2 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel5 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel6 = new javax.swing.JLabel();
		//}}
		
		public void ApplyChanges()
		{
			edgeInfo.SetTimeCreated(new Date(Long.getLong(JTextField1.getText()).longValue()));
			edgeInfo.SetTimeLastSeen(new Date(Long.getLong(JTextField2.getText()).longValue()));
		}
		
		public void InitializeDisplayValues()
		{
			JLabel5.setText(edgeInfo.GetSourceNodeNumber().toString());
			JLabel6.setText(edgeInfo.GetDestinationNodeNumber().toString());
			JTextField1.setText(String.valueOf(edgeInfo.GetTimeCreated()));
			JTextField2.setText(String.valueOf(edgeInfo.GetTimeLastSeen()));
		}
	}	          
	          //END OF EDGE INFO PANEL
              //***************************************************************************
              //***************************************************************************


              //***************************************************************************
              //***************************************************************************
	          //OBJECT MAINTAINER PROPERTIES PANEL
	          //to be shown in a standard dialog
	public class ObjectMaintainerPropertiesPanel extends ActivePanel
	{
		ObjectMaintainer objectMaintainer;
		
		public ObjectMaintainerPropertiesPanel(ObjectMaintainer pObjectMaintainer)
		{
			tabTitle = "Object Maintainer Properties";
			modal=true;
			objectMaintainer = pObjectMaintainer;

			//{{INIT_CONTROLS
			setLayout(null);
			setSize(286,264);
			add(nodeExpire);
			nodeExpire.setBounds(36,12,156,52);
			NodeExpireLabel.setText("label1");
			add(NodeExpireLabel);
			NodeExpireLabel.setBounds(204,12,47,52);
			nodeExpireSlider.setMinimum(100);
			nodeExpireSlider.setMaximum(10000);
			nodeExpireSlider.setToolTipText("The time before this node is deleted, since it last seen.");
			nodeExpireSlider.setBorder(bevelBorder1);
			nodeExpireSlider.setValue(100);
			add(nodeExpireSlider); 
			nodeExpireSlider.setBounds(60,48,192,24);
			nodeInitialPersistance.setText("Node Initial Persistance:");
			add(nodeInitialPersistance);
			nodeInitialPersistance.setBounds(36,60,156,52);
			nodeInitialPersistanceLabel.setText("label2");
			add(nodeInitialPersistanceLabel);
			nodeInitialPersistanceLabel.setBounds(204,60,47,52);
			nodeInitialPersistanceSlider.setMinimum(100);
			nodeInitialPersistanceSlider.setMaximum(10000);
			nodeInitialPersistanceSlider.setToolTipText("The time before a node is deleted, since it was first seen.");
			nodeInitialPersistanceSlider.setBorder(bevelBorder1);
			nodeInitialPersistanceSlider.setOpaque(false);
			nodeInitialPersistanceSlider.setValue(100);
			add(nodeInitialPersistanceSlider); 
			nodeInitialPersistanceSlider.setForeground(java.awt.Color.lightGray);
			nodeInitialPersistanceSlider.setBounds(60,96,192,24);
			edgeExpire.setText("Edge Expire Time:");
			add(edgeExpire);
			edgeExpire.setBounds(36,108,156,52);
			edgeExpireLabel.setText("label3");
			add(edgeExpireLabel);
			edgeExpireLabel.setBounds(204,108,47,52);
			edgeExpireSlider.setMinimum(100);
			edgeExpireSlider.setMaximum(10000);
			edgeExpireSlider.setToolTipText("The time before an edge is deleted, since it was last seen");
			edgeExpireSlider.setBorder(bevelBorder1);
			edgeExpireSlider.setValue(100);
			add(edgeExpireSlider); 
			edgeExpireSlider.setBounds(60,144,192,24);
			edgeInitialPersistance.setText("Edge Initial Persistance:");
			add(edgeInitialPersistance);
			edgeInitialPersistance.setBounds(36,156,156,52);
			edgeInitialPersistanceLabel.setText("label4");
			add(edgeInitialPersistanceLabel);
			edgeInitialPersistanceLabel.setBounds(204,156,47,52);
			edgeInitialPersistanceSlider.setMinimum(100);
			edgeInitialPersistanceSlider.setMaximum(10000);
			edgeInitialPersistanceSlider.setToolTipText("The time before an edge is deleted, since it was first seen.");
			edgeInitialPersistanceSlider.setBorder(bevelBorder1);
			edgeInitialPersistanceSlider.setValue(100);
			add(edgeInitialPersistanceSlider); 
			edgeInitialPersistanceSlider.setForeground(java.awt.Color.lightGray);
			edgeInitialPersistanceSlider.setBounds(60,192,192,24);
			expirationCheckRate.setText("Expiration Check Rate");
			add(expirationCheckRate);
			expirationCheckRate.setBounds(36,204,159,51);
			expirationCheckRateLabel.setText("label5");
			add(expirationCheckRateLabel);
			expirationCheckRateLabel.setBounds(204,204,48,51);
			JLabel1.setToolTipText("1 second is 1000 milliseconds");
			expirationCheckRateSlider.setValue(100);
			JLabel1.setText("Note: all times are in milliseconds");
			add(JLabel1);
			JLabel1.setForeground(java.awt.Color.blue);
			JLabel1.setBounds(48,0,219,21);
			expirationCheckRateSlider.setMinimum(100);
			expirationCheckRateSlider.setMaximum(10000);
			expirationCheckRateSlider.setToolTipText("The rate at which the Object Maintainer goes through all the objects and deletes old ones.  ");
			expirationCheckRateSlider.setBorder(bevelBorder1);
			add(expirationCheckRateSlider);
			expirationCheckRateSlider.setBackground(new java.awt.Color(204,204,204));
			expirationCheckRateSlider.setForeground(java.awt.Color.lightGray);
			expirationCheckRateSlider.setBounds(60,240,192,24);
		
			nodeExpire.setText("Node Expire Time:");
			//$$ bevelBorder1.move(0,306);
			//}}
		
			//{{REGISTER_LISTENERS
			SymChange lSymChange = new SymChange();
			nodeExpireSlider.addChangeListener(lSymChange);
			nodeInitialPersistanceSlider.addChangeListener(lSymChange);
			edgeExpireSlider.addChangeListener(lSymChange);
			edgeInitialPersistanceSlider.addChangeListener(lSymChange);
			expirationCheckRateSlider.addChangeListener(lSymChange);
			//}}
		}
		
			//{{DECLARE_CONTROLS
		javax.swing.JLabel nodeExpire = new javax.swing.JLabel();
		javax.swing.JLabel NodeExpireLabel = new javax.swing.JLabel();
		javax.swing.JSlider nodeExpireSlider = new javax.swing.JSlider();
		javax.swing.JLabel nodeInitialPersistance = new javax.swing.JLabel();
		javax.swing.JLabel nodeInitialPersistanceLabel = new javax.swing.JLabel();
		javax.swing.JSlider nodeInitialPersistanceSlider = new javax.swing.JSlider();
		javax.swing.JLabel edgeExpire = new javax.swing.JLabel();
		javax.swing.JLabel edgeExpireLabel = new javax.swing.JLabel();
		javax.swing.JSlider edgeExpireSlider = new javax.swing.JSlider();
		javax.swing.JLabel edgeInitialPersistance = new javax.swing.JLabel();
		javax.swing.JLabel edgeInitialPersistanceLabel = new javax.swing.JLabel();
		javax.swing.JSlider edgeInitialPersistanceSlider = new javax.swing.JSlider();
		javax.swing.JLabel expirationCheckRate = new javax.swing.JLabel();
		javax.swing.JLabel expirationCheckRateLabel = new javax.swing.JLabel();
		javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
		javax.swing.JSlider expirationCheckRateSlider = new javax.swing.JSlider();
		com.symantec.itools.javax.swing.borders.BevelBorder bevelBorder1 = new com.symantec.itools.javax.swing.borders.BevelBorder();
		//}}

            	//---------------------------------------------------------------------
            	//APPLY CHANGES
		public void ApplyChanges()
		{
			objectMaintainer.SetNodeExpireTime(nodeExpireSlider.getValue());
			objectMaintainer.SetEdgeExpireTime(edgeExpireSlider.getValue());
    		objectMaintainer.SetEdgeInitialPersisistance(edgeInitialPersistanceSlider.getValue());
    		objectMaintainer.SetNodeInitialPersisistance(nodeInitialPersistanceSlider.getValue());
    		objectMaintainer.SetExpirationCheckRate(expirationCheckRateSlider.getValue());
		}
            	//APPLY CHANGES
            	//---------------------------------------------------------------------
		

            	//---------------------------------------------------------------------
            	//INITIALIZE DISPLAY VALUES
		public void InitializeDisplayValues()
		{
			NodeExpireLabel.setText(String.valueOf(objectMaintainer.GetNodeExpireTime()));
			nodeExpireSlider.setValue((int)objectMaintainer.GetNodeExpireTime());
			nodeInitialPersistanceLabel.setText(String.valueOf(objectMaintainer.GetNodeInitialPersisistance()));
			nodeInitialPersistanceSlider.setValue((int)objectMaintainer.GetNodeInitialPersisistance());
			edgeExpireLabel.setText(String.valueOf(objectMaintainer.GetEdgeExpireTime()));
			edgeExpireSlider.setValue((int)objectMaintainer.GetEdgeExpireTime());
			edgeInitialPersistanceLabel.setText(String.valueOf(objectMaintainer.GetEdgeInitialPersisistance()));
			edgeInitialPersistanceSlider.setValue((int)objectMaintainer.GetEdgeInitialPersisistance());
			expirationCheckRateLabel.setText(String.valueOf(objectMaintainer.GetExpirationCheckRate()));
			expirationCheckRateSlider.setValue((int)objectMaintainer.GetExpirationCheckRate());

		    	//This function is called by a thread that runs in the background
		    	//and updates the values of the Active Panels so they are always
		    	//up to date.
		}
            	//INITIALIZE DISPLAY VALUES
            	//---------------------------------------------------------------------

		class SymChange implements javax.swing.event.ChangeListener
		{
			public void stateChanged(javax.swing.event.ChangeEvent event)
			{
				Object object = event.getSource();
				if (object == nodeExpireSlider)
					nodeExpireSlider_stateChanged(event);
				else if (object == nodeInitialPersistanceSlider)
					nodeInitialPersistanceSlider_stateChanged(event);
				else if (object == edgeExpireSlider)
					edgeExpireSlider_stateChanged(event);
				else if (object == edgeInitialPersistanceSlider)
					edgeInitialPersistanceSlider_stateChanged(event);
				else if (object == expirationCheckRateSlider)
					expirationCheckRateSlider_stateChanged(event);
			}
		}

		void nodeExpireSlider_stateChanged(javax.swing.event.ChangeEvent event)
		{
			// to do: code goes here.
				 
			nodeExpireSlider_stateChanged_Interaction1(event);
		}

		void nodeExpireSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
		{
			try {
				// convert int->class java.lang.String
				NodeExpireLabel.setText(java.lang.String.valueOf(nodeExpireSlider.getValue()));
			} catch (java.lang.Exception e) {
			}
		}

		void nodeInitialPersistanceSlider_stateChanged(javax.swing.event.ChangeEvent event)
		{
			// to do: code goes here.
				 
			nodeInitialPersistanceSlider_stateChanged_Interaction1(event);
		}

		void nodeInitialPersistanceSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
		{
			try {
				// convert int->class java.lang.String
				nodeInitialPersistanceLabel.setText(java.lang.String.valueOf(nodeInitialPersistanceSlider.getValue()));
			} catch (java.lang.Exception e) {
			}
		}

		void edgeExpireSlider_stateChanged(javax.swing.event.ChangeEvent event)
		{
			// to do: code goes here.
				 
			edgeExpireSlider_stateChanged_Interaction1(event);
		}

		void edgeExpireSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
		{
			try {
				// convert int->class java.lang.String
				edgeExpireLabel.setText(java.lang.String.valueOf(edgeExpireSlider.getValue()));
			} catch (java.lang.Exception e) {
			}
		}

		void edgeInitialPersistanceSlider_stateChanged(javax.swing.event.ChangeEvent event)
		{
			// to do: code goes here.
				 
			edgeInitialPersistanceSlider_stateChanged_Interaction1(event);
		}

		void edgeInitialPersistanceSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
		{
			try {
				// convert int->class java.lang.String
				edgeInitialPersistanceLabel.setText(java.lang.String.valueOf(edgeInitialPersistanceSlider.getValue()));
			} catch (java.lang.Exception e) {
			}
		}

		void expirationCheckRateSlider_stateChanged(javax.swing.event.ChangeEvent event)
		{
			// to do: code goes here.
				 
			expirationCheckRateSlider_stateChanged_Interaction1(event);
		}

		void expirationCheckRateSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
		{
			try {
				// convert int->class java.lang.String
				expirationCheckRateLabel.setText(java.lang.String.valueOf(expirationCheckRateSlider.getValue()));
			} catch (java.lang.Exception e) {
			}
		}

	}
	          //END OF OBJECT MAINTAINER PROPERTIES PANEL
              //***************************************************************************
              //***************************************************************************

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
			mainMenu.setText("Object Maintainer");
			mainMenu.setActionCommand("Object Maintainer");
			packetProcessingCheckBox.setSelected(true);
			packetProcessingCheckBox.setText("Create New Nodes and Edges");
			packetProcessingCheckBox.setActionCommand("Create New Nodes and Edges");
			mainMenu.add(packetProcessingCheckBox);
			backgroundProcessingCheckBox.setSelected(true);
			backgroundProcessingCheckBox.setText("Delete Old Nodes and Edges");
			backgroundProcessingCheckBox.setActionCommand("Delete Old Nodes and Edges");
			mainMenu.add(backgroundProcessingCheckBox);
			mainMenu.add(separator1);
			propertiesItem.setText("Options");
			propertiesItem.setActionCommand("Options");
			mainMenu.add(propertiesItem);
			mainMenu.add(separator2);
			serializeMenu.setText("Serialize");
			serializeMenu.setActionCommand("Serialize");
			saveNodesItem.setText("Save Node Maintanence Info");
			saveNodesItem.setActionCommand("Save Node Maintanence Info");
			serializeMenu.add(saveNodesItem);
			loadNodesItem.setText("Load Node Maintanence Info");
			loadNodesItem.setActionCommand("Load Node Maintanence Info");
			serializeMenu.add(loadNodesItem);
			saveEdgesItem.setText("Save Edge Maintanence Info");
			saveEdgesItem.setActionCommand("Save Edge Maintanence Info");
			serializeMenu.add(saveEdgesItem);
			loadEdgesItem.setText("Load Edge Maintanence Info");
			loadEdgesItem.setActionCommand("Load Edge Maintanence Info");
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
			{ //Note:  the following syntax "ObjectMaintainer.this" allows an inner class to refer to its enclosing class
				MainClass.AddPacketEventListener(ObjectMaintainer.this);//start the background thread of the enclosing packetAnalyzer
			}
			else
			{
				MainClass.RemovePacketEventListener(ObjectMaintainer.this);//stop the background thread of the enclosing packetAnalyzer
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
			{ //Note:  the following syntax "ObjectMaintainer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddNodePainter(ObjectMaintainer.this);//paint the nodes
			}
			else
			{
				MainClass.displayManager.RemoveNodePainter(ObjectMaintainer.this);//paint the nodes
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
			{ //Note:  the following syntax "ObjectMaintainer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddEdgePainter(ObjectMaintainer.this);//paint the edges
			}
			else
			{
				MainClass.displayManager.RemoveEdgePainter(ObjectMaintainer.this);//paint the edges
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
			{ //Note:  the following syntax "ObjectMaintainer.this" allows an inner class to refer to its enclosing class
				MainClass.displayManager.AddScreenPainter(ObjectMaintainer.this);//
			}
			else
			{
				MainClass.displayManager.RemoveScreenPainter(ObjectMaintainer.this);//
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
	          //END OF OBJECT MAINTAINER CLASS
              //***************************************************************************
              //***************************************************************************
