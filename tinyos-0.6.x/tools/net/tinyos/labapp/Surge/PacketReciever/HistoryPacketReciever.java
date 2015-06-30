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
//The code in this class has never been tested or run.
//This class is a base class for HistoryRecievers in general.
//It has two main roles
//1.  Listen to some other recievers, hear their packets and store them
//2.  Replay the store of packets that has been heard
//The serialize class should allow us to save and replay a series of
//Packets at a later date.  This is useful so that we don't actually 
//have to re-run experiments over and over again, and also so we can
//test the same exact data with different algorithms for comparison.
//This class can either be subclassed into things like a 
//SerialPortHistoryPacketReciever or one can put a menu item up
//to let people register it and de-register it with different
//packet recievers.
//*********************************************************
//*********************************************************
             
package Surge.PacketReciever;

import Surge.*;
import Surge.event.*;
import java.util.*;

public class HistoryPacketReciever extends Surge.PacketReciever.PacketReciever implements PacketEventListener
{
	protected Vector history;//a list of all the packets recieved
	protected Date replayStartTime;//the time the history started playing again
	protected Date historyStartTime;//the time the HistoryReciever starting listening and storing a history
	
	public HistoryPacketReciever()
	{
		history = new Vector();//define a vector to hold all the packets events I hears
	}

	public void PacketRecieved(PacketEvent e)
	{
		history.add(e);
	}
	
              //------------------------------------------------------------------------
	          //ACQUIRE HISTORY
	          //register to listen to all other packet recievers
		      //(Change this to only listen to e.g. serial port to create a SerialPortHistoryPacketReciever)
		      //or use a menu to allow one to select the Packet Recievers they want to save
	public void AcquireHistory()
	{
		PacketReciever reciever;
		for(Enumeration e = MainClass.packetRecievers.elements(); e.hasMoreElements(); )
		{
			reciever = (PacketReciever)e.nextElement();			
			reciever.AddPacketEventListener(this);
		}
	}
	          //ACQUIRE HISTORY
              //------------------------------------------------------------------------


              //------------------------------------------------------------------------
	          //REPLAY HISTORY
	          //start playing the history that has been acquired
	public void ReplayHistory()
	{
		replayStartTime = Calendar.getInstance().getTime();
		if(!history.isEmpty()) 
		{
			historyStartTime = ((PacketEvent)history.firstElement()).GetTime();
		}
		recievePacketsThread = new Thread();
		recievePacketsThread.run();
	}
	          //REPLAY HISTORY
              //------------------------------------------------------------------------


              //------------------------------------------------------------------------
	          //SERIALIZE HISTORY
	          //This function saves the history so that it can be used again later
	public void SerializeHistory()
	{
		      //this function should be used when you have acquired a history and
		      //you want to save it.  Just serialize the history vector
	}
	          //SERIALIZE HISTORY
              //------------------------------------------------------------------------


			  //------------------------------------------------------------------------
		      //DESERIALIZE HISTORY
	    	  //This function opens a serialized history for playback
	public void DeserializeHistory()
	{
		      //this function should be used when you want to retrieve a history
		      //that you previously acquired and you want to replay it
	}
		      //DESERIALIZE HISTORY
			  //------------------------------------------------------------------------


			  //------------------------------------------------------------------------
		      //RUN
		      //this is the function that is run in the background as a thread
		      //IT basically hears all packets and stores them in a history
	public void run()
	{
		Date currentTime;
		Date packetTime;
		PacketEvent event;
		try
		{
			while(true)
			{
				currentTime = Calendar.getInstance().getTime();
				for(Enumeration e = history.elements(); e.hasMoreElements();)
				{
					  event =  (PacketEvent)e.nextElement();
					  packetTime = event.GetTime();
					  if( (packetTime.getTime()-historyStartTime.getTime()) > (currentTime.getTime()-replayStartTime.getTime()))
					  {
						TriggerPacketEvent(new PacketEvent(this, event.GetPacket(), currentTime));
					  }
					  history.remove(event);
				}
			}
		}
		catch(Exception e){e.printStackTrace();}
	}
		      //RUN
			  //------------------------------------------------------------------------

}