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
//SerialPortMadeUpPackets or one can put a menu item up
//to let people register it and de-register it with different
//packet recievers.
//*********************************************************
//*********************************************************
             
package Surge.PacketReciever;

import Surge.*;
import Surge.event.*;
import java.util.*;
import Surge.Packet.*;

public class MadeUpPackets extends Surge.PacketReciever.PacketReciever 
{
	
	public MadeUpPackets()
	{
		try{
			Thread t = new Thread(this);
			t.start();
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	public void run()
	{
		Date currentTime;
		Date packetTime;
		PacketEvent event;
		try
		{
			int count = 0;
			while(true)
			{
				Thread.sleep(333);
				byte[] fake_data = new byte[Packet.NUMBER_OF_BYTES];
				fake_data[0] = 0x7e;
				fake_data[1] = (byte)0; //handler
				fake_data[2] = (byte)0x19;
				fake_data[3] = (byte)2;
				fake_data[4] = (byte)2;
				fake_data[5] = (byte)8;
				fake_data[6] = (byte)200;
				fake_data[7] = (byte)12;
				fake_data[8] = (byte)100;
				fake_data[9] = (byte)88;
				TriggerPacketEvent(new PacketEvent(this, new Packet(fake_data), Calendar.getInstance().getTime()));




			}
		}
		catch(Exception e){e.printStackTrace();}
	}
		      //RUN
			  //------------------------------------------------------------------------

}
