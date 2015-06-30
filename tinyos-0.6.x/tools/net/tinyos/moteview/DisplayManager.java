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
//this class is listening to the main panel on the mainFrame
//and generates events whenever a node or edge are clicked
//it can also be used for scrolling or zooming.
//This class could have been integrated with the MainFrame class
//but I wanted to leave that class to VisualCafe
//***********************************************************************
//***********************************************************************

package net.tinyos.moteview;

import java.awt.event.*;
import java.util.*;
import javax.swing.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.Dialog.*;
import java.lang.Math;
import net.tinyos.moteview.Dialog.*;
import net.tinyos.moteview.util.*;
import net.tinyos.moteview.Dialog.*;
import java.awt.*;
import net.tinyos.moteview.PacketAnalyzers.*;
import java.awt.event.*;
import java.io.*;
import java.util.zip.*;

public class DisplayManager implements java.awt.event.MouseListener, java.awt.event.MouseMotionListener, Runnable, NodePainter, EdgePainter, NodeEventListener, EdgeEventListener, NodeClickedEventListener, EdgeClickedEventListener, NodeDialogContributor, EdgeDialogContributor//, java.io.Serializable
{
	          //these vectors hold all people that want to paint on the edge, nodes, or over the entire screen
	protected Vector nodePainters;//a list of all objects that want to paint nodes
	protected Vector edgePainters;//a list of all objects that want to paint edges
	protected Vector screenPainters;//a list of all objects that want to paint the screen

	          //these vectors contain all people who want to add to the node/edge properties dialog
	protected Vector nodeDialogContributors;//a list of all objects that want to add to the node properties Dialog
	protected Vector edgeDialogContributors;//a list of all objects that want to add to the edge properties dialog

		//these vectors contain all the registered listeners for node and edge click events
	protected Vector NodeClickedEventListeners;
	protected Vector EdgeClickedEventListeners;

	          //these hashtables hold nodeInfo and edgeInfo objects, which hold display information about specific nodes and edges (e.g. color, image)
	protected static Hashtable proprietaryNodeInfo;
	protected static TwoKeyHashtable proprietaryEdgeInfo;

	protected MenuManager menuManager;

              //these variables describe how the mouse interacts with the network
	boolean selectMode;
	boolean handMode;
	boolean zoomMode;

	int pressedXCoord=-1;
	int pressedYCoord=-1;
	protected static long refreshRate;//refresh rate
	double zoomFactor;//the factor by which the screen is enlarged

	protected static Thread refreshScreenThread;//the thread that runs in the background and refreshes the screen periodically

        protected Vector m_vcNodesSelected = new Vector ( );

        JPopupMenu           m_pmRightClick      = new JPopupMenu ( );
        JMenuItem            m_miReprogramming   = new JMenuItem ("Reprogram");
        JMenuItem            m_miNodeProperties  = new JMenuItem ("Properties");
        JCheckBoxMenuItem    m_miDisplay         = new JCheckBoxMenuItem ("Display");
        JCheckBoxMenuItem    m_miSortID          = new JCheckBoxMenuItem ("Sort by Node ID");
        JCheckBoxMenuItem    m_miSortProgID      = new JCheckBoxMenuItem ("Sort by Prog ID");
        public static final int SORTBY_ID            = 0;
        public static final int SORTBY_PROGID        = 1;
        public static final int SORTBY_PROGLENGTH    = 2;

	DisplayManager(MainFrame pMainFrame)
	{
		nodePainters = new Vector();
		edgePainters = new Vector();
		screenPainters = new Vector();
		nodeDialogContributors = new Vector();
		edgeDialogContributors = new Vector();
		NodeClickedEventListeners = new Vector();
		EdgeClickedEventListeners = new Vector();
		proprietaryNodeInfo = new Hashtable();
		proprietaryEdgeInfo = new TwoKeyHashtable();

              //register to recieve all mouse clicks on the display panel
		pMainFrame.GetGraphDisplayPanel().addMouseListener(this);
		pMainFrame.GetGraphDisplayPanel().addMouseMotionListener(this);
              //register (with myself) to paint nodes and edges and display info panels
		this.AddNodePainter(this);//paint the nodes
		this.AddEdgePainter(this);//paint the edges
			//register myself to recieve NodeClickedEvents and EdgeClickedEvents
		this.AddNodeDialogContributor(this);
		this.AddEdgeDialogContributor(this);
              //register to be notified of nodes and edges being created or deleted
              //this is done in MainClass constructor because this object is instantiated before the Object Maintainer
//		MainClass.objectMaintainer.AddEdgeEventListener(this);//listen to node events
//		MainClass.objectMaintainer.AddNodeEventListener(this);//listen to edge event
              //register to contribute a panel to the SurgeOptions panel
        MainClass.AddOptionsPanelContributor(this);

		menuManager = new MenuManager();

		selectMode=true;
		handMode=false;
		zoomMode=false;
		refreshRate = 150;//this is the number of milliseconds that it waits before redrawing the screen again
        refreshScreenThread = new Thread(this);//this thread runs continually in the background to redraw the screen
		try{
			refreshScreenThread.setPriority(Thread.MIN_PRIORITY);
			refreshScreenThread.start(); //recall that start() calls the run() method defined in this class
		}
		catch(Exception e){e.printStackTrace();}

                BuildContextMenu ( );

	}

        protected void BuildContextMenu ( )
        {
            m_miDisplay.setSelected( true );
            m_miSortID.setSelected( true );

            m_pmRightClick.add( m_miDisplay );
            m_pmRightClick.addSeparator();
            m_pmRightClick.add( m_miSortID );
            m_pmRightClick.add( m_miSortProgID );
            m_pmRightClick.addSeparator();
            m_pmRightClick.add( m_miReprogramming );
            m_pmRightClick.addSeparator();
            m_pmRightClick.add( m_miNodeProperties );

            SymAction lAction = new SymAction ();
            m_miReprogramming.addActionListener( lAction );
            m_miDisplay.addActionListener( lAction );
            m_miSortID.addActionListener( lAction );
            m_miSortProgID.addActionListener( lAction );
        }

