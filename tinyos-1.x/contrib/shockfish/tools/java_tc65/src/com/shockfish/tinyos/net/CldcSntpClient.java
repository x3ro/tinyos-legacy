package com.shockfish.tinyos.net;
import java.io.ByteArrayInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;

import javax.microedition.io.Connector;
import javax.microedition.io.UDPDatagramConnection;
import javax.microedition.io.Datagram;
import javax.microedition.io.DatagramConnection;


/**
 * NtpClient - an NTP client for Java.  This program connects to an NTP server
 * and prints the response to the console.
 * 
 * The local clock offset calculation is implemented according to the SNTP
 * algorithm specified in RFC 2030.  
 * 
 * Note that on windows platforms, the curent time-of-day timestamp is limited
 * to an resolution of 10ms and adversely affects the accuracy of the results.
 * 
 * 
 * This code is copyright (c) Adam Buckley 2004
 *
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by the Free 
 * Software Foundation; either version 2 of the License, or (at your option) 
 * any later version.  A HTML version of the GNU General Public License can be
 * seen at http://www.gnu.org/licenses/gpl.html
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
 * more details.
 *  
 * @author Adam Buckley
 * @author Pierre Metrailler, Shockfish SA, for the CLDC port.
 * 
 * Note 1 : the Siemens MIDP has an awful time resolution.
 * Note 2 : the Siemens Tc65 drifts at about ~0.3s/hour
 */




public class CldcSntpClient
{
	public static long getOffset(String serverName, String gprsConf) throws IOException
	{


			// Send request
			UDPDatagramConnection sc = (UDPDatagramConnection)Connector.open("datagram://"+serverName+":"+123+gprsConf);
			byte[] buf = new CldcNtpMessage().toByteArray();
			Datagram packet = sc.newDatagram(buf, buf.length);
			
			// Set the transmit timestamp *just* before sending the packet
			// ToDo: Does this actually improve performance or not?
			CldcNtpMessage.encodeTimestamp(packet.getData(), 40, (System.currentTimeMillis()/1000.0) + 2208988800.0);
	
			sc.send(packet);
			// Get response
			System.out.println("NTP request sent, waiting for response...\n");
			packet = sc.newDatagram(buf, buf.length);
			sc.receive(packet);
			
			// Immediately record the incoming timestamp
			double destinationTimestamp =(System.currentTimeMillis()/1000.0) + 2208988800.0;
			
			
			// Process response
			CldcNtpMessage msg = new CldcNtpMessage(packet.getData());
			
			// Corrected, according to RFC2030 errata
			double roundTripDelay = (destinationTimestamp-msg.originateTimestamp) -
				(msg.transmitTimestamp-msg.receiveTimestamp);
				
			double localClockOffset =
				((msg.receiveTimestamp - msg.originateTimestamp) +
				(msg.transmitTimestamp - destinationTimestamp)) / 2;
			
			
			// Display response
			System.out.println("NTP server: " + serverName);
			System.out.println(msg.toString());
			System.out.println("Dest. timestamp: " +CldcNtpMessage.timestampToString(destinationTimestamp));
			System.out.println("Round-trip delay: " + (roundTripDelay*1000) + " ms");
			System.out.println("Local clock offset: " + (localClockOffset*1000) + " ms");
			System.out.println("Local delta: "+(destinationTimestamp-msg.originateTimestamp));
			System.out.println("Server processing time: "+(msg.transmitTimestamp-msg.receiveTimestamp));
			long cTime = ((long)((localClockOffset*1000)))+ System.currentTimeMillis();
			System.out.println("Correct time :"+cTime);
			sc.close();
			return (long)((localClockOffset*1000));
	}
	
}
