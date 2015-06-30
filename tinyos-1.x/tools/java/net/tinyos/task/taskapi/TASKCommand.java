// $Id: TASKCommand.java,v 1.4 2004/03/10 01:10:57 philipb Exp $

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
package net.tinyos.task.taskapi;

import java.util.*;
import java.io.*;
import net.tinyos.tinydb.CommandMsg;
import net.tinyos.tinydb.CommandMsgs;
import net.tinyos.message.*;

/**
 * Class encapsulating a TASK command call.
 */
public class TASKCommand implements Serializable
{
	public static final short BROADCAST_ID = (short)-1;
	/**
	 * Constructor for TASKCommand.
	 *
	 * @param	name	name of command.
	 * @param	arguments	Vector of Object for argument values.
	 * @param	moteId	a specific mote where the command is to be executed on
	 * 					or BROADCAST_ID for all motes.
	 */
	public TASKCommand(String name, Vector arguments, short moteId)
	{
		commandName = name;
		commandArguments = arguments;
		targetMoteId = moteId;
	};

	/**
	 * Returns the command name
	 */
	public String getCommandName() {  return commandName; };
	/**
	 * Returns argument values
	 *
	 * @return	Vector of Object's for argument values
	 */
	public Vector getCommandArguments() { return commandArguments; };
	/**
	 * Returns target mote id, BROADCAST_ID if it's for all motes
	 */
	public short getTargetMoteId() {  return targetMoteId; };

	public Message getTinyOSMessage(TASKCommandInfo commandInfo)
	{
		int msgSize = commandMsgSize(commandInfo);
		System.out.println("msgSize = " + msgSize + " name = " + commandName + " size = " + commandName.length());
		CommandMsg cmdMessage = new CommandMsg(msgSize);
		int i;
		int pos = 0;
		int[] argTypes = commandInfo.getArgTypes();

		if (commandArguments.size() < argTypes.length) {
			System.out.println("Malformed Command.  Expected " + argTypes.length + " args but got " + commandArguments.size());
		    return null; //invalid
		}
		cmdMessage.set_nodeid(targetMoteId);
		//cmdMessage.set_fromBase((byte)1);
		cmdMessage.set_seqNo(CommandMsgs.getNextSeqNo());
		for (i = 0; i < commandName.length(); i++)
			cmdMessage.setElement_data(pos++, (byte)commandName.charAt(i));
		cmdMessage.setElement_data(pos++, (byte)0);

		for (i = 0; i < argTypes.length; i++) {
			String argStr;
			try
				{
					argStr = (String)commandArguments.elementAt(i);
					pos = setArgValue(cmdMessage, pos, argTypes[i],argStr);
				}
			catch (Exception e)
				{
					System.out.println("Malformed argument vector. Cannot convert to string." + e.getMessage());
					return null;
				}
		}
		return cmdMessage;
	};

	private int commandMsgSize(TASKCommandInfo commandInfo)
	{
		int[] argTypes = commandInfo.getArgTypes();
		int size = CommandMsg.offset_data(0) + commandName.length() + 1;
		for (int i = 0; i < argTypes.length; i++)
			if (argTypes[i] == TASKTypes.STRING)
				size += ((String)commandArguments.elementAt(i)).length() + 1;
			else
				size += TASKTypes.typeLen(argTypes[i]);
		return size;
	}

	private int setArgValue(CommandMsg cmdMessage, int pos, int argType, String argVal) 
		throws NumberFormatException
	{
		switch (argType)
		{
			case TASKTypes.INT8:
			case TASKTypes.UINT8:
			case TASKTypes.BOOL:
				cmdMessage.setElement_data(pos++, Byte.parseByte(argVal));
				break;
			case TASKTypes.INT16:
			case TASKTypes.UINT16:
				{
					short val = Short.parseShort(argVal);
					cmdMessage.setElement_data(pos++, (byte)(val & 0xFF));
					cmdMessage.setElement_data(pos++, (byte)((val & 0xFF00) >> 8));
					break;
				}
			case TASKTypes.INT32:
			case TASKTypes.TIMESTAMP32:
				{
					int val = Integer.parseInt(argVal);
					cmdMessage.setElement_data(pos++, (byte)(val & 0xFF));
					cmdMessage.setElement_data(pos++, (byte)((val & 0xFF00) >> 8));
					cmdMessage.setElement_data(pos++, (byte)((val & 0xFF0000) >> 16));
					cmdMessage.setElement_data(pos++, (byte)((val & 0xFF000000) >> 24));
					break;
				}
			case TASKTypes.TIMESTAMP64:
				{
					// XXX to be supported later
					return -1;
				}
			case TASKTypes.STRING:
				{
					String val = argVal;
					for (int i = 0; i < val.length(); i++)
						cmdMessage.setElement_data(pos++, (byte)val.charAt(i));
					cmdMessage.setElement_data(pos++, (byte)0);
					break;
				}
			case TASKTypes.BYTES:
				{
					byte[] val = argVal.getBytes();
					for (int i = 0; i < val.length; i++)
						cmdMessage.setElement_data(pos++, (byte)val[i]);
					cmdMessage.setElement_data(pos++, (byte)0);
					break;
				}
		}
		return pos;
	}

	public String toString(TASKCommandInfo commandInfo)
	{
		String str = commandName + "(";
		boolean notFirst = false;
		for (Iterator it = commandArguments.iterator(); it.hasNext(); )
		{
			if (notFirst)
				str += ",";
			str += it.next();
			notFirst = true;
		}
		str += ")";
		return str;
	}

	private String	commandName;		// command name
	private Vector	commandArguments;	// Vector of Object's for argument values
	private short	targetMoteId;		// target mote id
};
