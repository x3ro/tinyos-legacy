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

package Surge.PacketAnalyzers.Location.StageTwo;

import Surge.PacketAnalyzers.Location.StageTwo.*;
import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;

public class StageTwoTimeWindow extends Surge.PacketAnalyzers.Location.StageTwo.StageTwoAnalyzer
{
	protected static Hashtable proprietaryNodeInfo;
	protected static TwoKeyHashtable proprietaryEdgeInfo;
	
	protected int windowSize = 10;

	public StageTwoTimeWindow()
	{
		proprietaryNodeInfo = new Hashtable();
		proprietaryEdgeInfo = new TwoKeyHashtable();		
	}
	
	              //----------------------------------------------------------------------
	             //ESTIMATE DISTANCE
	public double EstimateDistance(Integer pSourceNumber, Integer pDestinationNumber, double pDistance)
	{
		double distance, rand;
		EdgeInfo currentEdgeInfo = (EdgeInfo)proprietaryEdgeInfo.get(pSourceNumber, pDestinationNumber);
		if(Math.abs(pDistance) < 40)//this is a hack for noise filtering.  Should be some density estimator.
		{
			if(currentEdgeInfo != null)
			{
				currentEdgeInfo.AddDataPoint(pDistance);
				distance = currentEdgeInfo.GetMeanOfWindow();
				return distance;
			}
		}
		return Double.NaN;
	}
	             //ESTIMATE DISTANCE
              //----------------------------------------------------------------------
	

              //----------------------------------------------------------------------
              //Node/Edge CREATED/DELETED
	public synchronized void NodeCreated(NodeEvent e)
    {
    }

    public synchronized void NodeDeleted(NodeEvent e)
    {
    }
	
	public synchronized void EdgeCreated(EdgeEvent e)
    {
    	Integer sourceNumber = e.GetSourceNodeNumber();
    	Integer destinationNumber = e.GetDestinationNodeNumber();
    	EdgeInfo edgeInfo = new EdgeInfo(sourceNumber, destinationNumber, windowSize);
    	proprietaryEdgeInfo.put(sourceNumber, destinationNumber, edgeInfo);
    }
 
    public synchronized void EdgeDeleted(EdgeEvent e)
    {
    	Integer sourceNumber = e.GetSourceNodeNumber();
    	Integer destinationNumber = e.GetDestinationNodeNumber();
    	EdgeInfo edgeInfo = new EdgeInfo(sourceNumber, destinationNumber, windowSize);
    	proprietaryEdgeInfo.remove(sourceNumber, destinationNumber);
    }
              //Node/Edge CREATED/DELETED
              //----------------------------------------------------------------------

	public int GetWindowSize(){return windowSize;}
	public void SetWindowSize(int pWindowSize)
	{
		windowSize = pWindowSize;
		EdgeInfo currentEdgeInfo;
		for(Enumeration e = proprietaryEdgeInfo.elements(); e.hasMoreElements();)
		{
			currentEdgeInfo = (EdgeInfo)e.nextElement();
			currentEdgeInfo.SetWindowSize(windowSize);
		}
	}


              //**********************************************************************
              //**********************************************************************
              //NODE INFO CLASS
	protected class NodeInfo// implements java.io.Serializable
	{
		
	}
              //NODE INFO CLASS
              //**********************************************************************
              //**********************************************************************


              //**********************************************************************
              //**********************************************************************
              //EDGE INFO CLASS
	protected class EdgeInfo// implements java.io.Serializable
	{
		int windowSize;
		int windowPosition = 0;
		Vector window;//should create and Implement a circular Buffer class
		Integer sourceNumber;
		Integer destinationNumber;
		
		public EdgeInfo(Integer pSourceNumber, Integer pDestinationNumber, int pWindowSize)
		{
			sourceNumber = pSourceNumber;
			destinationNumber = pDestinationNumber;
			windowSize = pWindowSize;
			window = new Vector();
			window.setSize(windowSize);
		}

		public void AddDataPoint(double pData)
		{
			/*this if statement is a hack to filter out noisy data*/
/*			double mean = GetMeanOfWindow();
			double std = GetStdOfWindow();
			if( ((pData < mean + 2*std) &&
				(pData > mean - 2*std))  ||
				(Double.isNaN(mean))   ||
				(Double.isNaN(std))) 
			{*/
				window.removeElementAt(windowPosition);
				window.insertElementAt(new Double(pData), windowPosition);
				windowPosition = (windowPosition+1)%windowSize;
//			}
		}

		public double GetMeanOfWindow()
		{
			double sum =0;
			int count = 0;
			for(int index = 0; index < window.size(); index++)
			{
				if(window.elementAt(index)!=null)
				{
					sum += ((Double)window.elementAt(index)).doubleValue();
					count++;
				}
			}
			if(count==0)
				return Double.NaN;
			return sum/count;//(double)window.size();				
		}
		
		public double GetStdOfWindow()
		{
			double sum =0;
			double diff = 0;
			int count = 0;
			double mean = GetMeanOfWindow();
			for(int index = 0; index < window.size(); index++)
			{
				if(window.elementAt(index)!=null)
				{
					diff = ((Double)window.elementAt(index)).doubleValue()-mean;
					sum += Math.pow(diff,2);
					count++;
				}
			}
			if(count==0)
				return Double.NaN;
			return sum/count;//(double)window.size();				
		}
		
		public Integer GetSourceNumber(){return sourceNumber;}
		public Integer GetDestinationNumber(){return destinationNumber;}
		public int GetWindowSize(){return windowSize;}
		public void SetSourceNumber(Integer p){sourceNumber=p;}
		public void SetDestinationNumber(Integer p){destinationNumber=p;}
		public void SetWindowSize(int p)
		{
			windowSize=p;
			for(int index=window.size()-1;index >= windowSize; index--)
			{
				window.removeElementAt(index);
			}
			window.setSize(windowSize);
		}
	}
              //EDGE INFO CLASS
              //**********************************************************************
              //**********************************************************************
}