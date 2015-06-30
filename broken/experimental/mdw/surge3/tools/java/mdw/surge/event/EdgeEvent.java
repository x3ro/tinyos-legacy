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
* Authors:   Wei Hong, modified for tinydb
*/

package mdw.surge.event;

import mdw.surge.*;
import java.util.*;

              //this event is triggered every time a edge is created or deleted
public class EdgeEvent extends java.util.EventObject
{
	protected Integer sourceNodeNumber;
	protected Integer destinationNodeNumber;
	protected Date time;//and the time the event was generated
	
	          //*****---CONSTRUCTOR---******//
	public EdgeEvent(Object source, Integer pSourceNodeNumber, Integer pDestinationNodeNumber, Date pTime)
	{
		super(source);
		sourceNodeNumber = pSourceNodeNumber;
		destinationNodeNumber = pDestinationNodeNumber;
		time = pTime;
	}
	          //*****---CONSTRUCTOR---******//
	
	
	
	          //*****---Get Functions---******//
	public Integer GetSourceNodeNumber(){return sourceNodeNumber;} 
	public Integer GetDestinationNodeNumber(){return destinationNodeNumber;} 
	 
	public Date GetTime()
	{
		return time;
	}
	//*****---Get Functions---******//
	
}
