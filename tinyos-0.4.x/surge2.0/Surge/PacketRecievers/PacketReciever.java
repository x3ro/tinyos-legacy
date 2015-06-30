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

//*********************************************************
//*********************************************************
//this is a parent class for any class that might want to read packets.
//it basically holds the packetEvent code, allowing other classes
//to register as listeners and triggering events for all listeners
//It also implements the runnable interface, since packet recievers
//should always be running on their own thread
//*********************************************************
//*********************************************************


package Surge.PacketRecievers;

import Surge.*;
import Surge.event.*;
import Surge.Dialog.*;
import java.util.*;
import java.lang.*;
import java.io.*;



public class PacketReciever implements Runnable//, Serializable
{
	Thread recievePacketsThread;

	protected Vector listeners;//a list of all the listeners who want to know when a packet
	          //is recieved

	public PacketReciever()
	{
		listeners = new Vector();
	}
	
	public synchronized void AddPacketEventListener(PacketEventListener listener)
	{
		listeners.add(listener);//add the listeners to the listener list
	}
	
	public synchronized void RemovePacketEventListener(PacketEventListener listener)
	{
		listeners.remove(listener);//add the listeners to the listener list
	}
	
	protected void TriggerPacketEvent(PacketEvent e)
	{
		      //for each listener
		 
		PacketEventListener currentListener;
		for(Enumeration list = listeners.elements(); list.hasMoreElements();)
		{
			currentListener = (PacketEventListener)list.nextElement();
			currentListener.PacketRecieved(e);//send the listener an event
        }			
	}
	
	public void run()
	{
		
	}
	
	public ActivePanel GetOptionsPanel(){return null;}
		          //*****---Thread commands---******//
    public void start(){ try{ recievePacketsThread=new Thread(this);recievePacketsThread.start();} catch(Exception e){e.printStackTrace();}}
    public void stop(){ try{ recievePacketsThread.stop();} catch(Exception e){e.printStackTrace();}}
    public void sleep(long p){ try{ recievePacketsThread.sleep(p);} catch(Exception e){e.printStackTrace();}}
    public void setPriority(int p) { try{recievePacketsThread.setPriority(p);} catch(Exception e){e.printStackTrace();}}    
			//*****---Thread commands---******//

}


 