	public void mouseClicked(MouseEvent e){}
	public void mouseClickedCustom(MouseEvent e)
	{
            GraphDisplayPanel display = MainClass.mainFrame.GetGraphDisplayPanel();
            Double x = display.ScaleScreenXCoordToNodeCoord(e.getX());
            Double y = display.ScaleScreenYCoordToNodeCoord(e.getY());
            if (javax.swing.SwingUtilities.isLeftMouseButton(e))
            {
                Integer clickedNodeNumber = FindNearestNode(x.doubleValue(), y.doubleValue());

                if(clickedNodeNumber != null)
                {
                    HandleNodeClicked ( clickedNodeNumber, e.isControlDown() );
                    TriggerNodeClickedEvent(clickedNodeNumber );
                    if ( !e.isControlDown() && e.getClickCount() == 2 )
                    {
                        DisplayNodePropertyDialog(clickedNodeNumber);
                    }
                }
            }
            else if ( SwingUtilities.isRightMouseButton(e) )
            {
                //if ( e.isPopupTrigger() )
                //{
                    System.out.println ("DM: displaying popupmenu");
                    if ( m_vcNodesSelected.size() > 1 )
                    {
                        // node properties doesnt work for multiselect
                        //m_pmRightClick.remove( m_miNodeProperties );
                    }

                    m_pmRightClick.show( MainClass.mainFrame.GetGraphDisplayPanel(), e.getX(), e.getY() );
                 //}
            }
            else
            {
                    Vector edgeID = FindNearestEdge(x.doubleValue(), y.doubleValue());
                    if( (edgeID != null) && (edgeID.size() == 2) )
                    {
                            TriggerEdgeClickedEvent((Integer)edgeID.elementAt(0), (Integer)edgeID.elementAt(1));
                            DisplayEdgePropertyDialog((Integer)edgeID.elementAt(0), (Integer)edgeID.elementAt(1));
                    }
            }
	}

        private void HandleNodeClicked ( Integer nodeNumber, boolean cntrlPressed )
        {
            NodeInfo tempNode = null;

            if ( !cntrlPressed )
            {
                for(Enumeration nodes = m_vcNodesSelected.elements(); nodes.hasMoreElements();)
	        {
		    tempNode = (NodeInfo)nodes.nextElement();
                    tempNode.SetSelected ( false );
	        }
                m_vcNodesSelected.clear();

                tempNode = (NodeInfo) proprietaryNodeInfo.get( nodeNumber );
                tempNode.SetSelected ( true );
                m_vcNodesSelected.add( tempNode );
            }
            else
            {
                tempNode = (NodeInfo) proprietaryNodeInfo.get( nodeNumber );
                if ( tempNode.IsSelected() )
                {
                    tempNode.SetSelected ( false );
                    m_vcNodesSelected.remove( tempNode );
                }
                else
                {
                    tempNode.SetSelected ( true );
                    m_vcNodesSelected.add( tempNode );
                }
            }
        }
              //------------------------------------------------------------------
			//MOUSE DRAGGED
	public void mouseDragged(MouseEvent e)
	{
		DrawCoords(e);
	}//even though using this method instead of my custom method would make the graphics look better
	          //I use a custom mouse dragged method because otherwise handling all the events overwhelms the system and all the nodes might time-out

	public void mouseDraggedCustom(int startX, int startY, MouseEvent e)
    {
		if (javax.swing.SwingUtilities.isLeftMouseButton(e))
		{
			if(selectMode)
			{
				TriggerNodeDraggedEvent(startX, startY, e);
			}
			else if(handMode)
			{
				ScrollWithMouseDrag(startX, startY, e);
			}
			else if(zoomMode)
			{
				ZoomToMouseDragRectangle(startX, startY, e);
			}
		}
		else if (javax.swing.SwingUtilities.isMiddleMouseButton(e))
		{
			ScrollWithMouseDrag(startX, startY, e);
		}
		else if (javax.swing.SwingUtilities.isRightMouseButton(e))
		{
			ZoomToMouseDragRectangle(startX, startY, e);
		}
    }
			//MOUSE DRAGGED
              //------------------------------------------------------------------

	public void mouseEntered(MouseEvent e)
	{
	}

	public void mouseExited(MouseEvent e)
	{         //leave these lines if you don't want the custom mouse click to fire after the mouse has left and re-entered the screen
//		pressedXCoord = -1;
//		pressedYCoord = -1;
	}

		      //this function triggers an event for a mouse press
	public void mousePressed(MouseEvent e)
	{
            pressedXCoord = e.getX();
	    pressedYCoord = e.getY();


	}

	public void mouseReleased(MouseEvent e)
	{
		if((pressedXCoord == -1) || (pressedYCoord == -1))
		{
			return;
		}

		int x = e.getX();
		int y = e.getY();

		if((pressedXCoord == x) && (pressedYCoord == y))
		{     //if a mouse click
			mouseClickedCustom(e);
		}
		else
		{     //if it was a drag, pass the original coords and the final coords
			mouseDraggedCustom(pressedXCoord, pressedYCoord, e);
		}
		pressedXCoord = -1;//reset
		pressedYCoord = -1;
	}

    public void mouseMoved(MouseEvent e)
    {
		DrawCoords(e);
    }


		      //this function adds the node dialog contributors
	public  void AddNodeDialogContributor(NodeDialogContributor pContributor)
	{
		nodeDialogContributors.add(pContributor);
	}

	public  void RemoveNodeDialogContributor(NodeDialogContributor pContributor)
	{
		nodeDialogContributors.remove(pContributor);
	}

		      //this function adds the edge dialog contributors
	public  void AddEdgeDialogContributor(EdgeDialogContributor pContributor)
	{
		edgeDialogContributors.add(pContributor);
	}

	public  void RemoveEdgeDialogContributor(EdgeDialogContributor pContributor)
	{
		edgeDialogContributors.remove(pContributor);
	}

		      //this function adds the nodeclicked Listeners
	public  void AddNodeClickedEventListener(NodeClickedEventListener pListener)
	{
		NodeClickedEventListeners.add(pListener);
	}

