// $Id: TASKCommandInfo.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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

import java.io.*;

/**
 * Information about a TASK command.
 */
public class TASKCommandInfo implements Serializable
{
	/**
	 * Constructor for TASKCommandInfo.
	 *
	 * @param	name	name of command.
	 * @param	retType	return type id.
	 * @param	argTypes argument types.
	 * @param	description command description
	 */
	public TASKCommandInfo(String name, int retType, int[] argTypes, String description)
	{
		this.name = name;
		this.retType = retType;
		this.argTypes = argTypes;
		this.description = description;
	};
	/**
	 * Returns command name
	 */
	public String	getCommandName() {  return name; };
	/**
	 * Returns number of arguments
	 */
	public int	getNumArgs() { return argTypes.length; };
	/**
	 * Returns type of i-th argument.  i is 0-based
	 */
	public int		getArgType(int i) { return argTypes[i]; };
	/**
	 * Returns the return type of the command
	 */
	public int		getRetType() { return retType; };

	public int[] getArgTypes()
	{
		return argTypes;
	}

	/**
	 * returns command description
	 */
	public String	getDescription() { return description; };

	private String	name;			// command name
	private int[]	argTypes;		// argument types
	private int		retType;		// command return type
	private String	description;	// command description
};
