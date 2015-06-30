// $Id: DTNStub.java,v 1.5 2003/10/07 21:46:09 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:  Wei Hong  <whong@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */

/**
 * Implementation of SerialStub interface over Delay Tolerant Network (DTN)
 * @author Wei Hong <whong@intel-research.net>
 * @author Intel Research Berkeley Lab
 */
package net.tinyos.util;

import java.util.*;
import java.io.*;

public class DTNStub implements SerialStub
{
    private static final boolean DEBUG = false;
    private Vector listeners = new Vector();
	private int packetSize;
	private String bundleAgentHost;

	private native void openDTNAgent(String bundleAgentHost);
	private native void closeDTNAgent();
	private native void receiveDTNBundle(byte[] packet);
	private native void sendDTNBundle(byte[] bundle);

	static {
		System.loadLibrary("dtnstub");
	}

	public static void main(String[] args)
	{
		new DTNStub("localhost", 47).openDTNAgent("localhost");
	}

    public DTNStub(String bundleAgentHost, int packetSize)
    {
		this.bundleAgentHost = bundleAgentHost;
		this.packetSize = packetSize;
    }

    public void registerPacketListener(PacketListenerIF listener)
    {
		listeners.add(listener);
    }

    public void Close() throws IOException
    {
		closeDTNAgent();
    }

    private short calculateCRC(byte packet[]) {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 2;
	crc = 0;
	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}
	return (crc);
    }

    public void Open() throws IOException
    {
		openDTNAgent(bundleAgentHost);
	}

	public void packetReceived(byte[] packet)
	{
		if (DEBUG) 
		{
			System.out.print("DTN: Got packet: ");
			for (int i = 0; i < packet.length; i++) 
			{
				System.out.print(Integer.toHexString(packet[i] & 0xff) + " ");
			}
			System.out.println("");
		}
		Enumeration e = listeners.elements();
		while (e.hasMoreElements()) 
		{
			PacketListenerIF listener = (PacketListenerIF)e.nextElement();
			listener.packetReceived(packet);
		}
	}

    public void Read() throws IOException
    {
		byte[] packet = new byte[packetSize];
		receiveDTNBundle(packet);
    }
  
    public void Write(byte[] pack) throws IOException 
	{
		short crc = calculateCRC(pack);
		pack[pack.length-1] = (byte) ((crc >> 8) & 0xff);
		pack[pack.length-2] = (byte) (crc & 0xff);
		sendDTNBundle(pack);
    }
}
