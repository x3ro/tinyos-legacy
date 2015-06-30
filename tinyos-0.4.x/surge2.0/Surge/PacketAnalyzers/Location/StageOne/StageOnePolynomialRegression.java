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

package Surge.PacketAnalyzers.Location.StageOne;

import Surge.PacketAnalyzers.Location.StageOne.*;
import Surge.*;
import Surge.event.*;
import java.math.*;

public class StageOnePolynomialRegression extends Surge.PacketAnalyzers.Location.StageOne.StageOneAnalyzer
{
	protected double coefficient1 = 0;
	protected double coefficient2 = 0;
	protected double coefficient3 = 0;
	protected double coefficient4 = 0;
	protected double coefficient5 = 0;
	protected double SSNormalizingFactor;
	protected double distanceNormalizingFactor;
	
	public StageOnePolynomialRegression()
	{
		coefficient1 = 2.6852;
		coefficient2 = -2.7594;
		coefficient3 = -.9027;
		coefficient4 =  1.085;
		coefficient5 = 0;
		SSNormalizingFactor = 393;
/*		coefficient1 = 1.4714;
		coefficient2 = -1.4748;
		coefficient3 = -1.0426;
		coefficient4 = 1.0832;
		coefficient5 = 0;
		SSNormalizingFactor = 394;*/
		distanceNormalizingFactor = 25;
	
		//{{INIT_CONTROLS
		//}}
	}
	           //----------------------------------------------------------------------
	             //ESTIMATE DISTANCE
	public double EstimateDistance(Integer pSourceNumber, Integer pDestinationNumber, double SS)
	{
		SS = SS/SSNormalizingFactor;
		return distanceNormalizingFactor*(coefficient1 + coefficient2*SS + coefficient3*Math.pow(SS,2.0) + coefficient4*Math.pow(SS,3) + coefficient5*Math.pow(SS,4));
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
		
	}
              //NODE INFO CLASS
              //**********************************************************************
              //**********************************************************************


              //**********************************************************************
              //**********************************************************************
              //EDGE INFO CLASS
	protected class EdgeInfo //implements java.io.Serializable
	{
		
	}
              //EDGE INFO CLASS
              //**********************************************************************
              //**********************************************************************
	//{{DECLARE_CONTROLS
	//}}
}