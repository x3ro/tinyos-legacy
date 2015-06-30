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

package net.tinyos.tinydb.topology.event;

import net.tinyos.tinydb.topology.*;
import java.util.*;
import net.tinyos.tinydb.topology.Packet.*;

              //this event is triggered every time a data packet is recieved by a packetReciever
public class PacketEvent extends java.util.EventObject
{
	Packet data;// contains the data packet itself
	Date time;
	
	public PacketEvent(Object source, Packet pData, Date pTime)
	{
		super(source);
		data = pData;
		time = pTime;      //**here we have have to find out how to set the time
	}
	
	public Packet GetPacket()
	{
		return data;
	}
	
	public Date GetTime()
	{
		return time;
	}
	
}