	public  void RemoveNodeClickedEventListener(NodeClickedEventListener pListener)
	{
		NodeClickedEventListeners.remove(pListener);
	}

              //this function adds the edge clicked Listeners
	public  void AddEdgeClickedEventListener(EdgeClickedEventListener pListener)
	{
		EdgeClickedEventListeners.add(pListener);
	}

	public  void RemoveEdgeClickedEventListener(EdgeClickedEventListener pListener)
	{
		EdgeClickedEventListeners.remove(pListener);
	}


				          //*************************************************************
	          //*************************************************************
	          //this is where we register the node, edge and screen painters
	          //*************************************************************
	          //*************************************************************

	public void AddNodePainter(NodePainter painter)
	{
		nodePainters.add(painter);//add the painters to the painter list
	}

	public void RemoveNodePainter(NodePainter painter)
	{
		nodePainters.remove(painter);//add the painters to the painter list
	}

	public void AddEdgePainter(EdgePainter painter)
	{
		edgePainters.add(painter);//add the painters to the painter list
	}

	public void RemoveEdgePainter(EdgePainter painter)
	{
		edgePainters.remove(painter);//add the painters to the painter list
	}

	public void AddScreenPainter(ScreenPainter painter)
	{
		screenPainters.add(painter);//add the painters to the painter list
	}

	public void RemoveScreenPainter(ScreenPainter painter)
	{
		screenPainters.remove(painter);//add the painters to the painter list
	}


	          //------------------------------------------------------------------------
	          //*****---TRIGGER NODE CLICKED EVENT---******//
		      //this function sends an event to all node clicked listeners
	protected void TriggerNodeClickedEvent(Integer pNodeNumber)
	{
		NodeClickedEvent e = new NodeClickedEvent(this, pNodeNumber, Calendar.getInstance().getTime());
		for(int index = 0; index < NodeClickedEventListeners.size(); index++)
		{
			((NodeClickedEventListener)NodeClickedEventListeners.get(index)).NodeClicked(e);
		}
	}
	          //*****---TRIGGER NODE CLICKED EVENT---******//
	          //------------------------------------------------------------------------


	          //------------------------------------------------------------------------
	          //*****---TRIGGER EDGE CLICKED EVENT---******//
		      //this function sends an event to all edge-clicked listeners
	protected void TriggerEdgeClickedEvent(Integer pSourceNodeNumber, Integer pDestinationNodeNumber)
	{
		EdgeClickedEvent e = new EdgeClickedEvent(this, pSourceNodeNumber, pDestinationNodeNumber, Calendar.getInstance().getTime());
		for(int index = 0; index < EdgeClickedEventListeners.size(); index++)
		{
			((EdgeClickedEventListener)EdgeClickedEventListeners.get(index)).EdgeClicked(e);
		}
	}
	          //*****---TRIGGER EDGE CLICKED EVENT---******//
	          //------------------------------------------------------------------------


	          //------------------------------------------------------------------------
	          //*****---DRAG NEAREST NODE---******//
	          //when in select mode, the mouse draw will drag the nearest node with it
	public void TriggerNodeDraggedEvent(int startX, int startY, MouseEvent e)
	{
		GraphDisplayPanel display = MainClass.mainFrame.GetGraphDisplayPanel();
		Double x1 = display.ScaleScreenXCoordToNodeCoord(startX);
		Double y1 = display.ScaleScreenYCoordToNodeCoord(startY);
		Double x2 = display.ScaleScreenXCoordToNodeCoord(e.getX());
		Double y2 = display.ScaleScreenYCoordToNodeCoord(e.getY());

		Integer pNodeNumber = FindNearestNode(x1.doubleValue(), y1.doubleValue());//this is why we need custom mouse drag (startX andstartY)
		NodeDraggedEvent event = new NodeDraggedEvent(this, pNodeNumber, Calendar.getInstance().getTime(), x2.doubleValue(), y2.doubleValue());
		for(int index = 0; index < NodeClickedEventListeners.size(); index++)
		{
			((NodeClickedEventListener)NodeClickedEventListeners.get(index)).NodeDragged(event);
		}

	}
	          //*****---DRAG NEAREST NODE---******//
	          //------------------------------------------------------------------------


	          //------------------------------------------------------------------------
	          //*****---Draw Coords with Mouse Event---******//
	          //this is the function that changes the display of the mouse coords on the toolbar
	public void DrawCoords(MouseEvent e)
	{         //this method should be changed to draw the coords at the current mouse position
	          //it currently draws it on the toolbar
		String temp = String.valueOf(MainClass.mainFrame.GetGraphDisplayPanel().ScaleScreenXCoordToNodeCoord(e.getX()));
		String text = temp.substring(0,Math.min(4, temp.length()));
		text = text.concat(",");
		temp = String.valueOf(MainClass.mainFrame.GetGraphDisplayPanel().ScaleScreenYCoordToNodeCoord(e.getY()));
		text = text.concat(temp.substring(0,Math.min(4, temp.length())));
                MainClass.mainFrame.GetCoordLabel().setText(text);
	}
	          //*****---SCROLL WITH MOUSE DRAG---******//
	          //------------------------------------------------------------------------



	          //------------------------------------------------------------------------
	          //*****---SCROLL WITH MOUSE DRAG---******//
	          //when in hand mode, the mouse draw will scroll the screen
	public void ScrollWithMouseDrag(int startX, int startY, MouseEvent e)
	{
		int endX = e.getX();
		int endY = e.getY();
		Point currentPosition = MainClass.mainFrame.GetMainScrollPane().getViewport().getViewPosition();
		Point newPosition = new Point(currentPosition.x +(endX-startX), currentPosition.y +(endY-startY));
		MainClass.mainFrame.GetMainScrollPane().getViewport().setViewPosition(newPosition);
	}
	          //*****---SCROLL WITH MOUSE DRAG---******//
	          //------------------------------------------------------------------------


