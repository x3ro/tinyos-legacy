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
 * Date last modified: 2/28/03
 */

package isis.nest.printmsgs;

import net.tinyos.util.*;

/**
 *	This application prints on the standard all messages.
 */
class PrintAllMsgs implements PacketListenerIF
{
	protected static void printArguments()
	{
		System.out.println("Arguments:");
		SerialStubFactory.printArguments();
		System.out.println("  [-timestamp]            Print arrival times");
		System.out.println("  [-help]                 Prints out this message");
	}

	protected static SerialStub serialStub;
	protected static java.text.SimpleDateFormat timestamp = null;

	protected static void parseArguments(String[] args)
	{
		for(int i = 0; i < args.length; ++i)
		{
			int skip = SerialStubFactory.isParsed(args[i]);
			if( skip > 0 )
				i += skip - 1;
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

	protected String getTimeStamp()
	{
		if( timestamp != null )
			return timestamp.format(new java.util.Date()) + ' ';

		return "";
	}

	public static void main(String[] args) throws Exception
	{
		parseArguments(args);
		if( serialStub != null )
		{
			serialStub.registerPacketListener(new PrintAllMsgs());

			for(;;)
				serialStub.Read();
		}
	}

	// the first 5 bytes are: addr(2), type(1), group(1), length(1)
	public void packetReceived(byte[] packet)
	{
		int type = packet[2] & 0xFF;
		int len = packet[4] & 0xFF;

		System.out.print(getTimeStamp());

		// note that addr is always 0x7e (UART) and group is the current group
		System.out.print("type=" + type);
		System.out.print(" length=" + len);

		// first 5 bytes + 2 bytes for CRC
		if( len > packet.length - 7 )
			len = packet.length - 7;

		System.out.print(" data:");
		for(int i = 0; i < len; ++i)
		{
			int data = packet[5+i] & 0xFF;
			System.out.print(" " + data);
		}

		System.out.println();
	}
}
