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
import java.net.*;

/**
 * Interfaces with the IPPortPacketReciever class to send packets
 * through an IP port to a currently running SerialForwarder
 *
 * @author Joe Polastre <a href="mailto:polastre@cs.berkeley.edu">polastre@cs.berkeley.edu</a>
 */
public class IPPortPacketSender extends PacketSender
{
    /** Thread initialized by the Constructor to listen in the background
     */
        protected Thread packetsender;

        /** Default Constructor.  Starts the thread running in the background.
         */
	public IPPortPacketSender()
	{
            try{
                packetsender = new Thread(this);
                packetsender.start();
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
	}

        /** Default run method.  Waits for packets to be sent.
         */
	public void run()
	{

	}

        /**
         * getIPPortPacketReciever()
         * @desc the IP Port Packet Receiver has opened a port to the SerialForwarder
         * so we want to use this open port to write the packet out to the mote
         **/
        private IPPortPacketReciever getIPPortPacketReciever()
        {
            Vector packetrecs = MainClass.packetRecievers;
            PacketReciever pr = null;
            for (Enumeration e = packetrecs.elements(); e.hasMoreElements();)
            {
                pr = (PacketReciever)e.nextElement();
                if (pr instanceof IPPortPacketReciever)
                    return ((IPPortPacketReciever)pr);
            }
            return null;
        }

        /** sends a byte array packet to the IP Serial Forwarder.
         * Packets should be exactly 36 bytes long.
         * @param packet the packet to be sent as a byte array
         * @return true if the send completes successfully
         */
        public synchronized boolean sendPacket(byte[] packet)
        {
            IPPortPacketReciever rec = getIPPortPacketReciever();
            if (rec != null)
            {
                System.out.println ( "PacketSender: SendPacket: " + net.tinyos.moteview.util.Hex.toHex( packet ) );
		return rec.write(packet);
            }
            else
                return false;
        }

        /** sends a byte array packet to the IP Serial Forwarder.
         * Packets will be converted to byte arrays exactly 36 bytes long.<p>
         * <b>NOT YET IMPLEMENTED</b>
         * @param packet Instance of Packet class to be sent
         * @return true if the send completes sucessfully
         */
        public synchronized boolean sendPacket(Packet packet)
        {
            PacketReciever rec = getIPPortPacketReciever();
            if (rec != null)
            {
                /* need to convert something of type Packet to a byte array []
                return rec.write(packet);
                 * NOT YET IMPLEMENTED
                 */
                return false;
            }
            else
                return false;
        }

}