	          //------------------------------------------------------------------------
	          //*****---ZOOM TO MOUSE DRAG RECTANGLE---******//
	          //when in zoom mode, the mouse drag will zoom to the selected rectangle
	public void ZoomToMouseDragRectangle(int startX, int startY, MouseEvent e)
	{
		int x,y, width, height;
		double scale;
		Dimension graphPanelSize = MainClass.mainFrame.GetGraphDisplayPanel().getSize();
		Dimension scrollPaneSize = MainClass.mainFrame.GetMainScrollPane().getSize();
		int endX = e.getX();
		int endY = e.getY();
		if(startX < endX)//use the edge of the rectangle that is longer in proportion that the proportion of the window size
		{
			x = startX;
			width = endX-startX;
		}
		else
		{
			x = endX;
			width = startX - endX;
		}
		if(startY < endY)
		{
			y = startY;
			height = endY-startY;
		}
		else
		{
			y = endY;
			height = startY - endY;
		}
		if( (height==0) || (width==0)) return;
		if(width/height > graphPanelSize.getWidth()/graphPanelSize.getHeight())//zoom so that the longer of the width/height of the new rectangle is in view (Since the rect will not be the same proportion as the window)
		{
			scale = scrollPaneSize.getWidth()/width;
		}
		else
		{
			scale = scrollPaneSize.getHeight()/height;
		}
		scale = scale*MainClass.displayManager.GetScaleFactor();
		this.MultiplyGraphDisplayPanelSize(scale);
		MainClass.mainFrame.GetMainScrollPane().getViewport().setViewPosition(new Point(x,y));
	}
	          //*****---ZOOM TO MOUSE DRAG RECTANGLE---******//
	          //------------------------------------------------------------------------



				//------------------------------------------------------------------------
			  //*****---DISPLAY NODE PROPERTY DIALOG---******//
//this function displays the dialog showing all node properties
	protected void DisplayNodePropertyDialog(Integer pNodeNumber)
	{
		TabbedDialog nodeDialog = new TabbedDialog("Node " + pNodeNumber + " Properties");
		ActivePanel currentPanel;
		NodeDialogContributor listener;

		for(Enumeration e = nodeDialogContributors.elements(); e.hasMoreElements();)
		{
			listener = ((NodeDialogContributor)e.nextElement());
			currentPanel = listener.GetProprietaryNodeInfoPanel(pNodeNumber);
			if(currentPanel != null)//if you don't have proprietary info, return a null panel
			{
				if(currentPanel.GetCancelInfoDialog())
				{//if you don't want a node dialog to show up, return an Active Component with this set to true
					return;
				}
				nodeDialog.AddActivePanel(currentPanel.GetTabTitle(), currentPanel);
			}
		}
		//nodeDialog.setModal(false);
		nodeDialog.show();
	}

        protected void DisplayReprogramming ( )
        {
            TabbedDialog nodeDialog = new TabbedDialog("Reprogramming");
            ActivePanel currentPanel = MainClass.reprogramming.GetProprietaryNodeInfoPanel( m_vcNodesSelected );
            nodeDialog.AddActivePanel( currentPanel.GetTabTitle(), currentPanel );
            //nodeDialog.setModal( true );
            nodeDialog.show();
        }

        protected void HideNodes ( )
        {
            NodeInfo node;
            for ( Enumeration nodes = m_vcNodesSelected.elements(); nodes.hasMoreElements(); )
            {
                node = (NodeInfo) nodes.nextElement ( );
                node.SetDisplayThisNode( false );
                node.SetSelected( false );
            }
            m_vcNodesSelected.clear();
        }

        protected void SortNodes ( int sortby )
        {
            if ( sortby == SORTBY_ID )
            {
                m_miSortID.setSelected( true );
                m_miSortProgID.setSelected( false );
            }
            else if ( sortby == SORTBY_PROGID )
            {
                m_miSortID.setSelected( false );
                m_miSortProgID.setSelected( true );
            }
            MainClass.reprogramming.SetSortBy( sortby );

        }
			  //*****---DISPLAY NODE PROPERTY DIALOG---******//
	          //------------------------------------------------------------------------


	          //------------------------------------------------------------------------
			  //*****---DISPLAY EDGEPROPERTY DIALOG---******//
				//this function displays the dialog showing all edge properties
	protected void DisplayEdgePropertyDialog(Integer pSourceNodeNumber, Integer pDestinationNodeNumber)
	{
		TabbedDialog edgeDialog = new TabbedDialog("Edge Properties");
		ActivePanel currentPanel;

		for(Enumeration e = edgeDialogContributors.elements(); e.hasMoreElements();)
		{
			currentPanel = ((EdgeDialogContributor)e.nextElement()).GetProprietaryEdgeInfoPanel(pSourceNodeNumber, pDestinationNodeNumber);
			if(currentPanel != null)//if you don't have proprietary info, return a null panel
			{
				if(currentPanel.GetCancelInfoDialog())
				{//if you don't want a node dialog to show up, return an Active Component with this set to true
					return;
				}
				edgeDialog.AddActivePanel(currentPanel.GetTabTitle(),currentPanel);
			}
		}
		//edgeDialog.setModal(false);
		edgeDialog.show();
	}
			  //*****---DISPLAY EDGEPROPERTY DIALOG---******//
	          //------------------------------------------------------------------------


	          //*****---refresh screen NOW---******//
	          //this function will redraw the main screen with all nodes and edges in current positions
	public static void RefreshScreenNow()
	{
            MainClass.mainFrame.GraphDisplayPanel.repaint();
            //MainClass.mainFrame.paint(MainClass.mainFrame.getGraphics());
	}
	          //*****---refresh screen NOW---******//


              //-----------------------------------------------------------------------
	          //*****---MultiplyGraphDisplayPanelSize---******//
	public static void MultiplyGraphDisplayPanelSize(double factor)
	{
		Insets inset = MainClass.mainFrame.GetMainScrollPane().getInsets();
		Dimension d = MainClass.mainFrame.GetMainScrollPane().getSize();
		int x = (int)( (d.width-(inset.left+inset.right))*factor);
		int y = (int)( (d.height-(inset.top+inset.bottom))*factor);
		MainClass.mainFrame.GetGraphDisplayPanel().setSize(new Dimension(x, y));//this line makes the scroll pane put scroll bars if necessary
		MainClass.mainFrame.GetGraphDisplayPanel().setPreferredSize(new Dimension(x, y));//this line changes the size, and the node coordinates are automatically rescaled
		MainClass.mainFrame.GetMainScrollPane().setViewportView(MainClass.mainFrame.GetGraphDisplayPanel());//this line allows the scroll pane to reevaluate whether scroll bars are needed
	}
	          //*****---MultiplyGraphDisplayPanelSize---******//
              //-----------------------------------------------------------------------

