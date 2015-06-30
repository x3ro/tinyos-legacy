package net.tinyos.moteview.PacketAnalyzers;

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
* Authors:   Bret Hull
* History:   created 5/2002
*/


import net.tinyos.moteview.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.Dialog.*;
import net.tinyos.moteview.Packet.*;
import net.tinyos.moteview.util.*;
import java.util.*;
import java.lang.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.io.*;
import java.util.zip.*;


public class GenericSensor extends PacketAnalyzer
{

    protected               Hashtable       proprietaryNodeInfo;

    public GenericSensor ( )
    {
	MainClass.objectMaintainer.AddNodeEventListener(this);
	//register myself to be able to contribute to the node/edge properties panel
	MainClass.displayManager.AddNodeDialogContributor(this);
	//register myself to recieve NodeClickedEvents and EdgeClickedEvents
	MainClass.displayManager.AddNodeClickedEventListener(this);
	//register myself to paint nodes and edges and display info panels
	MainClass.displayManager.AddNodePainter(this);

	proprietaryNodeInfo     = new Hashtable();
    }

    public synchronized void NodeCreated(NodeEvent e)
    {
    	Integer newNodeNumber = e.GetNodeNumber();//you probably want to create a new info pbject to track the data of this new node
    	if(!proprietaryNodeInfo.containsKey(newNodeNumber))//unless it already exists (it might exist if you don't delete it in NodeDeleted()
    	{
            proprietaryNodeInfo.put(newNodeNumber, new NodeInfo(newNodeNumber));
    	}
    }

    public synchronized void NodeDeleted(NodeEvent e)
    {
        Integer deletedNodeNumber = e.GetNodeNumber();//you probably want to delete the info pbject to track the data of this new node
	System.out.println ("GENSEN: node deleted: " + deletedNodeNumber );
	proprietaryNodeInfo.remove(deletedNodeNumber);//but you might also want to leave it there but disable it, unless this node reappears and you want to use the same info
    }

    public synchronized void PacketRecieved(PacketEvent e)
    {
        //System.out.println ("GENSEN: PacketReceived");
    }


    public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
    {

    }

    public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber)
    {
            NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
            if(nodeInfo==null)  return null;
            ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel(nodeInfo);
            return (ActivePanel)panel;
    }

    public ActivePanel GetProprietaryNodeInfoPanel ( Vector nodes )
    {
        Vector myNodes = new Vector( );
        Integer nodeNumber;
        NodeInfo node;
        for ( Enumeration e = nodes.elements(); e.hasMoreElements(); )
        {
            nodeNumber = ((net.tinyos.moteview.util.NodeInfo) e.nextElement()).GetNodeNumber();
            node = (NodeInfo) proprietaryNodeInfo.get( nodeNumber );
            if ( node != null )
            {
                myNodes.add( node );
            }
        }

        ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel( myNodes );
        return (ActivePanel) panel;
    }

    public synchronized void NodeDragged(NodeDraggedEvent e)
    {

    }

    public class ProprietaryNodeInfoPanel extends net.tinyos.moteview.Dialog.ActivePanel
    {
        Vector             m_vctNodes       = new Vector ( );

        public ProprietaryNodeInfoPanel ( Vector nodes )
        {
            m_vctNodes = nodes;
            InitPanel ( );
        }

	public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)
	{
            m_vctNodes = new Vector ( );
            m_vctNodes.add( pNodeInfo );
            InitPanel ( );
	}


        private void InitPanel ( )
        {
            MainClass.reprogramming.myCodeInjector.RegisterActionListener( this );
            tabTitle = "Generic Sensor";

	    // Init Controls
	    setLayout(null);
	    Insets ins = getInsets();
	    //setSize(247,168);
	}


        public void ApplyChanges()
	{
            MainClass.reprogramming.myCodeInjector.UnregisterActionListener( this );
	}

        public void Cancel ( )
        {
           MainClass.reprogramming.myCodeInjector.UnregisterActionListener( this );
        }

        public void actionPerformed(ActionEvent e)
        {
	    switch ( e.getModifiers() )
            {
                default:
                    break;
            }
        }


	public void InitializeDisplayValues()
	{
	}

        private Vector ExtractNodeIDs ( )
        {
            if ( m_vctNodes == null ) return null;

            NodeInfo node;
            Vector   nodeIDs = new Vector( );
            for ( Enumeration nodes = m_vctNodes.elements(); nodes.hasMoreElements(); )
            {
                node = (NodeInfo) nodes.nextElement();
                nodeIDs.add( node.GetNodeNumber() );
            }
            return nodeIDs;
        }
    }


    public static class NodeInfo implements java.io.Serializable, Comparable
    {
            protected double           x;
	    protected double           y;
	    protected Integer          nodeNumber;
	    protected boolean          fixed;
	    protected boolean          displayCoords;

	    public NodeInfo(Integer pNodeNumber)
	    {
		    nodeNumber      = pNodeNumber;
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

            public int compareTo ( Object o )
            {
                NodeInfo node = (NodeInfo) o;
                return 0;
            }
    }

}