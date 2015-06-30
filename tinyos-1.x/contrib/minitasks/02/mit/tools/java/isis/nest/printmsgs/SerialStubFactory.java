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
 * Date last modified: 3/16/03
 */

package isis.nest.printmsgs;

import net.tinyos.util.*;
import java.io.*;

class SerialStubFactory
{
	protected static void printArguments()
	{
		System.out.println("  [-comm <port>]          The port name of direct connection (COM1)");
		System.out.println("  [-baud <baudrate>]      The speed of the serial port (19200)");
		System.out.println("  [-server <host>]        The host name of SerialForward (localhost)");
		System.out.println("  [-port <port>]          The port number of SerialForward (9000)");
		System.out.println("  [-packet-size <size>]   The size of the packets (36)");
	}
	
	/**
	 * Returns the number of arguments that are already parsed/accepted by this class
	 */
	public static int isParsed(String arg)
	{
		if( arg.equals("-comm") 
				|| arg.equals("-baud") 
				|| arg.equals("-server") 
				|| arg.equals("-port") 
				|| arg.equals("-packet-size") )
			return 2;
		else
			return 0;
	}

	public static SerialStub createSerialStub(String[] args)
	{
		String localPort = "COM1";
		String serverAddress = "";
		int baudrate = 19200;
		int serverPort = 9000;
		int packetSize = 36;
		int action = 0x0; // 0x0: default, 0x1: local, 0x2: server, 0x3 : illegal

		try
		{
			for(int i = 0; i < args.length; ++i)
			{
				if( args[i].equals("-comm") )
				{
					localPort = args[++i];
					action |= 0x1;
				}
				else if( args[i].equals("-baud") )
				{
					baudrate = Integer.parseInt(args[++i]);
					action |= 0x1;
				}
				else if( args[i].equals("-server") )
				{
					serverAddress = args[++i];
					action |= 0x2;
				}
				else if( args[i].equals("-port") )
				{
					serverPort = Integer.parseInt(args[++i]);
					action |= 0x2;
				}
				else if( args[i].equals("-packet-size") )
				{
					packetSize = Integer.parseInt(args[++i]);
				}
			}
		}
		catch(Exception e)
		{
			System.err.println("Missing or invalid parameter(s)");
			return null;
		}

		if( action == 0x2 )
		{
			try
			{
				SerialStub serialStub = new SerialForwarderStub(serverAddress, serverPort, packetSize);
				serialStub.Open();

				return serialStub;
			}
			catch(Exception e)
			{
				System.err.println("Could not connect to SerialForward: " + e.getMessage());
			}
		}
		else if( action == 0x0 || action == 0x1 )
		{
			try
			{
				SerialStub serialStub = new SerialPortStub(localPort, packetSize, baudrate);
				serialStub.Open();

				return serialStub;
			}
			catch(Exception e)
			{
				System.err.println("Could not connect to local port: " + e.toString());
			}
		}
		else if( action == 0x3 )
		{
			System.err.println("Incompatible parameters");
		}

		return null;
	}
}
