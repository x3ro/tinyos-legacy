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
* Authors:   Jason Hill
* History:   created 7/22/2001 
*/

package Surge.PacketAnalyzer.Location;

import Surge.PacketAnalyzer.Location.*;
import Surge.PacketAnalyzer.*;
import Surge.*;
import java.util.*;

public class FixedLocation
{
    public void EstimateLocation()
    {
		System.err.println("estimate");
		LocationAnalyzer.NodeInfo currentNode;
		for(Enumeration nodes = MainClass.locationAnalyzer.GetNodeInfo(); nodes.hasMoreElements();) 
		{
			currentNode = (LocationAnalyzer.NodeInfo)nodes.nextElement();
			synchronized(currentNode)
			{
				if(currentNode.GetFixed() == false)
				{
	    				currentNode.SetX(Math.random());
					currentNode.SetY(Math.random());
					currentNode.SetFixed(true);
				}
			}
		}
    }

}
