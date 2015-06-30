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

package Surge.PacketAnalyzer.Location.StageThree;

import Surge.PacketAnalyzer.Location.StageThree.*;
import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;
import Surge.PacketAnalyzer.*;

public class StageThreeResolutionOfForces extends Surge.PacketAnalyzer.Location.StageThree.StageThreeAnalyzer
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
		LocationAnalyzer.EdgeInfo currentEdge;
		Integer sourceNumber, destinationNumber;
		LocationAnalyzer.NodeInfo sourceNode, destinationNode, currentNode;
		DisplayManager.NodeInfo sourceDisplayInfo, destinationDisplayInfo, currentDisplayInfo;
		NodeInfo sourceNodeInfo, destinationNodeInfo, currentNodeInfo;
		double magnitude, angle;
		for(Enumeration edges = MainClass.locationAnalyzer.GetEdgeInfo(); edges.hasMoreElements();)
		{
			currentEdge = (LocationAnalyzer.EdgeInfo)edges.nextElement();
			if(currentEdge == null) continue;
			sourceNumber = currentEdge.GetSourceNodeNumber();
			destinationNumber = currentEdge.GetDestinationNodeNumber();
			sourceNode = MainClass.locationAnalyzer.GetNodeInfo(sourceNumber);
			destinationNode = MainClass.locationAnalyzer.GetNodeInfo(destinationNumber);
			if( (sourceNode == null) || (destinationNode == null)) continue;
			sourceNodeInfo = (NodeInfo)proprietaryNodeInfo.get(sourceNumber);
			destinationNodeInfo = (NodeInfo)proprietaryNodeInfo.get(destinationNumber);
			if( (sourceNodeInfo == null) || (destinationNodeInfo == null)) continue;
				
			magnitude = GetForceMagnitude(sourceNode.GetX(), sourceNode.GetY(), destinationNode.GetX(), destinationNode.GetY(), MainClass.locationAnalyzer.GetDistance(sourceNumber,destinationNumber));
			angle = GetForceAngle(sourceNode.GetX(), sourceNode.GetY(), destinationNode.GetX(), destinationNode.GetY());
				
			if( (!Double.isNaN(magnitude)) && (!Double.isNaN(angle)) &&
				(!Double.isInfinite(magnitude)) && (!Double.isInfinite(angle)) )
			{
				if( (sourceNode.GetFixed() != true) && (destinationNode.GetFixed() != true))
				{
					sourceNodeInfo.ProcessEdge((magnitude/2)*Math.cos(angle), (magnitude/2)*Math.sin(angle));
					destinationNodeInfo.ProcessEdge((-magnitude/2)*Math.cos(angle), (-magnitude/2)*Math.sin(angle));
				}
				else if(sourceNode.GetFixed() == true)
				{
					destinationNodeInfo.ProcessEdge((-magnitude)*Math.cos(angle), (-magnitude)*Math.sin(angle));
				}
				else if(destinationNode.GetFixed() == true)
				{
					sourceNodeInfo.ProcessEdge((magnitude)*Math.cos(angle), (magnitude)*Math.sin(angle));
				}
			}
			else
			{
				int i = 1;
			}
		}
			
		for(Enumeration nodes = MainClass.locationAnalyzer.GetNodeInfo(); nodes.hasMoreElements();)
		{
			currentNode = (LocationAnalyzer.NodeInfo)nodes.nextElement();
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
		if(x1-x2 == 0)
			return Double.NaN;//stop divide by zero errors
		return Math.atan((y1-y2)/(x1-x2));
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
	protected class NodeInfo
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
			return pXCoord + deltaX/numberOfEdges;
		}
		
		public double CalculateNewYCoord(double pYCoord)
		{
			if(numberOfEdges==0)
				return pYCoord;
			return pYCoord + deltaY/numberOfEdges;
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
	protected class EdgeInfo
	{
		
	}
              //EDGE INFO CLASS
              //**********************************************************************
              //**********************************************************************
	//{{DECLARE_CONTROLS
	//}}
}
