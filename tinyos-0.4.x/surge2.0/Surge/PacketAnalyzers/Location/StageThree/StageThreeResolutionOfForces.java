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

package Surge.PacketAnalyzers.Location.StageThree;

import Surge.PacketAnalyzers.Location.StageThree.*;
import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;
import Surge.PacketAnalyzers.*;

public class StageThreeResolutionOfForces extends Surge.PacketAnalyzers.Location.StageThree.StageThreeAnalyzer
{
	protected static Hashtable proprietaryNodeInfo;
	protected static TwoKeyHashtable proprietaryEdgeInfo;
         //----------------------------------------------------------------------
              //CONSTRUCTOR
	public StageThreeResolutionOfForces()
	{
		proprietaryNodeInfo = new Hashtable();
		proprietaryEdgeInfo = new TwoKeyHashtable();		

	
		//{{INIT_CONTROLS
		//}}
	}
              //CONSTRUCTOR
              //----------------------------------------------------------------------
	

              //----------------------------------------------------------------------
              //ESTIMATE LOCATION
	public void EstimateLocation()
	{
		MassSpringsLocationAnalyzer.EdgeInfo currentEdge;
		Integer sourceNumber, destinationNumber;
		MassSpringsLocationAnalyzer.NodeInfo sourceNode, destinationNode, currentNode;
		NodeInfo sourceNodeInfo, destinationNodeInfo, currentNodeInfo;
		double magnitude, angle, signX, signY;
		for(Enumeration edges = ((MassSpringsLocationAnalyzer)MainClass.locationAnalyzer).GetEdgeInfo(); edges.hasMoreElements();)
		{
			currentEdge = (MassSpringsLocationAnalyzer.EdgeInfo)edges.nextElement();
			if(currentEdge == null) continue;
			sourceNumber = currentEdge.GetSourceNodeNumber();
			destinationNumber = currentEdge.GetDestinationNodeNumber();
			sourceNode = ((MassSpringsLocationAnalyzer)MainClass.locationAnalyzer).GetNodeInfo(sourceNumber);
			destinationNode = ((MassSpringsLocationAnalyzer)MainClass.locationAnalyzer).GetNodeInfo(destinationNumber);
			if( (sourceNode == null) || (destinationNode == null)) continue;
			sourceNodeInfo = (NodeInfo)proprietaryNodeInfo.get(sourceNumber);
			destinationNodeInfo = (NodeInfo)proprietaryNodeInfo.get(destinationNumber);
			if( (sourceNodeInfo == null) || (destinationNodeInfo == null)) continue;
				
			magnitude = GetForceMagnitude(sourceNode.GetX(), sourceNode.GetY(), destinationNode.GetX(), destinationNode.GetY(), MainClass.locationAnalyzer.GetDistance(sourceNumber,destinationNumber));
			angle = GetForceAngle(sourceNode.GetX(), sourceNode.GetY(), destinationNode.GetX(), destinationNode.GetY());
			if( (destinationNode.GetX()-sourceNode.GetX()) >0) signX=-1; 	
			else if( (destinationNode.GetX()-sourceNode.GetX()) <0) signX=1; 	
			else signX=0;
			signX=signX*Math.abs(Math.cos(angle));
			if( (destinationNode.GetY()-sourceNode.GetY()) >0) signY=-1; 	
			else if( (destinationNode.GetY()-sourceNode.GetY()) <0) signY=1; 	
			else signY=0;
			signY=signY*Math.abs(Math.sin(angle));

			if( (!Double.isNaN(magnitude)) && (!Double.isNaN(angle)) &&
				(!Double.isInfinite(magnitude)) && (!Double.isInfinite(angle)) )
			{
				if( (sourceNode.GetFixed() != true) && (destinationNode.GetFixed() != true))
				{
					sourceNodeInfo.ProcessEdge(signX*(magnitude/2), signY*(magnitude/2));
					destinationNodeInfo.ProcessEdge(-signX*(magnitude/2), -signY*(magnitude/2));
				}
				else if(sourceNode.GetFixed() == true)
				{
					destinationNodeInfo.ProcessEdge(-signX*(magnitude), -signY*(magnitude));
				}
				else if(destinationNode.GetFixed() == true)
				{
					sourceNodeInfo.ProcessEdge(signX*(magnitude), signY*(magnitude));
				}
			}
			else
			{
				System.out.println("Error in Stage 3 of Location Analyzer: infinite of NaN");
				sourceNode.SetX(Math.random());
				sourceNode.SetY(Math.random());
				destinationNode.SetX(Math.random());
				destinationNode.SetY(Math.random());
			}
		}
			
		for(Enumeration nodes = ((MassSpringsLocationAnalyzer)MainClass.locationAnalyzer).GetNodeInfo(); nodes.hasMoreElements();)
		{
			currentNode = (MassSpringsLocationAnalyzer.NodeInfo)nodes.nextElement();
			currentNodeInfo = (NodeInfo)proprietaryNodeInfo.get(currentNode.GetNodeNumber());
			if((currentNode == null)||(currentNodeInfo==null)) continue;
			if(currentNode.GetFixed() ==false)
			{
				currentNode.SetX(currentNodeInfo.CalculateNewXCoord(currentNode.GetX()));
				currentNode.SetY(currentNodeInfo.CalculateNewYCoord(currentNode.GetY()));
			}
			if( (Double.isNaN(currentNode.GetX())) || (Double.isNaN(currentNode.GetY())) ||
			(Double.isInfinite(currentNode.GetX())) || (Double.isInfinite(currentNode.GetY())))
			{
				System.out.println("Error in Stage 3 of Location Analyzer: infinite of NaN location");
				currentNode.SetX(Math.random());
				currentNode.SetY(Math.random());
			}
			currentNodeInfo.reset();
		}
	}
              //ESTIMATE LOCATION
              //----------------------------------------------------------------------
	

