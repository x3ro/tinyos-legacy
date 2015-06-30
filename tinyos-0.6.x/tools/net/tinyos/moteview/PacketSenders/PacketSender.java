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
* Authors:   Joe Polastre (polastre@cs.berkeley.edu)
* History:   created 11/02/2001
*/

package net.tinyos.moteview.PacketSenders;

import net.tinyos.moteview.*;
import net.tinyos.moteview.Packet.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.Dialog.*;
import net.tinyos.moteview.PacketRecievers.*;
import java.util.*;
import java.lang.*;
import java.io.*;


/**
 * this is a parent class for any class that might want to write packets.
 *
 * @author Joe Polastre <a href="mailto:polastre@cs.berkeley.edu">polastre@cs.berkeley.edu</a>
 **/
public class PacketSender implements Runnable//, Serializable
{
    /** Default thread run by the constructor
     */
	protected Thread recievePacketsThread;

        /**
         * Default Constructor
         */
	public PacketSender()
	{
	}

        /**
         * Template run function
         */
	public void run()
	{

	}

        /**
         * the default packet sender sends to all registered PacketSenders<p>
         * Each packet must be exactly 36 bytes long for the mote to accept it
         * @param packet a byte array of packets
         * @return true if all sends are successful
         */
        public static synchronized boolean sendPackettoAll(byte[] packet)
        {
            boolean returnvalue = true;
            for (Enumeration e = MainClass.packetSenders.elements(); e.hasMoreElements();)
            {
                PacketSender ps = (PacketSender)e.nextElement();
                returnvalue = returnvalue && ps.sendPacket(packet);
            }
            return returnvalue;
        }

        public synchronized boolean sendPacket(byte[] packet)
        {
            return false;
        }

        public synchronized boolean sendPacket(Packet packet)
        {
            return false;
        }

         /**
          * the default packet sender sends to all registered PacketSenders
          * @param packet an instance of the Packet class representing the data to be sent
          * @return true if all sends are successful
          */
        public static synchronized boolean sendPackettoAll(Packet packet)
        {
            boolean returnvalue = true;
            for (Enumeration e = MainClass.packetSenders.elements(); e.hasMoreElements();)
            {
                returnvalue = returnvalue && ((PacketSender)e.nextElement()).sendPacket(packet);
            }
            return returnvalue;
        }

        /** Returns the options panel, if any, when queried by the Surge GUI
         * @return the ActivePanel object to be displayed in surge
         */
	public ActivePanel GetOptionsPanel(){return null;}
		          //*****---Thread commands---******//
        /** Default start method
         */
    public void start(){ try{ recievePacketsThread=new Thread(this);recievePacketsThread.start();} catch(Exception e){e.printStackTrace();}}
    /** Default stop method
     */
    public void stop(){ try{ recievePacketsThread.stop();} catch(Exception e){e.printStackTrace();}}
    /** Default thread sleep function
     * @param p the amount of time in ms to sleep
     */
    public void sleep(long p){ try{ recievePacketsThread.sleep(p);} catch(Exception e){e.printStackTrace();}}
    /** sets the priority of the current running thread
     * @param p new priority
     */
    public void setPriority(int p) { try{recievePacketsThread.setPriority(p);} catch(Exception e){e.printStackTrace();}}
			//*****---Thread commands---******//

}


