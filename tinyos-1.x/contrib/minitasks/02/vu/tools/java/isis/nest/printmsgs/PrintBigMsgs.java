/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 3/13/03
 */

package isis.nest.printmsgs;

import net.tinyos.util.*;
import java.util.*;

/**
 *	This application prints on the standard output all BigMsg messages.
 */
class PrintBigMsgs implements PacketListenerIF
{
	protected static void printArguments()
	{
		System.out.println("Arguments:");
		SerialStubFactory.printArguments();
		System.out.println("  [-am <active message>]  The active message id (0x6F)");
		System.out.println("  [-noid]                 Supress to print the source id of the messages");
		System.out.println("  [-timestamp]            Print arrival times");
		System.out.println("  [-help]                 Prints out this message");
	}

	protected static SerialStub serialStub;
	protected static byte activeMessage = 0x6F;
	protected static boolean supressId = false;
	protected static java.text.SimpleDateFormat timestamp = null;

	protected static void parseArguments(String[] args)
	{
		try
		{
			for(int i = 0; i < args.length; ++i)
			{
				int skip = SerialStubFactory.isParsed(args[i]);
				if( skip > 0 )
					i += skip - 1;
				else if( args[i].equals("-am") )
				{
					String arg = args[++i].toUpperCase();
					if( !arg.startsWith("0X") )
					{
						System.out.println("invalid argument: " + arg);
						serialStub = null;
					}
					else
						activeMessage = (byte)Integer.parseInt(arg.substring(2), 16);
				}
				else if( args[i].equals("-noid") )
					supressId = true;
				else if( args[i].equals("-timestamp") )
					timestamp = new java.text.SimpleDateFormat("HH:mm:ss.SSSS");
				else if( args[i].equals("-help") )
				{
					printArguments();
					return;
				}
				else
				{
					System.err.println("Invalid argument: " + args[i]);
					return;
				}
			}

			serialStub = SerialStubFactory.createSerialStub(args);
		}
		catch(Exception e)
		{
			System.err.println("Missing or invalid parameter(s)");
			serialStub = null;
		}
	}

	public static void main(String[] args) throws Exception
	{
		parseArguments(args);
		if( serialStub != null )
		{
			serialStub.registerPacketListener(new PrintBigMsgs());

			for(;;)
				serialStub.Read();
		}
	}

	static protected class BigMsg
	{
		int lastSeqNum;
		int nextPosition;
		byte[] packet;
	}

	protected HashMap bigMsgs = new HashMap();

	static final int PACKET_TYPE_FIELD = 2;
	static final int PACKET_LENGTH_FIELD = 4;
	static final int PACKET_SOURCE = 5;
	static final int PACKET_SEQNUM = 7;
	static final int PACKET_DATA = 8;
	static final int PACKET_CRC_SIZE = 2;

	// the first 5 bytes are: addr(2), type(1), group(1), length(1)
	public void packetReceived(byte[] packet)
	{
		if( packet[PACKET_TYPE_FIELD] != activeMessage )
			return;

		byte len = packet[PACKET_LENGTH_FIELD];
		int source = getShort(packet[PACKET_SOURCE], packet[PACKET_SOURCE+1]);
		int seqNum = packet[PACKET_SEQNUM] & 0xFF;

		// wrong format
		if( len < 4 || PACKET_SOURCE + len + PACKET_CRC_SIZE > packet.length )
			return;
		len -= 3;	// omit the source and seqnum fields

		byte[] data = new byte[len];
		System.arraycopy(packet, PACKET_DATA, data, 0, len);

		BigMsg bigMsg;
		if( seqNum == 0 )
		{
			bigMsgs.remove(new Integer(source));

			bigMsg = new BigMsg();
			bigMsg.lastSeqNum = 0;
			bigMsg.packet = new byte[getShort(data[0], data[1])];
			bigMsg.nextPosition = data.length - 2;
			System.arraycopy(data, 2, bigMsg.packet, 0, bigMsg.nextPosition);

			bigMsgs.put(new Integer(source), bigMsg);
		}
		else
		{
			bigMsg = (BigMsg)bigMsgs.get(new Integer(source));

			if( bigMsg == null || seqNum == bigMsg.lastSeqNum )
				return;
			else if( seqNum != bigMsg.lastSeqNum+1 )
				bigMsgs.remove(new Integer(source));

			bigMsg.lastSeqNum = seqNum;
			System.arraycopy(data, 0, bigMsg.packet, bigMsg.nextPosition, data.length);
			bigMsg.nextPosition += data.length;
		}

		if( bigMsg.nextPosition == bigMsg.packet.length )
		{
			bigMsgs.remove(new Integer(source));

			if( timestamp != null )
				System.out.print(timestamp.format(new java.util.Date()) + ' ');

			if( !supressId )
			{
				System.out.print(source);
				System.out.print(' ');
			}

			for(int i = 0; i < bigMsg.packet.length; ++i )
			{
				System.out.print(bigMsg.packet[i] & 0xFF);
				System.out.print(' ');
			}

			System.out.println();
		}
	}

	protected int getShort(byte a, byte b)
	{
		return (a & 0x00FF) + ((b << 8) & 0xFF00);
	}

}