              //----------------------------------------------------------------------
              //GET FORCE MAGNITUDE
	public double GetForceMagnitude(double x1, double y1, double x2, double y2, double length)
	{         //returns the difference of the length of the edge and the distance between the nodes (they should be the same; any difference is considered a force that will be used to move the nodes)
		double distance = Math.sqrt(Math.pow(x1-x2,2)+Math.pow(y1-y2,2));
		return length-distance;
	}
              //GET FORCE MAGNITUDE
              //----------------------------------------------------------------------

              
              //----------------------------------------------------------------------
              //GET FORCE ANGLE
	public double GetForceAngle(double x1, double y1, double x2, double y2)
	{
		if(x2-x1 == 0)
			return Math.PI/2;//stop divide by zero errors
		return Math.atan((y2-y1)/(x2-x1));
	}
              //GET FORCE ANGLE
              //----------------------------------------------------------------------

              
              //----------------------------------------------------------------------
              //NODE/EDGE CREATED/DELETED
	public synchronized void NodeCreated(NodeEvent e)
    {
    	Integer nodeNumber = e.GetNodeNumber();
    	proprietaryNodeInfo.put(nodeNumber, new NodeInfo(nodeNumber));
    }

    public synchronized void NodeDeleted(NodeEvent e)
    {
    	Integer nodeNumber = e.GetNodeNumber();
    	proprietaryNodeInfo.remove(nodeNumber);
    }
	
	public synchronized void EdgeCreated(EdgeEvent e)
    {
    }
 
    public synchronized void EdgeDeleted(EdgeEvent e)
    {
    }
              //Node/Edge CREATED/DELETED
              //----------------------------------------------------------------------




              //**********************************************************************
              //**********************************************************************
              //NODE INFO CLASS
	protected class NodeInfo// implements java.io.Serializable
	{
		Integer nodeNumber;
		double deltaX;
		double deltaY;
		int numberOfEdges;
		
		public NodeInfo(Integer pNodeNumber)
		{
			nodeNumber = pNodeNumber;
			reset();
		}
		
		public void reset()
		{
			deltaX = 0;
			deltaY = 0;
			numberOfEdges = 0;
		}	
		
		public void ProcessEdge(double pDeltaX, double pDeltaY)
		{
			deltaX += pDeltaX;
			deltaY += pDeltaY;
			numberOfEdges++;
		}
		
		public double CalculateNewXCoord(double pXCoord)
		{
			if(numberOfEdges==0)
				return pXCoord;
			return pXCoord + deltaX/numberOfEdges;//this should be scaled with the size of the edges
		}
		
		public double CalculateNewYCoord(double pYCoord)
		{
			if(numberOfEdges==0)
				return pYCoord;
			return pYCoord + deltaY/numberOfEdges;//this should be scaled with the size of the edges
		}
		
		public Integer GetNodeNumber()
		{
			return nodeNumber;
		}
	}
              //NODE INFO CLASS
              //**********************************************************************
              //**********************************************************************


              //**********************************************************************
              //**********************************************************************
              //EDGE INFO CLASS
	protected class EdgeInfo// implements java.io.Serializable
	{
		
	}
              //EDGE INFO CLASS
              //**********************************************************************
              //**********************************************************************
	//{{DECLARE_CONTROLS
	//}}
}