	public void PaintUnderScreen(Graphics g)
	{
		ScreenPainter screenPainter;
		for(Enumeration painters = screenPainters.elements(); painters.hasMoreElements();)
		{
			screenPainter = (ScreenPainter)painters.nextElement();
			screenPainter.PaintScreenBefore(g);
		}
    }

	public void PaintOverScreen(Graphics g)
	{
		ScreenPainter screenPainter;
		for(Enumeration painters = screenPainters.elements(); painters.hasMoreElements();)
		{
			screenPainter = (ScreenPainter)painters.nextElement();
			screenPainter.PaintScreenAfter(g);
		}
    }

	public void PaintAllNodes(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
	{
		NodePainter nodePainter;
		NodeInfo displayInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
		if( (displayInfo == null) || (displayInfo.GetDisplayThisNode() == false) ) return;
		for(Enumeration painters = nodePainters.elements(); painters.hasMoreElements();)
		{
			nodePainter = (NodePainter)painters.nextElement();
			nodePainter.PaintNode(pNodeNumber, x1, y1, x2, y2, g);
		}
	}

	public void PaintAllEdges(Integer pSourceNodeNumber, Integer pDestinationNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
	{
		EdgePainter edgePainter;
		NodeInfo sourceDisplayInfo = (NodeInfo)proprietaryNodeInfo.get(pSourceNodeNumber);
		NodeInfo destinationDisplayInfo= (NodeInfo)proprietaryNodeInfo.get(pDestinationNodeNumber);
		if( (sourceDisplayInfo == null) || (destinationDisplayInfo == null) || (sourceDisplayInfo.GetDisplayThisNode() == false) || (destinationDisplayInfo.GetDisplayThisNode() == false)) return;
		for(Enumeration painters = edgePainters.elements(); painters.hasMoreElements();)
		{
			edgePainter = (EdgePainter)painters.nextElement();
			edgePainter.PaintEdge(pSourceNodeNumber, pDestinationNodeNumber, x1, y1, x2, y2, g);
		}
	}

				    //--------------------------------------------------------------------------
		        	//*****---PAINT---******//
	public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
	{
		NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
		g.drawImage(nodeInfo.GetImage(), x1, y1, x2-x1, y2-y1, null);

		/*if(nodeInfo.GetDisplayNodeNumber() == true)
		{*/
                g.setColor(Color.black);
                g.setFont( new Font ( "Arial", 0, 10) );
                g.drawString("ID: " + String.valueOf(pNodeNumber),  x1 + (x2 - x1)/4, y2+(y2-y1)/4);

		//}
	}
		        //*****---PAINT---******//
	        	//--------------------------------------------------------------------------

	public void PaintEdge(Integer pSourceNodeNumber, Integer pDestinationNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
	{
		g.setColor(Color.black);
		g.drawLine(x1, y1, x2, y2);
	}



	          //*****---run---******//
	          //this function runs in the background and repaints the screen
	          //at the user determined refresh rate
	public void run()
	{
		while(true)
		try
		{
			sleep(refreshRate);
			RefreshScreenNow();
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}

	}
			//*****---run---******//


	          //------------------------------------------------------------------------
			  //*****---GET/SET FUNCTIONS---******//
	public  static double GetScaleFactor()
	{
		Dimension d1 = MainClass.mainFrame.GetMainScrollPane().getSize();
		Insets inset = MainClass.mainFrame.GetMainScrollPane().getInsets();
		Dimension d2 = MainClass.mainFrame.GetGraphDisplayPanel().getSize();
        return (d2.getHeight()+(inset.top+inset.bottom))/d1.getHeight();
	}

	public  static long GetRefreshRate(){return refreshRate;}
	public  static void SetRefreshRate(long pRefreshRate){refreshRate = pRefreshRate;	}

	public boolean GetSelectMode(){return selectMode;}
	public boolean GetHandMode(){return handMode;}
	public boolean GetZoomMode(){return zoomMode;}

	public void SetSelectMode(boolean b){selectMode=b;}
	public void SetHandMode(boolean b){handMode=b;}
	public void SetZoomMode(boolean b){zoomMode=b;}

	public NodeInfo GetNodeInfo(Integer nodeNumber){return (NodeInfo)proprietaryNodeInfo.get(nodeNumber);}
	public EdgeInfo GetEdgeInfo(Integer sourceNumber, Integer destinationNumber){return (EdgeInfo)proprietaryEdgeInfo.get(sourceNumber,destinationNumber);}
	public Hashtable GetNodeInfo(){return proprietaryNodeInfo;}
	public TwoKeyHashtable GetEdgeInfo(){return proprietaryEdgeInfo;}

			  //*****---GET/SET FUNCTIONS---******//
	          //------------------------------------------------------------------------

	          //*****---Thread commands---******//
    public void start(){ try{ refreshScreenThread=new Thread(this);refreshScreenThread.start();} catch(Exception e){e.printStackTrace();}}
    public void stop(){ try{ refreshScreenThread.stop();} catch(Exception e){e.printStackTrace();}}
	public static void sleep(long p){ try{ refreshScreenThread.sleep(p);} catch(Exception e){e.printStackTrace();}}
    public static void setPriority(int p) { try{refreshScreenThread.setPriority(p);} catch(Exception e){e.printStackTrace();}}
			//*****---Thread commands---******//



              //------------------------------------------------------------------------
	          //*****---Node Created---******//
	          //this function defines what you do when a new node is created
	          //It is called by net.tinyos.moteview.PacketAnalyzers.ObjectMainter
    public synchronized void NodeCreated(NodeEvent e)
    {
    	Integer newNodeNumber = e.GetNodeNumber();//you probably want to create a new info pbject to track the data of this new node

    	if(!proprietaryNodeInfo.containsKey(newNodeNumber))//unless it already exists (it might exist if you don't delete it in NodeDeleted()
    	{
    		NodeInfo nodeInfo = new NodeInfo (newNodeNumber );
                proprietaryNodeInfo.put(newNodeNumber, nodeInfo);
                nodeInfo.SetDisplayNodeNumber( true);
    	}
    	else
    	{
    		NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(newNodeNumber);//but you might also want to leave it there but disable it, unless this node reappears and you want to use the same info
    		nodeInfo.SetDisplayThisNode(true);
    	}
    }

                  //*****---Node Created---******//
              //------------------------------------------------------------------------


              //------------------------------------------------------------------------
    	          //*****---Node Deleted---******//
	          //this function defines what you do when a new node is deleted
	          //It is called by net.tinyos.moteview.PacketAnalyzers.ObjectMainter
    public synchronized void NodeDeleted(NodeEvent e)
    {
    	Integer deletedNodeNumber = e.GetNodeNumber();//you probably want to delete the info pbject to track the data of this new node
    	NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(deletedNodeNumber);//but you might also want to leave it there but disable it, unless this node reappears and you want to use the same info
    	if(nodeInfo!=null)
    	{
    		nodeInfo.SetDisplayThisNode(false);
    	}
    }
	          //*****---Node Deleted---******//
              //------------------------------------------------------------------------


              //------------------------------------------------------------------------
	          //*****---Edge Created---******//
	          //this function defines what you do when a new edge is created
	          //It is called by net.tinyos.moteview.PacketAnalyzers.ObjectMainter
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
	          //It is called by net.tinyos.moteview.PacketAnalyzers.ObjectMainter
    public synchronized void EdgeDeleted(EdgeEvent e)
    {
    	Integer sourceNodeNumber = e.GetSourceNodeNumber();
    	Integer destinationNodeNumber = e.GetDestinationNodeNumber();//you probably want to create a new info pbject to track the data of this new node
    	proprietaryEdgeInfo.remove(sourceNodeNumber, destinationNodeNumber);//but you might also want to leave it there but disable it, unless this edge reappears and you want to use the same info
    }
	          //*****---EdgeDeleted---******//
              //------------------------------------------------------------------------



              //------------------------------------------------------------------------
	          //*****---GRAPHICS COMMANDS---******//
	public void NodeClicked(NodeClickedEvent e){}
    public void NodeDragged(NodeDraggedEvent e){}
	public void EdgeClicked(EdgeClickedEvent e){}

	public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber)
	{
		ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel((NodeInfo)proprietaryNodeInfo.get(pNodeNumber));
		return (ActivePanel)panel;
	}

	public ActivePanel GetProprietaryEdgeInfoPanel(Integer pSourceNodeNumber, Integer pDestinationNodeNumber)
	{
		return null;
/*		ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel((NodeInfo)proprietaryNodeInfo.get(pEdge.GetSource().GetNodeNumber()));
		return (ActivePanel)panel;*/
	}

	public void ShowOptionsDialog()
	{
		StandardDialog newDialog = new StandardDialog(new OptionsPanel());
		newDialog.show();
	}

	public ActivePanel GetOptionsPanel()
	{
		return new OptionsPanel();
	}

	public void SetNodePosition ( Integer nNode, int nX, int nY )
	{
	    NodeInfo node = (NodeInfo) proprietaryNodeInfo.get( nNode );
	    if ( node != null )
	    {
		node.SetX ( nX );
		node.SetY ( nY );
	    }
	}

	public Integer FindNearestNode(double x, double y)
	{
	    System.out.println ( "DM: FindNearestNode: x: " + x + " y: " + y );
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
			x1=((NodeInfo)proprietaryNodeInfo.get(sourceNodeNumber)).GetX();
			y1=((NodeInfo)proprietaryNodeInfo.get(sourceNodeNumber)).GetY();
			x2=((NodeInfo)proprietaryNodeInfo.get(destinationNodeNumber)).GetX();
			y2=((NodeInfo)proprietaryNodeInfo.get(destinationNodeNumber)).GetY();
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

	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //PROPRIETARY NODE INFO DISPLAY PANEL
              //This class is an ActivePanel and should have all the information
              //in GUI form that this class stores with respect to nodes
              //It should be return with GetProprietaryNodeInfoPanel and it will be displayed
              //with all the other packet analyzer proprietary info when a node is clicked.
	public class ProprietaryNodeInfoPanel extends net.tinyos.moteview.Dialog.ActivePanel
	{
		NodeInfo nodeInfo;

		public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)
		{
			tabTitle = "Display";
			nodeInfo = pNodeInfo;
			//{{INIT_CONTROLS
			setLayout(null);
			Insets ins = getInsets();
			setSize(259,279);
			JLabel3.setText("Image Width");
			add(JLabel3);
			JLabel3.setBounds(36,48,84,24);
			JLabel4.setText("Image Height");
			add(JLabel4);
			JLabel4.setBounds(36,72,75,24);
			JTextField1.setNextFocusableComponent(JTextField2);
			JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
			JTextField1.setText("1.5");
			add(JTextField1);
			JTextField1.setBounds(120,48,87,18);
			JTextField2.setNextFocusableComponent(JCheckBox1);
			JTextField2.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
			JTextField2.setText("3.2");
			add(JTextField2);
			JTextField2.setBounds(120,72,87,18);
			JLabel1.setText("Image");
			add(JLabel1);
			JLabel1.setBounds(36,24,84,24);
			JTextField3.setNextFocusableComponent(JTextField1);
			JTextField3.setText("image/mote2.jpg");
			add(JTextField3);
			JTextField3.setBounds(84,24,162,18);
			JCheckBox1.setNextFocusableComponent(JCheckBox2);
			JCheckBox1.setSelected(true);
			JCheckBox1.setToolTipText("Check this if you want this node to appear on the screen");
			JCheckBox1.setText("Display This Node");
			add(JCheckBox1);
			JCheckBox1.setBounds(36,96,123,21);
			JCheckBox2.setNextFocusableComponent(JCheckBox3);
			JCheckBox2.setSelected(true);
			JCheckBox2.setToolTipText("This should be checked if you want this node to be fit onto the screen");
			JCheckBox2.setText("Fit To Screen");
			add(JCheckBox2);
			JCheckBox2.setBounds(36,120,123,21);
			JCheckBox3.setNextFocusableComponent(JTextField3);
			JCheckBox3.setSelected(true);
			JCheckBox3.setToolTipText("This should be checked if you want the number of the node to be drawn on the screen");
			JCheckBox3.setText("Display Node Number");
			add(JCheckBox3);
			JCheckBox3.setBounds(36,144,123,21);
			JButton1.setToolTipText("Click this button to see the image that is typed above");
			JButton1.setText("Preview");
			add(JButton1);
			JButton1.setBounds(168,108,84,27);
			JPanel1.setLayout(null);
			add(JPanel1);
			JPanel1.setBounds(36,165,153,126);
			//}}

			//{{REGISTER_LISTENERS
			SymAction lSymAction = new SymAction();
			JButton1.addActionListener(lSymAction);
			//}}
		}

		//{{DECLARE_CONTROLS
		javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
		javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
		javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
		javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
		javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
		javax.swing.JTextField JTextField3 = new javax.swing.JTextField();
		javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
		javax.swing.JCheckBox JCheckBox2 = new javax.swing.JCheckBox();
		javax.swing.JCheckBox JCheckBox3 = new javax.swing.JCheckBox();
		javax.swing.JButton JButton1 = new javax.swing.JButton();
		javax.swing.JPanel JPanel1 = new javax.swing.JPanel();
		//}}

		public void ApplyChanges()
		{
			nodeInfo.SetImageWidth(Double.parseDouble(JTextField1.getText()));
			nodeInfo.SetImageHeight(Double.parseDouble(JTextField2.getText()));
			nodeInfo.SetDisplayThisNode(JCheckBox1.isSelected());
			nodeInfo.SetFitOnScreen(JCheckBox2.isSelected());
			nodeInfo.SetDisplayNodeNumber(JCheckBox3.isSelected());
			nodeInfo.SetImageHelper(new ImageIcon(JTextField3.getText(),JTextField3.getText()));
			nodeInfo.SetImage(nodeInfo.GetImageHelper().getImage());
		}

		public void InitializeDisplayValues()
		{
			JTextField3.setText(nodeInfo.GetImageHelper().getDescription());
			JTextField1.setText(String.valueOf(nodeInfo.GetImageWidth()));
			JTextField2.setText(String.valueOf(nodeInfo.GetImageHeight()));
			JCheckBox1.setSelected(nodeInfo.GetDisplayThisNode());
			JCheckBox2.setSelected(nodeInfo.GetFitOnScreen());
			JCheckBox3.setSelected(nodeInfo.GetDisplayNodeNumber());
		}

		class SymAction implements java.awt.event.ActionListener
		{
			public void actionPerformed(java.awt.event.ActionEvent event)
			{
				Object object = event.getSource();
				if (object == JButton1)
					JButton1_actionPerformed(event);
			}
		}

		void JButton1_actionPerformed(java.awt.event.ActionEvent event)
		{
			// to do: code goes here.

			JButton1_actionPerformed_Interaction1(event);
		}

		void JButton1_actionPerformed_Interaction1(java.awt.event.ActionEvent event)
		{
			try {
			ImageIcon imageIcon = new ImageIcon(JTextField3.getText());
			Image tempImage = imageIcon.getImage();
			Graphics g = this.getGraphics();
			Dimension d = JPanel1.getSize();
			int width = (int)(MainClass.mainFrame.GetGraphDisplayPanel().GetXScale()*Double.parseDouble(JTextField1.getText()));
			int height = (int)(MainClass.mainFrame.GetGraphDisplayPanel().GetYScale()*Double.parseDouble(JTextField2.getText()));
			g.drawImage(tempImage, 36,144, width, height, null);
			} catch (java.lang.Exception e) {
			}
		}
	}              //PROPRIETARY NODE INFO DISPLAY PANEL
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************

	          //***********************************************************************
	          //***********************************************************************
	          //Class OptionsPanel
	          //This panel will be shown in a dialog when the users clicks the right menu
	public static class OptionsPanel extends ActivePanel implements ItemListener
	{

		public OptionsPanel()
		{
			tabTitle = "Display Properties";
			modal=true;
			//{{INIT_CONTROLS
			setLayout(null);
//			Insets ins = getInsets();
		setSize(280,114);
		JLabel1.setToolTipText("This is the number of times the screen will be magnified");
		JLabel1.setText("ZoomX:");
		add(JLabel1);
		JLabel1.setBounds(24,12,48,24);
		JComboBox1.setEditable(true);
		JComboBox1.setToolTipText("This is the number of times the screen will be magnified");
		JComboBox1.addItem(new Double(1.0));
		JComboBox1.addItem(new Double(1.5));
		JComboBox1.addItem(new Double(2.0));
		JComboBox1.addItem(new Double(2.5));
		JComboBox1.addItem(new Double(3.0));
		add(JComboBox1);
		JComboBox1.setBounds(144,12,108,24);
		JLabel2.setToolTipText("Times are listed in milliseconds");
		JLabel2.setText("Screen Refresh Rate:");
		add(JLabel2);
		JLabel2.setBounds(24,48,132,24);
		JLabel4.setText("msec");
		add(JLabel4);
		JLabel4.setFont(new Font("Dialog", Font.BOLD, 9));
		JLabel4.setBounds(204,48,24,24);
		JSlider1.setMinimum(100);
		JSlider1.setMaximum(10000);
		JSlider1.setToolTipText("Slide this to change the refresh rate");
		//JSlider1.setBorder(bevelBorder1);
		JSlider1.setValue(1500);
		add(JSlider1);
		JSlider1.setBounds(60,84,216,21);
		//$$ bevelBorder1.move(0,115);
		JLabel3.setText("jlabel");
		add(JLabel3);
		JLabel3.setFont(new Font("Dialog", Font.BOLD, 16));
		JLabel3.setBounds(156,48,51,27);
		JComboBox1.setSelectedIndex(0);
		JCheckBox3.setSelected(false);
		JCheckBox3.setToolTipText("This should be checked if you want the number of all the nodes to be drawn on the screen");
		JCheckBox3.setText("Display Node Numbers");
		add(JCheckBox3);
		JCheckBox3.setBounds(36,144,200,21);
		//}}

		//{{REGISTER_LISTENERS
		SymChange lSymChange = new SymChange();
		JSlider1.addChangeListener(lSymChange);
		SymAction lSymAction = new SymAction();
//		JCheckBox3.addItemListener(this);
		JCheckBox3.addChangeListener(lSymChange);
		//}}
	}

	//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JComboBox JComboBox1 = new javax.swing.JComboBox();
	javax.swing.JLabel JLabel2 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JSlider JSlider1 = new javax.swing.JSlider();
	//com.symantec.itools.javax.swing.borders.BevelBorder bevelBorder1 = new com.symantec.itools.javax.swing.borders.BevelBorder();
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JCheckBox JCheckBox3 = new javax.swing.JCheckBox();
	//}}


		public void ApplyChanges()
		{
            MainClass.displayManager.MultiplyGraphDisplayPanelSize( Double.parseDouble(JComboBox1.getSelectedItem().toString()));
			MainClass.displayManager.SetRefreshRate(JSlider1.getValue());

		}

		public void InitializeDisplayValues()
		{
            double factor = MainClass.displayManager.GetScaleFactor();
            JComboBox1.setSelectedItem(new Double(factor));
			JSlider1.setValue((int)MainClass.displayManager.GetRefreshRate());
			JLabel3.setText(String.valueOf(MainClass.displayManager.GetRefreshRate()));
		}


		class SymChange implements javax.swing.event.ChangeListener
		{
			public void stateChanged(javax.swing.event.ChangeEvent event)
			{
				Object object = event.getSource();
				if (object == JSlider1)
					JSlider1_stateChanged(event);
				else if (object == JCheckBox3)
				{
					NodeInfo currentNodeInfo;
					for(Enumeration e = proprietaryNodeInfo.elements();e.hasMoreElements();)
					{
						currentNodeInfo = (NodeInfo)e.nextElement();
						currentNodeInfo.SetDisplayNodeNumber(JCheckBox3.isSelected());
					}
				}
			}
		}

		void JSlider1_stateChanged(javax.swing.event.ChangeEvent event)
		{
			// to do: code goes here.

			JSlider1_stateChanged_Interaction1(event);
		}

		class SymAction implements java.awt.event.ActionListener
		{
			public void actionPerformed(java.awt.event.ActionEvent event)
			{
			}
		}

		void JSlider1_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
		{
			try {
				// convert int->class java.lang.String
				JLabel3.setText(java.lang.String.valueOf(JSlider1.getValue()));
			} catch (java.lang.Exception e) {
			}
		}

		public void ItemStateChanged(ItemEvent event)
		{
			Object object = event.getSource();
//			if(object == JCheckBox3)
		}
	}
	          //Class OptionsPanel
	          //***********************************************************************
	          //***********************************************************************

	class SymAction implements java.awt.event.ActionListener
	{
            public void actionPerformed(java.awt.event.ActionEvent event)
            {
                Object object = event.getSource();
                if ( object == m_miReprogramming ) { DisplayReprogramming ( ); }
                else if ( object == m_miDisplay ) { HideNodes ( ); }
                else if ( object == m_miSortID ) { SortNodes ( SORTBY_ID ); }
                else if ( object == m_miSortProgID ) { SortNodes ( SORTBY_PROGID ); }
            }
	}



		        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //MENU MANAGER
              //This class creates and holds the menu that controls this
              //DisplayManager.  It returns the menu to whoever wants
              //to display it and it also handles all events on the menu
	protected class MenuManager implements /*Serializable,*/ ActionListener, ItemListener
	{
			//{{DECLARE_CONTROLS
		JSeparator separator1 = new JSeparator();
		JMenuItem propertiesItem = new JMenuItem();
		JSeparator separator2 = new JSeparator();
		JMenu serializeMenu = new JMenu();
		JMenuItem saveNodesItem = new JMenuItem();
		JMenuItem loadNodesItem = new JMenuItem();
		JMenuItem saveEdgesItem = new JMenuItem();
		JMenuItem loadEdgesItem = new JMenuItem();
		//}}

		public MenuManager()
		{
			//{{INIT_CONTROLS
			MainClass.mainFrame.DisplayMenu.add(separator1);
			propertiesItem.setText("Display Options");
			propertiesItem.setActionCommand("Display Options");
			MainClass.mainFrame.DisplayMenu.add(propertiesItem);
			MainClass.mainFrame.DisplayMenu.add(separator2);
			serializeMenu.setText("Serialize");
			serializeMenu.setActionCommand("Serialize");
			saveNodesItem.setText("Save Node Display Info");
			saveNodesItem.setActionCommand("Save Node Display Info");
			serializeMenu.add(saveNodesItem);
			loadNodesItem.setText("Load Node Display Info");
			loadNodesItem.setActionCommand("Load Node Display Info");
			serializeMenu.add(loadNodesItem);
			saveEdgesItem.setText("Save Edge Display Info");
			saveEdgesItem.setActionCommand("Save Edge Display Info");
			serializeMenu.add(saveEdgesItem);
			loadEdgesItem.setText("Load Edge Display Info");
			loadEdgesItem.setActionCommand("Load Edge Display Info");
			serializeMenu.add(loadEdgesItem);
			MainClass.mainFrame.DisplayMenu.add(serializeMenu);
			//}}

			//{{REGISTER_LISTENERS
			propertiesItem.addActionListener(this);
			saveNodesItem.addActionListener(this);
			loadNodesItem.addActionListener(this);
			saveEdgesItem.addActionListener(this);
			loadEdgesItem.addActionListener(this);
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
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Load Nodes", FileDialog.LOAD);
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
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Save Edges", FileDialog.SAVE);
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
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Load Edges", FileDialog.LOAD);
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
	}
              //MENU MANAGER
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************

}