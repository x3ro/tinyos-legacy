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
 *	This application prints on the standard output all DiagMsg messages.
 */
class PrintDiagMsgs implements PacketListenerIF
{
	protected static void printArguments()
	{
		System.out.println("Arguments:");
		SerialStubFactory.printArguments();
		System.out.println("  [-tabs]                 Use tabs to separate fields");
		System.out.println("  [-timestamp]            Print arrival times");
		System.out.println("  [-help]                 Prints out this message");
	}

	protected static SerialStub serialStub;
	protected static String delimiter = " ";
	protected static java.text.SimpleDateFormat timestamp = null;

	protected static void parseArguments(String[] args)
	{
		for(int i = 0; i < args.length; ++i)
		{
			int skip = SerialStubFactory.isParsed(args[i]);
			if( skip > 0 )
				i += skip - 1;
			else if( args[i].equals("-tabs") )
				delimiter = "\t";
			else if( args[i].equals("-help") )
			{
				printArguments();
				return;
			}
			else if( args[i].equals("-timestamp") )
				timestamp = new java.text.SimpleDateFormat("HH:mm:ss.SSSS");
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
			return timestamp.format(new java.util.Date()) + delimiter;

		return "";
	}

	public static void main(String[] args) throws Exception
	{
		parseArguments(args);
		if( serialStub != null )
		{
			serialStub.registerPacketListener(new PrintDiagMsgs());

			for(;;)
				serialStub.Read();
		}
	}

	static final int PACKET_TYPE_FIELD = 2;
	static final int PACKET_LENGTH_FIELD = 4;
	static final int PACKET_DATA_FIELD = 5;
	static final int PACKET_CRC_SIZE = 2;

	static final byte DIAGMSG_ACTIVE_MESSAGE = (byte)0xB1;

	// the first 5 bytes are: addr(2), type(1), group(1), length(1)
	public void packetReceived(byte[] packet)
	{
		if( packet[PACKET_TYPE_FIELD] == DIAGMSG_ACTIVE_MESSAGE )
		{
			try
			{
				System.out.println(getTimeStamp() + decode(packet));
			}
			catch(DiagMsgException e)
			{
				System.out.println(e.getMessage());
			}
		}
	}

	static protected class DiagMsgException extends Exception
	{
		public DiagMsgException(String cause)
		{
			super(cause);
		}
	}

	protected byte[] packet;
	protected int end; 
	protected int head;
	protected StringBuffer line;

	protected synchronized String decode(byte[] packet) throws DiagMsgException
	{
		this.packet = packet;

		head = PACKET_DATA_FIELD;
		end = PACKET_DATA_FIELD + packet[PACKET_LENGTH_FIELD];

		if( end < head || end > packet.length - PACKET_CRC_SIZE )
			throw new DiagMsgException("illegal message length");

		line = new StringBuffer();

		while(head < end)
		{
			byte code = getByte();

			addSimple(code & 0xF);
			addSimple((code >> 4) & 0xF);
		}

		// delete the leading space
		if( line.length() > 0 && line.substring(0, delimiter.length()).equals(delimiter) )
			line.delete(0, delimiter.length());

		return new String(line);
	}

	static final int TYPE_END = 0;
	static final int TYPE_INT8 = 1;
	static final int TYPE_UINT8 = 2;
	static final int TYPE_HEX8 = 3;
	static final int TYPE_INT16 = 4;
	static final int TYPE_UINT16 = 5;
	static final int TYPE_HEX16 = 6;
	static final int TYPE_INT32 = 7;
	static final int TYPE_UINT32 = 8;
	static final int TYPE_HEX32 = 9;
	static final int TYPE_FLOAT = 10;
	static final int TYPE_CHAR = 11;
	static final int TYPE_INT64 = 12;
	static final int TYPE_UINT64 = 13;
	static final int TYPE_TOKEN = 14;
	static final int TYPE_ARRAY = 15;

	protected void addSimple(int type) throws DiagMsgException
	{
		switch(type)
		{
			case TYPE_END:                 break;
			case TYPE_INT8:   addInt8();   break;
			case TYPE_UINT8:  addUint8();  break;
			case TYPE_HEX8:   addHex8();   break;
			case TYPE_INT16:  addInt16();  break;
			case TYPE_UINT16: addUint16(); break;
			case TYPE_HEX16:  addHex16();  break;
			case TYPE_INT32:  addInt32();  break;
			case TYPE_UINT32: addUint32(); break;
			case TYPE_HEX32:  addHex32();  break;
			case TYPE_FLOAT:  addReal();   break;
			case TYPE_CHAR:   addChar();   break;
			case TYPE_INT64:  addInt64();  break;
			case TYPE_UINT64: addUint64(); break;
			case TYPE_TOKEN:  addToken();  break;
			case TYPE_ARRAY:  addArray();  break;
			
			default:
				line.append(delimiter + "unknown");
		}
	}

	protected void addArray() throws DiagMsgException
	{
		int len = getByte();
		int type = (len >> 4) & 0xF;
		len &= 0xF;

		if( type == TYPE_CHAR )
			addStr(len);
		else
		{
			line.append(delimiter + "[");

			while( --len >= 0 )
				addSimple(type);

			line.append(" ]");
		}
	}

	protected void check(int len) throws DiagMsgException
	{
		if( head + len > end )
			throw new DiagMsgException("illegal message format");
	}

	protected byte getByte() throws DiagMsgException
	{
		check(1);
		byte ret = packet[head];
		head += 1;
		return ret;
	}

	protected short getShort() throws DiagMsgException
	{
		short a,b;
		check(2);

		a = packet[head];            a &= 0x00FF;
		b = packet[head+1]; b <<= 8; b &= 0xFF00; a |= b;

		head += 2;
		return a;
	}

	protected int getInt() throws DiagMsgException
	{
		int a,b;
		check(4);

		a = packet[head];             a &= 0x000000FF;
		b = packet[head+1]; b <<= 8;  b &= 0x0000FF00; a |= b;
		b = packet[head+2]; b <<= 16; b &= 0x00FF0000; a |= b;
		b = packet[head+3]; b <<= 24; b &= 0xFF000000; a |= b;

		head += 4;
		return a;
	}

	protected long getLong() throws DiagMsgException
	{
		long a,b;
		check(8);

		a = packet[head];             a &= 0x00000000000000FF;
		b = packet[head+1]; b <<= 8;  b &= 0x000000000000FF00; a |= b;
		b = packet[head+2]; b <<= 16; b &= 0x0000000000FF0000; a |= b;
		b = packet[head+3]; b <<= 24; b &= 0x00000000FF000000; a |= b;
		b = packet[head+4]; b &= 0x00000000000000FF; b <<= 32; a |= b;
		b = packet[head+5]; b &= 0x00000000000000FF; b <<= 40; a |= b;
		b = packet[head+6]; b &= 0x00000000000000FF; b <<= 48; a |= b;
		b = packet[head+7]; b &= 0x00000000000000FF; b <<= 56; a |= b;

		head += 8;
		return a;
	}

	protected void addUint8() throws DiagMsgException
	{
		String value = Integer.toString(getByte() & 0xFF);
		line.append(delimiter + value);
	}

	protected void addInt8() throws DiagMsgException
	{
		String value = Byte.toString(getByte());
		line.append(delimiter + value);
	}

	protected void addHex8() throws DiagMsgException
	{
		String value = Integer.toHexString(getByte() & 0xFF);

		line.append(delimiter + "0x");
		for(int i = value.length(); i < 2; ++i)
			line.append('0');
		line.append(value);
	}

	protected void addUint16() throws DiagMsgException
	{
		String value = Integer.toString(getShort() & 0xFFFF);
		line.append(delimiter + value);
	}

	protected void addInt16() throws DiagMsgException
	{
		String value = Short.toString(getShort());
		line.append(delimiter + value);
	}

	protected void addHex16() throws DiagMsgException
	{
		String value = Integer.toHexString(getShort() & 0xFFFF);

		line.append(delimiter + "0x");
		for(int i = value.length(); i < 4; ++i)
			line.append('0');
		line.append(value);
	}

	protected void addUint32() throws DiagMsgException
	{
		String value = Long.toString(getInt() & 0xFFFFFFFF);
		line.append(delimiter + value);
	}

	protected void addInt32() throws DiagMsgException
	{
		String value = Integer.toString(getInt());
		line.append(delimiter + value);
	}

	protected void addHex32() throws DiagMsgException
	{
		String value = Integer.toHexString(getInt());

		line.append(delimiter + "0x");
		for(int i = value.length(); i < 8; ++i)
			line.append('0');
		line.append(value);
	}

	protected void addInt64() throws DiagMsgException
	{
		String value = Long.toString(getLong());
		line.append(delimiter + value);
	}

	protected void addUint64() throws DiagMsgException
	{
		String value = Long.toString(getLong());
		line.append(delimiter + value);
	}

	protected void addReal() throws DiagMsgException
	{
		float value = Float.intBitsToFloat(getInt());
		line.append(delimiter + Float.toString(value));
	}

	protected void addChar() throws DiagMsgException
	{
		char value = (char)getByte();
		line.append(delimiter + "'" + value + "'");
	}

	protected void addStr(int len) throws DiagMsgException
	{
		line.append(delimiter + "\"");

		while( --len >= 0 )
			line.append((char)getByte());

		line.append('"');
	}

	protected void addToken() throws DiagMsgException
	{
		int token = getByte() & 0xFF;

		line.append(delimiter);

		switch(token)
		{
			case 0 : line.append("false"); break;
			case 1 : line.append("true"); break;
			case 2 : line.append("node"); break;
			case 3 : line.append("source"); break;
			case 4 : line.append("destination"); break;
			case 5 : line.append("target"); break;
			case 6 : line.append("minimum"); break;
			case 7 : line.append("maximum"); break;
			case 8 : line.append("mean"); break;
			case 9 : line.append("average"); break;
			case 10 : line.append("time"); break;
			case 11 : line.append("counter"); break;
			case 12 : line.append("stamp"); break;
			case 13 : line.append("sequence"); break;
			case 14 : line.append("number"); break;
			case 15 : line.append("config"); break;
			case 16 : line.append("diameter"); break;
			case 17 : line.append("fail"); break;
			case 18 : line.append("success"); break;
			case 19 : line.append("ack"); break;
			case 20 : line.append("power"); break;
			case 21 : line.append("local"); break;
			case 22 : line.append("remote"); break;
			case 23 : line.append("leader"); break;
			case 24 : line.append("root"); break;
			case 25 : line.append("first"); break;
			case 26 : line.append("second"); break;
			case 27 : line.append("third"); break;
			case 28 : line.append("nodeid"); break;
			case 29 : line.append("delta"); break;
			case 30 : line.append("delay"); break;
			case 31 : line.append("rate"); break;
			case 32 : line.append("frequency"); break;
			case 33 : line.append("coord"); break;
			case 34 : line.append("coords"); break;
			case 35 : line.append("angle"); break;
			case 36 : line.append("temperature"); break;
			case 37 : line.append("light"); break;
			case 38 : line.append("next"); break;
			case 39 : line.append("previous"); break;
			case 40 : line.append("start"); break;
			case 41 : line.append("end"); break;
			case 42 : line.append("speed"); break;
			case 43 : line.append("cpu"); break;
			case 44 : line.append("beacon"); break;
			case 45 : line.append("arrival"); break;
			case 46 : line.append("senddone"); break;
			case 47 : line.append("global"); break;
			case 48 : line.append("clock"); break;

			default:
				line.append("token:" + token);
		}
	}
}
