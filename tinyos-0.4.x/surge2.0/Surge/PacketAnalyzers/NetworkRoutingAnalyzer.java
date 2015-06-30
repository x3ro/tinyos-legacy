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

import Surge.*;
import Surge.Dialog.*;
import Surge.event.*;
import java.awt.event.*;
import javax.swing.*;
import java.io.*;
import java.util.zip.*;

              //this class should figure out what network routes are being used
              //by the ad-hoc routing protocol and display it on the GUI
public class NetworkRoutingAnalyzer extends PacketAnalyzer
{
	          //*****---CONSTRUCTOR---******//
	public NetworkRoutingAnalyzer()
	{
	}
	          //*****---CONSTRUCTOR---*****//
	
	
		      //*****---PACKETRECIEVED EVENT HANDLER---*****//
	public void PacketRecieved(PacketEvent e)
	{
	}
		      //*****---PACKETRECIEVED EVENT HANDLER---*****//
		      
		                    //------------------------------------------------------------------------
	          //*****---SHOW PROPERTIES DIALOG---******//
	          //this function can be called by MainFrame (by the menus, in particular)
	          //and should simply show the dialog as shown here.
	          //You need to define the class "PacketAnalyzerTemplatePropertiesPanel"
	          //in order for this to do anything.  it is useful for setting parameters
	          //on your analyzer.
	public void ShowOptionsDialog() 
	{
		StandardDialog newDialog = new StandardDialog(new OptionsPanel(this));
		newDialog.show();
	}
			  //*****---SHOW PROPERTIES DIALOG---******//
              //------------------------------------------------------------------------
	          


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